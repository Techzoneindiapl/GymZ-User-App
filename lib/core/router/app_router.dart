import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/create_account_screen.dart';
import '../../features/auth/presentation/screens/fitness_pass_screen.dart';
import '../../features/gym_detail/presentation/screens/gym_detail_screen.dart';
import '../../features/home/domain/gym_model.dart';
import '../../features/location/presentation/screens/location_permission_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../widgets/user_shell_screen.dart';
import 'route_names.dart';

CustomTransitionPage<void> _slide({required GoRouterState state, required Widget child}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.onboarding,
  routes: [
    GoRoute(
      path: RoutePaths.onboarding,
      name: RouteNames.onboarding,
      pageBuilder: (context, state) => _slide(
        state: state,
        child: OnboardingScreen(
          onSkip: () => context.goNamed(RouteNames.auth),
          onGetStarted: () => context.goNamed(RouteNames.auth),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.auth,
      name: RouteNames.auth,
      pageBuilder: (context, state) => _slide(
        state: state,
        child: AuthScreen(
          onMobileNumber: () => context.goNamed(RouteNames.createAccount),
          onGoogle: () {},
          onApple: () {},
          onGuest: () => context.goNamed(RouteNames.locationPermission),
          onContinue: () => context.goNamed(RouteNames.createAccount),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.createAccount,
      name: RouteNames.createAccount,
      pageBuilder: (context, state) => _slide(
        state: state,
        child: CreateAccountScreen(
          onBack: () => context.pop(),
          onSubmit: () => context.goNamed(RouteNames.fitnessPass),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.fitnessPass,
      name: RouteNames.fitnessPass,
      pageBuilder: (context, state) => _slide(
        state: state,
        child: FitnessPassScreen(
          pass: FitnessPassData(
            fullName: 'Aasif Khan',
            gender: 'Male',
            passId: 'GZ-2026-08741',
            joinedAt: DateTime(2026, 6, 1),
          ),
          onContinue: () => context.goNamed(RouteNames.locationPermission),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.locationPermission,
      name: RouteNames.locationPermission,
      pageBuilder: (context, state) => _slide(
        state: state,
        child: LocationPermissionScreen(
          onAllowAccess: () => context.goNamed(RouteNames.home),
          onNotNow: () => context.goNamed(RouteNames.home),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      pageBuilder: (context, state) => _slide(state: state, child: const UserShellScreen()),
    ),
    GoRoute(
      path: RoutePaths.gymDetail,
      name: RouteNames.gymDetail,
      pageBuilder: (context, state) {
        final gym = state.extra as GymModel? ?? kSampleGyms.first;
        return _slide(
          state: state,
          child: GymDetailScreen(
            gym: gym,
            onBack: () => context.pop(),
            onShare: () {},
            onBookNow: () {},
          ),
        );
      },
    ),
  ],
);