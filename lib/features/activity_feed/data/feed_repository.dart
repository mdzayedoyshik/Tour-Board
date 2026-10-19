import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../settings/data/preferences.dart';
import '../domain/feed_event.dart';

class FeedRepository {
  FeedRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String tourId) =>
      _db.collection(FirestorePaths.activityFeed(tourId));

  /// Builds the document data for an event so callers can include it in
  /// their own batch (atomic with the change it describes).
  Map<String, dynamic> eventData({
    required FeedEventType type,
    required String actorUid,
    String? subjectUid,
    String? refId,
    String? label,
  }) => {
    'type': type.name,
    'actorUid': actorUid,
    'subjectUid': ?subjectUid,
    'refId': ?refId,
    if (label != null && label.trim().isNotEmpty)
      'label': label.trim().length > FeedEvent.maxLabelLength
          ? label.trim().substring(0, FeedEvent.maxLabelLength)
          : label.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  };

  DocumentReference<Map<String, dynamic>> newRef(String tourId) =>
      _col(tourId).doc();

  /// Best-effort standalone event. Failures are logged, never surfaced: the
  /// feed is informational and must not block the real action.
  Future<void> record(
    String tourId, {
    required FeedEventType type,
    required String actorUid,
    String? subjectUid,
    String? refId,
    String? label,
  }) async {
    try {
      await _col(tourId)
          .doc()
          .set(
            eventData(
              type: type,
              actorUid: actorUid,
              subjectUid: subjectUid,
              refId: refId,
              label: label,
            ),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Feed event not recorded: $e');
    }
  }

  /// Live first page only; older pages are fetched on demand.
  Stream<Snapshot<FeedEvent>> watchRecent(String tourId) => watchQuery(
    _col(tourId).orderBy('createdAt', descending: true),
    (doc) => FeedEvent.fromDoc(doc.id, doc.data()),
    limit: FeedEvent.pageSize,
  );

  Future<List<FeedEvent>> fetchOlder(String tourId, DateTime before) async {
    final snap = await _col(tourId)
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(before)])
        .limit(FeedEvent.pageSize)
        .get();
    return snap.docs.map((d) => FeedEvent.fromDoc(d.id, d.data())).toList();
  }
}

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepository(ref.watch(firestoreProvider)),
);

final recentFeedProvider = StreamProvider.autoDispose
    .family<Snapshot<FeedEvent>, String>(
      (ref, tourId) => ref.watch(feedRepositoryProvider).watchRecent(tourId),
    );

/// Last time this device opened a tour's activity feed (device-local).
class FeedSeenStore {
  FeedSeenStore(this._ref);
  final Ref _ref;

  String _key(String tourId) => 'feedSeen.$tourId';

  DateTime? lastSeen(String tourId) {
    final ms = _ref.read(sharedPreferencesProvider).getInt(_key(tourId));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markSeen(String tourId) => _ref
      .read(sharedPreferencesProvider)
      .setInt(_key(tourId), DateTime.now().millisecondsSinceEpoch);
}

final feedSeenStoreProvider = Provider<FeedSeenStore>(FeedSeenStore.new);

/// Unseen expense/plan events by others, filtered by the user's
/// notification preferences. Drives a small dot on the Activity entry.
final unseenFeedCountProvider = Provider.autoDispose.family<int, String>((
  ref,
  tourId,
) {
  final prefs = ref.watch(preferencesProvider);
  if (!prefs.notifyExpenses && !prefs.notifyPlans) return 0;
  final uid = ref.watch(currentUidProvider);
  final seen = ref.read(feedSeenStoreProvider).lastSeen(tourId);
  final events = ref.watch(recentFeedProvider(tourId)).value?.items ?? const [];
  const expenseTypes = {
    FeedEventType.expenseAdded,
    FeedEventType.expenseEdited,
    FeedEventType.expenseDeleted,
  };
  const planTypes = {FeedEventType.planAdded, FeedEventType.planEdited};
  return events.where((e) {
    if (e.actorUid == uid) return false;
    if (seen != null && !e.createdAt.isAfter(seen)) return false;
    return (prefs.notifyExpenses && expenseTypes.contains(e.type)) ||
        (prefs.notifyPlans && planTypes.contains(e.type));
  }).length;
});
