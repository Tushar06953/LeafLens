import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/plant.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../../ui/screens/onboarding/onboarding_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/scan/scan_screen.dart';
import '../../ui/screens/analyzing/analyzing_screen.dart';
import '../../ui/screens/result/result_screen.dart';
import '../../ui/screens/history/history_screen.dart';
import '../../ui/screens/encyclopedia/encyclopedia_screen.dart';
import '../../ui/screens/plant_detail/plant_detail_screen.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../constants/storage_keys.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const scan = '/scan';
  static const analyzing = '/analyzing';
  static const result = '/result';
  static const history = '/history';
  static const encyclopedia = '/encyclopedia';
  static const plantDetail = '/plant-detail';
  static const profile = '/profile';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool(StorageKeys.hasSeenOnboarding) ?? false;

      if (!hasSeenOnboarding && state.matchedLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        name: 'scan',
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.analyzing,
        name: 'analyzing',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AnalyzingScreen(
            images: extra['images'] as List<String>,
            mode: extra['mode'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.result,
        name: 'result',
        builder: (context, state) {
          final plant = state.extra as PlantModel;
          return ResultScreen(plant: plant);
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.encyclopedia,
        name: 'encyclopedia',
        builder: (context, state) => const EncyclopediaScreen(),
      ),
      GoRoute(
        path: AppRoutes.plantDetail,
        name: 'plantDetail',
        builder: (context, state) {
          final plant = state.extra as PlantModel;
          return PlantDetailScreen(plant: plant);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
