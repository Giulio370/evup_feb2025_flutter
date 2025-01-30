// login_screen.dart
import 'package:dio/dio.dart';
import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';
import 'package:evup_feb2025_flutter/core/utils/token_manager.dart';
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
                      /*if (_formKey.currentState!.validate()) {
                        try {
                          final Dio dio = Dio(); // Crea un'istanza di Dio

                          print('Trying login with: ${_emailController.text}');
                          final response = await dio.post(
                            'https://api.evup.it/auth/login/email', // Assicurati di usare l'URL completo
                            data: {'email': _emailController.text, 'password': _passwordController.text},
                          );
                          print('Response status: ${response.statusCode}');
                          print('Response headers: ${response.headers}');
                          print('Response body: ${response.data}');

                          // ... resto del codice
                        } catch (e) {
                          print('Error details: $e');
                          // ... gestione errore
                        }
                      }*/
                      if (_formKey.currentState!.validate()) {
                        try {
                          final success = await authRepo.login(
                            _emailController.text,
                            _passwordController.text,
                          );

                          if (success) {
                            final role = await authRepo.tokenManager.getRole();

                            if (role == UserRole.admin || role == UserRole.organizer) {
                              context.go('/admin-dashboard');
                            } else {
                              context.go('/home');
                            }
                          }
                        } catch (e) {
                          print('Errore ricevuto: $e');

                          if (e.toString().contains("EMAIL_NOT_VERIFIED")) { // Modifica qui
                            if (mounted) {
                              context.go('/');
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Devi verificare la tua email prima di accedere."),
                                backgroundColor: Colors.orange,
                              ),
                            );

                            // Aggiungi un delay per permettere la visualizzazione dello SnackBar



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
            ],
          ),
        ),
      ),
    );
  }
}