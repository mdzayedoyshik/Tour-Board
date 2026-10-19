import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../domain/packing_item.dart';

/// One document per item keeps conflicts small: two people ticking
/// different items never collide.
class PackingRepository {
  PackingRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String tourId) =>
      _db.collection(FirestorePaths.packingItems(tourId));

  Stream<Snapshot<PackingItem>> watch(String tourId) => watchQuery(
    _col(tourId).orderBy('createdAt'),
    (doc) => PackingItem.fromDoc(
      doc.id,
      doc.data(),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    ),
    limit: PackingItem.queryLimit,
  );

  Future<WriteOutcome> add(String tourId, String label, String uid) =>
      commitQueued(
        _col(tourId).doc().set({
          'label': label.trim(),
          'checked': false,
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  /// Persists only the final state change, not intermediate animation.
  Future<WriteOutcome> setChecked(
    String tourId,
    PackingItem item,
    bool checked,
    String uid,
  ) => commitQueued(
    _col(tourId).doc(item.id).update({
      'checked': checked,
      'checkedBy': checked ? uid : null,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<WriteOutcome> assign(
    String tourId,
    PackingItem item,
    String? assigneeUid,
  ) => commitQueued(
    _col(tourId).doc(item.id).update({
      'assigneeUid': assigneeUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<WriteOutcome> delete(String tourId, String itemId) =>
      commitQueued(_col(tourId).doc(itemId).delete());
}

final packingRepositoryProvider = Provider<PackingRepository>(
  (ref) => PackingRepository(ref.watch(firestoreProvider)),
);

final packingItemsProvider = StreamProvider.autoDispose
    .family<Snapshot<PackingItem>, String>(
      (ref, tourId) => ref.watch(packingRepositoryProvider).watch(tourId),
    );
