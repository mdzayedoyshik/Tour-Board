import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../../core/utils/dates.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/data/inbox_repository.dart';
import '../../tours/data/tour_repository.dart';
import '../../tours/domain/tour.dart';
import '../../tours/presentation/tour_status_ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tours = ref.watch(myToursProvider);
    final unread = ref.watch(unreadInboxCountProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.page,
        title: Row(
          children: [
            const AppLogo(size: 28),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.homeTitle),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.inboxTitle,
            onPressed: () => context.push(Routes.inbox),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: AsyncValueView(
        value: tours,
        onRetry: () => ref.invalidate(myToursProvider),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.luggage_outlined,
                title: l10n.homeEmptyTitle,
                message: l10n.homeEmptyBody,
                actions: [
                  PrimaryButton(
                    label: l10n.createTour,
                    icon: Icons.add,
                    onPressed: () => context.push(Routes.createTour),
                  ),
                  SecondaryButton(
                    label: l10n.joinTour,
                    icon: Icons.link,
                    onPressed: () => context.push(Routes.join),
                  ),
                ],
              )
            : _TourList(tours: list),
      ),
      bottomNavigationBar: tours.value?.isNotEmpty ?? false
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: l10n.joinTourShort,
                        icon: Icons.link,
                        onPressed: () => context.push(Routes.join),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: l10n.createTourShort,
                        icon: Icons.add,
                        onPressed: () => context.push(Routes.createTour),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _TourList extends ConsumerWidget {
  const _TourList({required this.tours});

  final List<TourSummary> tours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Active/upcoming first (soonest start), then closed, then archived.
    final open = tours.where((t) => t.tour.isOpen).toList()
      ..sort((a, b) => a.tour.startAt.compareTo(b.tour.startAt));
    final closed =
        tours.where((t) => t.tour.status == TourStatus.closed).toList()
          ..sort((a, b) => b.tour.endAt.compareTo(a.tour.endAt));
    final archived =
        tours.where((t) => t.tour.status == TourStatus.archived).toList()
          ..sort((a, b) => b.tour.endAt.compareTo(a.tour.endAt));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myToursProvider),
      child: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
            const _Greeting(),
            if (open.isNotEmpty) ...[
              SectionHeader(l10n.homeSectionCurrent),
              for (final t in open) _TourCard(summary: t),
            ],
            if (closed.isNotEmpty) ...[
              SectionHeader(l10n.homeSectionClosed),
              for (final t in closed) _TourCard(summary: t),
            ],
            if (archived.isNotEmpty)
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    l10n.homeSectionArchived(archived.length),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  children: [for (final t in archived) _TourCard(summary: t)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider).value;
    final name = profile?.displayName ?? '';
    final first = name.trim().split(RegExp(r'\s+')).first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  first.isEmpty
                      ? l10n.homeGreetingNoName
                      : l10n.homeGreeting(first),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.homeSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            MemberAvatar(
              name: name,
              photoUrl: profile?.photoUrl,
              size: AppSizes.avatarLg,
            ),
          ],
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.summary});

  final TourSummary summary;

  @override
  Widget build(BuildContext context) {
    final tour = summary.tour;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final count = summary.activeMemberCount;
    final now = DateTime.now().toUtc();
    final ended = hasEnded(tour, now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.lg,
      ),
      child: SurfaceCard(
        onTap: () => context.push(Routes.tour(tour.id)),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient cover with the trip's name and timing.
            Container(
              height: 112,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: TourPalette.gradientFor(tour.id),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Stack(
                children: [
                  Positioned(
                    right: -12,
                    bottom: -18,
                    child: Icon(
                      Icons.landscape_rounded,
                      size: 96,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(
                          tourTimingLabel(context, tour, now),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        tour.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      [
                        formatTripRange(context, tour.startAt, tour.endAt),
                        if (count != null) l10n.memberCount(count),
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TourStatusPill(tour: tour),
                ],
              ),
            ),
            if (ended)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_delete_outlined,
                      size: 16,
                      color: StatusColors.of(context).warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.tourDeletionShort(
                          formatTripDate(context, tourDeletionDate(tour)),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: StatusColors.of(context).warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
