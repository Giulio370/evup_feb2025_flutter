// features/home/presentation/screens/home_screen.dart
import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EVUP Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authRepo.logout();
                context.go('/'); // Torna alla schermata di login
              } catch (e) {
                print('Errore di logout: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Errore durante il logout')),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Benvenuto in EVUP!',
              style: TextStyle(fontSize: 24),
            ),
            Consumer(
              builder: (context, ref, _) {
                return FutureBuilder(
                  future: ref.read(authRepositoryProvider).tokenManager.getRole(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'Ruolo: ${snapshot.data!.name.toUpperCase()}',
                        style: const TextStyle(fontSize: 18),
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}