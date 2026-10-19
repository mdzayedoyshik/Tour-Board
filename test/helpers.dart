import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_board/app/providers.dart';
import 'package:tour_board/core/config/app_config.dart';
import 'package:tour_board/core/money/split.dart';
import 'package:tour_board/core/theme/app_theme.dart';
import 'package:tour_board/data/firebase/firestore_streams.dart';
import 'package:tour_board/features/expenses/domain/expense.dart';
import 'package:tour_board/features/membership/domain/member.dart';
import 'package:tour_board/features/settlements/domain/settlement.dart';
import 'package:tour_board/features/tours/domain/tour.dart';
import 'package:tour_board/l10n/gen/app_localizations.dart';

final testTime = DateTime.utc(2026, 3, 14, 10);

Tour testTour({
  TourStatus status = TourStatus.active,
  int? budget,
  TourSettings settings = const TourSettings(),
}) => Tour(
  id: 't1',
  name: 'Cox’s Bazar',
  hostUid: 'host',
  status: status,
  startAt: DateTime.utc(2026, 3, 13),
  endAt: DateTime.utc(2026, 3, 16),
  timeZone: 'Asia/Dhaka',
  currencyCode: 'BDT',
  budgetMinor: budget,
  inviteCode: 'K7QM4XPT9C2B',
  allMemberUids: const ['host', 'alice', 'bob'],
  settings: settings,
  createdAt: testTime,
  updatedAt: testTime,
);

Member testMember(
  String uid,
  MemberRole role, {
  MemberStatus status = MemberStatus.active,
  String? name,
}) => Member(
  uid: uid,
  displayName: name ?? uid[0].toUpperCase() + uid.substring(1),
  role: role,
  status: status,
  joinedAt: testTime,
);

final testMembers = [
  testMember('host', MemberRole.host),
  testMember('alice', MemberRole.member),
  testMember('bob', MemberRole.member),
];

Expense testExpense({
  String id = 'e1',
  int amount = 30000,
  String payer = 'alice',
  Map<String, int>? shares,
  int revisionCount = 0,
  bool deleted = false,
}) => Expense(
  id: id,
  title: 'Dinner',
  amountMinor: amount,
  currencyCode: 'BDT',
  payerUid: payer,
  shares: shares ?? {'alice': 10000, 'bob': 10000, 'host': 10000},
  splitMethod: SplitMethod.equal,
  category: ExpenseCategory.food,
  occurredAt: testTime,
  createdBy: payer,
  createdAt: testTime,
  updatedAt: testTime,
  revisionCount: revisionCount,
  deletedAt: deleted ? testTime : null,
  deletedBy: deleted ? payer : null,
);

Settlement testSettlement(SettlementStatus status, {String id = 's1'}) =>
    Settlement(
      id: id,
      fromUid: 'bob',
      toUid: 'alice',
      amountMinor: 10000,
      currencyCode: 'BDT',
      status: status,
      createdBy: 'bob',
      createdAt: testTime,
      updatedAt: testTime,
      disputeReason: status == SettlementStatus.disputed ? 'Not paid' : null,
    );

Snapshot<T> snap<T>(List<T> items, {bool fromCache = false}) =>
    Snapshot(items: items, fromCache: fromCache, hasPendingWrites: false);

/// Pumps [child] inside the app's theme and localizations with common
/// overrides. Firebase is never touched: feature providers are overridden.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  String? uid = 'alice',
  ThemeMode themeMode = ThemeMode.light,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromMap('test', const {}),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue(uid),
        clockProvider.overrideWithValue(() => testTime),
        ...overrides,
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump();
}
