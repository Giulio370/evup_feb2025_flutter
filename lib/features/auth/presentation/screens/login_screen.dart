// login_screen.dart
import 'package:dio/dio.dart';
import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';
import 'package:evup_feb2025_flutter/core/utils/token_manager.dart';
import 'package:evup_feb2025_flutter/features/auth/presentation/screens/role_selector_screen.dart';
import 'package:evup_feb2025_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:go_router/go_router.dart';


class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Inserisci una email valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password minimo 8 caratteri';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final authRepo = ref.watch(authRepositoryProvider);
                  return ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          final success = await authRepo.login(
                            _emailController.text,
                            _passwordController.text,
                          );

                          if (success) {
                            final role = await authRepo.tokenManager.getRole();

                            if (context.mounted) {
                              if (role == UserRole.admin || role == UserRole.organizer) {
                                context.go('/admin-dashboard');
                              } else {
                                context.go('/home');
                              }
                            }
                          }
                        } catch (e) {
                          print('Errore ricevuto: $e');

                          if (e.toString().contains("EMAIL_NOT_VERIFIED")) {
                            if (context.mounted) {
                              context.go('/');
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Devi verificare la tua email prima di accedere."),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: const Text('Login'),
                  );
                },
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Conferma'),
                        content: const Text('Sei sicuro di voler tornare alla selezione dei ruoli?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annulla'),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              return TextButton(
                                onPressed: () async {
                                  final authRepo = ref.read(authRepositoryProvider);
                                  await authRepo.logout();
                                  if (context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (context) => const RoleSelectorScreen()),
                                    );
                                  }
                                },
                                child: const Text('Conferma'),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text(
                  'Torna alla selezione dei ruoli',
                  style: TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }
}