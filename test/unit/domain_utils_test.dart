import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tour_board/core/utils/dates.dart';
import 'package:tour_board/features/location_sharing/domain/location_share.dart';
import 'package:tour_board/features/membership/domain/invite_code.dart';
import 'package:tour_board/features/tours/domain/tour.dart';

void main() {
  group('InviteCodes', () {
    test('generates codes of the right length and alphabet', () {
      final code = InviteCodes.generate(Random(1));
      expect(code.length, InviteCodes.length);
      expect(code.split('').every(InviteCodes.alphabet.contains), isTrue);
      expect(InviteCodes.generate(), isNot(InviteCodes.generate()));
    });

    test('parses raw codes, dashed codes and links', () {
      const code = 'K7QM4XPT9C2B';
      expect(InviteCodes.parse(code), code);
      expect(InviteCodes.parse('k7qm-4xpt-9c2b'), code);
      expect(InviteCodes.parse(' K7QM 4XPT 9C2B '), code);
      expect(InviteCodes.parse('https://tourboard.app/join/$code'), code);
      expect(InviteCodes.parse('https://example.com/a/join/$code?x=1'), code);
      expect(InviteCodes.parse('tourboard://join/$code'), code);
      expect(InviteCodes.format(code), 'K7QM-4XPT-9C2B');
    });

    test('normalises ambiguous Crockford characters', () {
      expect(InviteCodes.parse('K7QM4XPT9C2O'), 'K7QM4XPT9C20');
      expect(InviteCodes.parse('K7QM4XPT9CIL'), 'K7QM4XPT9C11');
    });

    test('rejects invalid input', () {
      expect(InviteCodes.parse(''), isNull);
      expect(InviteCodes.parse('SHORT'), isNull);
      expect(InviteCodes.parse('K7QM4XPT9C2BX'), isNull);
      expect(InviteCodes.parse('K7QM4XPT9C2U'), isNull);
      expect(
        InviteCodes.parse('https://tourboard.app/other/K7QM4XPT9C2B'),
        isNull,
      );
    });

    test('preview expiry and revocation', () {
      final now = DateTime.utc(2026, 5, 1);
      InvitePreview preview({
        required DateTime expires,
        bool revoked = false,
      }) => InvitePreview(
        code: 'X',
        tourId: 't',
        tourName: 'n',
        hostName: 'h',
        startAt: now,
        endAt: now,
        expiresAt: expires,
        revoked: revoked,
      );
      expect(
        preview(expires: now.add(const Duration(days: 1))).isUsable(now),
        isTrue,
      );
      expect(preview(expires: now).isUsable(now), isFalse);
      expect(
        preview(
          expires: now.add(const Duration(days: 1)),
          revoked: true,
        ).isUsable(now),
        isFalse,
      );
    });
  });

  group('LocationShare', () {
    final now = DateTime.utc(2026, 5, 1, 12);
    LocationShare share({
      Duration age = Duration.zero,
      Duration remaining = const Duration(hours: 1),
      String status = 'live',
    }) => LocationShare(
      uid: 'u',
      latitude: 21.4,
      longitude: 92.0,
      updatedAt: now.subtract(age),
      sharingUntil: now.add(remaining),
      sourceStatus: status,
    );

    test('live, stale, paused and expired states', () {
      expect(share().statusAt(now), LocationShareStatus.live);
      expect(
        share(age: const Duration(minutes: 6)).statusAt(now),
        LocationShareStatus.stale,
      );
      expect(share(status: 'paused').statusAt(now), LocationShareStatus.paused);
      expect(
        share(remaining: Duration.zero).statusAt(now),
        LocationShareStatus.notSharing,
      );
      expect(share(remaining: Duration.zero).isVisibleAt(now), isFalse);
      expect(share(status: 'paused').isVisibleAt(now), isFalse);
      expect(share(age: const Duration(minutes: 6)).isVisibleAt(now), isTrue);
    });

    test('sharing windows are capped and sensible', () {
      final tripEnd = DateTime.utc(2026, 5, 3);
      expect(
        sharingUntilFor(SharingDuration.twoHours, now, tripEnd),
        now.add(const Duration(hours: 2)),
      );
      expect(
        sharingUntilFor(SharingDuration.untilTripEnds, now, tripEnd),
        DateTime.utc(2026, 5, 4),
      );
      expect(
        sharingUntilFor(SharingDuration.untilTripEnds, now, DateTime.utc(2027)),
        now.add(LocationShare.maxSharingWindow),
      );
      expect(
        sharingUntilFor(SharingDuration.untilTripEnds, now, DateTime.utc(2026)),
        now.add(const Duration(hours: 2)),
      );
    });

    test('write policy throttles by time and distance', () {
      const policy = LocationWritePolicy();
      expect(
        policy.shouldWrite(
          now: now,
          lastWriteAt: null,
          metersSinceLastWrite: null,
        ),
        isTrue,
      );
      expect(
        policy.shouldWrite(
          now: now,
          lastWriteAt: now.subtract(const Duration(seconds: 10)),
          metersSinceLastWrite: 500,
        ),
        isFalse,
      );
      expect(
        policy.shouldWrite(
          now: now,
          lastWriteAt: now.subtract(const Duration(minutes: 1)),
          metersSinceLastWrite: 10,
        ),
        isFalse,
      );
      expect(
        policy.shouldWrite(
          now: now,
          lastWriteAt: now.subtract(const Duration(minutes: 1)),
          metersSinceLastWrite: 100,
        ),
        isTrue,
      );
      expect(
        policy.shouldWrite(
          now: now,
          lastWriteAt: now.subtract(const Duration(minutes: 11)),
          metersSinceLastWrite: 0,
        ),
        isTrue,
      );
    });

    test('coordinate validation', () {
      expect(isValidCoordinate(21.4, 92.0), isTrue);
      expect(isValidCoordinate(91, 0), isFalse);
      expect(isValidCoordinate(0, -181), isFalse);
      expect(isValidCoordinate(double.nan, 0), isFalse);
      expect(isValidCoordinate(null, 0), isFalse);
    });
  });

  group('dates', () {
    test('date range validation', () {
      final d = DateTime.utc(2026, 3, 10);
      expect(validateDateRange(d, d), isNull);
      expect(
        validateDateRange(d, d.subtract(const Duration(days: 1))),
        DateRangeError.endBeforeStart,
      );
      expect(
        validateDateRange(d, d.add(const Duration(days: 400))),
        DateRangeError.tooLong,
      );
    });

    test('day keys are inclusive', () {
      expect(
        dayKeysBetween(DateTime.utc(2026, 2, 27), DateTime.utc(2026, 3, 1)),
        ['2026-02-27', '2026-02-28', '2026-03-01'],
      );
      expect(parseDayKey('2026-03-01'), DateTime.utc(2026, 3, 1));
      expect(parseDayKey('nope'), isNull);
    });

    test('time parsing', () {
      expect(parseTimeOfDay('09:30'), 570);
      expect(parseTimeOfDay('24:00'), isNull);
      expect(parseTimeOfDay('9:30'), isNull);
    });

    test('tour-local times convert to UTC via IANA zone', () {
      // Asia/Dhaka is UTC+6 with no DST.
      expect(
        TimeZones.localToUtc('2026-03-14', '09:00', 'Asia/Dhaka'),
        DateTime.utc(2026, 3, 14, 3),
      );
      // New York observes DST in July (UTC-4).
      expect(
        TimeZones.localToUtc('2026-07-01', '12:00', 'America/New_York'),
        DateTime.utc(2026, 7, 1, 16),
      );
      expect(TimeZones.offsetLabel('Asia/Dhaka', DateTime.utc(2026)), 'GMT+6');
      expect(
        TimeZones.offsetLabel('Asia/Kolkata', DateTime.utc(2026)),
        'GMT+5:30',
      );
      expect(TimeZones.isValid('Asia/Dhaka'), isTrue);
      expect(TimeZones.isValid('Mars/Base'), isFalse);
    });

    test('effective status follows dates in the tour zone', () {
      Tour tour(TourStatus status) => Tour(
        id: 't',
        name: 'n',
        hostUid: 'h',
        status: status,
        startAt: DateTime.utc(2026, 3, 14),
        endAt: DateTime.utc(2026, 3, 16),
        timeZone: 'Asia/Dhaka',
        currencyCode: 'BDT',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      // 20:00 UTC on Mar 13 is already Mar 14 in Dhaka.
      expect(
        effectiveStatus(
          tour(TourStatus.upcoming),
          DateTime.utc(2026, 3, 13, 20),
        ),
        TourStatus.active,
      );
      expect(
        effectiveStatus(
          tour(TourStatus.upcoming),
          DateTime.utc(2026, 3, 13, 10),
        ),
        TourStatus.upcoming,
      );
      expect(
        effectiveStatus(tour(TourStatus.closed), DateTime.utc(2026, 3, 15)),
        TourStatus.closed,
      );
      expect(
        hasEnded(tour(TourStatus.active), DateTime.utc(2026, 3, 17, 12)),
        isTrue,
      );
    });
  });
}
