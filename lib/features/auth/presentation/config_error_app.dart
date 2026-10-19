import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../core/config/app_config.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';

/// Shown instead of crashing when Firebase/env configuration is missing.
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final theme = Theme.of(context);
          final details = error is ConfigException
              ? (error as ConfigException).message
              : error.toString();
          return Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Icon(
                    Icons.settings_suggest_outlined,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.configErrorTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.configErrorBody),
                  const SizedBox(height: AppSpacing.lg),
                  SelectableText(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
