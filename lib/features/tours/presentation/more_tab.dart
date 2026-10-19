import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../activity_feed/data/feed_repository.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/invite_code.dart';
import '../domain/tour.dart';

/// Shares the tour's current invite link via the system share sheet.
Future<void> shareInvite(BuildContext context, WidgetRef ref, Tour tour) async {
  final l10n = context.l10n;
  final code = tour.inviteCode;
  if (code == null) {
    showAppSnack(context, l10n.inviteOff);
    return;
  }
  final base = ref.read(appConfigProvider).inviteLinkBase;
  final link = InviteCodes.link(base, code);
  await SharePlus.instance.share(
    ShareParams(
      text: l10n.inviteShareText(tour.name, link, InviteCodes.format(code)),
      subject: l10n.inviteShareSubject(tour.name),
    ),
  );
}

class MoreTab extends ConsumerWidget {
  const MoreTab({required this.tour, super.key});

  final Tour tour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final permissions = ref.watch(permissionsProvider(tour.id));
    final pending = ref.watch(pendingRequestsProvider(tour.id)).value ?? [];
    final active = ref.watch(activeMembersProvider(tour.id));
    final unseen = ref.watch(unseenFeedCountProvider(tour.id));

    return ContentWidth(
      child: ListView(
        children: [
          if (permissions?.canManageInvites ?? false)
            ListTile(
              leading: const Icon(Icons.person_add_alt_outlined),
              title: Text(l10n.inviteMembers),
              subtitle: Text(l10n.inviteMembersHint),
              onTap: () => shareInvite(context, ref, tour),
            ),
          ListTile(
            leading: Badge(
              isLabelVisible: pending.isNotEmpty,
              label: Text('${pending.length}'),
              child: const Icon(Icons.group_outlined),
            ),
            title: Text(l10n.membersTitle),
            subtitle: Text(
              pending.isEmpty
                  ? l10n.memberCount(active.length)
                  : l10n.membersPendingCount(pending.length),
            ),
            onTap: () => context.push(Routes.members(tour.id)),
          ),
          ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text(l10n.notesTitle),
            onTap: () => context.push(Routes.notes(tour.id)),
          ),
          ListTile(
            leading: const Icon(Icons.checklist_outlined),
            title: Text(l10n.packingTitle),
            onTap: () => context.push(Routes.packing(tour.id)),
          ),
          ListTile(
            leading: Badge(
              isLabelVisible: unseen > 0,
              smallSize: 8,
              child: const Icon(Icons.history),
            ),
            title: Text(l10n.activityTitle),
            subtitle: unseen > 0 ? Text(l10n.activityNew(unseen)) : null,
            onTap: () => context.push(Routes.activity(tour.id)),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: Text(l10n.balancesOpen),
            onTap: () => context.push(Routes.balances(tour.id)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.tourSettingsTitle),
            subtitle: Text(l10n.tourSettingsHint),
            onTap: () => context.push(Routes.tourSettings(tour.id)),
          ),
        ],
      ),
    );
  }
}
