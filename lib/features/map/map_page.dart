import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List to store driver locations
  List<Map<String, dynamic>> drivers = [];

  @override
  void initState() {
    super.initState();
    // Listen for real-time updates from Firestore
    _listenToDrivers();
  }

  // Function to listen for driver location updates
  void _listenToDrivers() {
    _firestore.collection('drivers').snapshots().listen((snapshot) {
      setState(() {
        drivers = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'],
            'lat': data['currentLocation'].latitude,
            'lng': data['currentLocation'].longitude,
          };
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define the list of static locations
    final List<Map<String, dynamic>> locations = [
      {'name': 'IBCs Storage Area', 'lat': 30.819784, 'lng': 29.547249},
      {'name': 'Dispatching Dock', 'lat': 30.820240, 'lng': 29.546624},
      {'name': 'FP Drums WH', 'lat': 30.820446, 'lng': 29.546686},
      {'name': 'Empty Packs WH', 'lat': 30.820607, 'lng': 29.546889},
      {'name': 'Decanting', 'lat': 30.820685, 'lng': 29.546982},
      {'name': 'Production', 'lat': 30.820765, 'lng': 29.547137},
      {'name': 'Empty Drums WH', 'lat': 30.820920, 'lng': 29.547189},
      {'name': 'FP WH', 'lat': 30.820392, 'lng': 29.547330},
      {'name': 'Old Dock', 'lat': 30.820504, 'lng': 29.547709},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forklift Locations - Satellite View'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(30.820321599306563, 29.547253161870877),
          initialZoom: 18.0,
        ),
        children: [
          // Satellite Tile Layer
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.example.app',
          ),

          // Static Location Markers
          MarkerLayer(
            markers: locations.map((location) {
              return Marker(
                point: LatLng(location['lat'], location['lng']),
                width: 80,
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40.0,
                    ),
                    Text(
                      location['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Real-Time Driver Markers
          MarkerLayer(
            markers: drivers.map((driver) {
              return Marker(
                point: LatLng(driver['lat'], driver['lng']),
                width: 80,
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/forklift.png', // Forklift sprite image
                      width: 40,
                      height: 40,
                    ),
                    Text(
                      driver['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
