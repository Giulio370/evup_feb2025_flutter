
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';


import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';

final userEventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final eventRepo = ref.watch(eventRepositoryProvider);


  try {
    return await eventRepo.getEventsForUser();
  } catch (e) {
    throw Exception('Errore nel recupero degli eventi: $e');
  }
});


class OrganizerEventsScreen extends ConsumerWidget {
  const OrganizerEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(userEventsProvider);
    final eventRepo = ref.watch(eventRepositoryProvider);
    final authRepo = ref.watch(authRepositoryProvider);


    Future<void> _reloadEvents() async {
      ref.refresh(userEventsProvider);
    }


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



  Future<void> _showEventForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? event) async {
    final _formKey = GlobalKey<FormState>();
    final eventRepo = ref.read(eventRepositoryProvider);
    final picker = ImagePicker();


    Map<String, dynamic>? updatedEvent;
    if (event != null) {
      try {
        updatedEvent = await eventRepo.getEventBySlug(event['slug']);
      } catch (e) {
        print('Errore nel recupero dell\'evento: $e');
      }
    }

    final TextEditingController titleController = TextEditingController(text: updatedEvent?['title'] ?? '');
    final TextEditingController sbtitleController = TextEditingController(text: updatedEvent?['sbtitle'] ?? '');
    final TextEditingController addressController = TextEditingController(text: updatedEvent?['address'] ?? '');
    final TextEditingController guestController = TextEditingController(
        text: updatedEvent?['special_guest']?['name'] ?? ''
    );
    final TextEditingController descriptionController = TextEditingController(text: updatedEvent?['description'] ?? '');

    DateTime? timeStart = updatedEvent?['time_start'] != null ? DateTime.parse(updatedEvent!['time_start']) : null;
    DateTime? timeEnd = updatedEvent?['time_end'] != null ? DateTime.parse(updatedEvent!['time_end']) : null;

    File? selectedImage;
    String? imageUrl = updatedEvent?['picture_url'];

    Future<void> _pickImage() async {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        selectedImage = File(pickedFile.path);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 12,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  event == null ? 'Crea Evento' : 'Modifica Evento',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Sezione per l'immagine
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                      image: selectedImage != null
                          ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                          : imageUrl != null
                          ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedImage == null && imageUrl == null
                        ? const Center(child: Icon(Icons.camera_alt, size: 50, color: Colors.white))
                        : null,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Titolo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Campo obbligatorio' : null,
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: sbtitleController,
                  decoration: InputDecoration(
                    labelText: 'Sottotitolo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.subtitles),
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Indirizzo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: guestController,
                  decoration: InputDecoration(
                    labelText: 'Ospite Speciale',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descrizione',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 8),

                // Selezione Data e Ora
                ListTile(
                  title: Text(timeStart == null
                      ? "Scegli data e ora inizio"
                      : "Inizio: ${DateFormat('dd/MM/yyyy HH:mm').format(timeStart!)}"),
                  trailing: const Icon(Icons.access_time, color: Colors.blueAccent),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: timeStart ?? DateTime.now(),
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
                  title: Text(timeEnd == null
                      ? "Scegli data e ora fine"
                      : "Fine: ${DateFormat('dd/MM/yyyy HH:mm').format(timeEnd!)}"),
                  trailing: const Icon(Icons.access_time, color: Colors.redAccent),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: timeEnd ?? (timeStart ?? DateTime.now()).add(Duration(hours: 1)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: timeEnd != null
                            ? TimeOfDay.fromDateTime(timeEnd!)
                            : TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        timeEnd = DateTime(
                            pickedDate.year, pickedDate.month, pickedDate.day,
                            pickedTime.hour, pickedTime.minute
                        );
                      }
                    }
                  },
                ),

                // Bottoni Salva e Annulla
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text("Annulla", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (event == null) {
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
                          // Aggiorna lista eventi
                          ref.invalidate(userEventsProvider);

                          // Se l'utente ha selezionato una nuova immagine, caricala
                          if (selectedImage != null && event != null) {
                            await eventRepo.uploadEventImage(event['title'], selectedImage!);
                          }

                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Salva", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
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

                await eventRepo.deleteEvent(event["slug"]);

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

