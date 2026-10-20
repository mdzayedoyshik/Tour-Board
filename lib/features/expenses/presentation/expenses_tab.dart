import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/routes.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/states.dart';
import '../../membership/data/membership_repository.dart';
import '../../membership/domain/member.dart';
import '../../tours/domain/tour.dart';
import '../../tours/presentation/tour_status_ui.dart';
import '../data/expense_repository.dart';
import '../domain/balances.dart';
import '../domain/expense.dart';
import 'expense_ui.dart';

class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({required this.tour, super.key});

  final Tour tour;

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  String _query = '';
  ExpenseCategory? _category;
  String? _memberUid;
  bool _showDeleted = false;

  bool get _filtering =>
      _query.isNotEmpty || _category != null || _memberUid != null;

  List<Expense> _filter(List<Expense> items) {
    final q = _query.toLowerCase();
    return items.where((e) {
      if (e.isDeleted && !_showDeleted) return false;
      if (q.isNotEmpty && !e.title.toLowerCase().contains(q)) return false;
      if (_category != null && e.category != _category) return false;
      if (_memberUid != null &&
          e.payerUid != _memberUid &&
          !e.shares.containsKey(_memberUid)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openFilters(List<Member> members) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void update(VoidCallback fn) {
            setState(fn);
            setSheet(() {});
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.expenseFilters,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.expenseCategory),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final c in ExpenseCategory.values)
                        FilterChip(
                          label: Text(categoryLabel(l10n, c)),
                          avatar: Icon(categoryIcon(c), size: 16),
                          selected: _category == c,
                          onSelected: (on) =>
                              update(() => _category = on ? c : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.expenseFilterMember),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final m in members)
                        FilterChip(
                          label: Text(m.displayName),
                          selected: _memberUid == m.uid,
                          onSelected: (on) =>
                              update(() => _memberUid = on ? m.uid : null),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.expenseShowDeleted),
                    value: _showDeleted,
                    onChanged: (v) => update(() => _showDeleted = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: l10n.commonClear,
                    onPressed: () => update(() {
                      _category = null;
                      _memberUid = null;
                      _showDeleted = false;
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final l10n = context.l10n;
    final expensesAsync = ref.watch(expensesProvider(tour.id));
    final balances = ref.watch(balancesProvider(tour.id));
    final members = ref.watch(memberMapProvider(tour.id));
    final active = ref.watch(activeMembersProvider(tour.id));
    final permissions = ref.watch(permissionsProvider(tour.id));
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      floatingActionButton: permissions?.canAddExpense ?? false
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.newExpense(tour.id)),
              icon: const Icon(Icons.add),
              label: Text(l10n.expenseAdd),
            )
          : null,
      body: AsyncValueView(
        value: expensesAsync,
        onRetry: () => ref.invalidate(expensesProvider(tour.id)),
        data: (snapshot) {
          final filtered = _filter(snapshot.items);
          return CustomScrollView(
            slivers: [
              if (snapshot.fromCache)
                SliverToBoxAdapter(
                  child: InlineBanner(
                    icon: Icons.cloud_off_outlined,
                    message: l10n.stateOfflineCached,
                  ),
                ),
              if (snapshot.hasMore)
                SliverToBoxAdapter(
                  child: InlineBanner(
                    icon: Icons.info_outline,
                    message: l10n.expenseLimitReached(
                      ExpenseRepository.queryLimit,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: ContentWidth(
                  child: _Overview(
                    tour: tour,
                    balances: balances,
                    uid: uid,
                    memberCount: active.length,
                  ),
                ),
              ),
              if (snapshot.items.isNotEmpty)
                SliverToBoxAdapter(
                  child: ContentWidth(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.lg,
                        AppSpacing.page,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                isDense: true,
                                prefixIcon: const Icon(Icons.search),
                                hintText: l10n.expenseSearchHint,
                              ),
                              onChanged: (v) =>
                                  setState(() => _query = v.trim()),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton.filledTonal(
                            tooltip: l10n.expenseFilters,
                            onPressed: () => _openFilters(active),
                            icon: Badge(
                              isLabelVisible:
                                  _category != null ||
                                  _memberUid != null ||
                                  _showDeleted,
                              smallSize: 8,
                              child: const Icon(Icons.tune),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (snapshot.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.expenseEmptyTitle,
                    message: l10n.expenseEmptyBody,
                    actions: [
                      if (permissions?.canAddExpense ?? false)
                        PrimaryButton(
                          label: l10n.expenseAdd,
                          icon: Icons.add,
                          expand: false,
                          onPressed: () =>
                              context.push(Routes.newExpense(tour.id)),
                        ),
                    ],
                  ),
                )
              else if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      _filtering
                          ? l10n.expenseNoMatches
                          : l10n.expenseEmptyTitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => ContentWidth(
                    child: _ExpenseTile(
                      expense: filtered[i],
                      members: members,
                      uid: uid,
                      onTap: () =>
                          context.push(Routes.expense(tour.id, filtered[i].id)),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({
    required this.tour,
    required this.balances,
    required this.uid,
    required this.memberCount,
  });

  final Tour tour;
  final TourBalances? balances;
  final String? uid;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final b = balances;
    final locale = context.localeTag;
    final spent = b?.totalSpentByCurrency ?? const {};
    final mainSpent = spent[tour.currencyCode] ?? 0;
    final otherCurrencies = spent.keys.where((c) => c != tour.currencyCode);
    final budget = tour.budgetMinor;
    final currencies = {tour.currencyCode, ...?b?.currencies}.toList();
    const onHero = Colors.white;
    final heroMuted = Colors.white.withValues(alpha: 0.82);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: TourPalette.gradientFor(tour.id),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: Elevations.of(context).floating,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatTripRange(context, tour.startAt, tour.endAt)}'
                    '  ·  ${l10n.memberCount(memberCount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: heroMuted,
                    ),
                  ),
                ),
                _HeroPill(tour: tour),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.expenseTotalSpent,
              style: theme.textTheme.labelLarge?.copyWith(color: heroMuted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                formatMoney(mainSpent, tour.currencyCode, locale: locale),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: onHero,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            for (final c in otherCurrencies)
              Text(
                '+ ${formatMoney(spent[c]!, c, locale: locale)}',
                style: theme.textTheme.titleSmall?.copyWith(color: onHero),
              ),
            if (budget != null && budget > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Semantics(
                label: l10n.expenseBudgetProgress(
                  formatMoney(mainSpent, tour.currencyCode, locale: locale),
                  formatMoney(budget, tour.currencyCode, locale: locale),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: (mainSpent / budget).clamp(0, 1).toDouble(),
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: mainSpent > budget
                        ? const Color(0xFFFFD166)
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.expenseBudgetProgress(
                  formatMoney(mainSpent, tour.currencyCode, locale: locale),
                  formatMoney(budget, tour.currencyCode, locale: locale),
                ),
                style: theme.textTheme.bodySmall?.copyWith(color: heroMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (b == null)
              LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                color: Colors.white,
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final c in currencies)
                    _HeroBalance(
                      net: uid == null ? 0 : b.netFor(uid!, c),
                      currencyCode: c,
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () => context.push(Routes.balances(tour.id)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: AppColors.navy),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.balancesOpen,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.navy),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status label on the gradient hero (white text on translucent white).
class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.tour});

  final Tour tour;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      extensions: [
        Theme.of(context).extension<StatusColors>()!.copyWith(
          success: Colors.white,
          warning: Colors.white,
          muted: Colors.white,
        ),
        Elevations.of(context),
      ],
      colorScheme: Theme.of(
        context,
      ).colorScheme.copyWith(secondary: Colors.white),
    ),
    child: TourStatusPill(tour: tour),
  );
}

/// "You should receive / You owe / settled" on the hero card.
class _HeroBalance extends StatelessWidget {
  const _HeroBalance({required this.net, required this.currencyCode});

  final int net;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = formatMoney(
      net.abs(),
      currencyCode,
      locale: context.localeTag,
    );
    final (text, icon) = net > 0
        ? (l10n.balanceYouReceive(amount), Icons.south_west)
        : net < 0
        ? (l10n.balanceYouOwe(amount), Icons.north_east)
        : (l10n.balanceYouSettled, Icons.check);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.members,
    required this.uid,
    required this.onTap,
  });

  final Expense expense;
  final Map<String, Member> members;
  final String? uid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final payer = memberName(
      context,
      members,
      expense.payerUid,
      viewerUid: uid,
    );
    final deleted = expense.isDeleted;
    final markers = [
      if (deleted) l10n.stateDeleted,
      if (!deleted && expense.isEdited) l10n.stateEdited,
      if (expense.hasPendingWrites) l10n.statePendingSync,
    ];
    return ListTile(
      onTap: onTap,
      leading: CategoryIcon(expense.category),
      title: Text(
        expense.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: deleted
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        [
          l10n.expensePaidBy(payer),
          formatShortDate(context, expense.occurredAt),
          ...markers,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: muted),
      ),
      trailing: Text(
        formatMoney(
          expense.amountMinor,
          expense.currencyCode,
          locale: context.localeTag,
        ),
        style: theme.textTheme.titleSmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          color: deleted ? muted : null,
          decoration: deleted ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}
