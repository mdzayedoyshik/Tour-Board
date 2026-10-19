import '../../../data/firebase/firestore_helpers.dart';
import '../../membership/domain/permissions.dart';

enum SettlementStatus { pendingConfirmation, confirmed, disputed, cancelled }

/// Firestore stores the snake_case names from the brief.
const _statusNames = {
  SettlementStatus.pendingConfirmation: 'pending_confirmation',
  SettlementStatus.confirmed: 'confirmed',
  SettlementStatus.disputed: 'disputed',
  SettlementStatus.cancelled: 'cancelled',
};

String settlementStatusName(SettlementStatus status) => _statusNames[status]!;

SettlementStatus settlementStatusFromName(String? name) => _statusNames.entries
    .firstWhere(
      (e) => e.value == name,
      orElse: () => const MapEntry(
        SettlementStatus.pendingConfirmation,
        'pending_confirmation',
      ),
    )
    .key;

class Settlement {
  const Settlement({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.paymentMethod,
    this.transactionReference,
    this.note,
    this.confirmedBy,
    this.confirmedAt,
    this.disputeReason,
    this.hasPendingWrites = false,
  });

  factory Settlement.fromDoc(
    String id,
    Map<String, dynamic> data, {
    bool hasPendingWrites = false,
  }) => Settlement(
    id: id,
    fromUid: readString(data['fromUid']),
    toUid: readString(data['toUid']),
    amountMinor: readInt(data['amountMinor']),
    currencyCode: readString(data['currencyCode']),
    status: settlementStatusFromName(data['status'] as String?),
    paymentMethod: readStringOrNull(data['paymentMethod']),
    transactionReference: readStringOrNull(data['transactionReference']),
    note: readStringOrNull(data['note']),
    createdBy: readString(data['createdBy']),
    createdAt: readDate(data['createdAt']),
    updatedAt: readDate(data['updatedAt']),
    confirmedBy: readStringOrNull(data['confirmedBy']),
    confirmedAt: readDateOrNull(data['confirmedAt']),
    disputeReason: readStringOrNull(data['disputeReason']),
    hasPendingWrites: hasPendingWrites,
  );

  static const maxTextLength = 120;

  /// Document ID; generated once on the client before the write so a retried
  /// submission overwrites nothing and is never counted twice.
  final String id;

  /// Debtor who paid offline.
  final String fromUid;

  /// Creditor who received the payment.
  final String toUid;
  final int amountMinor;
  final String currencyCode;
  final SettlementStatus status;
  final String? paymentMethod;
  final String? transactionReference;
  final String? note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final String? disputeReason;
  final bool hasPendingWrites;

  bool get isConfirmed => status == SettlementStatus.confirmed;

  /// The party who must confirm: whoever did not create the record.
  String get counterpartyUid => createdBy == fromUid ? toUid : fromUid;

  bool involves(String uid) => uid == fromUid || uid == toUid;
}

/// Who may do what with a settlement. Mirrors firestore.rules.
class SettlementActions {
  const SettlementActions({
    required this.settlement,
    required this.permissions,
    required this.counterpartyIsActive,
  });

  final Settlement settlement;
  final TourPermissions permissions;

  /// Admin fallback confirmation is only allowed when the counterparty is no
  /// longer an active member and so cannot confirm themselves.
  final bool counterpartyIsActive;

  String? get _me => permissions.viewer?.uid;

  bool get _open =>
      settlement.status == SettlementStatus.pendingConfirmation ||
      settlement.status == SettlementStatus.disputed;

  bool get canConfirm {
    if (!permissions.isMember || !_open) return false;
    if (_me == settlement.counterpartyUid) return true;
    return permissions.isHostOrAdmin &&
        !settlement.involves(_me!) &&
        !counterpartyIsActive;
  }

  bool get canDispute =>
      permissions.isMember &&
      settlement.status == SettlementStatus.pendingConfirmation &&
      _me == settlement.counterpartyUid;

  bool get canCancel =>
      permissions.isMember && _open && _me == settlement.createdBy;
}
