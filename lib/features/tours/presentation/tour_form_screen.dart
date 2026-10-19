import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
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
import '../../auth/data/auth_repository.dart';
import '../data/tour_repository.dart';
import '../domain/tour.dart';

/// Create a tour, or edit an existing one when [tourId] is given.
class TourFormScreen extends ConsumerWidget {
  const TourFormScreen({this.tourId, super.key});

  final String? tourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = tourId;
    if (id == null) return const _TourForm(initial: null);
    final tour = ref.watch(tourProvider(id));
    return AsyncValueView(
      value: tour,
      loading: const Scaffold(body: LoadingView()),
      data: (t) => t == null
          ? Scaffold(
              appBar: AppBar(),
              body: const ErrorState(
                error: AppException(AppErrorKind.notFound),
              ),
            )
          : _TourForm(initial: t),
    );
  }
}

class _TourForm extends ConsumerStatefulWidget {
  const _TourForm({required this.initial});

  final Tour? initial;

  @override
  ConsumerState<_TourForm> createState() => _TourFormState();
}

class _TourFormState extends ConsumerState<_TourForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late DateTime? _start;
  late DateTime? _end;
  late String _currency;
  String _timeZone = 'UTC';
  int? _budget;
  bool _saving = false;

  /// Stable ID generated once so a retried create cannot duplicate the tour.
  String? _pendingId;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _name = TextEditingController(text: t?.name);
    _description = TextEditingController(text: t?.description);
    _start = t?.startAt;
    _end = t?.endAt;
    _currency = t?.currencyCode ?? _defaultCurrency();
    _budget = t?.budgetMinor;
    if (t != null) {
      _timeZone = t.timeZone;
    } else {
      _loadDeviceZone();
    }
  }

  String _defaultCurrency() {
    // Best-effort guess from the device locale; the user can change it.
    final country =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    const byCountry = {
      'BD': 'BDT',
      'IN': 'INR',
      'US': 'USD',
      'GB': 'GBP',
      'NP': 'NPR',
      'LK': 'LKR',
      'PK': 'PKR',
      'MY': 'MYR',
      'SG': 'SGD',
      'TH': 'THB',
      'JP': 'JPY',
      'AE': 'AED',
      'SA': 'SAR',
      'AU': 'AUD',
      'CA': 'CAD',
    };
    return byCountry[country] ?? 'USD';
  }

  Future<void> _loadDeviceZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final zone = info.identifier;
      if (mounted && TimeZones.isValid(zone)) {
        setState(() => _timeZone = zone);
      }
    } catch (_) {
      // Keep UTC; the user can pick a zone.
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  DateRangeError? get _rangeError =>
      _start == null || _end == null ? null : validateDateRange(_start!, _end!);

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _start != null &&
      _end != null &&
      _rangeError == null &&
      isSupportedCurrency(_currency);

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _start != null && _end != null
          ? DateTimeRange(
              start: DateTime(_start!.year, _start!.month, _start!.day),
              end: DateTime(_end!.year, _end!.month, _end!.day),
            )
          : null,
    );
    if (range == null) return;
    setState(() {
      _start = dateOnlyUtc(range.start);
      _end = dateOnlyUtc(range.end);
    });
  }

  Future<void> _save() async {
    if (_saving || !_valid || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    final draft = TourDraft(
      name: _name.text,
      description: _description.text,
      startDate: _start!,
      endDate: _end!,
      currencyCode: _currency,
      timeZone: _timeZone,
      budgetMinor: _budget,
    );
    final repo = ref.read(tourRepositoryProvider);
    try {
      final profile = ref.read(profileProvider).value;
      final user = ref.read(authRepositoryProvider).currentUser!;
      final WriteOutcome outcome;
      String id;
      if (_isEdit) {
        id = widget.initial!.id;
        outcome = await repo.updateDetails(id, draft, user.uid);
      } else {
        id = _pendingId ??= repo.newTourId();
        outcome = await repo.createTour(
          tourId: id,
          draft: draft,
          hostUid: user.uid,
          hostName: profile?.displayName ?? user.displayName ?? '—',
          hostPhotoUrl: profile?.photoUrl ?? user.photoURL,
        );
      }
      if (!mounted) return;
      showAppSnack(
        context,
        outcome == WriteOutcome.pendingSync
            ? l10n.stateSavedOffline
            : (_isEdit ? l10n.tourUpdated : l10n.tourCreated),
      );
      if (_isEdit) {
        context.pop();
      } else {
        context.pushReplacement(Routes.tour(id));
      }
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(context, e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = currencyOrDefault(_currency);
    final rangeError = switch (_rangeError) {
      DateRangeError.endBeforeStart => l10n.tourDatesEndBeforeStart,
      DateRangeError.tooLong => l10n.tourDatesTooLong,
      null => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editTourTitle : l10n.createTourTitle),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              TextFormField(
                controller: _name,
                autofocus: !_isEdit,
                maxLength: Tour.maxNameLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.tourNameLabel,
                  hintText: l10n.tourNameHint,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.tourNameRequired : null,
              ),
              const SizedBox(height: AppSpacing.md),
              PickerField(
                label: l10n.tourDatesLabel,
                icon: Icons.date_range_outlined,
                value: _start == null || _end == null
                    ? null
                    : formatTripRange(context, _start!, _end!),
                errorText: rangeError,
                onTap: _pickDates,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: PickerField(
                      label: l10n.currencyLabel,
                      value: _currency,
                      onTap: () async {
                        final code = await pickCurrency(context, _currency);
                        if (code != null) setState(() => _currency = code);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PickerField(
                      label: l10n.timeZoneLabel,
                      value: _timeZone.replaceAll('_', ' '),
                      onTap: () async {
                        final zone = await pickTimeZone(context, _timeZone);
                        if (zone != null) setState(() => _timeZone = zone);
                      },
                    ),
                  ),
                ],
              ),
              if (_isEdit && _currency != widget.initial!.currencyCode) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.tourCurrencyChangeNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AmountField(
                key: ValueKey('budget-$_currency'),
                currency: currency,
                initialMinor: _budget,
                label: l10n.tourBudgetLabel,
                optional: true,
                // Invalid input is caught by the form validator on save.
                onChanged: (v) => setState(() => _budget = v),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLength: Tour.maxDescriptionLength,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.tourDescriptionLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _isEdit ? l10n.commonSave : l10n.createTour,
                loading: _saving,
                onPressed: _valid ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
