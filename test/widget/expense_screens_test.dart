import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_board/features/expenses/data/expense_repository.dart';
import 'package:tour_board/features/expenses/presentation/expense_detail_screen.dart';
import 'package:tour_board/features/expenses/presentation/expense_form_screen.dart';
import 'package:tour_board/features/membership/data/membership_repository.dart';
import 'package:tour_board/features/membership/domain/member.dart';
import 'package:tour_board/features/settlements/data/settlement_repository.dart';
import 'package:tour_board/features/settlements/domain/settlement.dart';
import 'package:tour_board/features/settlements/presentation/balances_screen.dart';
import 'package:tour_board/features/tours/data/tour_repository.dart';

import '../helpers.dart';

/// Tall viewport so lazily built lists render every row.
void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  final common = [
    tourProvider('t1').overrideWith((ref) => Stream.value(testTour())),
    membersProvider('t1').overrideWith((ref) => Stream.value(testMembers)),
    myMemberProvider('t1').overrideWith(
      (ref) => Stream.value(testMember('alice', MemberRole.member)),
    ),
  ];

  group('ExpenseFormScreen', () {
    testWidgets('save is disabled until valid and preview shows shares', (
      tester,
    ) async {
      useTallView(tester);
      await pumpApp(
        tester,
        const ExpenseFormScreen(tourId: 't1'),
        overrides: [
          ...common,
          expensesProvider('t1').overrideWith((ref) => Stream.value(snap([]))),
        ],
      );
      await tester.pumpAndSettle();

      FilledButton saveButton() => tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Save'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(saveButton().onPressed, isNull);

      await tester.enterText(find.byType(TextFormField).first, '100');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Snacks',
      );
      await tester.pumpAndSettle();

      // 100.00 BDT split equally between 3 -> 33.34 / 33.33 / 33.33.
      expect(find.textContaining('33.34'), findsOneWidget);
      expect(find.textContaining('33.33'), findsNWidgets(2));
      expect(saveButton().onPressed, isNotNull);
    });

    testWidgets('custom split shows mismatch and blocks save', (tester) async {
      useTallView(tester);
      await pumpApp(
        tester,
        const ExpenseFormScreen(tourId: 't1'),
        overrides: [
          ...common,
          expensesProvider('t1').overrideWith((ref) => Stream.value(snap([]))),
        ],
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '90');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'),
        'Taxi',
      );
      await tester.tap(find.text('Amounts'));
      await tester.pumpAndSettle();
      expect(find.textContaining('must add up'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Save'),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('ExpenseDetailScreen', () {
    Future<void> pumpDetail(WidgetTester tester, int revisions) => pumpApp(
      tester,
      const ExpenseDetailScreen(tourId: 't1', expenseId: 'e1'),
      overrides: [
        ...common,
        expensesProvider('t1').overrideWith(
          (ref) => Stream.value(snap([testExpense(revisionCount: revisions)])),
        ),
      ],
    );

    testWidgets('"View edits" appears only when revisions exist', (
      tester,
    ) async {
      useTallView(tester);
      await pumpDetail(tester, 0);
      await tester.pumpAndSettle();
      expect(find.text('Dinner'), findsOneWidget);
      expect(find.text('View edits'), findsNothing);
      // Owner sees edit/delete controls.
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('edited expense shows the subtle "View edits" action', (
      tester,
    ) async {
      useTallView(tester);
      await pumpDetail(tester, 2);
      await tester.pumpAndSettle();
      expect(find.text('View edits'), findsOneWidget);
    });

    testWidgets('deleted expense is marked with text, not color only', (
      tester,
    ) async {
      useTallView(tester);
      await pumpApp(
        tester,
        const ExpenseDetailScreen(tourId: 't1', expenseId: 'e1'),
        overrides: [
          ...common,
          expensesProvider('t1').overrideWith(
            (ref) => Stream.value(snap([testExpense(deleted: true)])),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Deleted by'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });
  });

  group('BalancesScreen', () {
    testWidgets('shows settlement states and plain-language balances', (
      tester,
    ) async {
      useTallView(tester);
      await pumpApp(
        tester,
        const BalancesScreen(tourId: 't1'),
        overrides: [
          ...common,
          expensesProvider(
            't1',
          ).overrideWith((ref) => Stream.value(snap([testExpense()]))),
          settlementsProvider('t1').overrideWith(
            (ref) => Stream.value(
              snap([
                testSettlement(SettlementStatus.pendingConfirmation),
                testSettlement(SettlementStatus.confirmed, id: 's2'),
                testSettlement(SettlementStatus.disputed, id: 's3'),
              ]),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.text('Awaiting confirmation'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Disputed'), findsOneWidget);
      expect(find.textContaining('Not paid'), findsOneWidget);
      // Alice paid 300 for 3; Bob's 100 is confirmed -> Alice receives 100.
      expect(find.textContaining('You should receive'), findsOneWidget);
      // Alice is the counterparty of Bob's pending payment.
      expect(find.text('Confirm'), findsWidgets);
    });
  });
}
