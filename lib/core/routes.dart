// core/routes.dart
import 'package:evup_feb2025_flutter/core/utils/token_manager.dart';
import 'package:evup_feb2025_flutter/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:evup_feb2025_flutter/features/admin/presentation/screens/settings_page.dart';
import 'package:evup_feb2025_flutter/features/events/presentation/screens/PlanPage.dart';
import 'package:evup_feb2025_flutter/features/events/presentation/screens/events_map_screen.dart';

import 'package:evup_feb2025_flutter/features/events/presentation/screens/private_area_events_organizer.dart';
import 'package:evup_feb2025_flutter/features/profile/presentation/screens/user_profile.dart';
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
        final role = state.extra is UserRole ? state.extra as UserRole : UserRole.user;
        return LoginScreen(role: role);
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/events',
      builder: (context, state) => const OrganizerEventsScreen(),
      redirect: (context, state) async {
        final tokenManager = TokenManager(storage: const FlutterSecureStorage());
        final role = await tokenManager.getRole();
        return (role == UserRole.admin || role == UserRole.organizer)
            ? null
            : '/home';
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfilePage(),
    ),
    GoRoute(
      path: '/admin/profile',
      builder: (context, state) => const ProfilePage(isAdmin: true),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),

    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const SettingsPage(isAdmin: true),
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) => const EventsMapScreen(),
    ),
    GoRoute(
      path: '/admin/plans',
      builder: (context, state) => const PlanPage(),
    ),
    //
  ],
    redirect: (context, state) async {
      final tokenManager = TokenManager(storage: const FlutterSecureStorage());
      final isLoggedIn = await tokenManager.hasToken();

      if (!isLoggedIn) {
        //Se l'utente non è loggato, lo manda al login
        if (state.matchedLocation != '/login' && state.matchedLocation != '/signup') {
          return '/login';
        }
        return null;
      }

      //Otteniamo il ruolo dell'utente
      final role = await tokenManager.getRole();

      //Se l'utente è un admin/organizer e sta provando ad accedere alla root, lo manda al dashboard
      if ((state.matchedLocation == '/' || state.matchedLocation == '/login') &&
          (role == UserRole.admin || role == UserRole.organizer)) {
        return '/admin-dashboard';
      }

      //Se è un utente normale e prova ad accedere a '/', lo manda alla home
      if ((state.matchedLocation == '/' || state.matchedLocation == '/login') &&
          role == UserRole.user) {
        return '/home';
      }

      //Se sta provando ad accedere a /profile o /admin/profile, viene lasciato stare
      if (state.matchedLocation == '/profile' || state.matchedLocation == '/admin/profile') {
        return null; // Non forziamo il redirect
      }

      return null;
    }


);
