import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the list of locations with their names and coordinates
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
          initialCenter:
              LatLng(30.820321599306563, 29.547253161870877), // Center the map
          initialZoom: 18.0, // Zoom level for a closer view
        ),
        children: [
          // Thunderforest Satellite Tile Layer
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName:
                'com.example.app', // Replace with your app's package name
          ),

          // Marker Layer
          MarkerLayer(
            markers: locations.map((location) {
              return Marker(
                point: LatLng(
                    location['lat'], location['lng']), // Marker coordinates
                width: 80, // Marker width
                height: 80, // Marker height
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40.0,
                    ),
                    Text(
                      location['name'], // Display the location name
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
