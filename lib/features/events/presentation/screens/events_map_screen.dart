import 'package:evup_feb2025_flutter/core/models/bottom_navi_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:evup_feb2025_flutter/core/api/auth_repository.dart';

class EventsMapScreen extends ConsumerStatefulWidget {
  const EventsMapScreen({super.key});


  @override
  _EventsMapScreenState createState() => _EventsMapScreenState();
}

class _EventsMapScreenState extends ConsumerState<EventsMapScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _visibleEvents = [];



  final double _minChildSize = 0.15;
  final double _maxChildSize = 0.6;
  final DraggableScrollableController _draggableController =
  DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _loadEvents();


    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _updateVisibleEvents();
      }
    });
  }

  /// Carica gli eventi dall'API
  Future<void> _loadEvents() async {
    try {
      final eventRepo = ref.read(eventRepositoryProvider);
      final events = await eventRepo.getEventsNormalUser();

      if (mounted) {
        setState(() {
          _events = events.where((event) => event['coordinates'] != null).toList();
        });
      }
    } catch (e) {
      print("Errore nel caricamento degli eventi: $e");
    }
  }

  /// Controlla quali eventi sono visibili nella mappa
  void _updateVisibleEvents() {
    final LatLngBounds bounds = _mapController.camera.visibleBounds;
    setState(() {
      _visibleEvents = _events.where((event) {
        final lat = event['coordinates']['latitude'];
        final lng = event['coordinates']['longitude'];
        return bounds.contains(LatLng(lat, lng));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(46.066737, 11.150468),
              initialZoom: 12.0,
              onMapEvent: (event) {
                _updateVisibleEvents();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _events.map((event) {
                  final lat = event['coordinates']['latitude'];
                  final lng = event['coordinates']['longitude'];
                  return Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _updateVisibleEvents();
                        });
                      },
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),


          DraggableScrollableSheet(
            controller: _draggableController,
            initialChildSize: _minChildSize,
            minChildSize: _minChildSize,
            maxChildSize: _maxChildSize,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    GestureDetector(
                      onVerticalDragUpdate: (details) {
                        final screenHeight = MediaQuery.of(context).size.height;

                        final fractionDelta = details.primaryDelta! / screenHeight;


                        final newExtent = (_draggableController.size - fractionDelta)
                            .clamp(_minChildSize, _maxChildSize);

                        _draggableController.jumpTo(newExtent);
                      },
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    //const SizedBox(height: 10),


                    Expanded(
                      child: _visibleEvents.isEmpty
                          ? const Center(child: Text("Nessun evento visibile nella mappa."))
                          : ListView.builder(
                        controller: scrollController,
                        itemCount: _visibleEvents.length,
                        itemBuilder: (context, index) {
                          final event = _visibleEvents[index];
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[300],
                              ),
                              child: event['picture_url'] != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  event['picture_url'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : const Icon(Icons.event, size: 32, color: Colors.grey),
                            ),
                            title: Text(
                              event['title'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              event['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {},
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          );

                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const MyBottomNavigationBar(currentIndex: 1),
    );
  }
}