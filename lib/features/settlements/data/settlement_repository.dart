import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../data/backend/backend_client.dart';
import '../../../data/firebase/firestore_helpers.dart';
import '../../../data/firebase/firestore_paths.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../activity_feed/data/feed_repository.dart';
import '../../activity_feed/domain/feed_event.dart';
import '../domain/settlement.dart';

class SettlementDraft {
  const SettlementDraft({
    required this.fromUid,
    required this.toUid,
    required this.amountMinor,
    required this.currencyCode,
    this.paymentMethod,
    this.transactionReference,
    this.note,
  });

  final String fromUid;
  final String toUid;
  final int amountMinor;
  final String currencyCode;
  final String? paymentMethod;
  final String? transactionReference;
  final String? note;
}

/// Offline payments between members. The app never moves money.
class SettlementRepository {
  SettlementRepository(this._db, this._feed, this._events);

  final FirebaseFirestore _db;
  final FeedRepository _feed;
  final EventReporter _events;

  static const queryLimit = 500;
  static const _timeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _col(String tourId) =>
      _db.collection(FirestorePaths.settlements(tourId));

  /// Client-generated operation ID; reused on retry so a payment is never
  /// recorded twice.
  String newOperationId(String tourId) => _col(tourId).doc().id;

  Stream<Snapshot<Settlement>> watch(String tourId) => watchQuery(
    _col(tourId).orderBy('createdAt', descending: true),
    (doc) => Settlement.fromDoc(
      doc.id,
      doc.data(),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    ),
    limit: queryLimit,
  );

  /// Submission may queue offline: it is only "pending confirmation" and
  /// affects no balance until the counterparty confirms online.
  Future<WriteOutcome> submit({
    required String tourId,
    required String tourName,
    required String operationId,
    required SettlementDraft draft,
    required String uid,
    required String senderName,
  }) async {
    final outcome = await commitQueued(
      _col(tourId).doc(operationId).set({
        'fromUid': draft.fromUid,
        'toUid': draft.toUid,
        'amountMinor': draft.amountMinor,
        'currencyCode': draft.currencyCode,
        'status': settlementStatusName(SettlementStatus.pendingConfirmation),
        'paymentMethod': ?blankToNull(draft.paymentMethod),
        'transactionReference': ?blankToNull(draft.transactionReference),
        'note': ?blankToNull(draft.note),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
    if (outcome == WriteOutcome.synced) {
      final counterparty = uid == draft.fromUid ? draft.toUid : draft.fromUid;
      _events.report(
        ServerEvent.settlementSubmitted,
        tourId: tourId,
        refId: operationId,
      );
      await _feed.record(
        tourId,
        type: FeedEventType.settlementSubmitted,
        actorUid: uid,
        subjectUid: counterparty,
        refId: operationId,
      );
    }
    return outcome;
  }

  /// Confirmation is a transaction: it needs the server and is applied at
  /// most once (confirmed is terminal in rules too).
  Future<void> confirm({
    required String tourId,
    required String tourName,
    required Settlement settlement,
    required String uid,
    required String senderName,
  }) async {
    await _transition(
      tourId,
      settlement.id,
      {
        'status': settlementStatusName(SettlementStatus.confirmed),
        'confirmedBy': uid,
        'confirmedAt': FieldValue.serverTimestamp(),
      },
      allowedFrom: const {
        SettlementStatus.pendingConfirmation,
        SettlementStatus.disputed,
      },
    );
    _events.report(
      ServerEvent.settlementConfirmed,
      tourId: tourId,
      refId: settlement.id,
    );
    await _feed.record(
      tourId,
      type: FeedEventType.settlementConfirmed,
      actorUid: uid,
      refId: settlement.id,
    );
  }

  Future<void> dispute({
    required String tourId,
    required String tourName,
    required Settlement settlement,
    required String uid,
    required String senderName,
    required String reason,
  }) async {
    await _transition(
      tourId,
      settlement.id,
      {
        'status': settlementStatusName(SettlementStatus.disputed),
        'disputeReason': reason.trim(),
      },
      allowedFrom: const {SettlementStatus.pendingConfirmation},
    );
    _events.report(
      ServerEvent.settlementDisputed,
      tourId: tourId,
      refId: settlement.id,
    );
    await _feed.record(
      tourId,
      type: FeedEventType.settlementDisputed,
      actorUid: uid,
      refId: settlement.id,
    );
  }

  Future<void> cancel({
    required String tourId,
    required Settlement settlement,
    required String uid,
  }) async {
    await _transition(
      tourId,
      settlement.id,
      {'status': settlementStatusName(SettlementStatus.cancelled)},
      allowedFrom: const {
        SettlementStatus.pendingConfirmation,
        SettlementStatus.disputed,
      },
    );
    await _feed.record(
      tourId,
      type: FeedEventType.settlementCancelled,
      actorUid: uid,
      refId: settlement.id,
    );
  }

  Future<void> _transition(
    String tourId,
    String id,
    Map<String, Object> changes, {
    required Set<SettlementStatus> allowedFrom,
  }) async {
    final ref = _col(tourId).doc(id);
    await _db
        .runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) throw const AppException(AppErrorKind.notFound);
          final current = Settlement.fromDoc(snap.id, snap.data()!);
          if (!allowedFrom.contains(current.status)) {
            throw const AppException(AppErrorKind.conflict);
          }
          tx.update(ref, {
            ...changes,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        })
        .timeout(_timeout);
  }
}

final settlementRepositoryProvider = Provider<SettlementRepository>(
  (ref) => SettlementRepository(
    ref.watch(firestoreProvider),
    ref.watch(feedRepositoryProvider),
    ref.watch(eventReporterProvider),
  ),
);

final settlementsProvider = StreamProvider.autoDispose
    .family<Snapshot<Settlement>, String>(
      (ref, tourId) => ref.watch(settlementRepositoryProvider).watch(tourId),
    );
