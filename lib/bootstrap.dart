import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/config/app_config.dart';
import 'core/utils/dates.dart';
import 'data/firebase/firebase_bootstrap.dart';
import 'features/auth/presentation/config_error_app.dart';

/// Loads configuration, initialises Firebase and starts the app. Missing
/// configuration shows a setup screen instead of crashing.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    // No external crash reporter in MVP (see docs/FREE_TIER_LIMITS.md).
    debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  TimeZones.ensureInitialised();
  final config = await AppConfig.load();
  final prefs = await SharedPreferences.getInstance();

  try {
    await initFirebase(config);
  } catch (e) {
    runApp(ConfigErrorApp(error: e));
    return;
  }

  runApp(
    ProviderScope(
      // Streams that fail with permission-denied (e.g. removed from a tour)
      // should surface immediately, not retry in a loop.
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const TourBoardApp(),
    ),
  );
}
