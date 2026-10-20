import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/notifications/data/push_service.dart';
import '../features/settings/data/preferences.dart';
import 'providers.dart';
import 'router.dart';

class TourBoardApp extends ConsumerStatefulWidget {
  const TourBoardApp({super.key});

  @override
  ConsumerState<TourBoardApp> createState() => _TourBoardAppState();
}

class _TourBoardAppState extends ConsumerState<TourBoardApp> {
  @override
  void initState() {
    super.initState();
    // Notification taps open the related screen.
    PushService.onOpenRoute = (route) => ref.read(routerProvider).push(route);
    // Register this device for push while someone is signed in.
    ref.listenManual<String?>(currentUidProvider, (previous, uid) {
      final push = ref.read(pushServiceProvider);
      if (uid != null) {
        unawaited(push.start(uid));
      } else if (previous != null) {
        unawaited(push.stop(deleteToken: false));
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(preferencesProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: prefs.themeMode,
      locale: prefs.localeCode == null ? null : Locale(prefs.localeCode!),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
