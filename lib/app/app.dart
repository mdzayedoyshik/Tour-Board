import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/l10n.dart';
import '../core/theme/app_theme.dart';
import '../features/membership/domain/invite_code.dart';
import '../features/settings/data/preferences.dart';
import 'router.dart';
import 'routes.dart';

class TourBoardApp extends ConsumerStatefulWidget {
  const TourBoardApp({super.key});

  @override
  ConsumerState<TourBoardApp> createState() => _TourBoardAppState();
}

class _TourBoardAppState extends ConsumerState<TourBoardApp> {
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    _listenForInviteLinks();
  }

  /// Handles `https://<host>/join/<code>` App Links / Universal Links and the
  /// `tourboard://join/<code>` fallback scheme. Codes are validated first.
  void _listenForInviteLinks() {
    try {
      // uriLinkStream also delivers the link that launched the app.
      _links = AppLinks().uriLinkStream.listen(
        _handleLink,
        onError: (Object _) {},
      );
    } catch (_) {
      // Not supported in tests or on this platform.
    }
  }

  void _handleLink(Uri uri) {
    final code = InviteCodes.parse(uri.toString());
    if (code == null) return;
    // The router stores it if the user still has to sign in.
    ref.read(routerProvider).go(Routes.joinWithCode(code));
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
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
