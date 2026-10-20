import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tour_board/features/itinerary/domain/plan_item.dart';
import 'package:tour_board/features/itinerary/presentation/plan_tab.dart';
import 'package:tour_board/data/backend/backend_client.dart';
import 'package:tour_board/features/map/data/place_service.dart';
import 'package:tour_board/features/notifications/data/push_service.dart';
import 'package:tour_board/features/notifications/data/reminder_service.dart';

import '../helpers.dart';

PlanItem item(
  String id, {
  String day = '2026-03-14',
  int sort = 1024,
  DateTime? startAt,
  String? startTime,
  PlanStatus status = PlanStatus.planned,
}) => PlanItem(
  id: id,
  title: id,
  dayKey: day,
  sortOrder: sort,
  status: status,
  createdBy: 'a',
  createdAt: testTime,
  updatedAt: testTime,
  startAt: startAt,
  startTime: startTime,
);

void main() {
  group('sortKeyBetween', () {
    test('places items with sparse gaps', () {
      expect(sortKeyBetween(null, null), sortGap);
      expect(sortKeyBetween(1024, null), 2048);
      expect(sortKeyBetween(null, 1024), 0);
      expect(sortKeyBetween(1024, 2048), 1536);
      expect(sortKeyBetween(5, 6), isNull); // Caller renumbers.
    });

    test('sortPlanItems orders by sortOrder then time', () {
      final sorted = sortPlanItems([
        item('b', sort: 2048),
        item('a2', sort: 1024, startTime: '10:00'),
        item('a1', sort: 1024, startTime: '09:00'),
      ]);
      expect(sorted.map((i) => i.id), ['a1', 'a2', 'b']);
    });
  });

  test('groupByDay keeps every trip day and out-of-range items', () {
    final grouped = groupByDay(testTour(), [
      item('x', day: '2026-03-14'),
      item('y', day: '2026-04-01'),
    ]);
    expect(grouped.keys.first, '2026-03-13');
    expect(grouped.keys, contains('2026-04-01'));
    expect(grouped['2026-03-15'], isEmpty);
    expect(grouped['2026-03-14']!.single.id, 'x');
  });

  test('reminders: only future planned items with a start, soonest first', () {
    final now = DateTime.utc(2026, 3, 14, 3);
    final result = remindersToSchedule(
      [
        item('late', startAt: DateTime.utc(2026, 3, 14, 12)),
        item('soon', startAt: DateTime.utc(2026, 3, 14, 4)),
        item('past', startAt: DateTime.utc(2026, 3, 14, 3, 10)),
        item('none'),
        item(
          'done',
          startAt: DateTime.utc(2026, 3, 15),
          status: PlanStatus.completed,
        ),
      ],
      now: now,
      leadMinutes: 30,
    );
    expect(result.map((r) => r.item.id), ['soon', 'late']);
    expect(result.first.at, DateTime.utc(2026, 3, 14, 3, 30));
  });

  group('PlaceService (via backend)', () {
    PlaceService service(Future<http.Response> Function(http.Request) handler) {
      final user = _MockUser();
      when(() => user.getIdToken()).thenAnswer((_) async => 'id-token');
      final auth = _MockAuth();
      when(() => auth.currentUser).thenReturn(user);
      return PlaceService(
        BackendClient('https://api.example', auth, client: MockClient(handler)),
      );
    }

    test(
      'autocomplete sends auth and a session; short queries are skipped',
      () async {
        final requests = <http.Request>[];
        final s = service((req) async {
          requests.add(req);
          return http.Response(
            jsonEncode({
              'suggestions': [
                {
                  'placeId': 'p1',
                  'primary': 'Inani Beach',
                  'secondary': 'Ukhia',
                },
              ],
            }),
            200,
          );
        });
        expect(await s.autocomplete('ab'), isEmpty);
        final results = await s.autocomplete('inani', language: 'en');
        expect(results.single.primary, 'Inani Beach');
        expect(requests.single.headers['Authorization'], 'Bearer id-token');
        expect(requests.single.url.path, '/v1/places/autocomplete');
        expect(requests.single.url.queryParameters['session'], isNotEmpty);
      },
    );

    test('details keeps the suggestion name and ends the session', () async {
      final sessions = <String?>[];
      final s = service((req) async {
        sessions.add(req.url.queryParameters['session']);
        if (req.url.path.startsWith('/v1/places/details')) {
          return http.Response(
            jsonEncode({
              'place': {'address': 'Inani, Ukhia', 'lat': 21.2, 'lng': 92.05},
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'suggestions': []}), 200);
      });
      const suggestion = PlaceSuggestion(
        placeId: 'p1',
        primary: 'Inani Beach',
        secondary: 'Ukhia',
      );
      await s.autocomplete('inani');
      final place = await s.details(suggestion);
      await s.autocomplete('inani b');
      expect(place.name, 'Inani Beach');
      expect(place.latitude, 21.2);
      expect(sessions[0], sessions[1]);
      expect(sessions[2], isNot(sessions[1]));
    });

    test('maps quota and outages to friendly errors', () async {
      final quota = service(
        (_) async => http.Response('{"error":"quota-exceeded"}', 429),
      );
      await expectLater(
        quota.autocomplete('inani'),
        throwsA(
          isA<PlaceException>().having(
            (e) => e.kind,
            'kind',
            PlaceErrorKind.quota,
          ),
        ),
      );
      final down = service(
        (_) async => http.Response('{"error":"places-unavailable"}', 503),
      );
      await expectLater(
        down.reverse(21, 92),
        throwsA(
          isA<PlaceException>().having(
            (e) => e.kind,
            'kind',
            PlaceErrorKind.unavailable,
          ),
        ),
      );
    });
  });

  group('push routing', () {
    test('notification taps open the related screen', () {
      expect(
        routeForMessage({'type': 'joinRequest', 'tourId': 't'}),
        '/tour/t/members',
      );
      expect(
        routeForMessage({'type': 'settlementSubmitted', 'tourId': 't'}),
        '/tour/t/balances',
      );
      expect(
        routeForMessage({'type': 'expenseAdded', 'tourId': 't', 'refId': 'e1'}),
        '/tour/t/expenses/e1',
      );
      expect(
        routeForMessage({'type': 'planAdded', 'tourId': 't'}),
        '/tour/t?tab=1',
      );
      expect(routeForMessage({'type': 'tourClosed', 'tourId': 't'}), '/tour/t');
      expect(routeForMessage(<String, dynamic>{}), '/inbox');
    });
  });
}

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}
