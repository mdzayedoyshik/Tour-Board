import '../../../data/firebase/firestore_helpers.dart';

enum PlanStatus { planned, completed, skipped }

PlanStatus planStatusFromName(String? name) => PlanStatus.values.firstWhere(
  (s) => s.name == name,
  orElse: () => PlanStatus.planned,
);

/// One itinerary activity, stored at tours/{tourId}/activities/{id}.
///
/// Times are tour-local wall-clock strings ("HH:mm") for the given [dayKey];
/// [startAt] is the derived UTC instant used for reminders and sorting.
class PlanItem {
  const PlanItem({
    required this.id,
    required this.title,
    required this.dayKey,
    required this.sortOrder,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.startTime,
    this.endTime,
    this.startAt,
    this.placeName,
    this.address,
    this.placeId,
    this.latitude,
    this.longitude,
    this.note,
    this.estimatedCostMinor,
    this.currencyCode,
    this.favorite = false,
    this.updatedBy,
    this.hasPendingWrites = false,
  });

  factory PlanItem.fromDoc(
    String id,
    Map<String, dynamic> data, {
    bool hasPendingWrites = false,
  }) => PlanItem(
    id: id,
    title: readString(data['title']),
    dayKey: readString(data['dayKey']),
    startTime: readStringOrNull(data['startTime']),
    endTime: readStringOrNull(data['endTime']),
    startAt: readDateOrNull(data['startAt']),
    placeName: readStringOrNull(data['placeName']),
    address: readStringOrNull(data['address']),
    placeId: readStringOrNull(data['placeId']),
    latitude: readDoubleOrNull(data['latitude']),
    longitude: readDoubleOrNull(data['longitude']),
    note: readStringOrNull(data['note']),
    estimatedCostMinor: readIntOrNull(data['estimatedCostMinor']),
    currencyCode: readStringOrNull(data['currencyCode']),
    sortOrder: readInt(data['sortOrder']),
    status: planStatusFromName(data['status'] as String?),
    favorite: readBool(data['favorite']),
    createdBy: readString(data['createdBy']),
    updatedBy: readStringOrNull(data['updatedBy']),
    createdAt: readDate(data['createdAt']),
    updatedAt: readDate(data['updatedAt']),
    hasPendingWrites: hasPendingWrites,
  );

  static const maxTitleLength = 80;
  static const maxPlaceLength = 120;
  static const maxNoteLength = 500;

  /// Upper bound on items loaded per tour (one bounded listener).
  static const queryLimit = 300;

  final String id;
  final String title;
  final String dayKey;
  final String? startTime;
  final String? endTime;
  final DateTime? startAt;
  final String? placeName;

  /// Formatted address from Google (display only).
  final String? address;

  /// Google place ID, used to open the exact place in Google Maps.
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final String? note;
  final int? estimatedCostMinor;
  final String? currencyCode;

  /// Sparse ordering key within a day (gaps of 1024) so a reorder updates
  /// only the moved item.
  final int sortOrder;
  final PlanStatus status;
  final bool favorite;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasPendingWrites;

  bool get hasCoordinates => latitude != null && longitude != null;
}

/// Gap between consecutive sort keys for new items.
const sortGap = 1024;

/// Sort key for placing an item between [before] and [after] (either may be
/// null for the list ends). Returns null when there is no integer gap left;
/// the caller then renumbers the day.
int? sortKeyBetween(int? before, int? after) {
  if (before == null && after == null) return sortGap;
  if (before == null) return after! - sortGap;
  if (after == null) return before + sortGap;
  if (after - before < 2) return null;
  return before + (after - before) ~/ 2;
}

/// Orders a day's items by sortOrder, then start time, then creation.
List<PlanItem> sortPlanItems(Iterable<PlanItem> items) {
  final list = items.toList();
  list.sort((a, b) {
    final c = a.sortOrder.compareTo(b.sortOrder);
    if (c != 0) return c;
    final t = (a.startTime ?? '99:99').compareTo(b.startTime ?? '99:99');
    if (t != 0) return t;
    return a.createdAt.compareTo(b.createdAt);
  });
  return list;
}
