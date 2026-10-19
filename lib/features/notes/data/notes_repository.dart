import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../data/firebase/firestore_helpers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../expenses/domain/expense.dart';
import '../domain/note.dart';

class NotesRepository {
  NotesRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String tourId) =>
      _db.collection(FirestorePaths.notes(tourId));

  Stream<Snapshot<Note>> watchRecent(String tourId) => watchQuery(
    _col(tourId).orderBy('updatedAt', descending: true),
    (doc) => Note.fromDoc(
      doc.id,
      doc.data(),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    ),
    limit: Note.pageSize,
  );

  /// Single-note listener for the detail screen (also covers older notes
  /// that are not in the live first page).
  Stream<Note?> watchNote(String tourId, String noteId) => watchDoc(
    _col(tourId).doc(noteId),
    (doc) => Note.fromDoc(
      doc.id,
      doc.data()!,
      hasPendingWrites: doc.metadata.hasPendingWrites,
    ),
  );

  Future<List<Note>> fetchOlder(String tourId, DateTime before) async {
    final snap = await _col(tourId)
        .orderBy('updatedAt', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(Note.pageSize)
        .get();
    return snap.docs.map((d) => Note.fromDoc(d.id, d.data())).toList();
  }

  Future<WriteOutcome> add(
    String tourId, {
    String? title,
    required String body,
    required String uid,
  }) => commitQueued(
    _col(tourId).doc().set({
      'title': ?blankToNull(title),
      'body': body.trim(),
      'createdBy': uid,
      'updatedBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'revisionCount': 0,
    }),
  );

  /// Notes are not financial, but a concurrent edit is still detected and
  /// reported (rather than silently overwritten) via the revision counter.
  Future<void> edit(
    String tourId,
    Note note, {
    String? title,
    required String body,
    required String uid,
  }) async {
    final ref = _col(tourId).doc(note.id);
    await _db
        .runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) throw const AppException(AppErrorKind.notFound);
          final current = Note.fromDoc(snap.id, snap.data()!);
          if (current.revisionCount != note.revisionCount) {
            throw const AppException(AppErrorKind.conflict);
          }
          final after = {'title': blankToNull(title), 'body': body.trim()};
          final fields = diffFields(current.editableFields(), after);
          if (fields.isEmpty) return;
          if (current.revisionCount + 1 > Revision.maxRevisions) {
            throw const AppException(AppErrorKind.quota, 'revisions');
          }
          final revision = current.revisionCount + 1;
          tx.set(ref, {
            'title': ?after['title'],
            'body': after['body'],
            'createdBy': current.createdBy,
            'createdAt': snap.data()!['createdAt'],
            'updatedBy': uid,
            'updatedAt': FieldValue.serverTimestamp(),
            'revisionCount': revision,
          });
          final before = current.editableFields();
          tx.set(ref.collection('revisions').doc('$revision'), {
            'editorUid': uid,
            'editedAt': FieldValue.serverTimestamp(),
            'changedFields': fields,
            'before': {for (final f in fields) f: before[f]},
            'after': {for (final f in fields) f: after[f]},
          });
        })
        .timeout(const Duration(seconds: 20));
  }

  /// Deletes the note and its revisions (addressed by sequential IDs).
  Future<void> delete(String tourId, Note note) async {
    final ref = _col(tourId).doc(note.id);
    final batch = _db.batch()..delete(ref);
    for (var r = 1; r <= note.revisionCount; r++) {
      batch.delete(ref.collection('revisions').doc('$r'));
    }
    await commitQueued(batch.commit());
  }

  Future<List<Revision>> fetchRevisions(String tourId, String noteId) async {
    final snap = await _col(tourId)
        .doc(noteId)
        .collection('revisions')
        .orderBy('editedAt', descending: true)
        .limit(Revision.maxRevisions)
        .get();
    return snap.docs.map((d) => Revision.fromDoc(d.id, d.data())).toList();
  }
}

final notesRepositoryProvider = Provider<NotesRepository>(
  (ref) => NotesRepository(ref.watch(firestoreProvider)),
);

final recentNotesProvider = StreamProvider.autoDispose
    .family<Snapshot<Note>, String>(
      (ref, tourId) => ref.watch(notesRepositoryProvider).watchRecent(tourId),
    );

final noteProvider = StreamProvider.autoDispose
    .family<Note?, ({String tourId, String noteId})>(
      (ref, key) =>
          ref.watch(notesRepositoryProvider).watchNote(key.tourId, key.noteId),
    );
