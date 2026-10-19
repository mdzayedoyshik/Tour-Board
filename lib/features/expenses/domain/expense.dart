import '../../../core/money/split.dart';
import '../../../data/firebase/firestore_helpers.dart';

enum ExpenseCategory { food, transport, stay, activities, shopping, other }

ExpenseCategory expenseCategoryFromName(String? name) => ExpenseCategory.values
    .firstWhere((c) => c.name == name, orElse: () => ExpenseCategory.other);

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.currencyCode,
    required this.payerUid,
    required this.shares,
    required this.splitMethod,
    required this.category,
    required this.occurredAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
    this.splitWeights = const {},
    this.note,
    this.revisionCount = 0,
    this.deletedAt,
    this.deletedBy,
    this.hasPendingWrites = false,
  });

  factory Expense.fromDoc(
    String id,
    Map<String, dynamic> data, {
    bool hasPendingWrites = false,
  }) => Expense(
    id: id,
    title: readString(data['title']),
    amountMinor: readInt(data['amountMinor']),
    currencyCode: readString(data['currencyCode']),
    payerUid: readString(data['payerUid']),
    shares: readIntMap(data['shares']),
    splitMethod: splitMethodFromName(data['splitMethod'] as String?),
    splitWeights: readIntMap(data['splitWeights']),
    category: expenseCategoryFromName(data['category'] as String?),
    occurredAt: readDate(data['occurredAt']),
    note: readStringOrNull(data['note']),
    createdBy: readString(data['createdBy']),
    createdAt: readDate(data['createdAt']),
    updatedAt: readDate(data['updatedAt']),
    updatedBy: readStringOrNull(data['updatedBy']),
    revisionCount: readInt(data['revisionCount']),
    deletedAt: readDateOrNull(data['deletedAt']),
    deletedBy: readStringOrNull(data['deletedBy']),
    hasPendingWrites: hasPendingWrites,
  );

  static const schemaVersion = 1;
  static const maxTitleLength = 80;
  static const maxNoteLength = 500;

  final String id;
  final String title;
  final int amountMinor;
  final String currencyCode;
  final String payerUid;

  /// uid -> share in minor units. Always sums to [amountMinor]; this is the
  /// only authoritative split data.
  final Map<String, int> shares;
  final SplitMethod splitMethod;

  /// Weights used for [SplitMethod.shares], kept so the form can be re-opened.
  final Map<String, int> splitWeights;
  final ExpenseCategory category;
  final DateTime occurredAt;
  final String? note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? updatedBy;
  final int revisionCount;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// True while the local write has not been acknowledged by the server.
  final bool hasPendingWrites;

  bool get isDeleted => deletedAt != null;
  bool get isEdited => revisionCount > 0;
  bool get payerIsParticipant => shares.containsKey(payerUid);

  /// Values written for the editable fields; used to diff revisions.
  Map<String, Object?> editableFields() => {
    'title': title,
    'amountMinor': amountMinor,
    'currencyCode': currencyCode,
    'payerUid': payerUid,
    'shares': shares,
    'splitMethod': splitMethod.name,
    'splitWeights': splitWeights,
    'category': category.name,
    'occurredAt': occurredAt,
    'note': note,
  };
}

/// Draft values from the expense form, before IDs/metadata are attached.
class ExpenseDraft {
  const ExpenseDraft({
    required this.title,
    required this.amountMinor,
    required this.currencyCode,
    required this.payerUid,
    required this.shares,
    required this.splitMethod,
    required this.category,
    required this.occurredAt,
    this.splitWeights = const {},
    this.note,
  });

  final String title;
  final int amountMinor;
  final String currencyCode;
  final String payerUid;
  final Map<String, int> shares;
  final SplitMethod splitMethod;
  final Map<String, int> splitWeights;
  final ExpenseCategory category;
  final DateTime occurredAt;
  final String? note;

  Map<String, Object?> editableFields() => {
    'title': title,
    'amountMinor': amountMinor,
    'currencyCode': currencyCode,
    'payerUid': payerUid,
    'shares': shares,
    'splitMethod': splitMethod.name,
    'splitWeights': splitWeights,
    'category': category.name,
    'occurredAt': occurredAt.toUtc(),
    'note': note,
  };
}

/// Compact revision entry: only changed fields with before/after values.
class Revision {
  const Revision({
    required this.id,
    required this.editorUid,
    required this.editedAt,
    required this.changedFields,
    required this.before,
    required this.after,
    this.reason,
  });

  factory Revision.fromDoc(String id, Map<String, dynamic> data) => Revision(
    id: id,
    editorUid: readString(data['editorUid']),
    editedAt: readDate(data['editedAt']),
    changedFields: readStringList(data['changedFields']),
    before: readMap(data['before']),
    after: readMap(data['after']),
    reason: readStringOrNull(data['reason']),
  );

  /// Revisions kept per record; edits beyond this are refused so history
  /// cannot grow without bound. Mirrored in rules (`maxRevisions()`).
  static const maxRevisions = 50;

  final String id;
  final String editorUid;
  final DateTime editedAt;
  final List<String> changedFields;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final String? reason;
}

/// Field names whose values differ between [before] and [after]. Maps are
/// compared by content, so re-saving an unchanged split is not an edit.
List<String> diffFields(
  Map<String, Object?> before,
  Map<String, Object?> after,
) {
  final changed = <String>[];
  for (final key in after.keys) {
    if (!_deepEquals(before[key], after[key])) changed.add(key);
  }
  return changed;
}

bool _deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is DateTime && b is DateTime) {
    return a.toUtc().millisecondsSinceEpoch == b.toUtc().millisecondsSinceEpoch;
  }
  return a == b;
}
