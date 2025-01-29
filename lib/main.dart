// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'core/api/auth_repository.dart';
import 'core/api/dio_client.dart';
import 'core/utils/token_manager.dart';
import 'features/auth/presentation/screens/role_selector_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'package:riverpod/riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

enum UserRole {
  admin,
  organizer,
  user
}

class MyApp extends ConsumerWidget {
  MyApp({super.key});

  final _router = GoRouter(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'EVUP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/*
enum UserRole { user, organizer }*/
