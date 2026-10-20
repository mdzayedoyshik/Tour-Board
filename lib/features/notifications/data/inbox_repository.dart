import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../settings/data/preferences.dart';
import '../domain/inbox_item.dart';

/// In-app notifications at users/{uid}/inbox.
///
/// Items are written only by the Tour Board backend, after it verifies the
/// event against Firestore (see EventReporter); the same event is also
/// delivered as a push notification. The owner can read, mark read and
/// delete their items.
class InboxRepository {
  InboxRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection(FirestorePaths.inbox(uid));

  Stream<Snapshot<InboxItem>> watchRecent(String uid) => watchQuery(
    _col(uid).orderBy('createdAt', descending: true),
    (doc) => InboxItem.fromDoc(doc.id, doc.data()),
    limit: InboxItem.pageSize,
  );

  Future<void> markRead(String uid, String id) =>
      _col(uid).doc(id).update({'read': true});

  Future<void> markAllRead(String uid, Iterable<InboxItem> items) async {
    final unread = items.where((i) => !i.read).toList();
    if (unread.isEmpty) return;
    final batch = _db.batch();
    for (final item in unread) {
      batch.update(_col(uid).doc(item.id), {'read': true});
    }
    await batch.commit();
  }

  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();

  /// Lazy, bounded cleanup of expired records when the owner opens the
  /// inbox. Not guaranteed to run; the UI hides expired items regardless.
  Future<void> cleanupExpired(String uid) async {
    try {
      final snap = await _col(
        uid,
      ).where('expiresAt', isLessThan: Timestamp.now()).limit(50).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Inbox cleanup skipped: $e');
    }
  }

  /// Deletes up to [max] inbox records; used during account deletion.
  Future<void> deleteAll(String uid, {int max = 500}) async {
    var deleted = 0;
    while (deleted < max) {
      final snap = await _col(uid).limit(100).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += snap.docs.length;
    }
  }
}

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(ref.watch(firestoreProvider)),
);

final inboxProvider = StreamProvider.autoDispose<Snapshot<InboxItem>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return Stream.value(
      const Snapshot(items: [], fromCache: false, hasPendingWrites: false),
    );
  }
  return ref.watch(inboxRepositoryProvider).watchRecent(uid);
});

/// Unread, unexpired items in the first page — the Home badge count.
final unreadInboxCountProvider = Provider.autoDispose<int>((ref) {
  final prefs = ref.watch(preferencesProvider);
  final now = ref.watch(clockProvider)();
  final items = ref.watch(inboxProvider).value?.items ?? const [];
  return items
      .where((i) => !i.read && !i.isExpired(now) && inboxVisible(i, prefs))
      .length;
});

/// Hides categories the user switched off in Settings.
bool inboxVisible(InboxItem item, AppPreferences prefs) => switch (item.type) {
  InboxType.expenseAdded ||
  InboxType.expenseEdited ||
  InboxType.expenseDeleted => prefs.notifyExpenses,
  InboxType.planAdded || InboxType.planEdited => prefs.notifyPlans,
  InboxType.tourDeletionSoon => true,
  _ => prefs.notifyImportant,
};
