import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../features/tours/domain/tour.dart';

/// Trip dates are calendar dates. They are stored as UTC midnight of the
/// chosen date so every device shows the same day regardless of its zone.
DateTime dateOnlyUtc(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

enum DateRangeError { endBeforeStart, tooLong }

/// Longest tour accepted; keeps day lists and queries bounded.
const maxTourDays = 366;

DateRangeError? validateDateRange(DateTime start, DateTime end) {
  final s = dateOnlyUtc(start);
  final e = dateOnlyUtc(end);
  if (e.isBefore(s)) return DateRangeError.endBeforeStart;
  if (e.difference(s).inDays + 1 > maxTourDays) return DateRangeError.tooLong;
  return null;
}

/// "2026-03-14" keys for each day of the trip (inclusive).
List<String> dayKeysBetween(DateTime start, DateTime end) {
  final keys = <String>[];
  var day = dateOnlyUtc(start);
  final last = dateOnlyUtc(end);
  while (!day.isAfter(last) && keys.length < maxTourDays) {
    keys.add(dayKeyOf(day));
    day = day.add(const Duration(days: 1));
  }
  return keys;
}

String dayKeyOf(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime? parseDayKey(String key) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (match == null) return null;
  return DateTime.utc(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// "HH:mm" -> minutes since midnight, or null.
int? parseTimeOfDay(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(value);
  if (match == null) return null;
  return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
}

String formatTimeOfDay(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// Status to display: closed/archived come from the host's choice; open
/// tours read as upcoming/active from today's date in the tour's zone.
TourStatus effectiveStatus(Tour tour, DateTime nowUtc) {
  if (!tour.isOpen) return tour.status;
  final today = dateOnlyUtc(TimeZones.toZone(nowUtc, tour.timeZone));
  if (today.isBefore(dateOnlyUtc(tour.startAt))) return TourStatus.upcoming;
  return TourStatus.active;
}

/// True when the trip's last day has passed but the host has not closed it.
bool hasEnded(Tour tour, DateTime nowUtc) {
  final today = dateOnlyUtc(TimeZones.toZone(nowUtc, tour.timeZone));
  return today.isAfter(dateOnlyUtc(tour.endAt));
}

/// IANA time-zone helpers backed by the bundled tz database.
abstract final class TimeZones {
  static bool _initialised = false;

  static void ensureInitialised() {
    if (_initialised) return;
    tzdata.initializeTimeZones();
    _initialised = true;
  }

  static bool isValid(String name) {
    ensureInitialised();
    try {
      tz.getLocation(name);
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<String> all() {
    ensureInitialised();
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  /// Wall-clock time in [zone] for an instant, as a "naive" DateTime whose
  /// fields are the local values (year/month/day/hour...).
  static DateTime toZone(DateTime instant, String zone) {
    ensureInitialised();
    try {
      final local = tz.TZDateTime.from(instant, tz.getLocation(zone));
      return DateTime.utc(
        local.year,
        local.month,
        local.day,
        local.hour,
        local.minute,
      );
    } catch (_) {
      return instant.toUtc();
    }
  }

  /// Converts a local date + "HH:mm" in [zone] into a UTC instant.
  static DateTime? localToUtc(String dayKey, String? time, String zone) {
    ensureInitialised();
    final day = parseDayKey(dayKey);
    final minutes = parseTimeOfDay(time);
    if (day == null || minutes == null) return null;
    try {
      final local = tz.TZDateTime(
        tz.getLocation(zone),
        day.year,
        day.month,
        day.day,
        minutes ~/ 60,
        minutes % 60,
      );
      return local.toUtc();
    } catch (_) {
      return null;
    }
  }

  /// Short offset label such as "GMT+6" for showing tour-local times.
  static String offsetLabel(String zone, DateTime instant) {
    ensureInitialised();
    try {
      final local = tz.TZDateTime.from(instant, tz.getLocation(zone));
      final offset = local.timeZoneOffset;
      final sign = offset.isNegative ? '-' : '+';
      final h = offset.inHours.abs();
      final m = offset.inMinutes.abs() % 60;
      return m == 0
          ? 'GMT$sign$h'
          : 'GMT$sign$h:${m.toString().padLeft(2, '0')}';
    } catch (_) {
      return zone;
    }
  }
}
