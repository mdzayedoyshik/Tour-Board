import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Small device-local settings kept in shared_preferences.
class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.notifyImportant = true,
    this.notifyExpenses = false,
    this.notifyPlans = false,
    this.localReminders = false,
    this.reminderLeadMinutes = 30,
    this.showDiagnostics = false,
  });

  final ThemeMode themeMode;

  /// Null follows the device language.
  final String? localeCode;

  /// Show the inbox badge for important events (join requests, settlements).
  final bool notifyImportant;

  /// Highlight new expense activity in the feed badge.
  final bool notifyExpenses;

  /// Highlight new plan activity in the feed badge.
  final bool notifyPlans;

  /// Device-local itinerary reminders. Off until the user opts in.
  final bool localReminders;
  final int reminderLeadMinutes;

  /// Developer diagnostics entry in Settings.
  final bool showDiagnostics;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    String? Function()? localeCode,
    bool? notifyImportant,
    bool? notifyExpenses,
    bool? notifyPlans,
    bool? localReminders,
    int? reminderLeadMinutes,
    bool? showDiagnostics,
  }) => AppPreferences(
    themeMode: themeMode ?? this.themeMode,
    localeCode: localeCode != null ? localeCode() : this.localeCode,
    notifyImportant: notifyImportant ?? this.notifyImportant,
    notifyExpenses: notifyExpenses ?? this.notifyExpenses,
    notifyPlans: notifyPlans ?? this.notifyPlans,
    localReminders: localReminders ?? this.localReminders,
    reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
    showDiagnostics: showDiagnostics ?? this.showDiagnostics,
  );
}

class PreferencesNotifier extends Notifier<AppPreferences> {
  static const _theme = 'pref.themeMode';
  static const _locale = 'pref.locale';
  static const _important = 'pref.notifyImportant';
  static const _expenses = 'pref.notifyExpenses';
  static const _plans = 'pref.notifyPlans';
  static const _reminders = 'pref.localReminders';
  static const _lead = 'pref.reminderLead';
  static const _diagnostics = 'pref.diagnostics';

  @override
  AppPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppPreferences(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == prefs.getString(_theme),
        orElse: () => ThemeMode.system,
      ),
      localeCode: prefs.getString(_locale),
      notifyImportant: prefs.getBool(_important) ?? true,
      notifyExpenses: prefs.getBool(_expenses) ?? false,
      notifyPlans: prefs.getBool(_plans) ?? false,
      localReminders: prefs.getBool(_reminders) ?? false,
      reminderLeadMinutes: prefs.getInt(_lead) ?? 30,
      showDiagnostics: prefs.getBool(_diagnostics) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await ref.read(sharedPreferencesProvider).setString(_theme, mode.name);
  }

  Future<void> setLocale(String? code) async {
    state = state.copyWith(localeCode: () => code);
    final prefs = ref.read(sharedPreferencesProvider);
    if (code == null) {
      await prefs.remove(_locale);
    } else {
      await prefs.setString(_locale, code);
    }
  }

  Future<void> setNotifyImportant(bool value) =>
      _setBool(_important, value, state.copyWith(notifyImportant: value));

  Future<void> setNotifyExpenses(bool value) =>
      _setBool(_expenses, value, state.copyWith(notifyExpenses: value));

  Future<void> setNotifyPlans(bool value) =>
      _setBool(_plans, value, state.copyWith(notifyPlans: value));

  Future<void> setLocalReminders(bool value) =>
      _setBool(_reminders, value, state.copyWith(localReminders: value));

  Future<void> setShowDiagnostics(bool value) =>
      _setBool(_diagnostics, value, state.copyWith(showDiagnostics: value));

  Future<void> setReminderLead(int minutes) async {
    state = state.copyWith(reminderLeadMinutes: minutes);
    await ref.read(sharedPreferencesProvider).setInt(_lead, minutes);
  }

  Future<void> _setBool(String key, bool value, AppPreferences next) async {
    state = next;
    await ref.read(sharedPreferencesProvider).setBool(key, value);
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, AppPreferences>(
      PreferencesNotifier.new,
    );
