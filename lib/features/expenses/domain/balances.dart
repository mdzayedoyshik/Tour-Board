import '../../settlements/domain/settlement.dart';
import 'expense.dart';

/// Net positions per currency, recomputed from canonical records.
///
/// Sign convention (documented in docs/ARCHITECTURE.md):
///
///   net = paid_for_expenses - share_of_expenses
///         + confirmed_settlements_paid - confirmed_settlements_received
///
/// Positive net  -> the group owes this member ("You should receive").
/// Negative net  -> this member owes the group ("You owe").
///
/// Paying a settlement works like paying an expense on the creditor's
/// behalf, so it moves both parties toward zero. (The brief's formula lists
/// the settlement terms with the opposite labels; this is the reading that
/// keeps the books balanced.)
class TourBalances {
  const TourBalances({
    required this.netByCurrency,
    required this.totalSpentByCurrency,
    required this.shareByCurrency,
  });

  /// currency -> uid -> net minor units. Each currency's nets sum to zero.
  final Map<String, Map<String, int>> netByCurrency;

  /// currency -> total of non-deleted expenses.
  final Map<String, int> totalSpentByCurrency;

  /// currency -> uid -> that member's share of expenses (their consumption).
  final Map<String, Map<String, int>> shareByCurrency;

  List<String> get currencies =>
      ({...netByCurrency.keys, ...totalSpentByCurrency.keys}.toList()..sort());

  int netFor(String uid, String currency) => netByCurrency[currency]?[uid] ?? 0;

  bool get isEmpty => totalSpentByCurrency.isEmpty && netByCurrency.isEmpty;
}

TourBalances computeBalances(
  Iterable<Expense> expenses,
  Iterable<Settlement> settlements,
) {
  final net = <String, Map<String, int>>{};
  final spent = <String, int>{};
  final consumed = <String, Map<String, int>>{};

  void add(Map<String, Map<String, int>> target, String c, String uid, int v) {
    final perUid = target.putIfAbsent(c, () => <String, int>{});
    perUid[uid] = (perUid[uid] ?? 0) + v;
  }

  // Deduplicate by ID so a record delivered twice (e.g. cache + server) is
  // applied once.
  final seenExpenses = <String>{};
  for (final e in expenses) {
    if (e.isDeleted || !seenExpenses.add(e.id)) continue;
    spent[e.currencyCode] = (spent[e.currencyCode] ?? 0) + e.amountMinor;
    add(net, e.currencyCode, e.payerUid, e.amountMinor);
    e.shares.forEach((uid, share) {
      add(net, e.currencyCode, uid, -share);
      add(consumed, e.currencyCode, uid, share);
    });
  }

  final seenSettlements = <String>{};
  for (final s in settlements) {
    if (!s.isConfirmed || !seenSettlements.add(s.id)) continue;
    add(net, s.currencyCode, s.fromUid, s.amountMinor);
    add(net, s.currencyCode, s.toUid, -s.amountMinor);
  }

  return TourBalances(
    netByCurrency: net,
    totalSpentByCurrency: spent,
    shareByCurrency: consumed,
  );
}

/// A suggested offline payment from a debtor to a creditor.
class SuggestedTransfer {
  const SuggestedTransfer({
    required this.fromUid,
    required this.toUid,
    required this.amountMinor,
    required this.currencyCode,
  });

  final String fromUid;
  final String toUid;
  final int amountMinor;
  final String currencyCode;

  @override
  bool operator ==(Object other) =>
      other is SuggestedTransfer &&
      other.fromUid == fromUid &&
      other.toUid == toUid &&
      other.amountMinor == amountMinor &&
      other.currencyCode == currencyCode;

  @override
  int get hashCode => Object.hash(fromUid, toUid, amountMinor, currencyCode);

  @override
  String toString() => '$fromUid -> $toUid: $amountMinor $currencyCode';
}

/// Greedy settle-up: repeatedly match the largest debtor with the largest
/// creditor. Produces at most n-1 transfers per currency and is deterministic
/// (ties broken by uid). A suggestion only — the app never moves money.
List<SuggestedTransfer> suggestTransfers(TourBalances balances) {
  final result = <SuggestedTransfer>[];
  for (final currency in balances.netByCurrency.keys.toList()..sort()) {
    final nets = balances.netByCurrency[currency]!;
    final debtors = [
      for (final e in nets.entries)
        if (e.value < 0) MapEntry(e.key, -e.value),
    ];
    final creditors = [
      for (final e in nets.entries)
        if (e.value > 0) MapEntry(e.key, e.value),
    ];
    int byAmountThenUid(MapEntry<String, int> a, MapEntry<String, int> b) {
      final cmp = b.value.compareTo(a.value);
      return cmp != 0 ? cmp : a.key.compareTo(b.key);
    }

    debtors.sort(byAmountThenUid);
    creditors.sort(byAmountThenUid);
    var i = 0;
    var j = 0;
    var debt = debtors.isEmpty ? 0 : debtors[0].value;
    var credit = creditors.isEmpty ? 0 : creditors[0].value;
    while (i < debtors.length && j < creditors.length) {
      final amount = debt < credit ? debt : credit;
      if (amount > 0) {
        result.add(
          SuggestedTransfer(
            fromUid: debtors[i].key,
            toUid: creditors[j].key,
            amountMinor: amount,
            currencyCode: currency,
          ),
        );
      }
      debt -= amount;
      credit -= amount;
      if (debt == 0 && ++i < debtors.length) debt = debtors[i].value;
      if (credit == 0 && ++j < creditors.length) credit = creditors[j].value;
    }
  }
  return result;
}
