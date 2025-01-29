// role_selector_screen.dart
import 'package:evup_feb2025_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sei un organizzatore o un utente?',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.push('/login', extra: UserRole.user),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text('Partecipo a eventi'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/login', extra: UserRole.organizer),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text('Organizzo eventi'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.push('/signup'),
              child: const Text('Non hai un account? Registrati'),
            ),
          ],
        ),
      ),
    );
  }
}