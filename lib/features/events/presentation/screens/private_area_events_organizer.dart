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
            onPressed: () => _showEventForm(context, null),
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
            onEdit: () => _showEventForm(context, events[index]),
            onDelete: () => _confirmDelete(context, eventRepo, events[index]),
          ),
        ),
      ),
    );
  }

  void _showEventForm(BuildContext context, Map<String, dynamic>? event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EventFormModal(event: event),
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
            ? Image.network(event["imageUrl"], width: 50, height: 50, fit: BoxFit.cover)
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

