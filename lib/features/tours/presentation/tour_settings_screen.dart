import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/invite_code.dart';
import '../../membership/domain/permissions.dart';
import '../../../data/backend/backend_client.dart';
import '../data/tour_repository.dart';
import '../domain/tour.dart';
import 'more_tab.dart';
import 'tour_status_ui.dart';

class TourSettingsScreen extends ConsumerWidget {
  const TourSettingsScreen({required this.tourId, super.key});

  final String tourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tourAsync = ref.watch(tourProvider(tourId));
    final permissions = ref.watch(permissionsProvider(tourId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tourSettingsTitle)),
      body: AsyncValueView(
        value: tourAsync,
        data: (tour) {
          if (tour == null || permissions == null) {
            return const ErrorState(error: AppException(AppErrorKind.notFound));
          }
          return _Body(tour: tour, permissions: permissions);
        },
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.tour, required this.permissions});

  final Tour tour;
  final TourPermissions permissions;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  Future<void> _guard(Future<void> Function() action, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAppSnack(context, done);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setStatus(TourStatus status) async {
    final l10n = context.l10n;
    final (title, body, label) = switch (status) {
      TourStatus.closed => (
        l10n.tourCloseTitle,
        l10n.tourCloseBody,
        l10n.tourClose,
      ),
      TourStatus.archived => (
        l10n.tourArchiveTitle,
        l10n.tourArchiveBody,
        l10n.tourArchive,
      ),
      _ => (l10n.tourReopenTitle, l10n.tourReopenBody, l10n.tourReopen),
    };
    final ok = await confirmAction(
      context,
      title: title,
      message: body,
      confirmLabel: label,
    );
    if (!ok) return;
    final uid = ref.read(currentUidProvider)!;
    await _guard(() async {
      await ref
          .read(tourRepositoryProvider)
          .setStatus(widget.tour, status, uid);
      if (status == TourStatus.archived) return;
      ref
          .read(eventReporterProvider)
          .report(
            status == TourStatus.closed
                ? ServerEvent.tourClosed
                : ServerEvent.tourReopened,
            tourId: widget.tour.id,
          );
    }, l10n.tourStatusChanged);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      title: l10n.tourDeleteTitle,
      message: l10n.tourDeleteBody,
      confirmLabel: l10n.tourDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      // The server deletes every subcollection recursively.
      await ref
          .read(backendClientProvider)
          .delete('/v1/tours/${widget.tour.id}');
      if (!mounted) return;
      showAppSnack(context, l10n.tourDeleted);
      context.go(Routes.home);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final l10n = context.l10n;
    final me = widget.permissions.viewer;
    if (me == null) return;
    final ok = await confirmAction(
      context,
      title: l10n.tourLeaveTitle,
      message: l10n.tourLeaveBody,
      confirmLabel: l10n.tourLeave,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(membershipRepositoryProvider).leave(widget.tour.id, me);
      if (mounted) context.go(Routes.home);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tour = widget.tour;
    final p = widget.permissions;
    final code = tour.inviteCode;
    final repo = ref.read(tourRepositoryProvider);

    return AbsorbPointer(
      absorbing: _busy,
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: [
            if (_busy) const LinearProgressIndicator(),
            SectionHeader(
              l10n.tourDetails,
              trailing: p.canEditTourDetails && tour.isOpen
                  ? TextButton(
                      onPressed: () => context.push(Routes.editTour(tour.id)),
                      child: Text(l10n.commonEdit),
                    )
                  : null,
            ),
            ListTile(
              title: Text(tour.name),
              subtitle: Text(
                [
                  formatTripRange(context, tour.startAt, tour.endAt),
                  tour.currencyCode,
                  tour.timeZone.replaceAll('_', ' '),
                  if (tour.budgetMinor != null)
                    l10n.tourBudgetValue(
                      formatMoney(
                        tour.budgetMinor!,
                        tour.currencyCode,
                        locale: context.localeTag,
                      ),
                    ),
                ].join(' · '),
              ),
              trailing: TourStatusPill(tour: tour),
            ),
            if (tour.description != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Text(tour.description!),
              ),
            if (p.canManageInvites) ...[
              SectionHeader(l10n.inviteSection),
              if (code == null)
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: Text(l10n.inviteOff),
                  trailing: TextButton(
                    onPressed: () => _guard(
                      () => repo
                          .rotateInvite(
                            tour,
                            actorUid: ref.read(currentUidProvider)!,
                            hostName: _hostName(),
                          )
                          .then((_) {}),
                      l10n.inviteCreated,
                    ),
                    child: Text(l10n.inviteCreate),
                  ),
                )
              else ...[
                ListTile(
                  title: SelectableText(
                    InviteCodes.format(code),
                    style: theme.textTheme.titleMedium?.copyWith(
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  subtitle: Text(l10n.inviteCodeHint),
                  trailing: IconButton(
                    tooltip: l10n.commonCopy,
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: InviteCodes.format(code)),
                      );
                      if (context.mounted) {
                        showAppSnack(context, l10n.commonCopied);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: l10n.commonShare,
                          icon: Icons.ios_share,
                          onPressed: () => shareInvite(context, ref, tour),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.autorenew),
                  title: Text(l10n.inviteRotate),
                  subtitle: Text(l10n.inviteRotateHint),
                  onTap: () async {
                    final ok = await confirmAction(
                      context,
                      title: l10n.inviteRotate,
                      message: l10n.inviteRotateHint,
                      confirmLabel: l10n.inviteRotate,
                    );
                    if (!ok) return;
                    await _guard(
                      () => repo
                          .rotateInvite(
                            tour,
                            actorUid: ref.read(currentUidProvider)!,
                            hostName: _hostName(),
                          )
                          .then((_) {}),
                      l10n.inviteCreated,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: Text(l10n.inviteTurnOff),
                  onTap: () =>
                      _guard(() => repo.revokeInvite(tour), l10n.inviteOff),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Text(
                  l10n.inviteExplainer,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            if (p.canChangeSettings) ...[
              SectionHeader(l10n.permissionsSection),
              SwitchListTile(
                title: Text(l10n.permAdminsManage),
                value: tour.settings.adminsCanManageTour,
                onChanged: (v) => _guard(
                  () => repo.updateSettings(
                    tour.id,
                    tour.settings.copyWith(adminsCanManageTour: v),
                  ),
                  l10n.settingsSaved,
                ),
              ),
              SwitchListTile(
                title: Text(l10n.permMembersPacking),
                value: tour.settings.membersCanEditPacking,
                onChanged: (v) => _guard(
                  () => repo.updateSettings(
                    tour.id,
                    tour.settings.copyWith(membersCanEditPacking: v),
                  ),
                  l10n.settingsSaved,
                ),
              ),
              SwitchListTile(
                title: Text(l10n.permMembersForOthers),
                subtitle: Text(l10n.permMembersForOthersHint),
                value: tour.settings.membersCanRecordForOthers,
                onChanged: (v) => _guard(
                  () => repo.updateSettings(
                    tour.id,
                    tour.settings.copyWith(membersCanRecordForOthers: v),
                  ),
                  l10n.settingsSaved,
                ),
              ),
            ],
            if (p.canChangeStatus) ...[
              SectionHeader(l10n.lifecycleSection),
              if (tour.isOpen)
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.tourClose),
                  subtitle: Text(l10n.tourCloseHint),
                  onTap: () => _setStatus(TourStatus.closed),
                ),
              if (!tour.isOpen)
                ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: Text(l10n.tourReopen),
                  onTap: () => _setStatus(TourStatus.active),
                ),
              if (tour.status == TourStatus.closed)
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(l10n.tourArchive),
                  subtitle: Text(l10n.tourArchiveHint),
                  onTap: () => _setStatus(TourStatus.archived),
                ),
              if (p.canDeleteTour)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: DestructiveButton(
                    label: l10n.tourDelete,
                    icon: Icons.delete_forever_outlined,
                    onPressed: _delete,
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (p.canLeave)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: DestructiveButton(
                  label: l10n.tourLeave,
                  icon: Icons.logout,
                  onPressed: _leave,
                ),
              )
            else if (p.isHost)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Text(
                  l10n.tourHostCannotLeave,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _hostName() {
    final members = ref.read(memberMapProvider(widget.tour.id));
    return members[widget.tour.hostUid]?.displayName ??
        ref.read(profileProvider).value?.displayName ??
        '—';
  }
}
