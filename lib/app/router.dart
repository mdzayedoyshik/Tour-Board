import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_logo.dart';
import '../features/activity_feed/presentation/activity_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/expenses/presentation/expense_detail_screen.dart';
import '../features/expenses/presentation/expense_form_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/itinerary/presentation/plan_form_screen.dart';
import '../features/membership/presentation/join_screen.dart';
import '../features/membership/presentation/members_screen.dart';
import '../features/notes/presentation/notes_screen.dart';
import '../features/notifications/presentation/inbox_screen.dart';
import '../features/packing_list/presentation/packing_screen.dart';
import '../features/settings/presentation/diagnostics_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settlements/presentation/balances_screen.dart';
import '../features/settlements/presentation/settlement_form_screen.dart';
import '../features/tours/presentation/tour_form_screen.dart';
import '../features/tours/presentation/tour_settings_screen.dart';
import '../features/tours/presentation/tour_shell.dart';
import 'providers.dart';
import 'routes.dart';

/// Invite code received (deep link) before the user signed in; consumed
/// after sign-in so the join flow continues.
class PendingInvite extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? code) => state = code;
}

final pendingInviteProvider = NotifierProvider<PendingInvite, String?>(
  PendingInvite.new,
);

/// Bridges Riverpod auth state to go_router's refresh mechanism.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(pendingInviteProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final location = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue) {
        return location == Routes.splash ? null : Routes.splash;
      }
      final signedIn = auth.value != null;
      final pending = ref.read(pendingInviteProvider);

      if (!signedIn) {
        // Remember an invite so it survives the sign-in step.
        if (location == Routes.join) {
          final code = state.uri.queryParameters['code'];
          if (code != null) {
            Future.microtask(
              () => ref.read(pendingInviteProvider.notifier).set(code),
            );
          }
        }
        return location == Routes.welcome ? null : Routes.welcome;
      }
      if (location == Routes.welcome || location == Routes.splash) {
        if (pending != null) {
          Future.microtask(
            () => ref.read(pendingInviteProvider.notifier).set(null),
          );
          return Routes.joinWithCode(pending);
        }
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _Splash()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: Routes.createTour,
        builder: (_, _) => const TourFormScreen(),
      ),
      GoRoute(
        path: Routes.join,
        builder: (_, state) =>
            JoinScreen(initialCode: state.uri.queryParameters['code']),
      ),
      GoRoute(path: Routes.inbox, builder: (_, _) => const InboxScreen()),
      GoRoute(
        path: Routes.settings,
        builder: (_, _) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'diagnostics',
            builder: (_, _) => const DiagnosticsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/tour/:tourId',
        builder: (_, state) => TourShell(
          tourId: state.pathParameters['tourId']!,
          initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) =>
                TourFormScreen(tourId: state.pathParameters['tourId']),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, state) =>
                TourSettingsScreen(tourId: state.pathParameters['tourId']!),
          ),
          GoRoute(
            path: 'members',
            builder: (_, state) =>
                MembersScreen(tourId: state.pathParameters['tourId']!),
          ),
          GoRoute(
            path: 'expenses/new',
            builder: (_, state) =>
                ExpenseFormScreen(tourId: state.pathParameters['tourId']!),
          ),
          GoRoute(
            path: 'expenses/:expenseId',
            builder: (_, state) => ExpenseDetailScreen(
              tourId: state.pathParameters['tourId']!,
              expenseId: state.pathParameters['expenseId']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) => ExpenseFormScreen(
                  tourId: state.pathParameters['tourId']!,
                  expenseId: state.pathParameters['expenseId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'balances',
            builder: (_, state) =>
                BalancesScreen(tourId: state.pathParameters['tourId']!),
          ),
          GoRoute(
            path: 'settle',
            builder: (_, state) {
              final q = state.uri.queryParameters;
              return SettlementFormScreen(
                tourId: state.pathParameters['tourId']!,
                fromUid: q['from'],
                toUid: q['to'],
                amountMinor: int.tryParse(q['amount'] ?? ''),
                currencyCode: q['currency'],
              );
            },
          ),
          GoRoute(
            path: 'plan/new',
            builder: (_, state) => PlanFormScreen(
              tourId: state.pathParameters['tourId']!,
              initialDay: state.uri.queryParameters['day'],
            ),
          ),
          GoRoute(
            path: 'plan/:planId/edit',
            builder: (_, state) => PlanFormScreen(
              tourId: state.pathParameters['tourId']!,
              planId: state.pathParameters['planId'],
            ),
          ),
          GoRoute(
            path: 'notes',
            builder: (_, state) =>
                NotesScreen(tourId: state.pathParameters['tourId']!),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) =>
                    NoteEditorScreen(tourId: state.pathParameters['tourId']!),
              ),
              GoRoute(
                path: ':noteId',
                builder: (_, state) => NoteDetailScreen(
                  tourId: state.pathParameters['tourId']!,
                  noteId: state.pathParameters['noteId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'packing',
            builder: (_, state) =>
                PackingScreen(tourId: state.pathParameters['tourId']!),
          ),
          GoRoute(
            path: 'activity',
            builder: (_, state) =>
                ActivityScreen(tourId: state.pathParameters['tourId']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: AppLogo(size: 96)));
}
