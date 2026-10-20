import '../../../data/firebase/firestore_helpers.dart';

/// Types of in-app notifications, written by the backend. Stored without
/// free text: the device renders the message from [type] plus snapshots.
enum InboxType {
  joinRequest,
  joinApproved,
  joinRejected,
  settlementSubmitted,
  settlementConfirmed,
  settlementDisputed,
  tourClosed,
  tourReopened,
  roleChanged,
  expenseAdded,
  expenseEdited,
  expenseDeleted,
  planAdded,
  planEdited,
  tourDeletionSoon,
}

InboxType? inboxTypeFromName(String? name) {
  for (final t in InboxType.values) {
    if (t.name == name) return t;
  }
  return null;
}

/// users/{uid}/inbox/{id}
class InboxItem {
  const InboxItem({
    required this.id,
    required this.type,
    required this.tourId,
    required this.tourName,
    required this.senderUid,
    required this.senderName,
    required this.createdAt,
    required this.expiresAt,
    required this.read,
    this.refId,
  });

  factory InboxItem.fromDoc(String id, Map<String, dynamic> data) => InboxItem(
    id: id,
    type: inboxTypeFromName(data['type'] as String?),
    tourId: readString(data['tourId']),
    tourName: readString(data['tourName']),
    senderUid: readString(data['senderUid']),
    senderName: readString(data['senderName']),
    refId: readStringOrNull(data['refId']),
    createdAt: readDate(data['createdAt']),
    expiresAt: readDate(data['expiresAt']),
    read: readBool(data['read']),
  );

  static const pageSize = 30;

  /// Inbox records expire after 30 days; the backend's daily job deletes
  /// them and the UI hides expired ones regardless.
  static const lifetime = Duration(days: 30);

  final String id;
  final InboxType? type;
  final String tourId;
  final String tourName;
  final String senderUid;
  final String senderName;
  final String? refId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool read;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);
}
