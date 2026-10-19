import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../data/firebase/firestore_helpers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../activity_feed/data/feed_repository.dart';
import '../../activity_feed/domain/feed_event.dart';
import '../../membership/domain/invite_code.dart';
import '../domain/tour.dart';

/// Values from the create/edit tour form.
class TourDraft {
  const TourDraft({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.timeZone,
    this.description,
    this.budgetMinor,
  });

  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final String timeZone;
  final int? budgetMinor;

  Map<String, dynamic> detailFields() => {
    'name': name.trim(),
    'description': blankToNull(description),
    'startAt': Timestamp.fromDate(dateOnlyUtc(startDate)),
    'endAt': Timestamp.fromDate(dateOnlyUtc(endDate)),
    'timeZone': timeZone,
    'currencyCode': currencyCode,
    'budgetMinor': budgetMinor,
  };
}

/// A Home list entry: the tour plus a cheap member count.
class TourSummary {
  const TourSummary({required this.tour, this.activeMemberCount});

  final Tour tour;

  /// From a count() aggregation; null when offline.
  final int? activeMemberCount;
}

class TourRepository {
  TourRepository(this._db, this._feed);

  final FirebaseFirestore _db;
  final FeedRepository _feed;

  DocumentReference<Map<String, dynamic>> _tour(String id) =>
      _db.doc(FirestorePaths.tour(id));

  /// Pre-generates an ID so a retried create is idempotent.
  String newTourId() => _db.collection(FirestorePaths.tours).doc().id;

  Stream<Tour?> watchTour(String tourId) => watchDoc(
    _tour(tourId),
    (doc) => Tour.fromDoc(
      doc.id,
      doc.data()!,
      hasPendingWrites: doc.metadata.hasPendingWrites,
    ),
  );

  Stream<List<TourMembershipIndex>> watchMembershipIndex(String uid) =>
      watchQuery(
        _db
            .collection(FirestorePaths.membershipIndex(uid))
            .orderBy('joinedAt', descending: true),
        (doc) => TourMembershipIndex.fromDoc(doc.id, doc.data()),
        limit: 100,
      ).map((s) => s.items);

