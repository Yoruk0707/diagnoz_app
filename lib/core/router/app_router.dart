import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/phone_input_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/game/presentation/pages/game_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Route path sabitleri.
///
/// NEDEN: Typo riski → string yerine sabit kullan.
abstract class AppRoutes {
  // Auth flow
  static const splash = '/';
  static const authPhone = '/auth';
  static const authOtp = '/auth/otp';

  // Ana uygulama (authenticated)
  static const home = '/home';
  static const game = '/game';
  static const leaderboard = '/leaderboard';
  static const profile = '/profile';
}

/// Uygulama router yapılandırması.
///
/// NEDEN: Auth flow (splash → phone → otp) ve
/// ana uygulama (shell + bottom nav) ayrı route grupları.
/// Login olmadan ana ekranlara erişim yok — programmatic navigation ile.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    // ─────────────────────────────────────────────────────────
    // AUTH FLOW (bottom nav bar yok)
    // ─────────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SplashPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.authPhone,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: PhoneInputPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.authOtp,
      pageBuilder: (context, state) => const NoTransitionPage(
        child: OtpVerificationPage(),
      ),
    ),

    // ─────────────────────────────────────────────────────────
    // ANA UYGULAMA (bottom nav bar ile)
    // ─────────────────────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return _ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.game,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: GamePage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.leaderboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LeaderboardPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilePage(),
          ),
        ),
      ],
    ),
  ],
);

/// Alt navigation bar ile sarmalayan scaffold.
class _ScaffoldWithNavBar extends StatelessWidget {
  const _ScaffoldWithNavBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle_rounded),
            label: 'Oyna',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard_rounded),
            label: 'Sıralama',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.game)) return 1;
    if (location.startsWith(AppRoutes.leaderboard)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.game);
      case 2:
        context.go(AppRoutes.leaderboard);
      case 3:
        context.go(AppRoutes.profile);
    }
  }
}
