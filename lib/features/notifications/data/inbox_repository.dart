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
/// There is no trusted server in strict free mode, so these records are
/// written by the acting member's client and validated by Security Rules
/// (type-specific sender/recipient checks, no free text). Remote push is not
/// sent; recipients see items while the app is open.
class InboxRepository {
  InboxRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection(FirestorePaths.inbox(uid));

  /// Best-effort notification to each recipient (sender excluded).
  Future<void> notify({
    required Iterable<String> recipientUids,
    required InboxType type,
    required String tourId,
    required String tourName,
    required String senderUid,
    required String senderName,
    String? refId,
  }) async {
    final recipients = recipientUids.toSet()..remove(senderUid);
    if (recipients.isEmpty) return;
    final expiresAt = DateTime.now().toUtc().add(InboxItem.lifetime);
    // One write per recipient rather than a batch: rules check sender and
    // recipient membership with get() calls, and a batch shares a single
    // access budget across all its writes.
    await Future.wait([
      for (final uid in recipients)
        _col(uid)
            .doc()
            .set({
              'type': type.name,
              'tourId': tourId,
              'tourName': _bound(tourName, 80),
              'senderUid': senderUid,
              'senderName': _bound(senderName, 60),
              'refId': ?refId,
              'createdAt': FieldValue.serverTimestamp(),
              'expiresAt': Timestamp.fromDate(expiresAt),
              'read': false,
            })
            .timeout(const Duration(seconds: 10))
            // Notifications never block the action that triggered them.
            .catchError(
              (Object e) => debugPrint('Inbox notification not delivered: $e'),
            ),
    ]);
  }

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

  static String _bound(String value, int max) {
    final v = value.trim().isEmpty ? '—' : value.trim();
    return v.length > max ? v.substring(0, max) : v;
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
  if (!ref.watch(preferencesProvider).notifyImportant) return 0;
  final now = ref.watch(clockProvider)();
  final items = ref.watch(inboxProvider).value?.items ?? const [];
  return items.where((i) => !i.read && !i.isExpired(now)).length;
});
