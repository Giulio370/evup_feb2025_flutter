// core/routes.dart
import 'package:evup_feb2025_flutter/core/utils/token_manager.dart';
import 'package:evup_feb2025_flutter/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:evup_feb2025_flutter/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:evup_feb2025_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:evup_feb2025_flutter/features/auth/presentation/screens/role_selector_screen.dart';
import 'package:evup_feb2025_flutter/features/auth/presentation/screens/signup_screen.dart';
import 'package:evup_feb2025_flutter/features/home/presentation/screens/home_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RoleSelectorScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final role = state.extra as UserRole;
        return LoginScreen(role: role);
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) {
        final role = state.extra as UserRole;
        return SignupScreen(role: role);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    // Altre Route
  ],
  redirect: (context, state) async {
    final tokenManager = TokenManager(storage: const FlutterSecureStorage());
    final isLoggedIn = await tokenManager.hasToken();

    if (isLoggedIn && (state.matchedLocation == '/' || state.matchedLocation == '/login')) {
      return '/home';
    }
    return null;
  },
);