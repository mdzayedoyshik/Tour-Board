import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../itinerary/data/plan_repository.dart';
import '../../settings/data/preferences.dart';
import '../../tours/domain/tour.dart';
import '../data/reminder_service.dart';

/// Keeps this device's itinerary reminders in step with the plan while a
/// tour is open. Does nothing (and adds no listener) unless the user opted
/// in to local reminders.
class ReminderSync extends ConsumerWidget {
  const ReminderSync({required this.tour, required this.child, super.key});

  final Tour tour;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    if (prefs.localReminders && tour.isOpen) {
      ref.listen(planItemsProvider(tour.id), (_, next) {
        final items = next.value;
        if (items == null || items.fromCache) return;
        final l10n = context.l10n;
        ref
            .read(reminderServiceProvider)
            .syncTour(
              tourId: tour.id,
              tourName: tour.name,
              items: items.items,
              enabled: true,
              leadMinutes: prefs.reminderLeadMinutes,
              bodyFor: (item) => [
                if (item.startTime != null)
                  formatClock(context, item.startTime!),
                if (item.placeName != null) item.placeName!,
                l10n.reminderLocalNote,
              ].join(' · '),
            );
      });
    }
    return child;
  }
}
