import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/achievements_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/map_select_screen.dart';
import '../screens/match_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ranking_screen.dart';
import '../screens/result_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tutorial_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/menu',
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: '/map-select',
        builder: (context, state) => const MapSelectScreen(),
      ),
      GoRoute(
        path: '/tutorial',
        builder: (context, state) => const TutorialScreen(),
      ),
      GoRoute(
        path: '/match',
        builder: (context, state) => const MatchScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/ranking',
        builder: (context, state) => const RankingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
