import 'dart:math';

import '../../../data/firebase/firestore_helpers.dart';

/// High-entropy invite codes: 12 Crockford base32 characters (60 bits).
///
/// Codes are document IDs in `invites/{code}`. Rules allow a signed-in user
/// to `get` a single invite but never to list them, so guessing a code is
/// the only way to find one — infeasible at 2^60. A code only grants the
/// ability to *request* to join; a host/admin must still approve.
abstract final class InviteCodes {
  static const length = 12;
  static const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Default lifetime of a new invite. Mirrored in rules
  /// (`maxInviteLifetimeDays()`), which cap it at 30 days.
  static const defaultLifetime = Duration(days: 14);

  static String generate([Random? random]) {
    final rng = random ?? Random.secure();
    return List.generate(
      length,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
  }

  /// "K7QM4XPT9C2B" -> "K7QM-4XPT-9C2B" for display.
  static String format(String code) {
    final buffer = StringBuffer();
    for (var i = 0; i < code.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(code[i]);
    }
    return buffer.toString();
  }

  /// Accepts a raw code (any case, with or without dashes/spaces) or a full
  /// invite link (`https://host/join/CODE`, `tourboard://join/CODE`).
  /// Returns the canonical code or null if the input is not a valid code.
  static String? parse(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (uri.scheme == 'tourboard' && uri.host == 'join') {
        text = segments.isEmpty ? '' : segments.first;
      } else {
        final joinIndex = segments.indexOf('join');
        if (joinIndex < 0 || joinIndex + 1 >= segments.length) return null;
        text = segments[joinIndex + 1];
      }
    }

    // Crockford decoding: ambiguous letters map to digits.
    final normalised = text
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]'), '')
        .replaceAll('O', '0')
        .replaceAll(RegExp('[IL]'), '1');
    if (normalised.length != length) return null;
    for (final ch in normalised.split('')) {
      if (!alphabet.contains(ch)) return null;
    }
    return normalised;
  }

  static String link(String base, String code) {
    final trimmed = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return '$trimmed/$code';
  }
}

/// Public preview stored at invites/{code}. Contains only what a prospective
/// member needs to decide whether to request access — no emails, no member
/// list, no expenses.
class InvitePreview {
  const InvitePreview({
    required this.code,
    required this.tourId,
    required this.tourName,
    required this.hostUid,
    required this.hostName,
    required this.startAt,
    required this.endAt,
    required this.expiresAt,
    required this.revoked,
  });

  factory InvitePreview.fromDoc(String id, Map<String, dynamic> data) =>
      InvitePreview(
        code: id,
        tourId: readString(data['tourId']),
        tourName: readString(data['tourName']),
        hostUid: readString(data['hostUid']),
        hostName: readString(data['hostName']),
        startAt: readDate(data['startAt']),
        endAt: readDate(data['endAt']),
        expiresAt: readDate(data['expiresAt']),
        revoked: readBool(data['revoked']),
      );

  final String code;
  final String tourId;
  final String tourName;
  final String hostUid;
  final String hostName;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime expiresAt;
  final bool revoked;

  bool isUsable(DateTime now) => !revoked && now.isBefore(expiresAt);
}
