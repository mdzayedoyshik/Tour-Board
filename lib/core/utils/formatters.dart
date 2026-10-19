import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../localization/l10n.dart';
import 'dates.dart';

/// Locale-aware display helpers. Trip dates are UTC-midnight calendar dates,
/// so they are formatted as UTC to avoid shifting a day.
String formatTripDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(context.localeTag).format(dateOnlyUtc(date));

String formatTripRange(BuildContext context, DateTime start, DateTime end) {
  final locale = context.localeTag;
  final s = dateOnlyUtc(start);
  final e = dateOnlyUtc(end);
  if (s == e) return DateFormat.yMMMd(locale).format(s);
  if (s.year == e.year) {
    return '${DateFormat.MMMd(locale).format(s)} – '
        '${DateFormat.yMMMd(locale).format(e)}';
  }
  return '${DateFormat.yMMMd(locale).format(s)} – '
      '${DateFormat.yMMMd(locale).format(e)}';
}

/// Day header such as "Sat, Mar 14".
String formatDayKey(BuildContext context, String dayKey) {
  final day = parseDayKey(dayKey);
  if (day == null) return dayKey;
  return DateFormat.MMMEd(context.localeTag).format(day);
}

/// Instant shown in the device's local time.
String formatDateTime(BuildContext context, DateTime instant) =>
    DateFormat.yMMMd(context.localeTag).add_jm().format(instant.toLocal());

String formatShortDate(BuildContext context, DateTime instant) =>
    DateFormat.MMMd(context.localeTag).format(instant.toLocal());

/// "just now", "5 min ago", "3 h ago", or a date.
String formatRelative(BuildContext context, DateTime instant, DateTime now) {
  final l10n = context.l10n;
  final diff = now.difference(instant);
  if (diff.inSeconds < 60) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  return formatShortDate(context, instant);
}

/// "HH:mm" -> locale time like "9:30 AM".
String formatClock(BuildContext context, String hhmm) {
  final minutes = parseTimeOfDay(hhmm);
  if (minutes == null) return hhmm;
  final t = DateTime.utc(2000, 1, 1, minutes ~/ 60, minutes % 60);
  return DateFormat.jm(context.localeTag).format(t);
}
