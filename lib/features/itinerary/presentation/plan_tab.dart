import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/permissions.dart';
import '../../tours/domain/tour.dart';
import '../data/plan_repository.dart';
import '../domain/plan_item.dart';
import 'plan_item_actions.dart';

export 'plan_item_actions.dart' show planStatusLabel;

final _deviceZoneProvider = FutureProvider<String?>((ref) async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    return null;
  }
});

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

/// 1-based day number within the trip, or null for days outside it.
int? tripDayNumber(Tour tour, String dayKey) {
  final d = parseDayKey(dayKey);
  if (d == null) return null;
  final start = dateOnlyUtc(tour.startAt);
  if (d.isBefore(start) || d.isAfter(dateOnlyUtc(tour.endAt))) return null;
  return d.difference(start).inDays + 1;
}

/// Day-by-day itinerary: a day selector on top and a timeline of stops.
class PlanTab extends ConsumerStatefulWidget {
  const PlanTab({required this.tour, super.key});

  final Tour tour;

  @override
  ConsumerState<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends ConsumerState<PlanTab> {
  String? _selected;

  String _defaultDay(List<String> days) {
    final today = dayKeyOf(
      TimeZones.toZone(DateTime.now().toUtc(), widget.tour.timeZone),
    );
    return days.contains(today) ? today : days.first;
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final l10n = context.l10n;
    final items = ref.watch(planItemsProvider(tour.id));
    final permissions = ref.watch(permissionsProvider(tour.id));
    final deviceZone = ref.watch(_deviceZoneProvider).value;
    final canAdd = permissions?.canAddContent ?? false;

    return Scaffold(
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push(Routes.newPlan(tour.id, day: _selected)),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(l10n.planAdd),
            )
          : null,
      body: AsyncValueView(
        value: items,
        onRetry: () => ref.invalidate(planItemsProvider(tour.id)),
        data: (snapshot) {
          final days = groupByDay(tour, snapshot.items);
          final keys = days.keys.toList();
          final selected = keys.contains(_selected)
              ? _selected!
              : _defaultDay(keys);
          final dayItems = days[selected] ?? const <PlanItem>[];
          return Column(
            children: [
              if (snapshot.fromCache)
                InlineBanner(
                  icon: Icons.cloud_off_outlined,
                  message: l10n.stateOfflineCached,
                ),
              if (deviceZone != null && deviceZone != tour.timeZone)
                InlineBanner(
                  icon: Icons.schedule,
                  message: l10n.planTimesInZone(
                    tour.timeZone.replaceAll('_', ' '),
                    TimeZones.offsetLabel(tour.timeZone, DateTime.now()),
                  ),
                ),
              _DaySelector(
                tour: tour,
                days: days,
                selected: selected,
                onSelect: (k) => setState(() => _selected = k),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _DayTimeline(
                    key: ValueKey(selected),
                    tour: tour,
                    dayKey: selected,
                    items: dayItems,
                    permissions: permissions,
                    canAdd: canAdd,
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

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.tour,
    required this.days,
    required this.selected,
    required this.onSelect,
  });

  final Tour tour;
  final Map<String, List<PlanItem>> days;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final locale = context.localeTag;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.sm,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final key = days.keys.elementAt(i);
          final date = parseDayKey(key);
          final isSelected = key == selected;
          final number = tripDayNumber(tour, key);
          final count = days[key]!.length;
          final fg = isSelected ? scheme.onPrimary : scheme.onSurface;
          return Semantics(
            selected: isSelected,
            button: true,
            label: '${formatDayKey(context, key)}, ${l10n.planStops(count)}',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: () => onSelect(key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 64,
                decoration: BoxDecoration(
                  color: isSelected
                      ? scheme.primary
                      : theme.brightness == Brightness.dark
                      ? scheme.surfaceContainerHigh
                      : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: isSelected ? scheme.primary : scheme.outlineVariant,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      number == null
                          ? (date == null
                                ? key
                                : DateFormat.MMM(locale).format(date))
                          : l10n.planDayShort(number),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: fg.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      date == null ? '' : DateFormat.d(locale).format(date),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      date == null ? '' : DateFormat.E(locale).format(date),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: count == 0
                            ? Colors.transparent
                            : isSelected
                            ? scheme.onPrimary
                            : scheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayTimeline extends ConsumerWidget {
  const _DayTimeline({
    required this.tour,
    required this.dayKey,
    required this.items,
    required this.permissions,
    required this.canAdd,
    super.key,
  });

  final Tour tour;
  final String dayKey;
  final List<PlanItem> items;
  final TourPermissions? permissions;
  final bool canAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final number = tripDayNumber(tour, dayKey);
    // Estimated total per currency for the day.
    final costs = <String, int>{};
    for (final i in items) {
      if (i.estimatedCostMinor != null && i.status != PlanStatus.skipped) {
        final c = i.currencyCode ?? tour.currencyCode;
        costs[c] = (costs[c] ?? 0) + i.estimatedCostMinor!;
      }
    }
    final summary = [
      l10n.planStops(items.length),
      for (final e in costs.entries)
        l10n.planEstimated(
          formatMoney(e.value, e.key, locale: context.localeTag),
        ),
    ].join('  ·  ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number == null
                    ? formatDayKey(context, dayKey)
                    : l10n.planDayLabel(number, formatDayKey(context, dayKey)),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.page,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              children: [
                const IconBadge(
                  icon: Icons.wb_sunny_outlined,
                  color: AppColors.sunset,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.planDayEmptyTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.planDayEmptyBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (canAdd) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SecondaryButton(
                    label: l10n.planAddToDay,
                    icon: Icons.add,
                    expand: false,
                    onPressed: () =>
                        context.push(Routes.newPlan(tour.id, day: dayKey)),
                  ),
                ],
              ],
            ),
          )
        else
          for (var i = 0; i < items.length; i++)
            ContentWidth(
              child: _TimelineEntry(
                item: items[i],
                tour: tour,
                isFirst: i == 0,
                isLast: i == items.length - 1,
                onTap: () => showPlanItemActions(
                  context,
                  ref,
                  tour: tour,
                  item: items[i],
                  dayItems: items,
                  permissions: permissions,
                ),
              ),
            ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.item,
    required this.tour,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final PlanItem item;
  final Tour tour;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    final l10n = context.l10n;
    final done = item.status != PlanStatus.planned;
    final dotColor = switch (item.status) {
      PlanStatus.planned => scheme.primary,
      PlanStatus.completed => status.success,
      PlanStatus.skipped => status.muted,
    };
    final lineColor = scheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time column.
          SizedBox(
            width: 76,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.page, top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.startTime == null
                        ? l10n.planAnyTime
                        : formatClock(context, item.startTime!),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: done ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                  ),
                  if (item.endTime != null)
                    Text(
                      formatClock(context, item.endTime!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Rail: line + status dot.
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : lineColor,
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? dotColor : scheme.surface,
                    border: Border.all(color: dotColor, width: 3),
                  ),
                  child: item.status == PlanStatus.completed
                      ? const Icon(Icons.check, size: 8, color: Colors.white)
                      : null,
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          // Card.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: SurfaceCard(
                onTap: onTap,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Opacity(
                  opacity: item.status == PlanStatus.skipped ? 0.6 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: item.status == PlanStatus.skipped
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (item.favorite)
                            Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: scheme.secondary,
                              semanticLabel: l10n.planFavorite,
                            ),
                        ],
                      ),
                      if (item.placeName != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              item.hasCoordinates
                                  ? Icons.place
                                  : Icons.place_outlined,
                              size: 16,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                item.placeName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.note != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (item.estimatedCostMinor != null ||
                          item.status != PlanStatus.planned ||
                          item.hasPendingWrites) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (item.estimatedCostMinor != null)
                              StatusPill(
                                label: formatMoney(
                                  item.estimatedCostMinor!,
                                  item.currencyCode ?? tour.currencyCode,
                                  locale: context.localeTag,
                                ),
                                icon: Icons.payments_outlined,
                                color: scheme.tertiary,
                              ),
                            if (item.status != PlanStatus.planned)
                              StatusPill(
                                label: planStatusLabel(l10n, item.status),
                                color: dotColor,
                              ),
                            if (item.hasPendingWrites)
                              StatusPill(label: l10n.statePendingSync),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
