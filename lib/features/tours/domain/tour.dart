import '../../../data/firebase/firestore_helpers.dart';

enum TourStatus { upcoming, active, closed, archived }

TourStatus tourStatusFromName(String? name) => TourStatus.values.firstWhere(
  (s) => s.name == name,
  orElse: () => TourStatus.upcoming,
);

/// Host-controlled switches stored on the tour document. Mirrored in
/// firestore.rules (`tourSettings()`).
class TourSettings {
  const TourSettings({
    this.adminsCanManageTour = true,
    this.membersCanEditPacking = true,
    this.membersCanRecordForOthers = false,
  });

  factory TourSettings.fromMap(Map<String, dynamic> map) => TourSettings(
    adminsCanManageTour: readBool(map['adminsCanManageTour'], fallback: true),
    membersCanEditPacking: readBool(
      map['membersCanEditPacking'],
      fallback: true,
    ),
    membersCanRecordForOthers: readBool(map['membersCanRecordForOthers']),
  );

  /// Admins may edit tour details and close/reopen the tour.
  final bool adminsCanManageTour;

  /// Ordinary members may add and check packing items.
  final bool membersCanEditPacking;

  /// Ordinary members may record an expense paid by someone else.
  final bool membersCanRecordForOthers;

  Map<String, dynamic> toMap() => {
    'adminsCanManageTour': adminsCanManageTour,
    'membersCanEditPacking': membersCanEditPacking,
    'membersCanRecordForOthers': membersCanRecordForOthers,
  };

  TourSettings copyWith({
    bool? adminsCanManageTour,
    bool? membersCanEditPacking,
    bool? membersCanRecordForOthers,
  }) => TourSettings(
    adminsCanManageTour: adminsCanManageTour ?? this.adminsCanManageTour,
    membersCanEditPacking: membersCanEditPacking ?? this.membersCanEditPacking,
    membersCanRecordForOthers:
        membersCanRecordForOthers ?? this.membersCanRecordForOthers,
  );
}

class Tour {
  const Tour({
    required this.id,
    required this.name,
    required this.hostUid,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.timeZone,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.budgetMinor,
    this.inviteCode,
    this.allMemberUids = const [],
    this.settings = const TourSettings(),
    this.hasPendingWrites = false,
  });

  factory Tour.fromDoc(
    String id,
    Map<String, dynamic> data, {
    bool hasPendingWrites = false,
  }) => Tour(
    id: id,
    name: readString(data['name']),
    description: readStringOrNull(data['description']),
    hostUid: readString(data['hostUid']),
    status: tourStatusFromName(data['status'] as String?),
    startAt: readDate(data['startAt']),
    endAt: readDate(data['endAt']),
    timeZone: readString(data['timeZone'], fallback: 'UTC'),
    currencyCode: readString(data['currencyCode'], fallback: 'USD'),
    budgetMinor: readIntOrNull(data['budgetMinor']),
    inviteCode: readStringOrNull(data['inviteCode']),
    allMemberUids: readStringList(data['allMemberUids']),
    settings: TourSettings.fromMap(readMap(data['settings'])),
    createdAt: readDate(data['createdAt']),
    updatedAt: readDate(data['updatedAt']),
    hasPendingWrites: hasPendingWrites,
  );

  static const schemaVersion = 1;
  static const maxNameLength = 80;
  static const maxDescriptionLength = 500;

  /// Practical MVP group-size cap; mirrored in rules (`maxMembers()`).
  static const maxMembers = 30;

  final String id;
  final String name;
  final String? description;
  final String hostUid;
  final TourStatus status;

  /// Inclusive trip dates, stored as UTC midnight of the local calendar date.
  final DateTime startAt;
  final DateTime endAt;

  /// IANA zone, e.g. "Asia/Dhaka", used for itinerary local times.
  final String timeZone;
  final String currencyCode;
  final int? budgetMinor;
  final String? inviteCode;

  /// Everyone who has ever been an approved member. Used by rules to validate
  /// payer/participant UIDs (including historical members) without a get()
  /// per participant.
  final List<String> allMemberUids;
  final TourSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool hasPendingWrites;

  /// Ordinary content (expenses, plans, notes) can be changed.
  bool get isOpen =>
      status == TourStatus.upcoming || status == TourStatus.active;

  bool get isClosedOrArchived => !isOpen;
}

/// Entry under users/{uid}/tourMemberships/{tourId}. A convenience index for
/// the Home screen; never an authorization source.
class TourMembershipIndex {
  const TourMembershipIndex({required this.tourId, required this.joinedAt});

  factory TourMembershipIndex.fromDoc(String id, Map<String, dynamic> data) =>
      TourMembershipIndex(tourId: id, joinedAt: readDate(data['joinedAt']));

  final String tourId;
  final DateTime joinedAt;
}
