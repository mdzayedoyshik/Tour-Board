import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Approximate number of live Firestore listeners, shown on the developer
/// diagnostics page. A plain notifier (not a provider) so it can change
/// while providers are building or disposing.
final ValueNotifier<int> activeListenerCount = ValueNotifier<int>(0);

/// Number of local writes not yet acknowledged, best-effort.
final ValueNotifier<int> pendingWriteCount = ValueNotifier<int>(0);

/// Whether the most recent snapshot of any stream came from cache.
final ValueNotifier<bool> lastSnapshotFromCache = ValueNotifier<bool>(false);

/// Wraps a snapshot stream so the diagnostics counter tracks it.
Stream<T> trackListener<T>(Stream<T> source) {
  StreamSubscription<T>? subscription;
  late final StreamController<T> controller;
  controller = StreamController<T>(
    onListen: () {
      activeListenerCount.value++;
      subscription = source.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      activeListenerCount.value--;
      await subscription?.cancel();
    },
  );
  return controller.stream;
}

/// A query result with the metadata the UI needs for honest offline states.
class Snapshot<T> {
  const Snapshot({
    required this.items,
    required this.fromCache,
    required this.hasPendingWrites,
    this.hasMore = false,
  });

  final List<T> items;

  /// Data came from the local cache (offline or not yet synced).
  final bool fromCache;

  /// At least one item has a local write not yet acknowledged.
  final bool hasPendingWrites;

  /// The live window was full; older items may exist.
  final bool hasMore;
}

/// Listens to [query] (including metadata changes so "pending sync" clears
/// once the server acknowledges) and maps documents with [fromDoc].
Stream<Snapshot<T>> watchQuery<T>(
  Query<Map<String, dynamic>> query,
  T Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) fromDoc, {
  int? limit,
}) {
  final limited = limit == null ? query : query.limit(limit);
  return trackListener(
    limited.snapshots(includeMetadataChanges: true).map((snap) {
      lastSnapshotFromCache.value = snap.metadata.isFromCache;
      return Snapshot<T>(
        items: snap.docs.map(fromDoc).toList(),
        fromCache: snap.metadata.isFromCache,
        hasPendingWrites: snap.metadata.hasPendingWrites,
        hasMore: limit != null && snap.docs.length >= limit,
      );
    }),
  );
}

/// Listens to a single document; emits null when it does not exist.
Stream<T?> watchDoc<T>(
  DocumentReference<Map<String, dynamic>> ref,
  T Function(DocumentSnapshot<Map<String, dynamic>> doc) fromDoc,
) => trackListener(
  ref.snapshots(includeMetadataChanges: true).map((snap) {
    lastSnapshotFromCache.value = snap.metadata.isFromCache;
    return snap.exists ? fromDoc(snap) : null;
  }),
);

enum WriteOutcome {
  /// The server acknowledged the write.
  synced,

  /// The write is queued locally and will sync when online. Used only for
  /// operations that are safe to queue (never approvals or confirmations).
  pendingSync,
}

/// Awaits a write that Firestore may queue offline. Returns [WriteOutcome
/// .pendingSync] if the server has not acknowledged within [timeout]; the
/// write continues in the background and is never reported as synced
/// before it actually is.
Future<WriteOutcome> commitQueued(
  Future<void> write, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  pendingWriteCount.value++;
  final tracked = write.whenComplete(() => pendingWriteCount.value--);
  try {
    await tracked.timeout(timeout);
    return WriteOutcome.synced;
  } on TimeoutException {
    // Surface later rule rejections in debug logs; the local copy disappears
    // automatically when the server rejects the write.
    unawaited(
      tracked.catchError((Object e) => debugPrint('Queued write failed: $e')),
    );
    return WriteOutcome.pendingSync;
  }
}
