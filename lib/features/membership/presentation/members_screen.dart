import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../../tours/data/tour_repository.dart';
import '../../tours/domain/tour.dart';
import '../../tours/presentation/more_tab.dart';
import '../data/membership_repository.dart';
import '../domain/member.dart';
import '../domain/permissions.dart';

String roleLabel(AppLocalizations l10n, MemberRole role) => switch (role) {
  MemberRole.host => l10n.roleHost,
  MemberRole.admin => l10n.roleAdmin,
  MemberRole.member => l10n.roleMember,
};

class MembersScreen extends ConsumerWidget {
  const MembersScreen({required this.tourId, super.key});

  final String tourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tour = ref.watch(tourProvider(tourId)).value;
    final membersAsync = ref.watch(membersProvider(tourId));
    final permissions = ref.watch(permissionsProvider(tourId));
    final pending = ref.watch(pendingRequestsProvider(tourId)).value ?? [];
    final active = ref.watch(activeMembersProvider(tourId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.membersTitle),
        actions: [
          if (tour != null && (permissions?.canManageInvites ?? false))
            IconButton(
              tooltip: l10n.inviteMembers,
              icon: const Icon(Icons.person_add_alt_outlined),
              onPressed: () => shareInvite(context, ref, tour),
            ),
        ],
      ),
      body: AsyncValueView(
        value: membersAsync,
        onRetry: () => ref.invalidate(membersProvider(tourId)),
        data: (all) {
          if (tour == null || permissions == null) return const LoadingList();
          final former = all.where((m) => !m.isActive).toList();
          return ContentWidth(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                if (pending.isNotEmpty) ...[
                  SectionHeader(l10n.membersPendingCount(pending.length)),
                  for (final r in pending)
                    _RequestTile(
                      tour: tour,
                      request: r,
                      activeCount: active.length,
                    ),
                ],
                SectionHeader(l10n.memberCount(active.length)),
                for (final m in active)
                  _MemberTile(
                    tour: tour,
                    member: m,
                    permissions: permissions,
                    members: active,
                  ),
                if (former.isNotEmpty) ...[
                  SectionHeader(l10n.membersFormer),
                  for (final m in former)
                    ListTile(
                      leading: MemberAvatar(
                        name: m.displayName,
                        photoUrl: m.photoUrl,
                      ),
                      title: Text(m.displayName),
                      subtitle: Text(
                        m.status == MemberStatus.left
                            ? l10n.memberLeft
                            : l10n.memberRemoved,
                      ),
                    ),
                ],
                if (active.length >= Tour.maxMembers)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: Text(l10n.membersCapReached(Tour.maxMembers)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({
    required this.tour,
    required this.request,
    required this.activeCount,
  });

  final Tour tour;
  final JoinRequest request;
  final int activeCount;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _review(bool approve) async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final repo = ref.read(membershipRepositoryProvider);
    final uid = ref.read(currentUidProvider)!;
    final name = ref.read(profileProvider).value?.displayName ?? '—';
    try {
      // Approval needs the server; it is never queued offline.
      if (approve) {
        await repo.approve(
          tour: widget.tour,
          request: widget.request,
          reviewerUid: uid,
          reviewerName: name,
          activeMemberCount: widget.activeCount,
        );
      } else {
        await repo.reject(
          tour: widget.tour,
          request: widget.request,
          reviewerUid: uid,
          reviewerName: name,
        );
      }
      if (mounted) {
        showAppSnack(
          context,
          approve ? l10n.requestApproved : l10n.requestRejected,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = classifyError(e) == AppErrorKind.quota
          ? l10n.membersCapReached(Tour.maxMembers)
          : errorMessage(context, e);
      showAppSnack(context, message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = widget.request;
    return ListTile(
      leading: MemberAvatar(name: r.displayName, photoUrl: r.photoUrl),
      title: Text(r.displayName),
      subtitle: Text(l10n.requestedOn(formatShortDate(context, r.updatedAt))),
      trailing: _busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.requestReject,
                  icon: const Icon(Icons.close),
                  onPressed: () => _review(false),
                ),
                IconButton.filledTonal(
                  tooltip: l10n.requestApprove,
                  icon: const Icon(Icons.check),
                  onPressed: () => _review(true),
                ),
              ],
            ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.tour,
    required this.member,
    required this.permissions,
    required this.members,
  });

  final Tour tour;
  final Member member;
  final TourPermissions permissions;
  final List<Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isMe = member.uid == permissions.viewer?.uid;
    final canRemove = permissions.canRemoveMember(member);
    final canRole = permissions.canChangeRoles && !isMe && !member.isHost;
    final canTransfer = permissions.canTransferHost && !isMe;
    final hasActions = canRemove || canRole || canTransfer;

    return ListTile(
      leading: MemberAvatar(
        name: member.displayName,
        photoUrl: member.photoUrl,
      ),
      title: Text(
        isMe ? '${member.displayName} (${l10n.commonYou})' : member.displayName,
      ),
      subtitle: Text(roleLabel(l10n, member.role)),
      trailing: hasActions
          ? IconButton(
              tooltip: l10n.memberActions,
              icon: const Icon(Icons.more_vert),
              onPressed: () =>
                  _actions(context, ref, canRemove, canRole, canTransfer),
            )
          : null,
    );
  }

  Future<void> _actions(
    BuildContext context,
    WidgetRef ref,
    bool canRemove,
    bool canRole,
    bool canTransfer,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(membershipRepositoryProvider);
    final uid = ref.read(currentUidProvider)!;
    final myName = ref.read(profileProvider).value?.displayName ?? '—';

    Future<void> guarded(Future<void> Function() action, String done) async {
      try {
        await action();
        if (context.mounted) showAppSnack(context, done);
      } catch (e) {
        if (context.mounted) {
          showAppSnack(context, errorMessage(context, e), error: true);
        }
      }
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canRole)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: Text(
                  member.role == MemberRole.admin
                      ? l10n.memberMakeMember
                      : l10n.memberMakeAdmin,
                ),
                onTap: () => Navigator.pop(context, 'role'),
              ),
            if (canTransfer)
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: Text(l10n.memberTransferHost),
                onTap: () => Navigator.pop(context, 'transfer'),
              ),
            if (canRemove)
              ListTile(
                leading: Icon(
                  Icons.person_remove_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  l10n.memberRemove,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;

    switch (choice) {
      case 'role':
        final role = member.role == MemberRole.admin
            ? MemberRole.member
            : MemberRole.admin;
        await guarded(
          () => repo.changeRole(
            tour: tour,
            member: member,
            role: role,
            actorUid: uid,
            actorName: myName,
          ),
          l10n.memberRoleChanged,
        );
      case 'transfer':
        final ok = await confirmAction(
          context,
          title: l10n.memberTransferTitle(member.displayName),
          message: l10n.memberTransferBody,
          confirmLabel: l10n.memberTransferHost,
        );
        if (!ok) return;
        await guarded(
          () => repo.transferHost(
            tour: tour,
            newHost: member,
            currentHostUid: uid,
          ),
          l10n.memberHostTransferred,
        );
      case 'remove':
        final ok = await confirmAction(
          context,
          title: l10n.memberRemoveTitle(member.displayName),
          message: l10n.memberRemoveBody,
          confirmLabel: l10n.memberRemove,
          destructive: true,
        );
        if (!ok) return;
        await guarded(
          () => repo.removeMember(tour, member, uid),
          l10n.memberRemovedDone,
        );
    }
  }
}
