import '../../../data/firebase/firestore_helpers.dart';

/// Display state for a member's shared location.
enum LocationShareStatus {
  /// Updated recently enough to be shown as current.
  live,

  /// Still within the sharing window but not updated for a while — shown
  /// with a "last seen" label, never as live.
  stale,

  /// The member paused sharing; coordinates are hidden.
  paused,

  /// Sharing window ended (or no record). Coordinates must not be shown even
  /// if the document still physically exists.
  notSharing,
}

/// Latest location document at tours/{tourId}/locations/{uid}. Only one per
/// member per tour, overwritten in place; no history is kept.
class LocationShare {
  const LocationShare({
    required this.uid,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    required this.sharingUntil,
    required this.sourceStatus,
    this.accuracyMeters,
  });

  factory LocationShare.fromDoc(String id, Map<String, dynamic> data) =>
      LocationShare(
        uid: id,
        latitude: readDoubleOrNull(data['latitude']) ?? 0,
        longitude: readDoubleOrNull(data['longitude']) ?? 0,
        accuracyMeters: readDoubleOrNull(data['accuracyMeters']),
        updatedAt: readDate(data['updatedAt']),
        sharingUntil: readDate(data['sharingUntil']),
        sourceStatus: readString(data['sourceStatus'], fallback: 'live'),
      );

  /// A location older than this is labelled stale.
  static const staleAfter = Duration(minutes: 5);

  /// Longest sharing window a client may set; mirrored in rules.
  static const maxSharingWindow = Duration(days: 30);

  final String uid;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime updatedAt;
  final DateTime sharingUntil;

  /// 'live' while sending updates, 'paused' when the sharer paused.
  final String sourceStatus;

  bool isExpired(DateTime now) => !now.isBefore(sharingUntil);

  LocationShareStatus statusAt(DateTime now) {
    if (isExpired(now)) return LocationShareStatus.notSharing;
    if (sourceStatus == 'paused') return LocationShareStatus.paused;
    if (now.difference(updatedAt) > staleAfter) {
      return LocationShareStatus.stale;
    }
    return LocationShareStatus.live;
  }

  /// Whether a marker may be drawn at all.
  bool isVisibleAt(DateTime now) {
    final status = statusAt(now);
    return status == LocationShareStatus.live ||
        status == LocationShareStatus.stale;
  }
}

bool isValidCoordinate(double? latitude, double? longitude) =>
    latitude != null &&
    longitude != null &&
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

/// Durations offered when starting to share. Conservative default: 2 hours.
enum SharingDuration { thirtyMinutes, twoHours, untilTripEnds }

DateTime sharingUntilFor(
  SharingDuration duration,
  DateTime now,
  DateTime tripEndUtc,
) {
  final cap = now.add(LocationShare.maxSharingWindow);
  final until = switch (duration) {
    SharingDuration.thirtyMinutes => now.add(const Duration(minutes: 30)),
    SharingDuration.twoHours => now.add(const Duration(hours: 2)),
    // End of the last trip day.
    SharingDuration.untilTripEnds => tripEndUtc.add(const Duration(days: 1)),
  };
  if (until.isAfter(cap)) return cap;
  // A trip that already ended falls back to the default window.
  if (!until.isAfter(now)) return now.add(const Duration(hours: 2));
  return until;
}

/// Throttle for outgoing location writes (brief §11). A write happens only
/// if the user moved at least [minDistanceMeters] *and* at least
/// [minInterval] passed, or if [maxInterval] passed regardless of movement
/// (so "last updated" stays meaningful while stationary).
class LocationWritePolicy {
  const LocationWritePolicy({
    this.minDistanceMeters = 75,
    this.minInterval = const Duration(seconds: 45),
    this.maxInterval = const Duration(minutes: 10),
  });

  final double minDistanceMeters;
  final Duration minInterval;
  final Duration maxInterval;

  bool shouldWrite({
    required DateTime now,
    required DateTime? lastWriteAt,
    required double? metersSinceLastWrite,
  }) {
    if (lastWriteAt == null || metersSinceLastWrite == null) return true;
    final elapsed = now.difference(lastWriteAt);
    if (elapsed < minInterval) return false;
    if (metersSinceLastWrite >= minDistanceMeters) return true;
    return elapsed >= maxInterval;
  }
}
