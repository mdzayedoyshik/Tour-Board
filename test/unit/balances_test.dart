import 'package:flutter_test/flutter_test.dart';
import 'package:tour_board/core/money/split.dart';
import 'package:tour_board/features/expenses/domain/balances.dart';
import 'package:tour_board/features/expenses/domain/expense.dart';
import 'package:tour_board/features/settlements/domain/settlement.dart';

final _t = DateTime.utc(2026, 1, 1);

Expense expense(
  String id,
  String payer,
  int amount,
  Map<String, int> shares, {
  String currency = 'BDT',
  bool deleted = false,
}) => Expense(
  id: id,
  title: id,
  amountMinor: amount,
  currencyCode: currency,
  payerUid: payer,
  shares: shares,
  splitMethod: SplitMethod.custom,
  category: ExpenseCategory.food,
  occurredAt: _t,
  createdBy: payer,
  createdAt: _t,
  updatedAt: _t,
  deletedAt: deleted ? _t : null,
);

Settlement settlement(
  String id,
  String from,
  String to,
  int amount, {
  SettlementStatus status = SettlementStatus.confirmed,
  String currency = 'BDT',
}) => Settlement(
  id: id,
  fromUid: from,
  toUid: to,
  amountMinor: amount,
  currencyCode: currency,
  status: status,
  createdBy: from,
  createdAt: _t,
  updatedAt: _t,
);

void main() {
  group('computeBalances', () {
    test('payer is credited and participants debited', () {
      final b = computeBalances([
        expense('e1', 'host', 300, splitEqual(300, ['host', 'a', 'b'])),
      ], []);
      expect(b.netFor('host', 'BDT'), 200);
      expect(b.netFor('a', 'BDT'), -100);
      expect(b.netFor('b', 'BDT'), -100);
      expect(b.totalSpentByCurrency['BDT'], 300);
    });

    test('payer not included as participant is credited in full', () {
      final b = computeBalances([
        expense('e1', 'p', 200, {'a': 100, 'b': 100}),
      ], []);
      expect(b.netFor('p', 'BDT'), 200);
      expect(b.netFor('a', 'BDT'), -100);
    });

    test('nets in each currency always sum to zero', () {
      final b = computeBalances(
        [
          expense('e1', 'a', 1001, splitEqual(1001, ['a', 'b', 'c'])),
          expense('e2', 'b', 777, splitByWeights(777, {'a': 2, 'c': 1})),
        ],
        [settlement('s1', 'c', 'a', 50)],
      );
      expect(b.netByCurrency['BDT']!.values.reduce((x, y) => x + y), 0);
    });

    test('full settlement brings both parties to zero', () {
      final b = computeBalances(
        [
          expense('e1', 'a', 200, {'a': 100, 'b': 100}),
        ],
        [settlement('s1', 'b', 'a', 100)],
      );
      expect(b.netFor('a', 'BDT'), 0);
      expect(b.netFor('b', 'BDT'), 0);
    });

    test('partial settlements accumulate', () {
      final b = computeBalances(
        [
          expense('e1', 'a', 200, {'a': 100, 'b': 100}),
        ],
        [settlement('s1', 'b', 'a', 30), settlement('s2', 'b', 'a', 20)],
      );
      expect(b.netFor('b', 'BDT'), -50);
      expect(b.netFor('a', 'BDT'), 50);
    });

    test('pending, disputed and cancelled settlements are ignored', () {
      final b = computeBalances(
        [
          expense('e1', 'a', 200, {'a': 100, 'b': 100}),
        ],
        [
          settlement(
            's1',
            'b',
            'a',
            100,
            status: SettlementStatus.pendingConfirmation,
          ),
          settlement('s2', 'b', 'a', 100, status: SettlementStatus.disputed),
          settlement('s3', 'b', 'a', 100, status: SettlementStatus.cancelled),
        ],
      );
      expect(b.netFor('b', 'BDT'), -100);
    });

    test('duplicate settlement records are applied once', () {
      final s = settlement('same-op', 'b', 'a', 100);
      final b = computeBalances(
        [
          expense('e1', 'a', 200, {'a': 100, 'b': 100}),
        ],
        [s, s],
      );
      expect(b.netFor('b', 'BDT'), 0);
    });

    test('soft-deleted expenses are excluded', () {
      final b = computeBalances([
        expense('e1', 'a', 200, {'a': 100, 'b': 100}),
        expense('e2', 'b', 999, {'a': 999}, deleted: true),
      ], []);
      expect(b.netFor('a', 'BDT'), 100);
      expect(b.totalSpentByCurrency['BDT'], 200);
    });

    test('currencies stay separate', () {
      final b = computeBalances([
        expense('e1', 'a', 200, {'a': 100, 'b': 100}),
        expense('e2', 'b', 50, {'a': 50}, currency: 'USD'),
      ], []);
      expect(b.netFor('a', 'BDT'), 100);
      expect(b.netFor('a', 'USD'), -50);
      expect(b.currencies, ['BDT', 'USD']);
    });

    test('host can be a debtor like anyone else', () {
      final b = computeBalances([
        expense('e1', 'member', 400, {'host': 200, 'member': 200}),
      ], []);
      expect(b.netFor('host', 'BDT'), -200);
    });
  });

  group('suggestTransfers', () {
    test('settles every debt with at most n-1 transfers', () {
      final b = computeBalances([
        expense('e1', 'a', 900, splitEqual(900, ['a', 'b', 'c'])),
        expense('e2', 'b', 300, splitEqual(300, ['a', 'b', 'c'])),
      ], []);
      final transfers = suggestTransfers(b);
      expect(transfers.length, lessThanOrEqualTo(2));
      final applied = computeBalances(
        [
          expense('e1', 'a', 900, splitEqual(900, ['a', 'b', 'c'])),
          expense('e2', 'b', 300, splitEqual(300, ['a', 'b', 'c'])),
        ],
        [
          for (var i = 0; i < transfers.length; i++)
            settlement(
              's$i',
              transfers[i].fromUid,
              transfers[i].toUid,
              transfers[i].amountMinor,
            ),
        ],
      );
      expect(applied.netByCurrency['BDT']!.values.every((v) => v == 0), true);
    });

    test('is deterministic and per currency', () {
      final b = computeBalances([
        expense('e1', 'a', 200, {'b': 100, 'c': 100}),
        expense('e2', 'c', 10, {'a': 10}, currency: 'USD'),
      ], []);
      expect(suggestTransfers(b), [
        const SuggestedTransfer(
          fromUid: 'b',
          toUid: 'a',
          amountMinor: 100,
          currencyCode: 'BDT',
        ),
        const SuggestedTransfer(
          fromUid: 'c',
          toUid: 'a',
          amountMinor: 100,
          currencyCode: 'BDT',
        ),
        const SuggestedTransfer(
          fromUid: 'a',
          toUid: 'c',
          amountMinor: 10,
          currencyCode: 'USD',
        ),
      ]);
    });

    test('no transfers when everyone is even', () {
      expect(suggestTransfers(computeBalances([], [])), isEmpty);
    });
  });

  group('diffFields', () {
    test('detects changed fields only', () {
      expect(
        diffFields(
          {
            'title': 'A',
            'shares': {'a': 1},
            'note': null,
          },
          {
            'title': 'A',
            'shares': {'a': 1},
            'note': 'x',
          },
        ),
        ['note'],
      );
      expect(
        diffFields(
          {
            'shares': {'a': 1},
          },
          {
            'shares': {'a': 2},
          },
        ),
        ['shares'],
      );
    });
  });
}
