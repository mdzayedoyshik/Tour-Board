import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../settings/data/preferences.dart';
import '../data/inbox_repository.dart';
import '../domain/inbox_item.dart';

String describeInbox(AppLocalizations l10n, InboxItem item) =>
    switch (item.type) {
      InboxType.joinRequest => l10n.inboxJoinRequest(item.senderName),
      InboxType.joinApproved => l10n.inboxJoinApproved,
      InboxType.joinRejected => l10n.inboxJoinRejected,
      InboxType.settlementSubmitted => l10n.inboxSettlementSubmitted(
        item.senderName,
      ),
      InboxType.settlementConfirmed => l10n.inboxSettlementConfirmed(
        item.senderName,
      ),
      InboxType.settlementDisputed => l10n.inboxSettlementDisputed(
        item.senderName,
      ),
      InboxType.tourClosed => l10n.inboxTourClosed(item.senderName),
      InboxType.tourReopened => l10n.inboxTourReopened(item.senderName),
      InboxType.roleChanged => l10n.inboxRoleChanged(item.senderName),
      InboxType.expenseAdded => l10n.inboxExpenseAdded(item.senderName),
      InboxType.expenseEdited => l10n.inboxExpenseEdited(item.senderName),
      InboxType.expenseDeleted => l10n.inboxExpenseDeleted(item.senderName),
      InboxType.planAdded => l10n.inboxPlanAdded(item.senderName),
      InboxType.planEdited => l10n.inboxPlanEdited(item.senderName),
      InboxType.tourDeletionSoon => l10n.inboxTourDeletionSoon,
      null => l10n.feedUnknown,
    };

/// Where tapping an inbox item leads.
String inboxTarget(InboxItem item) => switch (item.type) {
  InboxType.joinRequest => Routes.members(item.tourId),
  InboxType.joinRejected => Routes.join,
  InboxType.settlementSubmitted ||
  InboxType.settlementConfirmed ||
  InboxType.settlementDisputed => Routes.balances(item.tourId),
  InboxType.expenseAdded || InboxType.expenseEdited || InboxType.expenseDeleted
      when item.refId != null =>
    Routes.expense(item.tourId, item.refId!),
  InboxType.planAdded ||
  InboxType.planEdited => Routes.tour(item.tourId, tab: 1),
  _ => Routes.tour(item.tourId),
};

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  @override
  void initState() {
    super.initState();
    // Lazy, bounded cleanup of expired records when the inbox is opened.
    final uid = ref.read(currentUidProvider);
    if (uid != null) {
      ref.read(inboxRepositoryProvider).cleanupExpired(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inbox = ref.watch(inboxProvider);
    final uid = ref.watch(currentUidProvider);
    final now = ref.watch(clockProvider)();
    final repo = ref.read(inboxRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inboxTitle),
        actions: [
          if ((inbox.value?.items ?? const []).any((i) => !i.read))
            TextButton(
              onPressed: uid == null
                  ? null
                  : () => repo.markAllRead(uid, inbox.value!.items),
              child: Text(l10n.inboxMarkAllRead),
            ),
        ],
      ),
      body: AsyncValueView(
        value: inbox,
        onRetry: () => ref.invalidate(inboxProvider),
        data: (snap) {
          final prefs = ref.watch(preferencesProvider);
          final items = snap.items
              .where((i) => !i.isExpired(now) && inboxVisible(i, prefs))
              .toList();
          return Column(
            children: [
              InlineBanner(
                icon: Icons.info_outline,
                message: l10n.inboxExplainer,
              ),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.notifications_none,
                        title: l10n.inboxEmpty,
                      )
                    : ContentWidth(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final item = items[i];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: AlignmentDirectional.centerEnd,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.page,
                                ),
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                                child: const Icon(Icons.delete_outline),
                              ),
                              onDismissed: (_) => repo.delete(uid!, item.id),
                              child: ListTile(
                                leading: Icon(
                                  item.read
                                      ? Icons.notifications_none
                                      : Icons.notifications_active_outlined,
                                  color: item.read
                                      ? null
                                      : Theme.of(context).colorScheme.secondary,
                                ),
                                title: Text(
                                  describeInbox(l10n, item),
                                  style: item.read
                                      ? null
                                      : const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                                subtitle: Text(
                                  '${item.tourName} · '
                                  '${formatRelative(context, item.createdAt, now)}',
                                ),
                                onTap: () {
                                  if (!item.read && uid != null) {
                                    repo.markRead(uid, item.id);
                                  }
                                  context.push(inboxTarget(item));
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
