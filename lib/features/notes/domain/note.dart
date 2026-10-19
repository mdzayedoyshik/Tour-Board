import '../../../data/firebase/firestore_helpers.dart';

class Note {
  const Note({
    required this.id,
    required this.body,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.updatedBy,
    this.revisionCount = 0,
    this.hasPendingWrites = false,
  });

  factory Note.fromDoc(
    String id,
    Map<String, dynamic> data, {
    bool hasPendingWrites = false,
  }) => Note(
    id: id,
    title: readStringOrNull(data['title']),
    body: readString(data['body']),
    createdBy: readString(data['createdBy']),
    updatedBy: readStringOrNull(data['updatedBy']),
    createdAt: readDate(data['createdAt']),
    updatedAt: readDate(data['updatedAt']),
    revisionCount: readInt(data['revisionCount']),
    hasPendingWrites: hasPendingWrites,
  );

  static const maxTitleLength = 80;
  static const maxBodyLength = 2000;
  static const pageSize = 30;

  final String id;
  final String? title;
  final String body;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revisionCount;
  final bool hasPendingWrites;

  bool get isEdited => revisionCount > 0;

  Map<String, Object?> editableFields() => {'title': title, 'body': body};
}
