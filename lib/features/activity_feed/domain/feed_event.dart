import '../../../data/firebase/firestore_helpers.dart';

/// Event types written to tours/{tourId}/activityFeed. Only meaningful
/// collaboration events — never location updates, typing or checkbox noise.
/// Keep in sync with `feedTypes()` in firestore.rules.
enum FeedEventType {
  memberJoined,
  memberRemoved,
  memberLeft,
  roleChanged,
  hostTransferred,
  expenseAdded,
  expenseEdited,
  expenseDeleted,
  planAdded,
  planEdited,
  settlementSubmitted,
  settlementConfirmed,
  settlementDisputed,
  settlementCancelled,
  tourClosed,
  tourReopened,
  tourArchived,
  tourUpdated,
}

FeedEventType? feedEventTypeFromName(String? name) {
  for (final t in FeedEventType.values) {
    if (t.name == name) return t;
  }
  return null;
}

class FeedEvent {
  const FeedEvent({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.createdAt,
    this.subjectUid,
    this.refId,
    this.label,
  });

  factory FeedEvent.fromDoc(String id, Map<String, dynamic> data) => FeedEvent(
    id: id,
    type: feedEventTypeFromName(data['type'] as String?),
    actorUid: readString(data['actorUid']),
    subjectUid: readStringOrNull(data['subjectUid']),
    refId: readStringOrNull(data['refId']),
    label: readStringOrNull(data['label']),
    createdAt: readDate(data['createdAt']),
  );

  static const pageSize = 30;
  static const maxLabelLength = 80;

  final String id;

  /// Null for an unknown type written by a newer app version.
  final FeedEventType? type;
  final String actorUid;

  /// The member affected (e.g. who was removed), if any.
  final String? subjectUid;

  /// ID of the related expense/plan/settlement, if any.
  final String? refId;

  /// Short title snapshot such as an expense title. Never coordinates.
  final String? label;
  final DateTime createdAt;
}
