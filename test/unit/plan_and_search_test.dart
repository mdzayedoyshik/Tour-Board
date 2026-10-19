import 'package:flutter_test/flutter_test.dart';
import 'package:tour_board/features/itinerary/domain/plan_item.dart';
import 'package:tour_board/features/itinerary/presentation/plan_tab.dart';
import 'package:tour_board/features/map/data/map_provider.dart';
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

  group('Nominatim parsing', () {
    test('parses results and skips invalid coordinates', () {
      const body = '''
[
  {"lat": "21.4272", "lon": "92.0058", "name": "Cox's Bazar",
   "display_name": "Cox's Bazar, Chattogram, Bangladesh"},
  {"lat": "999", "lon": "0", "display_name": "Broken"},
  {"lat": "21.1", "lon": "92.1", "name": "",
   "display_name": "Inani Beach, Ukhia, Bangladesh"}
]''';
      final results = NominatimPlaceSearch.parseNominatim(body);
      expect(results.length, 2);
      expect(results.first.name, "Cox's Bazar");
      expect(results.first.latitude, closeTo(21.4272, 1e-9));
      expect(results.last.name, 'Inani Beach');
    });

    test('handles unexpected payloads', () {
      expect(NominatimPlaceSearch.parseNominatim('{}'), isEmpty);
    });

    test('short queries make no request', () async {
      final search = NominatimPlaceSearch(
        baseUrl: 'https://invalid.example',
        contactEmail: '',
      );
      expect(await search.search('ab'), isEmpty);
    });
  });
}
