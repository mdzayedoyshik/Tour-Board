import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../map/data/map_provider.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/permissions.dart';
import '../../tours/domain/tour.dart';
import '../data/plan_repository.dart';
import '../domain/plan_item.dart';

final _deviceZoneProvider = FutureProvider<String?>((ref) async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    return null;
  }
});

String planStatusLabel(AppLocalizations l10n, PlanStatus s) => switch (s) {
  PlanStatus.planned => l10n.planStatusPlanned,
  PlanStatus.completed => l10n.planStatusDone,
  PlanStatus.skipped => l10n.planStatusSkipped,
};

/// Groups items by day: every trip day, plus any day keys outside the trip
/// (e.g. after the dates were changed) so nothing disappears.
Map<String, List<PlanItem>> groupByDay(Tour tour, List<PlanItem> items) {
  final days = <String, List<PlanItem>>{
    for (final key in dayKeysBetween(tour.startAt, tour.endAt)) key: [],
  };
  for (final item in items) {
    days.putIfAbsent(item.dayKey, () => []).add(item);
  }
  final sortedKeys = days.keys.toList()..sort();
  return {for (final k in sortedKeys) k: sortPlanItems(days[k]!)};
}

class PlanTab extends ConsumerWidget {
  const PlanTab({required this.tour, super.key});

  final Tour tour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(planItemsProvider(tour.id));
    final permissions = ref.watch(permissionsProvider(tour.id));
    final deviceZone = ref.watch(_deviceZoneProvider).value;
    final canAdd = permissions?.canAddContent ?? false;

