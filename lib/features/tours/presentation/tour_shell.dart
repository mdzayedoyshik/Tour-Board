import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/states.dart';
import '../../expenses/presentation/expenses_tab.dart';
import '../../itinerary/presentation/plan_tab.dart';
import '../../map/presentation/map_tab.dart';
import '../../membership/data/membership_repository.dart';
import '../../notifications/presentation/reminder_sync.dart';
import '../data/tour_repository.dart';
import 'more_tab.dart';
import 'tour_status_ui.dart';

/// Tour workspace with four destinations. Only the selected tab is built,
/// so leaving the Map tab cancels its location listener.
class TourShell extends ConsumerStatefulWidget {
  const TourShell({required this.tourId, this.initialTab = 0, super.key});

  final String tourId;
  final int initialTab;

  @override
  ConsumerState<TourShell> createState() => _TourShellState();
}

class _TourShellState extends ConsumerState<TourShell> {
  late int _tab = widget.initialTab.clamp(0, 3);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tourAsync = ref.watch(tourProvider(widget.tourId));
    final meAsync = ref.watch(myMemberProvider(widget.tourId));

    void back() => context.canPop() ? context.pop() : context.go(Routes.home);

    // Access checks: a removed member's tour read fails with
    // permission-denied, while their own member record is still readable.
    final me = meAsync.value;
    if ((meAsync.hasValue && (me == null || !me.isActive)) ||
        (tourAsync.hasError &&
            classifyError(tourAsync.error!) == AppErrorKind.permissionDenied)) {
      return Scaffold(
        appBar: AppBar(),
        body: AccessRevokedView(onBack: back),
      );
    }
    if (tourAsync.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          error: tourAsync.error!,
          onRetry: () => ref.invalidate(tourProvider(widget.tourId)),
        ),
      );
    }
    final tour = tourAsync.value;
    if (!tourAsync.hasValue || !meAsync.hasValue) {
      return const Scaffold(body: LoadingView());
    }
    if (tour == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorState(error: AppException(AppErrorKind.notFound)),
      );
    }

    final members = ref.watch(activeMembersProvider(widget.tourId));
    final pending = ref.watch(pendingRequestsProvider(widget.tourId)).value;
    final pendingCount = pending?.length ?? 0;

    final destinations = [
      (Icons.receipt_long_outlined, Icons.receipt_long, l10n.tabExpenses),
      (Icons.event_note_outlined, Icons.event_note, l10n.tabPlan),
      (Icons.map_outlined, Icons.map, l10n.tabMap),
      (Icons.more_horiz, Icons.more_horiz, l10n.tabMore),
    ];

    final body = switch (_tab) {
      0 => ExpensesTab(tour: tour),
      1 => PlanTab(tour: tour),
      2 => MapTab(tour: tour),
      _ => MoreTab(tour: tour),
    };

    final wide = MediaQuery.sizeOf(context).width >= 840;

    Widget moreIcon(IconData icon) => Badge(
      isLabelVisible: pendingCount > 0,
      label: Text('$pendingCount'),
      child: Icon(icon),
    );

    return ReminderSync(
      tour: tour,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: back),
          titleSpacing: 0,
          title: Semantics(
            header: true,
            child: Text(tour.name, overflow: TextOverflow.ellipsis),
          ),
          actions: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: () => context.push(Routes.members(tour.id)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AvatarStack(
                  semanticLabel: l10n.memberCount(members.length),
                  people: [
                    for (final m in members)
                      (name: m.displayName, photoUrl: m.photoUrl),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: Column(
          children: [
            TourDeletionBanner(tour: tour),
            if (!tour.isOpen)
              InlineBanner(
                icon: Icons.lock_outline,
                message: l10n.tourClosedBanner,
              ),
            Expanded(
              child: wide
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _tab,
                          labelType: NavigationRailLabelType.all,
                          onDestinationSelected: (i) =>
                              setState(() => _tab = i),
                          destinations: [
                            for (var i = 0; i < destinations.length; i++)
                              NavigationRailDestination(
                                icon: i == 3
                                    ? moreIcon(destinations[i].$1)
                                    : Icon(destinations[i].$1),
                                selectedIcon: Icon(destinations[i].$2),
                                label: Text(destinations[i].$3),
                              ),
                          ],
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: body),
                      ],
                    )
                  : body,
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  for (var i = 0; i < destinations.length; i++)
                    NavigationDestination(
                      icon: i == 3
                          ? moreIcon(destinations[i].$1)
                          : Icon(destinations[i].$1),
                      selectedIcon: Icon(destinations[i].$2),
                      label: destinations[i].$3,
                    ),
                ],
              ),
      ),
    );
  }
}
