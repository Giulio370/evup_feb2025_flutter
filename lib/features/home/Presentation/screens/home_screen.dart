import 'dart:math';

import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';
import 'package:evup_feb2025_flutter/core/models/bottom_navi_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final eventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final eventRepo = ref.read(eventRepositoryProvider);
  return await eventRepo.getEventsNormalUser();
});

String formatDate(String dateTime) {
  try {
    final parsedDate = DateTime.parse(dateTime).toLocal();
    return DateFormat('dd-MM-yyyy HH:mm').format(parsedDate);
  } catch (e) {
    return 'Data non disponibile';
  }
}
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EVUP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await authRepo.logout();
                context.go('/');
              } catch (e) {
                print('Errore di logout: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Errore durante il logout')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cerca eventi...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('Oggi'),
                _filterChip('Domani'),
                _filterChip('Questo Weekend'),
                _filterChip('Gratuiti'),
                _filterChip('Per Famiglie'),
              ],
            ),
          ),
          Expanded(
            child: eventsAsync.when(
              data: (events) => ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _eventCard(context, ref, events[index]);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Errore: $err')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MyBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _filterChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.blue.shade100,
      ),
    );
  }

  Widget _eventCard(BuildContext context, WidgetRef ref, Map<String, dynamic> event) {
    final random = Random();
    final imageUrls = [
      'https://i.pinimg.com/236x/86/e4/0e/86e40e92caeb09ed28e3edf0176e00ca.jpg',
      'https://i.pinimg.com/736x/d7/fb/c0/d7fbc0d42009bb8e145b98447bd8a807.jpg',
      'https://i.pinimg.com/736x/88/f0/fc/88f0fcd5fa63f65bb2ff50a522a360d4.jpg',
    ];

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: event['picture_url'] != null && event['picture_url'].isNotEmpty
            ? Image.network(event['picture_url'], width: 50, height: 50, fit: BoxFit.cover)
            : Image.network(imageUrls[random.nextInt(imageUrls.length)], width: 50, height: 50, fit: BoxFit.cover),
        title: Text(event['title'] ?? 'Senza titolo'),
        subtitle: Text(event['time_start'] != null
            ? '${formatDate(event['time_start'])}'
            : 'Evento in Allestimento'),
        trailing: IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {},
        ),
        onTap: () => _showEventDetails(context, ref, event['slug']),
      ),
    );
  }

  void _showEventDetails(BuildContext context, WidgetRef ref, String eventSlug) async {
    final eventRepo = ref.read(eventRepositoryProvider);
    final eventDetails = await eventRepo.getEventBySlug(eventSlug);

    final primaryColor = Theme.of(context).primaryColor;
    //final secondaryColor = Colors.grey.shade600;
    final backgroundColor = Theme.of(context).canvasColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                eventDetails['title'] ?? 'Senza titolo',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              eventDetails['picture_url'] != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(eventDetails['picture_url'], height: 250, fit: BoxFit.cover),
              )
                  : Container(height: 250, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              _infoRow(' Indirizzo:', eventDetails['address'], icon: Icons.location_on),
              _infoRow(' Ospite speciale:', eventDetails['special_guest']?['name'], icon: Icons.person),
              _infoRow(' Tag:', eventDetails['tags']?['name'], icon: Icons.tag),
              _infoRow(' Creato da:', eventDetails['created_by'], icon: Icons.account_circle),
              _infoRow(' Descrizione:', eventDetails['description'], icon: Icons.description),
              _infoRow(
                  ' Inizio:',
                  eventDetails['time_start'] != null
                      ? formatDate(eventDetails['time_start'])
                      : 'Non disponibile',
                  icon: Icons.calendar_today),
              _infoRow(
                  ' Fine:',
                  eventDetails['time_end'] != null
                      ? formatDate(eventDetails['time_end'])
                      : 'Non disponibile',
                  icon: Icons.calendar_today),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18, color: Colors.white),
                      backgroundColor: primaryColor,
                    ),
                    child: const Text('Partecipo'),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Segnala evento'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String? value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Allinea in alto
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
          ],
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: Alignment.topLeft, // Allinea a sinistra e in alto
              child: Text(value ?? 'Non disponibile', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }


}
