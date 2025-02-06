import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';
import 'package:evup_feb2025_flutter/core/models/bottom_navi_bar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? userData;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Chiamata post-frame per essere sicuri che il context sia disponibile
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserData());
  }

  Future<void> _fetchUserData() async {
    try {
      final eventRepository = ref.read(eventRepositoryProvider);
      final data = await eventRepository.fetchUser();
      setState(() {
        userData = data;
        _descriptionController.text = data['description'] ?? '';
      });
    } catch (e) {
      print('Errore nel recupero utente: $e');
      // In caso di errore, mostrare un messaggio oppure gestire lo stato
      setState(() {
        userData = {'error': e.toString()};
      });
    }
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Implementa l'upload della nuova immagine
    }
  }

  Future<void> _changeDescription() async {
    final authRepo = ref.read(authRepositoryProvider);
    final newDescription = _descriptionController.text.trim();

    if (newDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La descrizione non può essere vuota'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      bool success = await authRepo.updateDescription(newDescription);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descrizione aggiornata con successo!'), backgroundColor: Colors.green),
        );
      } else {
        throw 'Errore sconosciuto';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
      );
    }
  }


  Future<void> _changePassword() async {
    final TextEditingController passwordController = TextEditingController();
    final authRepo = ref.read(authRepositoryProvider);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) { // Usiamo dialogContext locale per evitare problemi
        return AlertDialog(
          title: const Text('Cambia Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nuova Password',
              hintText: 'Inserisci la nuova password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Chiudiamo il dialogo con il contesto locale
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () async {
                final newPassword = passwordController.text.trim();
                if (newPassword.isEmpty) {
                  return;
                }

                print('🔹 Tentativo di cambio password...');

                Navigator.pop(dialogContext); // Chiudiamo il popup di inserimento

                try {
                  final success = await authRepo.changePassword(newPassword);
                  print('🔹 Risultato API cambio password: $success');

                  if (!mounted) return;

                  // ✅ Usiamo lo `ScaffoldMessenger` per garantire che il `context` sia valido
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(success ? Icons.check_circle : Icons.error, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(success
                              ? ' Password cambiata con successo!'
                              : ' Errore: password non cambiata'),
                        ],
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } catch (e) {
                  print('⚠️ Errore cambio password: $e');
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Text('❌ Si è verificato un errore nel cambio password.'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );
  }


  /// Converte una stringa data (ISO) in una data formattata, se possibile.
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final DateTime date = DateTime.parse(dateStr);
      return DateFormat.yMMMd().format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Ritorna una "textbox" di sola lettura per visualizzare il valore con label.
  Widget buildInfoTextField(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se c'è un errore, lo mostra in modo semplice
    if (userData != null && userData!.containsKey('error')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profilo')),
        body: Center(child: Text('Errore: ${userData!['error']}')),
        bottomNavigationBar: const MyBottomNavigationBar(currentIndex: 2),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con sfondo a gradiente e avatar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: userData!['picture'] != null &&
                            (userData!['picture'] as String).isNotEmpty
                            ? NetworkImage(userData!['picture'])
                            : NetworkImage('https://cdn-icons-png.flaticon.com/512/149/149071.png')
                        as ImageProvider,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _changeProfilePicture,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${userData!['firstName']} ${userData!['lastName']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userData!['email'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Card con informazioni personali e campi extra, se disponibili
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Informazioni personali',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24, thickness: 1),
                    // Sezione per modificare la descrizione
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Descrizione',
                        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campi informativi in "textbox" read-only
                    buildInfoTextField("Ruolo", userData!['role']?.toString() ?? ""),
                    buildInfoTextField("Ultimo accesso", formatDate(userData!['lastLogin'])),
                    buildInfoTextField("Stato", (userData!['isActive'] ?? false) ? "Attivo" : "Inattivo"),
                    buildInfoTextField("Verifica email", (userData!['emailVerified'] ?? false) ? "Verificato" : "Non verificato"),
                    buildInfoTextField("Piano", userData!['plan']?.toString() ?? ""),
                    buildInfoTextField("Data rinnovo", formatDate(userData!['dateRenew'])),
                    const SizedBox(height: 16),
                    // Pulsanti disposti uno sotto l'altro
                    ElevatedButton(
                      onPressed: _changeDescription,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Aggiorna descrizione'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Cambia password'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const MyBottomNavigationBar(currentIndex: 2),
    );
  }
}
