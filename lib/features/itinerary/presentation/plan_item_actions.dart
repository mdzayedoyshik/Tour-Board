import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../map/data/place_service.dart';
import '../../membership/domain/permissions.dart';
import '../../tours/domain/tour.dart';
import '../data/plan_repository.dart';
import '../domain/plan_item.dart';

String planStatusLabel(AppLocalizations l10n, PlanStatus s) => switch (s) {
  PlanStatus.planned => l10n.planStatusPlanned,
  PlanStatus.completed => l10n.planStatusDone,
  PlanStatus.skipped => l10n.planStatusSkipped,
};

/// Details + actions for one stop, as a bottom sheet: directions, edit,
/// status, pin, reorder and delete (per permissions).
Future<void> showPlanItemActions(
  BuildContext context,
  WidgetRef ref, {
  required Tour tour,
  required PlanItem item,
  required List<PlanItem> dayItems,
  required TourPermissions? permissions,
}) async {
  final l10n = context.l10n;
  final canEdit = permissions?.canEditContent(item.createdBy) ?? false;
  final uid = ref.read(currentUidProvider);
  final repo = ref.read(planRepositoryProvider);
  final index = dayItems.indexWhere((i) => i.id == item.id);
  final hasPlace = item.hasCoordinates || item.placeName != null;

  Future<void> run(
    BuildContext sheet,
    Future<Object?> Function() action,
  ) async {
    Navigator.pop(sheet);
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        showAppSnack(context, errorMessage(context, e), error: true);
      }
    }
  }

  Future<void> move(BuildContext sheet, int delta) => run(sheet, () {
    final reordered = [...dayItems]..removeAt(index);
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
    isScrollControlled: true,
    builder: (sheet) {
      final theme = Theme.of(sheet);
      final scheme = theme.colorScheme;
      final time = [
        if (item.startTime != null) formatClock(sheet, item.startTime!),
        if (item.endTime != null) formatClock(sheet, item.endTime!),
      ].join(' – ');
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(
                    label: formatDayKey(sheet, item.dayKey),
                    icon: Icons.today_outlined,
                  ),
                  if (time.isNotEmpty)
                    StatusPill(label: time, icon: Icons.schedule),
                  if (item.status != PlanStatus.planned)
                    StatusPill(
                      label: planStatusLabel(l10n, item.status),
                      color: item.status == PlanStatus.completed
                          ? StatusColors.of(sheet).success
                          : StatusColors.of(sheet).muted,
                    ),
                  if (item.estimatedCostMinor != null)
                    StatusPill(
                      label: l10n.planEstimated(
                        formatMoney(
                          item.estimatedCostMinor!,
                          item.currencyCode ?? tour.currencyCode,
                          locale: sheet.localeTag,
                        ),
                      ),
                      icon: Icons.payments_outlined,
                    ),
                ],
              ),
              if (hasPlace) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_outlined, color: scheme.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        [
                          ?item.placeName,
                          ?item.address,
                        ].where((e) => e.isNotEmpty).toSet().join('\n'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              if (item.note != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.note!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (hasPlace)
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.directions),
                        label: Text(l10n.planDirections),
                        onPressed: () async {
                          Navigator.pop(sheet);
                          final ok = await openInMaps(
                            latitude: item.latitude,
                            longitude: item.longitude,
                            name: item.placeName ?? item.title,
                            placeId: item.placeId,
                          );
                          if (!ok && context.mounted) {
                            showAppSnack(context, l10n.planOpenMapsFailed);
                          }
                        },
                      ),
                    ),
                  if (hasPlace && canEdit) const SizedBox(width: AppSpacing.sm),
                  if (canEdit)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.commonEdit),
                        onPressed: () {
                          Navigator.pop(sheet);
                          context.push(Routes.editPlan(tour.id, item.id));
                        },
                      ),
                    ),
                ],
              ),
              if (canEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final s in PlanStatus.values)
                  if (s != item.status)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(switch (s) {
                        PlanStatus.planned => Icons.radio_button_unchecked,
                        PlanStatus.completed => Icons.check_circle_outline,
                        PlanStatus.skipped => Icons.do_not_disturb_on_outlined,
                      }),
                      title: Text(l10n.planMarkAs(planStatusLabel(l10n, s))),
                      onTap: () => run(
                        sheet,
                        () => repo.setStatus(tour.id, item, s, uid!),
                      ),
                    ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.favorite ? Icons.star : Icons.star_border),
                  title: Text(
                    item.favorite ? l10n.planUnfavorite : l10n.planFavorite,
                  ),
                  onTap: () => run(
                    sheet,
                    () => repo.setFavorite(tour.id, item, !item.favorite, uid!),
                  ),
                ),
                if (index > 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.arrow_upward),
                    title: Text(l10n.planMoveUp),
                    onTap: () => move(sheet, -1),
                  ),
                if (index >= 0 && index < dayItems.length - 1)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.arrow_downward),
                    title: Text(l10n.planMoveDown),
                    onTap: () => move(sheet, 1),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline, color: scheme.error),
                  title: Text(
                    l10n.commonDelete,
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: () async {
                    Navigator.pop(sheet);
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
            ],
          ),
        ),
      );
    },
  );
}
