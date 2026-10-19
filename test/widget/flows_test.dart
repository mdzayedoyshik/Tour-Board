import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tour_board/core/theme/app_theme.dart';
import 'package:tour_board/core/widgets/common.dart';
import 'package:tour_board/features/itinerary/data/plan_repository.dart';
import 'package:tour_board/features/itinerary/presentation/plan_form_screen.dart';
import 'package:tour_board/features/itinerary/presentation/plan_tab.dart';
import 'package:tour_board/features/map/data/map_provider.dart';
import 'package:tour_board/features/membership/data/membership_repository.dart';
import 'package:tour_board/features/membership/domain/invite_code.dart';
import 'package:tour_board/features/membership/domain/member.dart';
import 'package:tour_board/features/membership/presentation/join_screen.dart';
import 'package:tour_board/features/tours/data/tour_repository.dart';
import 'package:tour_board/features/tours/presentation/tour_form_screen.dart';

import '../helpers.dart';

class _MockMembership extends Mock implements MembershipRepository {}

void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('JoinScreen', () {
    testWidgets('invalid code shows an error without a network call', (
      tester,
    ) async {
      final repo = _MockMembership();
      await pumpApp(
        tester,
        const JoinScreen(),
        overrides: [membershipRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.tap(find.text('Find tour'));
      await tester.pump();
      expect(
        find.textContaining("doesn't look like an invite"),
        findsOneWidget,
      );
      verifyNever(() => repo.fetchInvite(any()));
    });

    testWidgets('expired invite is explained', (tester) async {
      final repo = _MockMembership();
      when(() => repo.fetchInvite('K7QM4XPT9C2B')).thenAnswer(
        (_) async => InvitePreview(
          code: 'K7QM4XPT9C2B',
          tourId: 't1',
          tourName: 'Trip',
          hostUid: 'host',
          hostName: 'Host',
          startAt: testTime,
          endAt: testTime,
          expiresAt: testTime.subtract(const Duration(days: 1)),
          revoked: false,
        ),
      );
      await pumpApp(
        tester,
        const JoinScreen(initialCode: 'k7qm-4xpt-9c2b'),
        overrides: [membershipRepositoryProvider.overrideWithValue(repo)],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('expired'), findsOneWidget);
      expect(find.text('Request to join'), findsNothing);
    });
  });

  group('TourFormScreen', () {
    testWidgets('create is disabled until name and dates are set', (
      tester,
    ) async {
      useTallView(tester);
      await pumpApp(tester, const TourFormScreen());
      await tester.pumpAndSettle();
      FilledButton create() => tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Create tour'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(create().onPressed, isNull);
      await tester.enterText(find.byType(TextFormField).first, 'Weekend');
      await tester.pump();
      // Dates still missing.
      expect(create().onPressed, isNull);
      expect(find.text('Dates'), findsOneWidget);
    });
  });

  group('Plan', () {
    final common = [
      tourProvider('t1').overrideWith((ref) => Stream.value(testTour())),
      membersProvider('t1').overrideWith((ref) => Stream.value(testMembers)),
      myMemberProvider('t1').overrideWith(
        (ref) => Stream.value(testMember('alice', MemberRole.member)),
      ),
      planItemsProvider('t1').overrideWith((ref) => Stream.value(snap([]))),
    ];

    testWidgets('empty itinerary lists trip days and an add action', (
      tester,
    ) async {
      useTallView(tester);
      await pumpApp(
        tester,
        Scaffold(body: PlanTab(tour: testTour())),
        overrides: common,
      );
      await tester.pumpAndSettle();
      expect(find.text('Nothing planned yet'), findsOneWidget);
      expect(find.textContaining('Day 1'), findsOneWidget);
      expect(find.textContaining('Day 4'), findsOneWidget);
      expect(find.text('Add plan'), findsOneWidget);
    });

    testWidgets('manual place entry works when search is unavailable', (
      tester,
    ) async {
      useTallView(tester);
      await pumpApp(
        tester,
        const PlanFormScreen(tourId: 't1'),
        overrides: [
          ...common,
          placeSearchProvider.overrideWithValue(DisabledPlaceSearch()),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Place search is turned off'), findsOneWidget);
      expect(find.text('Latitude'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Beach walk');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Latitude'),
        '200',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Longitude'),
        '92',
      );
      await tester.pump();
      expect(find.textContaining('Enter both latitude'), findsOneWidget);
    });
  });

  group('Design system', () {
    testWidgets('status pill carries text, not color alone', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: StatusPill(label: 'Pending', icon: Icons.schedule),
        ),
      );
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('dark theme uses the dark background token', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: SizedBox()),
        themeMode: ThemeMode.dark,
      );
      final scaffold = tester.element(find.byType(Scaffold));
      expect(
        Theme.of(scaffold).scaffoldBackgroundColor,
        AppColors.darkBackground,
      );
    });

    test('primary text meets WCAG AA contrast in both themes', () {
      double luminance(Color c) => c.computeLuminance();
      double ratio(Color a, Color b) {
        final l1 = luminance(a), l2 = luminance(b);
        final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
        return (hi + 0.05) / (lo + 0.05);
      }

      expect(
        ratio(AppColors.lightText, AppColors.lightBackground),
        greaterThan(4.5),
      );
      expect(
        ratio(AppColors.lightTextSecondary, AppColors.lightBackground),
        greaterThan(4.5),
      );
      expect(
        ratio(AppColors.darkText, AppColors.darkBackground),
        greaterThan(4.5),
      );
      expect(
        ratio(AppColors.darkTextSecondary, AppColors.darkBackground),
        greaterThan(4.5),
      );
    });
  });
}
