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
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../auth/data/auth_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/domain/balances.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/member.dart';
import '../../membership/domain/permissions.dart';
import '../../tours/data/tour_repository.dart';
import '../data/settlement_repository.dart';
import '../domain/settlement.dart';

class BalancesScreen extends ConsumerWidget {
  const BalancesScreen({required this.tourId, super.key});

  final String tourId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final balances = ref.watch(balancesProvider(tourId));
    final settlements = ref.watch(settlementsProvider(tourId));
    final members = ref.watch(memberMapProvider(tourId));
    final permissions = ref.watch(permissionsProvider(tourId));
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.balancesTitle)),
      floatingActionButton: permissions?.isMember ?? false
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newSettlement(tourId)),
              icon: const Icon(Icons.payments_outlined),
              label: Text(l10n.settlementRecord),
            )
          : null,
      body: AsyncValueView(
        value: settlements,
        onRetry: () => ref.invalidate(settlementsProvider(tourId)),
        data: (snap) {
          final b = balances;
          if (b == null) return const LoadingList();
          final transfers = suggestTransfers(b);
          return ContentWidth(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    0,
                  ),
                  child: Text(
                    l10n.balancesExplainer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (b.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      l10n.balancesEmpty,
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final currency in b.netByCurrency.keys.toList()..sort())
                  ..._currencySection(context, b, currency, members, uid),
                if (transfers.isNotEmpty) ...[
                  SectionHeader(l10n.balancesSuggested),
                  for (final t in transfers)
                    _TransferTile(
                      tourId: tourId,
                      transfer: t,
                      members: members,
                      uid: uid,
                    ),
                ],
                if (snap.items.isNotEmpty) ...[
                  SectionHeader(l10n.settlementsTitle),
                  for (final s in snap.items)
                    _SettlementTile(
                      tourId: tourId,
                      settlement: s,
                      members: members,
                      uid: uid,
                      permissions: permissions,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _currencySection(
    BuildContext context,
    TourBalances b,
    String currency,
    Map<String, Member> members,
    String? uid,
  ) {
    final nets = b.netByCurrency[currency]!;
    final uids = nets.keys.toList()
      ..sort((a, x) => nets[x]!.compareTo(nets[a]!));
    return [
      SectionHeader(
        context.l10n.balancesInCurrency(currency),
        trailing: Text(
          formatMoney(
            b.totalSpentByCurrency[currency] ?? 0,
            currency,
            locale: context.localeTag,
          ),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      for (final memberUid in uids)
        ListTile(
          leading: MemberAvatar(
            name: members[memberUid]?.displayName ?? '?',
            photoUrl: members[memberUid]?.photoUrl,
          ),
          title: Text(memberName(context, members, memberUid, viewerUid: uid)),
          subtitle: BalanceLine(
            net: nets[memberUid]!,
            currencyCode: currency,
            subject: memberUid == uid
                ? null
                : memberName(context, members, memberUid),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: members[memberUid]?.isActive ?? false
              ? null
              : StatusPill(label: context.l10n.memberFormer),
        ),
    ];
  }
}

class _TransferTile extends StatelessWidget {
  const _TransferTile({
    required this.tourId,
    required this.transfer,
    required this.members,
    required this.uid,
  });

  final String tourId;
  final SuggestedTransfer transfer;
  final Map<String, Member> members;
  final String? uid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final from = memberName(context, members, transfer.fromUid, viewerUid: uid);
    final to = memberName(context, members, transfer.toUid, viewerUid: uid);
    final amount = formatMoney(
      transfer.amountMinor,
      transfer.currencyCode,
      locale: context.localeTag,
    );
    final involved = uid == transfer.fromUid || uid == transfer.toUid;
    return ListTile(
      leading: const Icon(Icons.arrow_forward),
      title: Text(l10n.transferLine(from, to)),
      subtitle: Text(amount),
      trailing: involved
          ? TextButton(
              onPressed: () => context.push(
                Routes.newSettlement(
                  tourId,
                  from: transfer.fromUid,
                  to: transfer.toUid,
                  amount: transfer.amountMinor,
                  currency: transfer.currencyCode,
                ),
              ),
              child: Text(
                uid == transfer.fromUid
                    ? l10n.settlementMarkPaid
                    : l10n.settlementMarkReceived,
              ),
            )
          : null,
    );
  }
}

class _SettlementTile extends ConsumerStatefulWidget {
  const _SettlementTile({
    required this.tourId,
    required this.settlement,
    required this.members,
    required this.uid,
    required this.permissions,
  });

  final String tourId;
  final Settlement settlement;
  final Map<String, Member> members;
  final String? uid;
  final TourPermissions? permissions;

  @override
  ConsumerState<_SettlementTile> createState() => _SettlementTileState();
}

class _SettlementTileState extends ConsumerState<_SettlementTile> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showAppSnack(context, done);
    } catch (e) {
      if (!mounted) return;
      final msg = classifyError(e) == AppErrorKind.conflict
          ? context.l10n.settlementAlreadyChanged
          : errorMessage(context, e);
      showAppSnack(context, msg, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settlement;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = StatusColors.of(context);
    final p = widget.permissions;
    final members = widget.members;
    String name(String u) =>
        memberName(context, members, u, viewerUid: widget.uid);
    final repo = ref.read(settlementRepositoryProvider);
    final tourName = ref.read(tourProvider(widget.tourId)).value?.name ?? '';
    final myName = ref.read(profileProvider).value?.displayName ?? '—';
    final actions = p == null
        ? null
        : SettlementActions(
            settlement: s,
            permissions: p,
            counterpartyIsActive: members[s.counterpartyUid]?.isActive ?? false,
          );

    final (label, color, icon) = switch (s.status) {
      SettlementStatus.pendingConfirmation => (
        l10n.settlementPending,
        colors.warning,
        Icons.hourglass_top,
      ),
      SettlementStatus.confirmed => (
        l10n.settlementConfirmed,
        colors.success,
        Icons.check_circle_outline,
      ),
      SettlementStatus.disputed => (
        l10n.settlementDisputed,
        colors.error,
        Icons.report_outlined,
      ),
      SettlementStatus.cancelled => (
        l10n.settlementCancelled,
        colors.muted,
        Icons.block,
      ),
    };

    final details = [
      ?s.paymentMethod,
      if (s.transactionReference != null)
        l10n.settlementRefShort(s.transactionReference!),
      ?s.note,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.md,
      ),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.transferLine(name(s.fromUid), name(s.toUid)),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  formatMoney(
                    s.amountMinor,
                    s.currencyCode,
                    locale: context.localeTag,
                  ),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(label: label, color: color, icon: icon),
                if (s.hasPendingWrites)
                  StatusPill(label: l10n.statePendingSync),
                Text(
                  formatShortDate(context, s.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(details.join(' · '), style: theme.textTheme.bodySmall),
            ],
            if (s.status == SettlementStatus.disputed &&
                s.disputeReason != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.settlementDisputeReason(s.disputeReason!),
                style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
              ),
            ],
            if (s.isConfirmed && s.confirmedBy != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.settlementConfirmedBy(name(s.confirmedBy!)),
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (actions != null &&
                (actions.canConfirm ||
                    actions.canDispute ||
                    actions.canCancel)) ...[
              const SizedBox(height: AppSpacing.sm),
              if (_busy)
                const LinearProgressIndicator()
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    if (actions.canConfirm)
                      FilledButton.tonal(
                        onPressed: () async {
                          final ok = await confirmAction(
                            context,
                            title: l10n.settlementConfirmTitle,
                            message: l10n.settlementConfirmBody(
                              formatMoney(
                                s.amountMinor,
                                s.currencyCode,
                                locale: context.localeTag,
                              ),
                              name(s.fromUid),
                            ),
                            confirmLabel: l10n.settlementConfirmAction,
                          );
                          if (!ok) return;
                          await _run(
                            () => repo.confirm(
                              tourId: widget.tourId,
                              tourName: tourName,
                              settlement: s,
                              uid: widget.uid!,
                              senderName: myName,
                            ),
                            l10n.settlementConfirmed,
                          );
                        },
                        child: Text(l10n.settlementConfirmAction),
                      ),
                    if (actions.canDispute)
                      OutlinedButton(
                        onPressed: () async {
                          final reason = await promptText(
                            context,
                            title: l10n.settlementDisputeTitle,
                            label: l10n.settlementDisputeLabel,
                            confirmLabel: l10n.settlementDisputeAction,
                          );
                          if (reason == null) return;
                          await _run(
                            () => repo.dispute(
                              tourId: widget.tourId,
                              tourName: tourName,
                              settlement: s,
                              uid: widget.uid!,
                              senderName: myName,
                              reason: reason,
                            ),
                            l10n.settlementDisputed,
                          );
                        },
                        child: Text(l10n.settlementDisputeAction),
                      ),
                    if (actions.canCancel)
                      TextButton(
                        onPressed: () async {
                          final ok = await confirmAction(
                            context,
                            title: l10n.settlementCancelTitle,
                            confirmLabel: l10n.settlementCancelAction,
                            destructive: true,
                          );
                          if (!ok) return;
                          await _run(
                            () => repo.cancel(
                              tourId: widget.tourId,
                              settlement: s,
                              uid: widget.uid!,
                            ),
                            l10n.settlementCancelled,
                          );
                        },
                        child: Text(l10n.settlementCancelAction),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}
