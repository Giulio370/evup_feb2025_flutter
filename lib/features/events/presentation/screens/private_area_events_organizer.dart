import 'package:evup_feb2025_flutter/features/events/presentation/screens/event_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:evup_feb2025_flutter/core/api/event_repository.dart';
import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';

final userEventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final eventRepo = ref.watch(eventRepositoryProvider);

  // Fetch the events from the event repository
  try {
    return await eventRepo.getEventsForUser(); // Assuming getEventsForUser fetches events
  } catch (e) {
    throw Exception('Errore nel recupero degli eventi: $e'); // Handle error
  }
});


class OrganizerEventsScreen extends ConsumerWidget {
  const OrganizerEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(userEventsProvider);
    final eventRepo = ref.watch(eventRepositoryProvider);
    final authRepo = ref.watch(authRepositoryProvider);

    // Ricarica gli eventi automaticamente all'apertura della pagina
    Future<void> _reloadEvents() async {
      ref.refresh(userEventsProvider);
    }

    // Chiamata automatica a _reloadEvents() quando la pagina entra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadEvents();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei Eventi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEventForm(context,ref, null),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Ricarica gli eventi
              ref.refresh(userEventsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authRepo.logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
        data: (events) => events.isEmpty
            ? const Center(child: Text('Nessun evento trovato'))
            : ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) => _EventCard(
            event: events[index],
            onEdit: () => _showEventForm(context, ref, events[index]),
            onDelete: () => _confirmDelete(context, eventRepo, events[index]),
          ),
        ),
      ),
    );
  }

  void _showEventForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? event) {
    final _formKey = GlobalKey<FormState>();
    final eventRepo = ref.read(eventRepositoryProvider);
    final TextEditingController titleController = TextEditingController(text: event?['title'] ?? '');
    final TextEditingController sbtitleController = TextEditingController(text: event?['sbtitle'] ?? '');
    final TextEditingController addressController = TextEditingController(text: event?['address'] ?? '');
    final TextEditingController guestController = TextEditingController(text: event?['special_guest'] ?? '');
    final TextEditingController descriptionController = TextEditingController(text: event?['description'] ?? '');
    List<String> tags = List<String>.from(event?['tags'] ?? []);
    DateTime? timeStart = event?['time_start'] != null ? DateTime.parse(event!['time_start']) : null;
    DateTime? timeEnd = event?['time_end'] != null ? DateTime.parse(event!['time_end']) : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event == null ? 'Crea Evento' : 'Modifica Evento'),
        content: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Titolo'),
                    validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
                  ),
                  TextFormField(
                    controller: sbtitleController,
                    decoration: InputDecoration(labelText: 'Sottotitolo'),
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: 'Indirizzo'),
                  ),
                  TextFormField(
                    controller: guestController,
                    decoration: InputDecoration(labelText: 'Ospite Speciale'),
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Descrizione'),
                    maxLines: 3,
                  ),
                  ListTile(
                    title: Text(timeStart == null ? "Scegli data e ora inizio" : "Inizio: ${DateFormat('dd/MM/yyyy HH:mm').format(timeStart!)}"),
                    trailing: Icon(Icons.access_time),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          timeStart = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        }
                      }
                    },
                  ),
                  ListTile(
                    title: Text(timeEnd == null ? "Scegli data e ora fine" : "Fine: ${DateFormat('dd/MM/yyyy HH:mm').format(timeEnd!)}"),
                    trailing: Icon(Icons.access_time),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: timeStart ?? DateTime.now(),
                        firstDate: timeStart ?? DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          timeEnd = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (event == null) {
                  print("NUOVOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO");
                  await eventRepo.createEvent(
                    title: titleController.text,
                    address: addressController.text,
                    timeStart: timeStart!,
                    timeEnd: timeEnd!,
                    description: descriptionController.text,
                  );
                } else {
                  await eventRepo.updateEvent(
                    eventSlug: event['slug'],
                    title: titleController.text,
                    address: addressController.text,
                    timeStart: timeStart!,
                    timeEnd: timeEnd!,
                    description: descriptionController.text,
                  );
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }


  Future<String?> _showTagDialog(BuildContext context) async {
    TextEditingController tagController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Aggiungi Tag"),
        content: TextField(
          controller: tagController,
          decoration: InputDecoration(labelText: "Tag"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annulla"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, tagController.text),
            child: Text("Aggiungi"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EventRepository eventRepo, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Eliminare "${event["title"]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              print("Dialogo chiuso");

              if (event["slug"] != null) {

                await eventRepo.deleteEvent(event["slug"]); // Passa lo slug

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento eliminato')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Errore: evento senza slug')),
                  );
                }
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}



class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: event["imageUrl"] != null
            ? Image.network(event["picture_url"], width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.event),
        title: Text(event["title"] ?? "Senza titolo"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(event["time_start"] != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(event["time_start"]))
                : 'Data non disponibile'),
            Text(event["description"] ?? ""),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

