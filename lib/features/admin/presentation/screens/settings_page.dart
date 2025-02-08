import 'package:evup_feb2025_flutter/core/models/bottom_navi_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';

class SettingsPage extends ConsumerStatefulWidget {
  final bool isAdmin;  // Se true, l'utente è un organizer

  const SettingsPage({Key? key, this.isAdmin = false}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true; // Default: notifiche attive
  bool _darkMode = false; // Default: tema chiaro

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Impostazioni"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Generali"),
          _buildSwitchTile(
            title: "Modalità Scura",
            subtitle: "Attiva o disattiva il tema scuro",
            value: _darkMode,
            onChanged: (val) {
              setState(() {
                _darkMode = val;
              });
            },
          ),
          _buildSwitchTile(
            title: "Notifiche",
            subtitle: "Abilita o disabilita le notifiche",
            value: _notificationsEnabled,
            onChanged: (val) {
              setState(() {
                _notificationsEnabled = val;
              });
            },
          ),
          _buildSectionTitle("Sicurezza"),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Cambia Password"),
            onTap: () => _changePassword(),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy e Sicurezza"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sezione Privacy in sviluppo")),
              );
            },
          ),
          _buildSectionTitle("Account"),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Esci"),
            onTap: () async {
              await authRepo.logout();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
          if (widget.isAdmin) ...[
            _buildSectionTitle("Amministrazione"),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Gestione Utenti"),
              onTap: () {
                context.push('/admin/users');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_applications),
              title: const Text("Impostazioni Avanzate"),
              onTap: () {
                context.push('/admin/settings');
              },
            ),
          ],
          _buildSectionTitle("Supporto"),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text("Centro Assistenza"),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Informazioni sull'App"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "EvUp",
                applicationVersion: "1.0.0",
                applicationLegalese: "© 2025 Giulio C.",
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: widget.isAdmin
          ? null
          : const MyBottomNavigationBar(currentIndex: 3), // Aggiunge la barra solo per utenti normali
    );

  }

  /// Mostra un titolo di sezione nella lista delle impostazioni
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Costruisce un interruttore con titolo e sottotitolo
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  /// Mostra un popup per il cambio password
  void _changePassword() {
    final TextEditingController passwordController = TextEditingController();
    final authRepo = ref.read(authRepositoryProvider);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Cambia Password"),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Nuova Password",
              hintText: "Inserisci la nuova password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () async {
                final newPassword = passwordController.text.trim();
                if (newPassword.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext); // Chiudi il popup

                try {
                  final success = await authRepo.changePassword(newPassword);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? "Password cambiata con successo!"
                          : "Errore: password non cambiata"),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Errore: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Conferma"),
            ),
          ],
        );
      },
    );
  }
}
