// main.dart
import 'package:evup_feb2025_flutter/core/routes.dart';
import 'package:evup_feb2025_flutter/features/home/Presentation/screens/home_screen.dart';
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
      routerConfig: router, // Usa le route centralizzate
      debugShowCheckedModeBanner: false,
    );
  }
}

/*
enum UserRole { user, organizer }*/
