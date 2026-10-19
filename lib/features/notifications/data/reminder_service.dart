import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../app/providers.dart';
import '../../../core/utils/dates.dart';
import '../../itinerary/domain/plan_item.dart';

/// Device-local itinerary reminders (opt-in, off by default).
///
/// These are local notifications scheduled on this device only; they never
/// notify other members and are not remote push. Inexact scheduling is used
/// so no exact-alarm permission is required.
class ReminderService {
  ReminderService(this._prefs);

  final SharedPreferences _prefs;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  /// Upper bound per tour so a large itinerary cannot flood the OS queue.
  static const maxPerTour = 30;

  static const _channel = AndroidNotificationDetails(
    'itinerary_reminders',
    'Itinerary reminders',
    channelDescription: 'Reminders for plans you opted in to on this device',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> _ensureInit() async {
    if (_initialised) return;
    TimeZones.ensureInitialised();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialised = true;
  }

  /// Asks the OS for notification permission. Returns false if denied.
  Future<bool> requestPermission() async {
    await _ensureInit();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  static int idFor(String tourId, String itemId) =>
      Object.hash(tourId, itemId) & 0x7fffffff;

  String _key(String tourId) => 'reminders.$tourId';

  /// Replaces this tour's reminders with ones for upcoming planned items.
  /// Called whenever the itinerary changes, so edits/removals reschedule.
  Future<void> syncTour({
    required String tourId,
    required String tourName,
    required List<PlanItem> items,
    required bool enabled,
    required int leadMinutes,
    required String Function(PlanItem item) bodyFor,
    DateTime? now,
  }) async {
    try {
      await _ensureInit();
      await cancelTour(tourId);
      if (!enabled) return;
      final current = (now ?? DateTime.now()).toUtc();
      final upcoming = remindersToSchedule(
        items,
        now: current,
        leadMinutes: leadMinutes,
      ).take(maxPerTour);
      final ids = <String>[];
      for (final entry in upcoming) {
        final id = idFor(tourId, entry.item.id);
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(entry.at, tz.UTC),
          notificationDetails: const NotificationDetails(
            android: _channel,
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: '${entry.item.title} · $tourName',
          body: bodyFor(entry.item),
          payload: tourId,
        );
        ids.add('$id');
      }
      await _prefs.setStringList(_key(tourId), ids);
    } catch (e) {
      debugPrint('Reminders not scheduled: $e');
    }
  }

  Future<void> cancelTour(String tourId) async {
    await _ensureInit();
    for (final id in _prefs.getStringList(_key(tourId)) ?? const <String>[]) {
      await _plugin.cancel(id: int.parse(id));
    }
    await _prefs.remove(_key(tourId));
  }

  Future<void> cancelAll() async {
    await _ensureInit();
    await _plugin.cancelAll();
    for (final key in _prefs.getKeys().where(
      (k) => k.startsWith('reminders.'),
    )) {
      await _prefs.remove(key);
    }
  }
}

/// Pure selection logic (tested): planned items with a start time, minus
/// the lead time, still in the future; soonest first.
List<({PlanItem item, DateTime at})> remindersToSchedule(
  Iterable<PlanItem> items, {
  required DateTime now,
  required int leadMinutes,
}) {
  final result = <({PlanItem item, DateTime at})>[];
  for (final item in items) {
    final start = item.startAt;
    if (item.status != PlanStatus.planned || start == null) continue;
    final at = start.subtract(Duration(minutes: leadMinutes));
    if (at.isAfter(now)) result.add((item: item, at: at));
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(ref.watch(sharedPreferencesProvider)),
);
