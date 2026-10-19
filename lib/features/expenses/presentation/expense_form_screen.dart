import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/money.dart';
import '../../../core/money/split.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/pickers.dart';
import '../../../core/widgets/states.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/member.dart';
import '../../tours/data/tour_repository.dart';
import '../../tours/domain/tour.dart';
import '../data/expense_repository.dart';
import '../domain/expense.dart';
import 'expense_ui.dart';

/// Add an expense, or edit [expenseId].
class ExpenseFormScreen extends ConsumerWidget {
  const ExpenseFormScreen({required this.tourId, this.expenseId, super.key});

  final String tourId;
  final String? expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tour = ref.watch(tourProvider(tourId)).value;
    final members = ref.watch(membersProvider(tourId)).value;
    final expenses = ref.watch(expensesProvider(tourId)).value;
    final uid = ref.watch(currentUidProvider);
    if (tour == null || members == null || uid == null) {
      return const Scaffold(body: LoadingView());
    }
    Expense? existing;
    if (expenseId != null) {
      if (expenses == null) return const Scaffold(body: LoadingView());
      existing = expenses.items.where((e) => e.id == expenseId).firstOrNull;
      if (existing == null || existing.isDeleted) {
        return Scaffold(
          appBar: AppBar(),
          body: const ErrorState(error: AppException(AppErrorKind.notFound)),
        );
      }
    }
    return _ExpenseForm(
      tour: tour,
      members: members,
      uid: uid,
      existing: existing,
    );
  }
}

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({
    required this.tour,
    required this.members,
    required this.uid,
    this.existing,
  });

  final Tour tour;
  final List<Member> members;
  final String uid;
  final Expense? existing;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _note;
  late String _currency;
  int? _amount;
  late String _payer;
  late DateTime _occurredAt;
  late ExpenseCategory _category;
  late SplitMethod _method;
  late Set<String> _participants;
  final Map<String, int> _weights = {};
  final Map<String, int?> _custom = {};
  bool _saving = false;

  /// Generated once so retrying a failed/queued save cannot duplicate.
  String? _newId;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title);
    _note = TextEditingController(text: e?.note);
    _currency = e?.currencyCode ?? widget.tour.currencyCode;
    _amount = e?.amountMinor;
    _payer = e?.payerUid ?? widget.uid;
    _occurredAt = e?.occurredAt.toLocal() ?? DateTime.now();
    _category = e?.category ?? ExpenseCategory.food;
    _method = e?.splitMethod ?? SplitMethod.equal;
    _participants = e == null
        ? _selectable.where((m) => m.isActive).map((m) => m.uid).toSet()
        : e.shares.keys.toSet();
    if (e != null) {
      _weights.addAll(e.splitWeights);
      if (e.splitMethod == SplitMethod.custom) _custom.addAll(e.shares);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Active members, plus historical members already on this expense.
  List<Member> get _selectable {
    final inExpense = widget.existing?.shares.keys.toSet() ?? const {};
    final list = widget.members
        .where(
          (m) =>
              m.isActive ||
              inExpense.contains(m.uid) ||
              m.uid == widget.existing?.payerUid,
        )
        .toList();
    list.sort((a, b) {
      if (a.uid == widget.uid) return -1;
      if (b.uid == widget.uid) return 1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return list;
  }

  Currency get _cur => currencyOrDefault(_currency);

  /// Shares for the current inputs, or the reason they are invalid.
  ({Map<String, int>? shares, SplitError? error}) _compute() {
    final total = _amount;
    if (total == null || total <= 0) {
      return (shares: null, error: SplitError.nonPositiveTotal);
    }
    try {
      final shares = switch (_method) {
        SplitMethod.equal => splitEqual(total, _participants),
        SplitMethod.shares => splitByWeights(total, {
          for (final uid in _participants) uid: _weights[uid] ?? 1,
        }),
        SplitMethod.custom => validateCustomSplit(total, {
          for (final uid in _participants) uid: _custom[uid] ?? 0,
        }),
      };
      return (shares: shares, error: null);
    } on SplitException catch (e) {
      return (shares: null, error: e.reason);
    }
  }

  bool _canPickPayer() {
    final p = ref.read(permissionsProvider(widget.tour.id));
    return p?.canRecordForOthers ?? false;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _occurredAt.hour,
        time?.minute ?? _occurredAt.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final result = _compute();
    final shares = result.shares;
    if (shares == null) return;
    final l10n = context.l10n;
    final draft = ExpenseDraft(
      title: _title.text,
      amountMinor: _amount!,
      currencyCode: _currency,
      payerUid: _payer,
      shares: shares,
      splitMethod: _method,
      splitWeights: _method == SplitMethod.shares
          ? {for (final uid in shares.keys) uid: _weights[uid] ?? 1}
          : const {},
      category: _category,
      occurredAt: _occurredAt.toUtc(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );

    final existing = widget.existing;
    if (existing != null) {
      // Confirm only when other members' balances change.
      final affected =
          <String>{
            ...existing.shares.keys,
            ...shares.keys,
            existing.payerUid,
            _payer,
          }.where((uid) {
            if (uid == widget.uid) return false;
            final before =
                (existing.payerUid == uid ? existing.amountMinor : 0) -
                (existing.shares[uid] ?? 0);
            final after = (_payer == uid ? _amount! : 0) - (shares[uid] ?? 0);
            return before != after || existing.currencyCode != _currency;
          }).length;
      if (affected > 0) {
        final ok = await confirmAction(
          context,
          title: l10n.expenseConfirmEditTitle,
          message: l10n.expenseConfirmEditBody(affected),
          confirmLabel: l10n.commonSave,
        );
        if (!ok || !mounted) return;
      }
    }

    setState(() => _saving = true);
    final repo = ref.read(expenseRepositoryProvider);
    try {
      if (existing == null) {
        final id = _newId ??= repo.newId(widget.tour.id);
        final outcome = await repo.add(
          tourId: widget.tour.id,
          id: id,
          draft: draft,
          uid: widget.uid,
        );
        if (!mounted) return;
        showAppSnack(
          context,
          outcome == WriteOutcome.pendingSync
              ? l10n.stateSavedOffline
              : l10n.expenseSaved,
        );
      } else {
        await repo.edit(
          tourId: widget.tour.id,
          expenseId: existing.id,
          draft: draft,
          expectedRevision: existing.revisionCount,
          uid: widget.uid,
        );
        if (!mounted) return;
        showAppSnack(context, l10n.expenseUpdated);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      if (classifyError(e) == AppErrorKind.conflict) {
        await confirmAction(
          context,
          title: l10n.conflictTitle,
          message: l10n.conflictExpenseBody,
          confirmLabel: l10n.commonOk,
        );
        if (mounted) context.pop();
      } else {
        showAppSnack(context, errorMessage(context, e), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _splitErrorText(SplitError? error) {
    final l10n = context.l10n;
    return switch (error) {
      null || SplitError.nonPositiveTotal => null,
      SplitError.noParticipants => l10n.splitNoParticipants,
      SplitError.sumMismatch => l10n.splitSumMismatch(
        formatMoney(
          (_amount ?? 0) -
              _participants.fold<int>(0, (s, u) => s + (_custom[u] ?? 0)),
          _currency,
          locale: context.localeTag,
        ),
      ),
      SplitError.negativeShare => l10n.amountInvalid,
      SplitError.invalidWeight => l10n.splitInvalidWeight,
      SplitError.tooManyParticipants => l10n.splitTooMany(maxSplitParticipants),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final result = _compute();
    final valid =
        result.shares != null &&
        _title.text.trim().isNotEmpty &&
        _amount != null;
    final byUid = {for (final m in _selectable) m.uid: m};
    final payerName = memberName(context, byUid, _payer, viewerUid: widget.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.expenseEditTitle : l10n.expenseAddTitle),
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AmountField(
                      key: ValueKey('amount-$_currency'),
                      currency: _cur,
                      initialMinor: _amount,
                      large: true,
                      autofocus: !_isEdit,
                      onChanged: (v) => setState(() => _amount = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 104,
                    child: PickerField(
                      label: l10n.currencyLabel,
                      value: _currency,
                      onTap: () async {
                        final code = await pickCurrency(context, _currency);
                        if (code != null && code != _currency) {
                          setState(() {
                            _currency = code;
                            _amount = null;
                            _custom.clear();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_currency != widget.tour.currencyCode)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    l10n.expenseOtherCurrencyNote(widget.tour.currencyCode),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _title,
                maxLength: Expense.maxTitleLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.expenseTitleLabel,
                  hintText: l10n.expenseTitleHint,
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.expenseTitleRequired : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in ExpenseCategory.values)
                    ChoiceChip(
                      label: Text(categoryLabel(l10n, c)),
                      avatar: Icon(categoryIcon(c), size: 16),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: PickerField(
                      label: l10n.expensePayer,
                      value: payerName,
                      icon: _canPickPayer() ? null : Icons.person_outline,
                      onTap: () async {
                        if (!_canPickPayer()) {
                          showAppSnack(context, l10n.expensePayerLocked);
                          return;
                        }
                        final m = await pickFromList<Member>(
                          context,
                          title: l10n.expensePayer,
                          items: _selectable.where((m) => m.isActive).toList(),
                          label: (m) => m.uid == widget.uid
                              ? '${m.displayName} (${l10n.commonYou})'
                              : m.displayName,
                          selected: byUid[_payer],
                        );
                        if (m != null) setState(() => _payer = m.uid);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PickerField(
                      label: l10n.expenseDate,
                      value: formatDateTime(context, _occurredAt),
                      icon: Icons.event_outlined,
                      onTap: _pickDateTime,
                    ),
                  ),
                ],
              ),
              SectionHeaderInline(l10n.expenseSplit),
              SegmentedButton<SplitMethod>(
                segments: [
                  ButtonSegment(
                    value: SplitMethod.equal,
                    label: Text(l10n.splitEqual),
                  ),
                  ButtonSegment(
                    value: SplitMethod.custom,
                    label: Text(l10n.splitCustom),
                  ),
                  ButtonSegment(
                    value: SplitMethod.shares,
                    label: Text(l10n.splitShares),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _payer == widget.uid
                    ? l10n.splitPayerHintYou
                    : l10n.splitPayerHint(payerName),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final m in _selectable)
                _ParticipantRow(
                  member: m,
                  isYou: m.uid == widget.uid,
                  included: _participants.contains(m.uid),
                  method: _method,
                  currency: _cur,
                  share: result.shares?[m.uid],
                  weight: _weights[m.uid] ?? 1,
                  custom: _custom[m.uid],
                  onIncluded: (on) => setState(() {
                    on ? _participants.add(m.uid) : _participants.remove(m.uid);
                  }),
                  onWeight: (w) => setState(() => _weights[m.uid] = w),
                  onCustom: (v) => setState(() => _custom[m.uid] = v),
                ),
              if (_splitErrorText(result.error) case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      error,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              if (result.shares != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    l10n.splitPreview(
                      formatMoney(
                        _amount!,
                        _currency,
                        locale: context.localeTag,
                      ),
                      result.shares!.length,
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _note,
                maxLength: Expense.maxNoteLength,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.expenseNote),
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

/// Small inline section title for forms.
class SectionHeaderInline extends StatelessWidget {
  const SectionHeaderInline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.member,
    required this.isYou,
    required this.included,
    required this.method,
    required this.currency,
    required this.share,
    required this.weight,
    required this.custom,
    required this.onIncluded,
    required this.onWeight,
    required this.onCustom,
  });

  final Member member;
  final bool isYou;
  final bool included;
  final SplitMethod method;
  final Currency currency;
  final int? share;
  final int weight;
  final int? custom;
  final ValueChanged<bool> onIncluded;
  final ValueChanged<int> onWeight;
  final ValueChanged<int?> onCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = isYou
        ? '${member.displayName} (${l10n.commonYou})'
        : member.displayName;
    Widget? trailing;
    if (included) {
      trailing = switch (method) {
        SplitMethod.equal => Text(
          share == null
              ? '—'
              : formatMoney(share!, currency.code, locale: context.localeTag),
        ),
        SplitMethod.shares => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.splitFewerShares,
              onPressed: weight > 1 ? () => onWeight(weight - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('$weight×'),
            IconButton(
              tooltip: l10n.splitMoreShares,
              onPressed: weight < 99 ? () => onWeight(weight + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        SplitMethod.custom => SizedBox(
          width: 132,
          child: AmountField(
            key: ValueKey('custom-${member.uid}-${currency.code}'),
            currency: currency,
            initialMinor: custom,
            allowZero: true,
            optional: true,
            label: l10n.splitShareLabel,
            onChanged: onCustom,
          ),
        ),
      };
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Checkbox(
            value: included,
            onChanged: (v) => onIncluded(v ?? false),
            semanticLabel: name,
          ),
          MemberAvatar(
            name: member.displayName,
            photoUrl: member.photoUrl,
            size: AppSizes.avatarSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (method == SplitMethod.shares && included && share != null)
                  Text(
                    formatMoney(
                      share!,
                      currency.code,
                      locale: context.localeTag,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
