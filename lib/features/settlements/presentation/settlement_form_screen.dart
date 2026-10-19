import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/currency.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amount_field.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/pickers.dart';
import '../../../core/widgets/states.dart';
import '../../../data/firebase/firestore_streams.dart';
import '../../auth/data/auth_repository.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/member.dart';
import '../../tours/data/tour_repository.dart';
import '../data/settlement_repository.dart';
import '../domain/settlement.dart';

/// "Mark as paid" / "Record payment received". Creates a settlement in
/// pending_confirmation; only the counterparty's confirmation makes it
/// count toward balances.
class SettlementFormScreen extends ConsumerStatefulWidget {
  const SettlementFormScreen({
    required this.tourId,
    this.fromUid,
    this.toUid,
    this.amountMinor,
    this.currencyCode,
    super.key,
  });

  final String tourId;
  final String? fromUid;
  final String? toUid;
  final int? amountMinor;
  final String? currencyCode;

  @override
  ConsumerState<SettlementFormScreen> createState() =>
      _SettlementFormScreenState();
}

class _SettlementFormScreenState extends ConsumerState<SettlementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _method = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  late bool _iPaid;
  String? _otherUid;
  String? _currency;
  int? _amount;
  bool _saving = false;
  String? _operationId;

  @override
  void initState() {
    super.initState();
    final uid = ref.read(currentUidProvider);
    _iPaid = widget.toUid != uid;
    _otherUid = _iPaid ? widget.toUid : widget.fromUid;
    _currency = widget.currencyCode;
    _amount = widget.amountMinor;
  }

  @override
  void dispose() {
    _method.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final other = _otherUid;
    final amount = _amount;
    final currency = _currency;
    if (other == null || amount == null || currency == null) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    final repo = ref.read(settlementRepositoryProvider);
    try {
      final tour = ref.read(tourProvider(widget.tourId)).value;
      final id = _operationId ??= repo.newOperationId(widget.tourId);
      final outcome = await repo.submit(
        tourId: widget.tourId,
        tourName: tour?.name ?? '',
        operationId: id,
        draft: SettlementDraft(
          fromUid: _iPaid ? uid : other,
          toUid: _iPaid ? other : uid,
          amountMinor: amount,
          currencyCode: currency,
          paymentMethod: _method.text,
          transactionReference: _reference.text,
          note: _note.text,
        ),
        uid: uid,
        senderName: ref.read(profileProvider).value?.displayName ?? '—',
      );
      if (!mounted) return;
      showAppSnack(
        context,
        outcome == WriteOutcome.pendingSync
            ? l10n.stateSavedOffline
            : l10n.settlementSubmitted,
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
    final uid = ref.watch(currentUidProvider);
    final tour = ref.watch(tourProvider(widget.tourId)).value;
    final members = ref.watch(membersProvider(widget.tourId)).value;
    if (uid == null || tour == null || members == null) {
      return const Scaffold(body: LoadingView());
    }
    _currency ??= tour.currencyCode;
    // Counterparty may be a former member (to settle a leftover balance)
    // but only if they are in the tour's member history.
    final others = members.where((m) => m.uid != uid).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final byUid = {for (final m in others) m.uid: m};
    final otherName = _otherUid == null
        ? null
        : byUid[_otherUid]?.displayName ?? l10n.commonUnknownMember;

    final valid = _otherUid != null && _amount != null && _currency != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settlementRecord)),
      body: Form(
        key: _formKey,
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l10n.settlementIPaid)),
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.settlementIReceived),
                  ),
                ],
                selected: {_iPaid},
                onSelectionChanged: (s) => setState(() => _iPaid = s.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              PickerField(
                label: _iPaid
                    ? l10n.settlementPaidTo
                    : l10n.settlementReceivedFrom,
                value: otherName,
                onTap: () async {
                  final m = await pickFromList<Member>(
                    context,
                    title: _iPaid
                        ? l10n.settlementPaidTo
                        : l10n.settlementReceivedFrom,
                    items: others,
                    label: (m) => m.isActive
                        ? m.displayName
                        : '${m.displayName} (${l10n.memberFormer})',
                    selected: byUid[_otherUid],
                  );
                  if (m != null) setState(() => _otherUid = m.uid);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AmountField(
                      key: ValueKey('settle-$_currency'),
                      currency: currencyOrDefault(_currency!),
                      initialMinor: _amount,
                      large: true,
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
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.settlementPartialHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _method,
                maxLength: Settlement.maxTextLength,
                decoration: InputDecoration(
                  labelText: l10n.settlementMethod,
                  hintText: l10n.settlementMethodHint,
                ),
              ),
              TextFormField(
                controller: _reference,
                maxLength: Settlement.maxTextLength,
                decoration: InputDecoration(labelText: l10n.settlementRef),
              ),
              TextFormField(
                controller: _note,
                maxLength: Settlement.maxTextLength,
                decoration: InputDecoration(labelText: l10n.expenseNote),
              ),
              const SizedBox(height: AppSpacing.md),
              InlineBanner(
                icon: Icons.info_outline,
                message: l10n.settlementOfflineNote,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: l10n.settlementSubmit,
                loading: _saving,
                onPressed: valid ? () => _save(uid) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