    return Scaffold(
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newPlan(tour.id)),
              icon: const Icon(Icons.add),
              label: Text(l10n.planAdd),
            )
          : null,
      body: AsyncValueView(
        value: items,
        onRetry: () => ref.invalidate(planItemsProvider(tour.id)),
        data: (snapshot) {
          final days = groupByDay(tour, snapshot.items);
          final tripStart = dateOnlyUtc(tour.startAt);
          return CustomScrollView(
            slivers: [
              if (snapshot.fromCache)
                SliverToBoxAdapter(
                  child: InlineBanner(
                    icon: Icons.cloud_off_outlined,
                    message: l10n.stateOfflineCached,
                  ),
                ),
              if (deviceZone != null && deviceZone != tour.timeZone)
                SliverToBoxAdapter(
                  child: InlineBanner(
                    icon: Icons.schedule,
                    message: l10n.planTimesInZone(
                      tour.timeZone.replaceAll('_', ' '),
                      TimeZones.offsetLabel(tour.timeZone, DateTime.now()),
                    ),
                  ),
                ),
              if (snapshot.items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.event_note_outlined,
                      title: l10n.planEmptyTitle,
                      message: l10n.planEmptyBody,
                    ),
                  ),
                ),
              for (final entry in days.entries) ...[
                SliverToBoxAdapter(
                  child: ContentWidth(
                    child: _DayHeader(
                      dayKey: entry.key,
                      dayNumber: () {
                        final d = parseDayKey(entry.key);
                        if (d == null) return null;
                        final n = d.difference(tripStart).inDays + 1;
                        return n >= 1 && !d.isAfter(dateOnlyUtc(tour.endAt))
                            ? n
                            : null;
                      }(),
                      onAdd: canAdd
                          ? () => context.push(
                              Routes.newPlan(tour.id, day: entry.key),
                            )
                          : null,
                    ),
                  ),
                ),
                if (entry.value.isEmpty)
                  SliverToBoxAdapter(
                    child: ContentWidth(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          0,
                          AppSpacing.page,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          l10n.planDayEmpty,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (context, i) => ContentWidth(
                      child: _PlanTile(
                        tour: tour,
                        item: entry.value[i],
                        dayItems: entry.value,
                        permissions: permissions,
                      ),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.dayKey, this.dayNumber, this.onAdd});

  final String dayKey;
  final int? dayNumber;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = dayNumber == null
        ? formatDayKey(context, dayKey)
        : l10n.planDayLabel(dayNumber!, formatDayKey(context, dayKey));
    return SectionHeader(
      label,
      trailing: onAdd == null
          ? null
          : IconButton(
              tooltip: l10n.planAddToDay,
              icon: const Icon(Icons.add),
              onPressed: onAdd,
            ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({
    required this.tour,
    required this.item,
    required this.dayItems,
    required this.permissions,
  });

  final Tour tour;
  final PlanItem item;
  final List<PlanItem> dayItems;
  final TourPermissions? permissions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final done = item.status != PlanStatus.planned;
    final time = [
      if (item.startTime != null) formatClock(context, item.startTime!),
      if (item.endTime != null) formatClock(context, item.endTime!),
    ].join(' – ');
    final subtitle = [
      if (item.placeName != null) item.placeName!,
      if (item.estimatedCostMinor != null)
        l10n.planEstimated(
          formatMoney(
            item.estimatedCostMinor!,
            item.currencyCode ?? tour.currencyCode,
            locale: context.localeTag,
          ),
        ),
      if (done) planStatusLabel(l10n, item.status),
      if (item.hasPendingWrites) l10n.statePendingSync,
    ].join(' · ');

    return ListTile(
      onTap: () => _showActions(context, ref),
      leading: SizedBox(
        width: 56,
        child: Text(
          time.isEmpty ? '—' : time.split(' – ').first,
          style: theme.textTheme.labelLarge?.copyWith(
            color: done ? muted : null,
          ),
        ),
      ),
      title: Row(
        children: [
          if (item.favorite)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: Icon(
                Icons.star,
                size: AppSizes.iconSm,
                color: theme.colorScheme.secondary,
                semanticLabel: l10n.planFavorite,
              ),
            ),
          Expanded(
            child: Text(
              item.title,
              style: TextStyle(
                decoration: done ? TextDecoration.lineThrough : null,
                color: done ? muted : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, style: TextStyle(color: muted)),
      trailing: item.hasCoordinates
          ? Icon(Icons.place_outlined, semanticLabel: l10n.planHasLocation)
          : null,
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final canEdit = permissions?.canEditContent(item.createdBy) ?? false;
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(planRepositoryProvider);
    final index = dayItems.indexOf(item);

    Future<void> run(Future<Object?> Function() action) async {
      Navigator.pop(context);
      try {
        await action();
      } catch (e) {
        if (context.mounted) {
          showAppSnack(context, errorMessage(context, e), error: true);
        }
      }
    }

    Future<void> move(int delta) => run(() {
      final reordered = [...dayItems];
      reordered.removeAt(index);
      reordered.insert(index + delta, item);
      return repo.move(
        tourId: tour.id,
        item: item,
        dayItemsInNewOrder: reordered,
        uid: uid!,
      );
    });

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: Text(
                  item.title,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              if (item.note != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.sm,
                    AppSpacing.page,
                    0,
                  ),
                  child: Text(item.note!),
                ),
              const SizedBox(height: AppSpacing.sm),
              if (item.hasCoordinates || item.placeName != null)
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: Text(l10n.planOpenInMaps),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final ok = await openInMaps(
                      latitude: item.latitude,
                      longitude: item.longitude,
                      name: item.placeName ?? item.title,
                    );
                    if (!ok && context.mounted) {
                      showAppSnack(context, l10n.planOpenMapsFailed);
                    }
                  },
                ),
              if (canEdit) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.commonEdit),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(Routes.editPlan(tour.id, item.id));
                  },
                ),
                for (final s in PlanStatus.values)
                  if (s != item.status)
                    ListTile(
                      leading: Icon(switch (s) {
                        PlanStatus.planned => Icons.radio_button_unchecked,
                        PlanStatus.completed => Icons.check_circle_outline,
                        PlanStatus.skipped => Icons.do_not_disturb_on_outlined,
                      }),
                      title: Text(l10n.planMarkAs(planStatusLabel(l10n, s))),
                      onTap: () =>
                          run(() => repo.setStatus(tour.id, item, s, uid!)),
                    ),
                ListTile(
                  leading: Icon(item.favorite ? Icons.star : Icons.star_border),
                  title: Text(
                    item.favorite ? l10n.planUnfavorite : l10n.planFavorite,
                  ),
                  onTap: () => run(
                    () => repo.setFavorite(tour.id, item, !item.favorite, uid!),
                  ),
                ),
                if (index > 0)
                  ListTile(
                    leading: const Icon(Icons.arrow_upward),
                    title: Text(l10n.planMoveUp),
                    onTap: () => move(-1),
                  ),
                if (index < dayItems.length - 1)
                  ListTile(
                    leading: const Icon(Icons.arrow_downward),
                    title: Text(l10n.planMoveDown),
                    onTap: () => move(1),
                  ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(sheetContext).colorScheme.error,
                  ),
                  title: Text(
                    l10n.commonDelete,
                    style: TextStyle(
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final ok = await confirmAction(
                      context,
                      title: l10n.planDeleteTitle,
                      confirmLabel: l10n.commonDelete,
                      destructive: true,
                    );
                    if (!ok) return;
                    try {
                      await repo.delete(tour.id, item.id);
                    } catch (e) {
                      if (context.mounted) {
                        showAppSnack(
                          context,
                          errorMessage(context, e),
                          error: true,
                        );
                      }
                    }
                  },
                ),
              ],
              if (!canEdit && !(item.hasCoordinates || item.placeName != null))
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: SecondaryButton(
                    label: l10n.commonClose,
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
