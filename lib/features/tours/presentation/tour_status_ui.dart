import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../domain/tour.dart';

String tourStatusLabel(AppLocalizations l10n, TourStatus status) =>
    switch (status) {
      TourStatus.upcoming => l10n.statusUpcoming,
      TourStatus.active => l10n.statusActive,
      TourStatus.closed => l10n.statusClosed,
      TourStatus.archived => l10n.statusArchived,
    };

/// Status pill using the date-derived status for open tours.
class TourStatusPill extends StatelessWidget {
  const TourStatusPill({required this.tour, super.key});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = effectiveStatus(tour, DateTime.now().toUtc());
    final colors = StatusColors.of(context);
    final ended = tour.isOpen && hasEnded(tour, DateTime.now().toUtc());
    final (label, color, icon) = switch (status) {
      _ when ended => (l10n.statusEnded, colors.warning, Icons.flag_outlined),
      TourStatus.active => (l10n.statusActive, colors.success, Icons.circle),
      TourStatus.upcoming => (
        l10n.statusUpcoming,
        Theme.of(context).colorScheme.secondary,
        Icons.schedule,
      ),
      TourStatus.closed => (
        l10n.statusClosed,
        colors.muted,
        Icons.lock_outline,
      ),
      TourStatus.archived => (
        l10n.statusArchived,
        colors.muted,
        Icons.inventory_2_outlined,
      ),
    };
    return StatusPill(label: label, color: color, icon: icon);
  }
}

/// Tours are deleted by the server 30 days after their end date
/// (backend retention policy). Mirrors `retention.tourDays` on the server.
const tourRetentionDays = 30;

DateTime tourDeletionDate(Tour tour) =>
    dateOnlyUtc(tour.endAt).add(const Duration(days: tourRetentionDays + 1));

/// Short, human trip timing: "Starts in 5 days", "Day 2 of 4", "Ended".
String tourTimingLabel(BuildContext context, Tour tour, DateTime nowUtc) {
  final l10n = context.l10n;
  final today = dateOnlyUtc(TimeZones.toZone(nowUtc, tour.timeZone));
  final start = dateOnlyUtc(tour.startAt);
  final end = dateOnlyUtc(tour.endAt);
  final total = end.difference(start).inDays + 1;
  if (today.isBefore(start)) {
    return l10n.tourStartsIn(start.difference(today).inDays);
  }
  if (!today.isAfter(end)) {
    return l10n.tourDayOf(today.difference(start).inDays + 1, total);
  }
  return l10n.statusEnded;
}

/// Warns members once the trip has ended that the server will delete it.
class TourDeletionBanner extends StatelessWidget {
  const TourDeletionBanner({required this.tour, super.key});

  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    if (!hasEnded(tour, now)) return const SizedBox.shrink();
    final date = formatTripDate(context, tourDeletionDate(tour));
    return InlineBanner(
      icon: Icons.auto_delete_outlined,
      color: StatusColors.of(context).warning,
      message: context.l10n.tourDeletionNotice(date),
    );
  }
}
