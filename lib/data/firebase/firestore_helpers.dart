import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads a Firestore timestamp-ish value into a UTC [DateTime].
///
/// Server timestamps are null in local snapshots until the write is
/// acknowledged, so callers get [fallback] (usually "now") in that window.
DateTime readDate(Object? value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  return (fallback ?? DateTime.now()).toUtc();
}

DateTime? readDateOrNull(Object? value) {
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  return null;
}

int readInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

int? readIntOrNull(Object? value) => value is num ? value.toInt() : null;

double? readDoubleOrNull(Object? value) =>
    value is num ? value.toDouble() : null;

String readString(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

String? readStringOrNull(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

bool readBool(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;

List<String> readStringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

Map<String, int> readIntMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is num)
        entry.key as String: (entry.value as num).toInt(),
  };
}

Map<String, dynamic> readMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

/// Trims and returns null for blank strings, so optional fields are omitted
/// rather than stored as empty strings.
String? blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
