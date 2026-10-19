import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../domain/location_share.dart';

class LocationRepository {
  LocationRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String tourId) =>
      _db.collection(FirestorePaths.locations(tourId));

  /// Only the Map screen listens to this (≤ one doc per member).
  Stream<Snapshot<LocationShare>> watch(String tourId) => watchQuery(
    _col(tourId),
    (doc) => LocationShare.fromDoc(doc.id, doc.data()),
    limit: 60,
  );

  /// Overwrites the single latest-location document. No history is kept.
  Future<void> write({
    required String tourId,
    required String uid,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    required DateTime sharingUntil,
    String sourceStatus = 'live',
  }) => _col(tourId)
      .doc(uid)
      .set({
        'uid': uid,
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': ?accuracyMeters,
        'updatedAt': FieldValue.serverTimestamp(),
        'sharingUntil': Timestamp.fromDate(sharingUntil.toUtc()),
        'sourceStatus': sourceStatus,
      })
      .timeout(const Duration(seconds: 15));

  Future<void> setPaused(String tourId, String uid, bool paused) => _col(tourId)
      .doc(uid)
      .update({
        'sourceStatus': paused ? 'paused' : 'live',
        'updatedAt': FieldValue.serverTimestamp(),
      })
      .timeout(const Duration(seconds: 15));

  Future<void> stop(String tourId, String uid) =>
      _col(tourId).doc(uid).delete();

  /// Bounded cleanup of expired records the viewer can see. The UI already
  /// hides them by timestamp; this just keeps the collection small.
  Future<void> cleanupExpired(
    String tourId,
    Iterable<LocationShare> shares,
    DateTime now,
  ) async {
    final expired = shares.where((s) => s.isExpired(now)).take(20).toList();
    if (expired.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final s in expired) {
        batch.delete(_col(tourId).doc(s.uid));
      }
      await batch.commit().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Location cleanup skipped: $e');
    }
  }
}

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => LocationRepository(ref.watch(firestoreProvider)),
);

final locationsProvider = StreamProvider.autoDispose
    .family<Snapshot<LocationShare>, String>(
      (ref, tourId) => ref.watch(locationRepositoryProvider).watch(tourId),
    );