  /// One get() per tour plus a count() aggregation, instead of a live
  /// listener per tour on Home. Tours the user can no longer read (removed,
  /// deleted) are skipped and their stale index entries cleaned up.
  Future<List<TourSummary>> fetchSummaries(
    String uid,
    List<TourMembershipIndex> index,
  ) async {
    final results = await Future.wait(
      index.map((entry) async {
        try {
          final snap = await _tour(entry.tourId).get();
          if (!snap.exists) {
            await _removeIndex(uid, entry.tourId);
            return null;
          }
          final tour = Tour.fromDoc(snap.id, snap.data()!);
          int? count;
          try {
            final agg = await _db
                .collection(FirestorePaths.members(tour.id))
                .where('status', isEqualTo: 'active')
                .count()
                .get();
            count = agg.count;
          } catch (_) {
            count = null; // Aggregations need the network.
          }
          return TourSummary(tour: tour, activeMemberCount: count);
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            await _removeIndex(uid, entry.tourId);
          }
          return null;
        }
      }),
    );
    return results.whereType<TourSummary>().toList();
  }

  Future<void> _removeIndex(String uid, String tourId) async {
    try {
      await _db.doc(FirestorePaths.membershipIndexEntry(uid, tourId)).delete();
    } catch (e) {
      debugPrint('Could not remove stale index $tourId: $e');
    }
  }

  /// Creates the tour, the host's member record, the membership index and a
  /// first invite in one atomic batch.
  Future<WriteOutcome> createTour({
    required String tourId,
    required TourDraft draft,
    required String hostUid,
    required String hostName,
    String? hostPhotoUrl,
  }) {
    final code = InviteCodes.generate();
    final batch = _db.batch();
    final now = DateTime.now().toUtc();
    final status = now.isBefore(dateOnlyUtc(draft.startDate))
        ? TourStatus.upcoming
        : TourStatus.active;
    batch.set(_tour(tourId), {
      ...draft.detailFields(),
      'hostUid': hostUid,
      'status': status.name,
      'inviteCode': code,
      'allMemberUids': [hostUid],
      'settings': const TourSettings().toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': Tour.schemaVersion,
    });
    batch.set(_db.doc(FirestorePaths.member(tourId, hostUid)), {
      'uid': hostUid,
      'displayNameSnapshot': hostName,
      'photoUrlSnapshot': ?hostPhotoUrl,
      'role': 'host',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.doc(FirestorePaths.membershipIndexEntry(hostUid, tourId)), {
      'tourId': tourId,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _db.doc('${FirestorePaths.invites}/$code'),
      _inviteData(
        tourId: tourId,
        tourName: draft.name.trim(),
        hostUid: hostUid,
        hostName: hostName,
        startDate: draft.startDate,
        endDate: draft.endDate,
        createdBy: hostUid,
      ),
    );
    return commitQueued(batch.commit());
  }

  Map<String, dynamic> _inviteData({
    required String tourId,
    required String tourName,
    required String hostUid,
    required String hostName,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
  }) => {
    'tourId': tourId,
    'tourName': tourName,
    'hostUid': hostUid,
    'hostName': hostName,
    'startAt': Timestamp.fromDate(dateOnlyUtc(startDate)),
    'endAt': Timestamp.fromDate(dateOnlyUtc(endDate)),
    'expiresAt': Timestamp.fromDate(
      DateTime.now().toUtc().add(InviteCodes.defaultLifetime),
    ),
    'revoked': false,
    'createdBy': createdBy,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Future<WriteOutcome> updateDetails(
    String tourId,
    TourDraft draft,
    String actorUid,
  ) {
    final batch = _db.batch()
      ..update(_tour(tourId), {
        ...draft.detailFields(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        _feed.newRef(tourId),
        _feed.eventData(
          type: FeedEventType.tourUpdated,
          actorUid: actorUid,
          label: draft.name,
        ),
      );
    return commitQueued(batch.commit());
  }

  /// Lifecycle changes require the server (no offline status changes), so
  /// this awaits the acknowledgement.
  Future<void> setStatus(Tour tour, TourStatus status, String actorUid) async {
    final type = switch (status) {
      TourStatus.closed => FeedEventType.tourClosed,
      TourStatus.archived => FeedEventType.tourArchived,
      _ => FeedEventType.tourReopened,
    };
    final batch = _db.batch()
      ..update(_tour(tour.id), {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        _feed.newRef(tour.id),
        _feed.eventData(type: type, actorUid: actorUid),
      );
    await batch.commit().timeout(const Duration(seconds: 20));
  }

  Future<void> updateSettings(String tourId, TourSettings settings) =>
      _tour(tourId)
          .update({
            'settings': settings.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 20));

  /// Issues a new invite code and revokes the previous one atomically.
  Future<String> rotateInvite(
    Tour tour, {
    required String actorUid,
    required String hostName,
  }) async {
    final code = InviteCodes.generate();
    final batch = _db.batch()
      ..set(
        _db.doc('${FirestorePaths.invites}/$code'),
        _inviteData(
          tourId: tour.id,
          tourName: tour.name,
          hostUid: tour.hostUid,
          hostName: hostName,
          startDate: tour.startAt,
          endDate: tour.endAt,
          createdBy: actorUid,
        ),
      )
      ..update(_tour(tour.id), {
        'inviteCode': code,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    final old = tour.inviteCode;
    if (old != null) {
      batch.update(_db.doc('${FirestorePaths.invites}/$old'), {
        'revoked': true,
      });
    }
    await batch.commit().timeout(const Duration(seconds: 20));
    return code;
  }

  /// Disables joining until a new invite is created.
  Future<void> revokeInvite(Tour tour) async {
    final old = tour.inviteCode;
    final batch = _db.batch()
      ..update(_tour(tour.id), {
        'inviteCode': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    if (old != null) {
      batch.update(_db.doc('${FirestorePaths.invites}/$old'), {
        'revoked': true,
      });
    }
    await batch.commit().timeout(const Duration(seconds: 20));
  }

  /// Bounded deletion of an archived tour by its host.
  ///
  /// Without a backend there is no recursive delete, so the client removes
  /// known subcollections page by page (max [maxDocs] documents). Revision
  /// documents are addressed directly by their sequential IDs. If the limit
  /// is hit the tour stays archived and the host can run deletion again.
  Future<bool> deleteArchivedTour(
    Tour tour,
    String hostUid, {
    int maxDocs = 5000,
  }) async {
    var budget = maxDocs;

    Future<void> deleteRefs(
      List<DocumentReference<Map<String, dynamic>>> refs,
    ) async {
      for (var i = 0; i < refs.length; i += 400) {
        final batch = _db.batch();
        for (final ref in refs.skip(i).take(400)) {
          batch.delete(ref);
        }
        await batch.commit();
      }
      budget -= refs.length;
    }

    Future<bool> drain(String path, {bool withRevisions = false}) async {
      while (budget > 0) {
        final snap = await _db.collection(path).limit(300).get();
        if (snap.docs.isEmpty) return true;
        final refs = <DocumentReference<Map<String, dynamic>>>[];
        for (final doc in snap.docs) {
          if (withRevisions) {
            final count = readInt(doc.data()['revisionCount']);
            for (var r = 1; r <= count; r++) {
              refs.add(doc.reference.collection('revisions').doc('$r'));
            }
          }
          refs.add(doc.reference);
        }
        await deleteRefs(refs);
      }
      return false;
    }

    final id = tour.id;
    final complete =
        await drain(FirestorePaths.expenses(id), withRevisions: true) &&
        await drain(FirestorePaths.notes(id), withRevisions: true) &&
        await drain(FirestorePaths.settlements(id)) &&
        await drain(FirestorePaths.activities(id)) &&
        await drain(FirestorePaths.packingItems(id)) &&
        await drain(FirestorePaths.activityFeed(id)) &&
        await drain(FirestorePaths.joinRequests(id));
    if (!complete) return false;

    // Membership indexes and member records (host's own record last: rules
    // need it to authorise the deletes above).
    final members = await _db.collection(FirestorePaths.members(id)).get();
    final refs = <DocumentReference<Map<String, dynamic>>>[];
    for (final m in members.docs) {
      refs.add(_db.doc(FirestorePaths.membershipIndexEntry(m.id, id)));
      if (m.id != hostUid) refs.add(m.reference);
    }
    final code = tour.inviteCode;
    if (code != null) refs.add(_db.doc('${FirestorePaths.invites}/$code'));
    await deleteRefs(refs);
    await _tour(id).delete();
    await _db.doc(FirestorePaths.member(id, hostUid)).delete();
    return true;
  }
}

final tourRepositoryProvider = Provider<TourRepository>(
  (ref) => TourRepository(
    ref.watch(firestoreProvider),
    ref.watch(feedRepositoryProvider),
  ),
);

/// The open tour document. One listener per visible workspace.
final tourProvider = StreamProvider.autoDispose.family<Tour?, String>(
  (ref, tourId) => ref.watch(tourRepositoryProvider).watchTour(tourId),
);

/// Home list: index stream + one fetch per tour.
final myToursProvider = StreamProvider.autoDispose<List<TourSummary>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  final repo = ref.watch(tourRepositoryProvider);
  return repo
      .watchMembershipIndex(uid)
      .asyncMap((index) => repo.fetchSummaries(uid, index));
});
