import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/dates.dart';
import '../../../data/backend/backend_client.dart';
import '../../../data/firebase/firestore_helpers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../activity_feed/data/feed_repository.dart';
import '../../activity_feed/domain/feed_event.dart';
import '../domain/plan_item.dart';

class PlanDraft {
  const PlanDraft({
    required this.title,
    required this.dayKey,
    this.startTime,
    this.endTime,
    this.placeName,
    this.address,
    this.placeId,
    this.latitude,
    this.longitude,
    this.note,
    this.estimatedCostMinor,
    this.currencyCode,
    this.status = PlanStatus.planned,
    this.favorite = false,
  });

  final String title;
  final String dayKey;
  final String? startTime;
  final String? endTime;
  final String? placeName;
  final String? address;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? note;
  final int? estimatedCostMinor;
  final String? currencyCode;
  final PlanStatus status;
  final bool favorite;

  Map<String, dynamic> fields(String timeZone) {
    final startAt = TimeZones.localToUtc(dayKey, startTime, timeZone);
    return {
      'title': title.trim(),
      'dayKey': dayKey,
      'startTime': ?startTime,
      'endTime': ?endTime,
      if (startAt != null) 'startAt': Timestamp.fromDate(startAt),
      'placeName': ?blankToNull(placeName),
      'address': ?blankToNull(address),
      'placeId': ?blankToNull(placeId),
      if (latitude != null && longitude != null) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
      'note': ?blankToNull(note),
      if (estimatedCostMinor != null) ...{
        'estimatedCostMinor': estimatedCostMinor,
        'currencyCode': currencyCode,
      },
      'status': status.name,
      'favorite': favorite,
    };
  }
}

class PlanRepository {
  PlanRepository(this._db, this._feed, this._events);

  final FirebaseFirestore _db;
  final FeedRepository _feed;
  final EventReporter _events;

  CollectionReference<Map<String, dynamic>> _col(String tourId) =>
      _db.collection(FirestorePaths.activities(tourId));

  Stream<Snapshot<PlanItem>> watch(String tourId) => watchQuery(
    _col(tourId).orderBy('dayKey'),
    (doc) => PlanItem.fromDoc(
      doc.id,
      doc.data(),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    ),
    limit: PlanItem.queryLimit,
  );

  Future<WriteOutcome> add({
    required String tourId,
    required String timeZone,
    required PlanDraft draft,
    required int sortOrder,
    required String uid,
  }) {
    final ref = _col(tourId).doc();
    final batch = _db.batch()
      ..set(ref, {
        ...draft.fields(timeZone),
        'sortOrder': sortOrder,
        'createdBy': uid,
        'updatedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        _feed.newRef(tourId),
        _feed.eventData(
          type: FeedEventType.planAdded,
          actorUid: uid,
          refId: ref.id,
          label: draft.title,
        ),
      );
    return _reportWhenSynced(
      commitQueued(batch.commit()),
      ServerEvent.planAdded,
      tourId,
      ref.id,
    );
  }

  /// Optional fields cleared in the form are deleted. Plans use
  /// last-write-wins; they carry no financial meaning.
  Future<WriteOutcome> update({
    required String tourId,
    required String timeZone,
    required PlanItem item,
    required PlanDraft draft,
    required String uid,
  }) {
    final fields = draft.fields(timeZone);
    const optional = [
      'startTime',
      'endTime',
      'startAt',
      'placeName',
      'address',
      'placeId',
      'latitude',
      'longitude',
      'note',
      'estimatedCostMinor',
      'currencyCode',
    ];
    final batch = _db.batch()
      ..update(_col(tourId).doc(item.id), {
        for (final key in optional)
          if (!fields.containsKey(key)) key: FieldValue.delete(),
        ...fields,
        if (item.dayKey != draft.dayKey) 'sortOrder': sortGap,
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        _feed.newRef(tourId),
        _feed.eventData(
          type: FeedEventType.planEdited,
          actorUid: uid,
          refId: item.id,
          label: draft.title,
        ),
      );
    return _reportWhenSynced(
      commitQueued(batch.commit()),
      ServerEvent.planEdited,
      tourId,
      item.id,
    );
  }

  /// Notifies other members only once the server has the write; a queued
  /// offline write does not exist on the server yet.
  Future<WriteOutcome> _reportWhenSynced(
    Future<WriteOutcome> write,
    ServerEvent event,
    String tourId,
    String refId,
  ) async {
    final outcome = await write;
    if (outcome == WriteOutcome.synced) {
      _events.report(event, tourId: tourId, refId: refId);
    }
    return outcome;
  }

  /// Status toggles are tiny updates without a feed event.
  Future<WriteOutcome> setStatus(
    String tourId,
    PlanItem item,
    PlanStatus status,
    String uid,
  ) => commitQueued(
    _col(tourId).doc(item.id).update({
      'status': status.name,
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<WriteOutcome> setFavorite(
    String tourId,
    PlanItem item,
    bool favorite,
    String uid,
  ) => commitQueued(
    _col(tourId).doc(item.id).update({
      'favorite': favorite,
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<WriteOutcome> delete(String tourId, String itemId) =>
      commitQueued(_col(tourId).doc(itemId).delete());

  /// Moves [item] between its new neighbours. Normally one write; when the
  /// gap is exhausted the day is renumbered in one batch.
  Future<WriteOutcome> move({
    required String tourId,
    required PlanItem item,
    required List<PlanItem> dayItemsInNewOrder,
    required String uid,
  }) {
    final index = dayItemsInNewOrder.indexWhere((i) => i.id == item.id);
    final before = index > 0 ? dayItemsInNewOrder[index - 1].sortOrder : null;
    final after = index < dayItemsInNewOrder.length - 1
        ? dayItemsInNewOrder[index + 1].sortOrder
        : null;
    final key = sortKeyBetween(before, after);
    if (key != null) {
      return commitQueued(
        _col(tourId).doc(item.id).update({
          'sortOrder': key,
          'updatedBy': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );
    }
    final batch = _db.batch();
    for (var i = 0; i < dayItemsInNewOrder.length; i++) {
      batch.update(_col(tourId).doc(dayItemsInNewOrder[i].id), {
        'sortOrder': (i + 1) * sortGap,
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return commitQueued(batch.commit());
  }
}

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(
    ref.watch(firestoreProvider),
    ref.watch(feedRepositoryProvider),
    ref.watch(eventReporterProvider),
  ),
);

final planItemsProvider = StreamProvider.autoDispose
    .family<Snapshot<PlanItem>, String>(
      (ref, tourId) => ref.watch(planRepositoryProvider).watch(tourId),
    );
