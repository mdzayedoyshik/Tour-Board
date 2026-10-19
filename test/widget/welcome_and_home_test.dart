import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tour_board/features/auth/data/auth_repository.dart';
import 'package:tour_board/features/auth/presentation/welcome_screen.dart';
import 'package:tour_board/features/home/presentation/home_screen.dart';
import 'package:tour_board/features/notifications/data/inbox_repository.dart';
import 'package:tour_board/features/tours/data/tour_repository.dart';
import 'package:tour_board/features/tours/domain/tour.dart';

import '../helpers.dart';

class _MockAuth extends Mock implements AuthRepository {}

void main() {
  group('WelcomeScreen', () {
    testWidgets('shows wordmark, tagline, single action and privacy note', (
      tester,
    ) async {
      await pumpApp(tester, const WelcomeScreen(), uid: null);
      expect(find.text('Tour Board'), findsOneWidget);
      expect(
        find.text('Plan together. Spend clearly. Travel better.'),
        findsOneWidget,
      );
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(
        find.text('Your tours are shared only with people who are members.'),
        findsOneWidget,
      );
    });

    testWidgets('shows progress while signing in and blocks duplicates', (
      tester,
    ) async {
      final auth = _MockAuth();
      final completer = Completer<Never>();
      when(auth.signInWithGoogle).thenAnswer((_) => completer.future);
      await pumpApp(
        tester,
        const WelcomeScreen(),
        uid: null,
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Button is disabled while loading: a second tap does nothing.
      await tester.tap(find.byType(FilledButton));
      verify(auth.signInWithGoogle).called(1);
      completer.completeError(const SignInException(SignInFailure.cancelled));
      await tester.pump();
    });

    testWidgets('shows a recoverable error on network failure', (tester) async {
      final auth = _MockAuth();
      when(
        auth.signInWithGoogle,
      ).thenThrow(const SignInException(SignInFailure.network));
      await pumpApp(
        tester,
        const WelcomeScreen(),
        uid: null,
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('cancelling sign-in shows no error', (tester) async {
      final auth = _MockAuth();
      when(
        auth.signInWithGoogle,
      ).thenThrow(const SignInException(SignInFailure.cancelled));
      await pumpApp(
        tester,
        const WelcomeScreen(),
        uid: null,
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
      );
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      expect(find.textContaining("Couldn't"), findsNothing);
    });
  });

  group('HomeScreen', () {
    testWidgets('empty state offers create and join', (tester) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        overrides: [
          myToursProvider.overrideWith((ref) => Stream.value(const [])),
          unreadInboxCountProvider.overrideWithValue(0),
        ],
      );
      await tester.pump();
      expect(find.text('No tours yet'), findsOneWidget);
      expect(find.text('Create tour'), findsOneWidget);
      expect(find.text('Join with a code'), findsOneWidget);
    });

    testWidgets('lists tours in sections with status and member count', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const HomeScreen(),
        overrides: [
          myToursProvider.overrideWith(
            (ref) => Stream.value([
              TourSummary(tour: testTour(), activeMemberCount: 3),
              TourSummary(
                tour: testTour(status: TourStatus.closed),
                activeMemberCount: 2,
              ),
            ]),
          ),
          unreadInboxCountProvider.overrideWithValue(2),
        ],
      );
      await tester.pump();
      expect(find.text('Active & upcoming'), findsOneWidget);
      expect(find.text('Recently closed'), findsOneWidget);
      expect(find.textContaining('3 members'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      // Inbox badge count.
      expect(find.text('2'), findsOneWidget);
    });
  });
}
