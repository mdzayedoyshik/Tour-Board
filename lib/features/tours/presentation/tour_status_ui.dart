import 'package:flutter/material.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/common.dart';
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
