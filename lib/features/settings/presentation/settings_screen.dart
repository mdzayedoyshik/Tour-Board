import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_profile.dart';
import '../../notifications/data/reminder_service.dart';
import '../data/account_deletion.dart';
import '../data/preferences.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final prefs = ref.watch(preferencesProvider);
    final notifier = ref.read(preferencesProvider.notifier);
    final profile = ref.watch(profileProvider).value;
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            ListTile(
              leading: MemberAvatar(
                name: profile?.displayName ?? user?.displayName ?? '?',
                photoUrl: profile?.photoUrl ?? user?.photoURL,
                size: AppSizes.avatarLg,
              ),
              title: Text(profile?.displayName ?? user?.displayName ?? ''),
              subtitle: Text(profile?.email ?? user?.email ?? ''),
              trailing: IconButton(
                tooltip: l10n.profileEdit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: profile == null
                    ? null
                    : () => _editName(context, ref, profile),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Text(
                l10n.profileEmailReadOnly,
                style: theme.textTheme.bodySmall,
              ),
            ),
            SectionHeader(l10n.settingsAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {prefs.themeMode},
                onSelectionChanged: (s) => notifier.setThemeMode(s.first),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(
                prefs.localeCode == null
                    ? l10n.languageSystem
                    : _languageName(prefs.localeCode!),
              ),
              onTap: () => _pickLanguage(context, ref, prefs.localeCode),
            ),
            SectionHeader(l10n.settingsNotifications),
            SwitchListTile(
              title: Text(l10n.prefImportant),
              subtitle: Text(l10n.prefImportantHint),
              value: prefs.notifyImportant,
              onChanged: notifier.setNotifyImportant,
            ),
            SwitchListTile(
              title: Text(l10n.prefExpenses),
              value: prefs.notifyExpenses,
              onChanged: notifier.setNotifyExpenses,
            ),
            SwitchListTile(
              title: Text(l10n.prefPlans),
              value: prefs.notifyPlans,
              onChanged: notifier.setNotifyPlans,
            ),
            SwitchListTile(
              title: Text(l10n.prefReminders),
              subtitle: Text(l10n.prefRemindersHint),
              value: prefs.localReminders,
              onChanged: (on) async {
                if (on) {
                  final granted = await ref
                      .read(reminderServiceProvider)
                      .requestPermission();
                  if (!granted) {
                    if (context.mounted) {
                      showAppSnack(context, l10n.prefRemindersDenied);
                    }
                    return;
                  }
                } else {
                  await ref.read(reminderServiceProvider).cancelAll();
                }
                await notifier.setLocalReminders(on);
              },
            ),
            if (prefs.localReminders)
              ListTile(
                title: Text(l10n.prefReminderLead),
                trailing: DropdownButton<int>(
                  value: prefs.reminderLeadMinutes,
                  onChanged: (v) =>
                      v == null ? null : notifier.setReminderLead(v),
                  items: [
                    for (final m in const [10, 30, 60, 120])
                      DropdownMenuItem(
                        value: m,
                        child: Text(l10n.minutesBefore(m)),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Text(
                l10n.pushLimitation,
                style: theme.textTheme.bodySmall,
              ),
            ),
            SectionHeader(l10n.settingsLocation),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(l10n.locationHelpTitle),
              subtitle: Text(l10n.locationHelpBody),
              isThreeLine: true,
            ),
            ListTile(
              leading: const Icon(Icons.settings_applications_outlined),
              title: Text(l10n.locationOpenSettings),
              onTap: Geolocator.openAppSettings,
            ),
            SectionHeader(l10n.settingsPrivacy),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(l10n.privacyTitle),
              onTap: () =>
                  _showText(context, l10n.privacyTitle, l10n.privacyBody),
            ),
            if (prefs.showDiagnostics)
              ListTile(
                leading: const Icon(Icons.developer_mode),
                title: Text(l10n.diagnosticsTitle),
                onTap: () => context.push(Routes.diagnostics),
              ),
            SectionHeader(l10n.settingsAccount),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: Column(
                children: [
                  SecondaryButton(
                    label: l10n.signOut,
                    icon: Icons.logout,
                    onPressed: () async {
                      final ok = await confirmAction(
                        context,
                        title: l10n.signOutConfirm,
                        confirmLabel: l10n.signOut,
                      );
                      if (!ok) return;
                      await ref.read(reminderServiceProvider).cancelAll();
                      await ref.read(authRepositoryProvider).signOut();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DestructiveButton(
                    label: l10n.deleteAccount,
                    icon: Icons.person_off_outlined,
                    onPressed: () => _deleteAccount(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              // Long-press the version line to toggle developer diagnostics.
              onLongPress: () =>
                  notifier.setShowDiagnostics(!prefs.showDiagnostics),
              child: Center(
                child: Text(
                  '${l10n.appTitle} · ${ref.watch(appConfigProvider).environment}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _languageName(String code) => switch (code) {
    'en' => 'English',
    _ => code,
  };

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final l10n = context.l10n;
    final options = <String?>[
      null,
      ...AppLocalizations.supportedLocales.map((l) => l.languageCode),
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final code in options)
              ListTile(
                title: Text(
                  code == null ? l10n.languageSystem : _languageName(code),
                ),
                trailing: code == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, code ?? ''),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    final code = picked.isEmpty ? null : picked;
    await ref.read(preferencesProvider.notifier).setLocale(code);
    final uid = ref.read(currentUidProvider);
    final profile = ref.read(profileProvider).value;
    if (uid != null && profile != null) {
      try {
        await ref
            .read(authRepositoryProvider)
            .updateProfile(
              uid,
              displayName: profile.displayName,
              locale: code ?? 'en',
            );
      } catch (_) {
        // Device preference already applied; profile sync is best-effort.
      }
    }
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = context.l10n;
    final name = await promptText(
      context,
      title: l10n.profileEdit,
      label: l10n.profileName,
      confirmLabel: l10n.commonSave,
      maxLength: UserProfile.maxNameLength,
      initial: profile.displayName,
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            profile.uid,
            displayName: name,
            locale: profile.locale,
          );
      if (context.mounted) showAppSnack(context, l10n.profileUpdated);
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, errorMessage(context, e), error: true);
      }
    }
  }

  void _showText(BuildContext context, String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Text(body),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final service = ref.read(accountDeletionProvider);
    try {
      final blockers = await service.findBlockers(uid);
      if (!context.mounted) return;
      if (blockers.isNotEmpty) {
        await confirmAction(
          context,
          title: l10n.deleteBlockedTitle,
          message: l10n.deleteBlockedBody(
            blockers.map((b) => b.tourName).join(', '),
          ),
          confirmLabel: l10n.commonOk,
        );
        return;
      }
      final ok = await confirmAction(
        context,
        title: l10n.deleteAccountTitle,
        message: l10n.deleteAccountBody,
        confirmLabel: l10n.deleteAccount,
        destructive: true,
      );
      if (!ok) return;
      await service.deleteAccount(uid);
    } on SignInException catch (e) {
      if (context.mounted && e.reason != SignInFailure.cancelled) {
        showAppSnack(context, l10n.signInErrorGeneric, error: true);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, errorMessage(context, e), error: true);
      }
    }
  }
}
