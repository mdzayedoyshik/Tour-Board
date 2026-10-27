import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/member.dart';
import '../data/feed_repository.dart';
import '../domain/feed_event.dart';

IconData feedIcon(FeedEventType? type) => switch (type) {
  FeedEventType.memberJoined => Icons.person_add_alt,
  FeedEventType.memberRemoved ||
  FeedEventType.memberLeft => Icons.person_remove_outlined,
  FeedEventType.roleChanged ||
  FeedEventType.hostTransferred => Icons.admin_panel_settings_outlined,
  FeedEventType.expenseAdded ||
  FeedEventType.expenseEdited ||
  FeedEventType.expenseDeleted => Icons.receipt_long_outlined,
  FeedEventType.planAdded || FeedEventType.planEdited => Icons.event_note,
  FeedEventType.settlementSubmitted ||
  FeedEventType.settlementConfirmed ||
  FeedEventType.settlementDisputed ||
  FeedEventType.settlementCancelled => Icons.payments_outlined,
  FeedEventType.tourClosed ||
  FeedEventType.tourReopened ||
  FeedEventType.tourArchived ||
  FeedEventType.tourUpdated => Icons.flag_outlined,
  null => Icons.info_outline,
};

String describeFeedEvent(
  BuildContext context,
  FeedEvent e,
  Map<String, Member> members,
  String? viewerUid,
) {
  final l10n = context.l10n;
  final actor = memberName(context, members, e.actorUid, viewerUid: viewerUid);
  final subject = e.subjectUid == null
      ? (e.label ?? '')
      : memberName(context, members, e.subjectUid!, viewerUid: viewerUid);
  final label = e.label ?? '';
  return switch (e.type) {
    FeedEventType.memberJoined => l10n.feedMemberJoined(actor, subject),
    FeedEventType.memberRemoved => l10n.feedMemberRemoved(actor, subject),
    FeedEventType.memberLeft => l10n.feedMemberLeft(actor),
    FeedEventType.roleChanged => l10n.feedRoleChanged(actor, subject),
    FeedEventType.hostTransferred => l10n.feedHostTransferred(actor, subject),
    FeedEventType.expenseAdded => l10n.feedExpenseAdded(actor, label),
    FeedEventType.expenseEdited => l10n.feedExpenseEdited(actor, label),
    FeedEventType.expenseDeleted => l10n.feedExpenseDeleted(actor, label),
    FeedEventType.planAdded => l10n.feedPlanAdded(actor, label),
    FeedEventType.planEdited => l10n.feedPlanEdited(actor, label),
    FeedEventType.settlementSubmitted => l10n.feedSettlementSubmitted(actor),
    FeedEventType.settlementConfirmed => l10n.feedSettlementConfirmed(actor),
    FeedEventType.settlementDisputed => l10n.feedSettlementDisputed(actor),
    FeedEventType.settlementCancelled => l10n.feedSettlementCancelled(actor),
    FeedEventType.tourClosed => l10n.feedTourClosed(actor),
    FeedEventType.tourReopened => l10n.feedTourReopened(actor),
    FeedEventType.tourArchived => l10n.feedTourArchived(actor),
    FeedEventType.tourUpdated => l10n.feedTourUpdated(actor),
    null => l10n.feedUnknown,
  };
}

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({required this.tourId, super.key});

  final String tourId;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final List<FeedEvent> _older = [];
  bool _loading = false;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    ref.read(feedSeenStoreProvider).markSeen(widget.tourId);
  }

  Future<void> _loadMore(DateTime before) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final page = await ref
          .read(feedRepositoryProvider)
          .fetchOlder(widget.tourId, before);
      setState(() {
        _older.addAll(page);
        _exhausted = page.length < FeedEvent.pageSize;
      });
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feed = ref.watch(recentFeedProvider(widget.tourId));
    final members = ref.watch(memberMapProvider(widget.tourId));
    final uid = ref.watch(currentUidProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.activityTitle)),
      body: AsyncValueView(
        value: feed,
        onRetry: () => ref.invalidate(recentFeedProvider(widget.tourId)),
        data: (snap) {
          final ids = snap.items.map((e) => e.id).toSet();
          final all = [
            ...snap.items,
            ..._older.where((e) => !ids.contains(e.id)),
          ];
          if (all.isEmpty) {
            return EmptyState(icon: Icons.history, title: l10n.activityEmpty);
          }
          return ContentWidth(
            child: ListView.builder(
              itemCount: all.length + 1,
              itemBuilder: (context, i) {
                if (i == all.length) {
                  if (!snap.hasMore || _exhausted) {
                    return const SizedBox(height: AppSpacing.xl);
                  }
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: SecondaryButton(
                      label: l10n.commonLoadMore,
                      loading: _loading,
                      onPressed: () => _loadMore(all.last.createdAt),
                    ),
                  );
                }
                final e = all[i];
                return ListTile(
                  leading: _ActorAvatar(
                    members: members,
                    uid: e.actorUid,
                    icon: feedIcon(e.type),
                  ),
                  title: Text(describeFeedEvent(context, e, members, uid)),
                  subtitle: Text(formatRelative(context, e.createdAt, now)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// The actor's photo with the event type as a small badge.
class _ActorAvatar extends StatelessWidget {
  const _ActorAvatar({
    required this.members,
    required this.uid,
    required this.icon,
  });

  final Map<String, Member> members;
  final String uid;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: AppSizes.avatarMd + 4,
      child: Stack(
        children: [
          MemberUidAvatar(members: members, uid: uid, size: AppSizes.avatarMd),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Icon(icon, size: 12, color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
