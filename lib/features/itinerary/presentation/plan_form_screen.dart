import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/pickers.dart';
import '../../../core/widgets/states.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../map/data/place_service.dart';
import '../../map/presentation/place_picker_screen.dart';
import '../../tours/data/tour_repository.dart';
import '../../tours/domain/tour.dart';
import '../data/plan_repository.dart';
import '../domain/plan_item.dart';
import 'plan_tab.dart';

class PlanFormScreen extends ConsumerWidget {
  const PlanFormScreen({
    required this.tourId,
    this.planId,
    this.initialDay,
    super.key,
  });

  final String tourId;
  final String? planId;
  final String? initialDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tour = ref.watch(tourProvider(tourId)).value;
    final items = ref.watch(planItemsProvider(tourId)).value;
    if (tour == null || items == null) {
      return const Scaffold(body: LoadingView());
    }
    PlanItem? existing;
    if (planId != null) {
      existing = items.items.where((i) => i.id == planId).firstOrNull;
      if (existing == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const ErrorState(error: AppException(AppErrorKind.notFound)),
        );
      }
    }
    return _PlanForm(
      tour: tour,
      items: items.items,
      existing: existing,
      initialDay: initialDay,
    );
  }
}

class _PlanForm extends ConsumerStatefulWidget {
  const _PlanForm({
    required this.tour,
    required this.items,
    this.existing,
    this.initialDay,
  });

  final Tour tour;
  final List<PlanItem> items;
  final PlanItem? existing;
  final String? initialDay;

