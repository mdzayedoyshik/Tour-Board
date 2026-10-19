import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../location_sharing/domain/location_share.dart';
import '../../map/data/map_provider.dart';
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
  late final TextEditingController _place;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _note;
  late final TextEditingController _search;
  late String _dayKey;
  String? _start;
  String? _end;
  int? _cost;
  late String _costCurrency;
  late bool _favorite;
  late PlanStatus _status;
  bool _saving = false;
  bool _manualPlace = false;

  Timer? _debounce;
  List<PlaceResult> _results = const [];
  String? _searchError;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final days = dayKeysBetween(widget.tour.startAt, widget.tour.endAt);
    _title = TextEditingController(text: e?.title);
    _place = TextEditingController(text: e?.placeName);
    _lat = TextEditingController(text: e?.latitude?.toString());
    _lng = TextEditingController(text: e?.longitude?.toString());
    _note = TextEditingController(text: e?.note);
    _search = TextEditingController();
    _dayKey = e?.dayKey ?? widget.initialDay ?? _defaultDay(days);
    _start = e?.startTime;
    _end = e?.endTime;
    _cost = e?.estimatedCostMinor;
    _costCurrency = e?.currencyCode ?? widget.tour.currencyCode;
    _favorite = e?.favorite ?? false;
    _status = e?.status ?? PlanStatus.planned;
    _manualPlace = e?.hasCoordinates ?? false;
  }

  String _defaultDay(List<String> days) {
    final today = dayKeyOf(
      TimeZones.toZone(DateTime.now().toUtc(), widget.tour.timeZone),
    );
    return days.contains(today) ? today : days.first;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_title, _place, _lat, _lng, _note, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    final provider = ref.read(placeSearchProvider);
    if (text.trim().length < provider.minQueryLength) {
      setState(() => _results = const []);
      return;
    }
    // Debounce so typing never sends a request per keystroke.
    _debounce = Timer(
      const Duration(milliseconds: 700),
      () => _runSearch(text),
    );
  }

  Future<void> _runSearch(String text) async {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await ref
          .read(placeSearchProvider)
          .search(text, language: language);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searchError = results.isEmpty ? l10n.placeNoResults : null;
      });
    } on PlaceSearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _searchError = switch (e.reason) {
          PlaceSearchFailure.rateLimited => l10n.placeRateLimited,
          PlaceSearchFailure.network => l10n.placeOffline,
          PlaceSearchFailure.unavailable => l10n.placeUnavailable,
        };
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _choose(PlaceResult r) {
    setState(() {
      _place.text = r.name;
      _lat.text = r.latitude.toStringAsFixed(6);
      _lng.text = r.longitude.toStringAsFixed(6);
      _results = const [];
      _search.clear();
      if (_title.text.trim().isEmpty) _title.text = r.name;
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

  ({double? lat, double? lng, bool valid}) _coords() {
    final latText = _lat.text.trim();
    final lngText = _lng.text.trim();
    if (latText.isEmpty && lngText.isEmpty) {
      return (lat: null, lng: null, valid: true);
    }
    final lat = double.tryParse(latText.replaceAll(',', '.'));
    final lng = double.tryParse(lngText.replaceAll(',', '.'));
    return (lat: lat, lng: lng, valid: isValidCoordinate(lat, lng));
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final coords = _coords();
    if (!coords.valid) return;
    final uid = ref.read(currentUidProvider)!;
    final l10n = context.l10n;
    final draft = PlanDraft(
      title: _title.text,
      dayKey: _dayKey,
      startTime: _start,
      endTime: _end,
      placeName: _place.text,
      latitude: coords.lat,
      longitude: coords.lng,
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
    final search = ref.watch(placeSearchProvider);
    final days = {
      ...dayKeysBetween(widget.tour.startAt, widget.tour.endAt),
      _dayKey,
    }.toList()..sort();
    final coords = _coords();
    final endBeforeStart =
        _start != null &&
        _end != null &&
        parseTimeOfDay(_end)! < parseTimeOfDay(_start)!;
    final valid =
        _title.text.trim().isNotEmpty && coords.valid && !endBeforeStart;

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
                value: formatDayKey(context, _dayKey),
                icon: Icons.today_outlined,
                onTap: () async {
                  final d = await pickFromList<String>(
                    context,
                    title: l10n.planDay,
                    items: days,
                    label: (k) => formatDayKey(context, k),
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
              Text(
                l10n.planTimeZoneNote(
                  widget.tour.timeZone.replaceAll('_', ' '),
                ),
                style: theme.textTheme.bodySmall,
              ),
              FormSectionLabel(l10n.planPlace),
              if (search.isAvailable && !_manualPlace) ...[
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.placeSearchHint,
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    helperText: l10n.placeSearchAttribution,
                    errorText: _searchError,
                  ),
                  onChanged: _onSearchChanged,
                ),
                for (final r in _results)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(r.name),
                    subtitle: r.detail == null
                        ? null
                        : Text(
                            r.detail!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    onTap: () => _choose(r),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ] else if (!search.isAvailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    l10n.placeManualOnly,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              TextFormField(
                controller: _place,
                maxLength: PlanItem.maxPlaceLength,
                decoration: InputDecoration(labelText: l10n.planPlaceName),
              ),
              if (_manualPlace ||
                  !search.isAvailable ||
                  coords.lat != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lat,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.planLatitude,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _lng,
                        keyboardType: const TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.planLongitude,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!coords.valid)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      l10n.planInvalidCoordinates,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
              if (search.isAvailable)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () =>
                        setState(() => _manualPlace = !_manualPlace),
                    child: Text(
                      _manualPlace
                          ? l10n.placeUseSearch
                          : l10n.placeEnterManually,
                    ),
                  ),
                ),
              if (coords.lat != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => setState(() {
                      _lat.clear();
                      _lng.clear();
                    }),
                    child: Text(l10n.planRemoveCoordinates),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
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
                title: Text(l10n.planFavorite),
                value: _favorite,
                onChanged: (v) => setState(() => _favorite = v),
              ),
              if (widget.existing != null)
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
              const SizedBox(height: AppSpacing.lg),
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
