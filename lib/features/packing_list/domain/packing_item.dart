import '../../../data/firebase/firestore_helpers.dart';

class PackingItem {
  const PackingItem({
    required this.id,
    required this.label,
    required this.checked,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeUid,
    this.checkedBy,
    this.hasPendingWrites = false,
  });

  factory PackingItem.fromDoc(
    String id,
    Map<String, dynamic> data, {
    bool hasPendingWrites = false,
  }) => PackingItem(
    id: id,
    label: readString(data['label']),
    checked: readBool(data['checked']),
    assigneeUid: readStringOrNull(data['assigneeUid']),
    checkedBy: readStringOrNull(data['checkedBy']),
    createdBy: readString(data['createdBy']),
    createdAt: readDate(data['createdAt']),
    updatedAt: readDate(data['updatedAt']),
    hasPendingWrites: hasPendingWrites,
  );

  static const maxLabelLength = 80;
  static const queryLimit = 200;

  final String id;
  final String label;
  final bool checked;
  final String? assigneeUid;
  final String? checkedBy;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasPendingWrites;
}