  @override
  ConsumerState<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<_PlanForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late String _dayKey;
  String? _start;
  String? _end;
  PickedPlace? _place;
  int? _cost;
  late String _costCurrency;
  late bool _favorite;
  late PlanStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final days = dayKeysBetween(widget.tour.startAt, widget.tour.endAt);
    _title = TextEditingController(text: e?.title);
    _note = TextEditingController(text: e?.note);
    _dayKey = e?.dayKey ?? widget.initialDay ?? _defaultDay(days);
    _start = e?.startTime;
    _end = e?.endTime;
    if (e != null && e.hasCoordinates) {
      _place = PickedPlace(
        name: e.placeName ?? e.title,
        address: e.address,
        latitude: e.latitude!,
        longitude: e.longitude!,
        placeId: e.placeId,
      );
    }
    _cost = e?.estimatedCostMinor;
    _costCurrency = e?.currencyCode ?? widget.tour.currencyCode;
    _favorite = e?.favorite ?? false;
    _status = e?.status ?? PlanStatus.planned;
  }

  String _defaultDay(List<String> days) {
    final today = dayKeyOf(
      TimeZones.toZone(DateTime.now().toUtc(), widget.tour.timeZone),
    );
    return days.contains(today) ? today : days.first;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Centre the picker near the tour's other stops.
  LatLng? get _nearby {
    final withCoords = widget.items.where((i) => i.hasCoordinates).toList();
    if (withCoords.isEmpty) return null;
    final sameDay = withCoords.where((i) => i.dayKey == _dayKey);
    final ref = sameDay.isNotEmpty ? sameDay.last : withCoords.last;
    return LatLng(ref.latitude!, ref.longitude!);
  }

  Future<void> _choosePlace() async {
    final picked = await pickPlace(context, initial: _place, near: _nearby);
    if (picked == null) return;
    setState(() {
      _place = picked;
      if (_title.text.trim().isEmpty) _title.text = picked.name;
    });
  }

  Future<void> _pickTime(bool start) async {
    final current = parseTimeOfDay(start ? _start : _end);
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    setState(() {
      final value = formatTimeOfDay(picked.hour, picked.minute);
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final uid = ref.read(currentUidProvider)!;
    final l10n = context.l10n;
    final place = _place;
    final draft = PlanDraft(
      title: _title.text,
      dayKey: _dayKey,
      startTime: _start,
      endTime: _end,
      // Keep a legacy name-only place (no coordinates) unless replaced.
      placeName:
          place?.name ??
          (widget.existing?.hasCoordinates == false
              ? widget.existing?.placeName
              : null),
      address: place?.address,
      placeId: place?.placeId,
      latitude: place?.latitude,
      longitude: place?.longitude,
      note: _note.text,
      estimatedCostMinor: _cost,
      currencyCode: _cost == null ? null : _costCurrency,
      status: _status,
      favorite: _favorite,
    );
    setState(() => _saving = true);
    final repo = ref.read(planRepositoryProvider);
    try {
      final WriteOutcome outcome;
      final existing = widget.existing;
      if (existing == null) {
        final dayItems = sortPlanItems(
          widget.items.where((i) => i.dayKey == _dayKey),
        );
        outcome = await repo.add(
          tourId: widget.tour.id,
          timeZone: widget.tour.timeZone,
          draft: draft,
          sortOrder: sortKeyBetween(
            dayItems.isEmpty ? null : dayItems.last.sortOrder,
            null,
          )!,
          uid: uid,
        );
      } else {
        outcome = await repo.update(
          tourId: widget.tour.id,
          timeZone: widget.tour.timeZone,
          item: existing,
          draft: draft,
          uid: uid,
        );
      }
      if (!mounted) return;
      showAppSnack(
        context,
        outcome == WriteOutcome.pendingSync
            ? l10n.stateSavedOffline
            : l10n.planSaved,
      );
      context.pop();
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final days = {
      ...dayKeysBetween(widget.tour.startAt, widget.tour.endAt),
      _dayKey,
    }.toList()..sort();
    final endBeforeStart =
        _start != null &&
        _end != null &&
        parseTimeOfDay(_end)! < parseTimeOfDay(_start)!;
    final valid = _title.text.trim().isNotEmpty && !endBeforeStart;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? l10n.planAddTitle : l10n.planEditTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              _PlaceField(
                place: _place,
                onTap: _choosePlace,
                onClear: () {
                  setState(() => _place = null);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _title,
                maxLength: PlanItem.maxTitleLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.planTitleLabel,
                  hintText: l10n.planTitleHint,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.planTitleRequired : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              PickerField(
                label: l10n.planDay,
                value: () {
                  final n = tripDayNumber(widget.tour, _dayKey);
                  final date = formatDayKey(context, _dayKey);
                  return n == null ? date : l10n.planDayLabel(n, date);
                }(),
                icon: Icons.today_outlined,
                onTap: () async {
                  final d = await pickFromList<String>(
                    context,
                    title: l10n.planDay,
                    items: days,
                    label: (k) {
                      final n = tripDayNumber(widget.tour, k);
                      final date = formatDayKey(context, k);
                      return n == null ? date : l10n.planDayLabel(n, date);
                    },
                    selected: _dayKey,
                  );
                  if (d != null) setState(() => _dayKey = d);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: PickerField(
                      label: l10n.planStart,
                      value: _start == null
                          ? null
                          : formatClock(context, _start!),
                      icon: Icons.schedule,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PickerField(
                      label: l10n.planEnd,
                      value: _end == null ? null : formatClock(context, _end!),
                      icon: Icons.schedule,
                      errorText: endBeforeStart
                          ? l10n.planEndBeforeStart
                          : null,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              if (_start != null || _end != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _start = null;
                      _end = null;
                    }),
                    child: Text(l10n.planClearTimes),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.planTimeZoneNote(
                    widget.tour.timeZone.replaceAll('_', ' '),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AmountField(
                      key: ValueKey('cost-$_costCurrency'),
                      currency: currencyOrDefault(_costCurrency),
                      initialMinor: _cost,
                      optional: true,
                      label: l10n.planEstimatedCost,
                      onChanged: (v) => setState(() => _cost = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 104,
                    child: PickerField(
                      label: l10n.currencyLabel,
                      value: _costCurrency,
                      onTap: () async {
                        final c = await pickCurrency(context, _costCurrency);
                        if (c != null && c != _costCurrency) {
                          setState(() {
                            _costCurrency = c;
                            _cost = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                maxLength: PlanItem.maxNoteLength,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(labelText: l10n.expenseNote),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  _favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _favorite ? theme.colorScheme.secondary : null,
                ),
                title: Text(l10n.planFavorite),
                value: _favorite,
                onChanged: (v) => setState(() => _favorite = v),
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final s in PlanStatus.values)
                      ChoiceChip(
                        label: Text(planStatusLabel(l10n, s)),
                        selected: _status == s,
                        onSelected: (_) => setState(() => _status = s),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.commonSave,
                loading: _saving,
                onPressed: valid ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable card that opens the map picker; shows the chosen place.
class _PlaceField extends StatelessWidget {
  const _PlaceField({
    required this.place,
    required this.onTap,
    required this.onClear,
  });

  final PickedPlace? place;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = place;
    return Semantics(
      button: true,
      label: p == null ? l10n.planChoosePlace : '${l10n.planPlace}: ${p.name}',
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            IconBadge(
              icon: p == null ? Icons.add_location_alt_outlined : Icons.place,
              color: scheme.primary,
              size: 52,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p?.name ?? l10n.planChoosePlace,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p == null
                        ? l10n.planChoosePlaceHint
                        : (p.address?.isNotEmpty ?? false)
                        ? p.address!
                        : l10n.planChangePlace,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (p != null)
              IconButton(
                tooltip: l10n.planRemovePlace,
                icon: const Icon(Icons.close),
                onPressed: onClear,
              )
            else
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
