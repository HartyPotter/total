import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math' as math;

// MapTiler API key
const String maptilerApiKey =
    "0bDGxkCxPAzfSOBEuF2b"; // Get your own key at https://www.maptiler.com/cloud/

// MapTiler styles
enum MapStyle {
  satellite,
  streets,
  basic,
  outdoor,
  topo,
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Map controller
  final MapController _mapController = MapController();

  // Current map style
  MapStyle _currentMapStyle = MapStyle.basic;

  // Show/hide location markers
  bool _showLocationMarkers = true;

  // List to store driver locations
  List<Map<String, dynamic>> drivers = [];

  // List to store tasks for display
  List<Map<String, dynamic>> tasks = [];

  // Selected driver for tracking
  String? _selectedDriverId;

  // Current zoom level
  double _currentZoom = 18.0;

  // Current rotation
  double _currentRotation = 0.0;

  // Timer for continuous rotation updates
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    // Listen for real-time updates from Firestore
    _listenToDrivers();
    _listenToTasks();

    // Start continuous rotation monitoring
    _startRotationMonitoring();
  }

  void _startRotationMonitoring() {
    // Cancel any existing timer
    _rotationTimer?.cancel();

    // Create a timer that updates rotation very frequently
    _rotationTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (mounted && _mapController.camera.rotation != _currentRotation) {
        setState(() {
          _currentRotation = _mapController.camera.rotation;
        });
      }
    });

    // Also listen for specific map events
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventRotateStart ||
          event is MapEventRotate ||
          event is MapEventRotateEnd) {
        if (mounted) {
          setState(() {
            _currentRotation = _mapController.camera.rotation;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  // Function to listen for driver location updates
  void _listenToDrivers() {
    _firestore.collection('drivers').snapshots().listen((snapshot) {
      setState(() {
        drivers = snapshot.docs.map((doc) {
          final data = doc.data();
          // Handle possible null or missing currentLocation
          if (data['currentLocation'] == null) {
            return {
              'id': doc.id,
              'name': data['name'],
              'lat': 0.0, // Default value
              'lng': 0.0, // Default value
              'hasLocation': false,
            };
          }

          // Format name as first initial + last name
          final String fullName = data['name'] ?? '';
          final List<String> nameParts = fullName.split(' ');
          String formattedName = fullName;

          if (nameParts.length > 1) {
            final String firstName = nameParts[0];
            final String lastName = nameParts.last;
            formattedName =
                firstName.isNotEmpty ? '${firstName[0]}. $lastName' : lastName;
          }

          return {
            'id': doc.id,
            'name': formattedName,
            'fullName': data['name'],
            'lat': data['currentLocation'].latitude,
            'lng': data['currentLocation'].longitude,
            'hasLocation': true,
          };
        }).toList();

        // If we're tracking a driver, center the map on their location
        if (_selectedDriverId != null) {
          final selectedDriver = drivers.firstWhere(
            (driver) => driver['id'] == _selectedDriverId,
            orElse: () => {'hasLocation': false},
          );

          if (selectedDriver['hasLocation'] == true) {
            _mapController.move(
              LatLng(selectedDriver['lat'], selectedDriver['lng']),
              _currentZoom,
            );
          }
        }
      });
    });
  }

  // Function to listen for task updates
  void _listenToTasks() {
    _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'assigned')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        tasks = snapshot.docs
            .map((doc) {
              final data = doc.data();
              // Only include tasks with source and destination
              if (data['source'] == null || data['destination'] == null) {
                return {'hasLocation': false};
              }

              return {
                'id': doc.id,
                'name': data['name'] ?? 'Unnamed Task',
                'source': data['source'],
                'destination': data['destination'],
                'hasLocation': true,
              };
            })
            .where((task) => task['hasLocation'] == true)
            .toList();
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
        title: Text('Facility Map - ${_getStyleName(_currentMapStyle)}'),
        actions: [
          // Button to toggle location markers
          IconButton(
            icon:
                Icon(_showLocationMarkers ? Icons.place : Icons.place_outlined),
            tooltip: _showLocationMarkers ? 'Hide Locations' : 'Show Locations',
            onPressed: () {
              setState(() {
                _showLocationMarkers = !_showLocationMarkers;
              });
            },
          ),
          // Map style selector
          PopupMenuButton<MapStyle>(
            icon: const Icon(Icons.layers),
            tooltip: 'Change Map Style',
            onSelected: (MapStyle style) {
              setState(() {
                _currentMapStyle = style;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MapStyle>>[
              const PopupMenuItem<MapStyle>(
                value: MapStyle.basic,
                child: Text('Basic'),
              ),
              const PopupMenuItem<MapStyle>(
                value: MapStyle.streets,
                child: Text('Streets'),
              ),
              const PopupMenuItem<MapStyle>(
                value: MapStyle.satellite,
                child: Text('Satellite'),
              ),
              const PopupMenuItem<MapStyle>(
                value: MapStyle.outdoor,
                child: Text('Outdoor'),
              ),
              const PopupMenuItem<MapStyle>(
                value: MapStyle.topo,
                child: Text('Topographic'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(30.820321599306563, 29.547253161870877),
              initialZoom: 18.0,
              onMapEvent: (MapEvent mapEvent) {
                if (mapEvent is MapEventMoveEnd) {
                  setState(() {
                    _currentZoom = mapEvent.camera.zoom;
                  });
                }
              },
              backgroundColor: _currentMapStyle == MapStyle.satellite
                  ? Colors.black
                  : Colors.white,
            ),
            children: [
              // Map Layer using MapTiler
              TileLayer(
                urlTemplate: _getUrlTemplate(_currentMapStyle),
                // Add attribution as required by MapTiler's terms of service
                additionalOptions: {
                  'attribution': '© MapTiler © OpenStreetMap contributors',
                },
                userAgentPackageName: 'com.example.app',
                // Add border to tiles for non-satellite maps
                tileBuilder: (context, widget, tile) {
                  return Container(
                    decoration: BoxDecoration(
                      border: _currentMapStyle == MapStyle.satellite
                          ? null
                          : Border.all(
                              color: Colors.black12,
                              width: 0.5,
                            ),
                    ),
                    child: widget,
                  );
                },
              ),

              // Task paths (only shown if tasks exist)
              if (tasks.isNotEmpty)
                PolylineLayer(
                  polylines: tasks.map((task) {
                    // Find source and destination locations
                    final sourceLocation = locations.firstWhere(
                      (loc) => loc['name'] == task['source'],
                      orElse: () => {'lat': 0.0, 'lng': 0.0},
                    );

                    final destLocation = locations.firstWhere(
                      (loc) => loc['name'] == task['destination'],
                      orElse: () => {'lat': 0.0, 'lng': 0.0},
                    );

                    if (sourceLocation['lat'] == 0.0 ||
                        destLocation['lat'] == 0.0) {
                      return Polyline(
                        points: [],
                        strokeWidth: 3,
                        color: Colors.orange.withOpacity(0.7),
                      );
                    }

                    return Polyline(
                      points: [
                        LatLng(sourceLocation['lat'], sourceLocation['lng']),
                        LatLng(destLocation['lat'], destLocation['lng']),
                      ],
                      strokeWidth: 3,
                      color: Colors.orange.withOpacity(0.7),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    );
                  }).toList(),
                ),

              // Static Location Markers with better visualization and rotation compensation
              if (_showLocationMarkers)
                MarkerLayer(
                  markers: _buildLocationMarkers(locations),
                ),

              // Real-Time Driver Markers with rotation compensation
              MarkerLayer(
                markers: _buildDriverMarkers(),
              ),
            ],
          ),

          // Map controls overlay
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapButton(
                  icon: Icons.add,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _currentZoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.remove,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _currentZoom - 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.refresh,
                  onPressed: () {
                    _mapController.rotate(0); // Reset rotation
                  },
                ),
                const SizedBox(height: 8),
                _buildMapButton(
                  icon: Icons.my_location,
                  onPressed: () {
                    _centerOnInitialLocation();
                  },
                ),
              ],
            ),
          ),

          // Map info overlay
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rotation: ${_currentRotation.toStringAsFixed(1)}°',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    'Zoom: ${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Attribution overlay (required by MapTiler ToS)
          Positioned(
            left: 8,
            bottom: drivers.isNotEmpty ? 90 : 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© MapTiler © OpenStreetMap contributors',
                style: TextStyle(color: Colors.black54, fontSize: 10),
              ),
            ),
          ),

          // Driver tracking controls
          if (drivers.isNotEmpty)
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Track Driver:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('None'),
                                selected: _selectedDriverId == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _selectedDriverId = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            ...drivers.map((driver) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  avatar: const Icon(Icons.local_shipping,
                                      size: 18),
                                  label: Text(driver['name']),
                                  selected: _selectedDriverId == driver['id'],
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedDriverId = driver['id'];
                                      });
                                      if (driver['hasLocation'] == true) {
                                        _mapController.move(
                                          LatLng(driver['lat'], driver['lng']),
                                          _currentZoom,
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method to build location markers with current rotation
  List<Marker> _buildLocationMarkers(List<Map<String, dynamic>> locations) {
    return locations.map((location) {
      return Marker(
        point: LatLng(location['lat'], location['lng']),
        width: 120,
        height: 40,
        rotate: false, // Disable built-in rotation
        child: Transform.rotate(
          angle: -_currentRotation *
              (math.pi / 180.0), // Convert to radians and negate
          alignment: Alignment.center,
          child: Tooltip(
            message: location['name'],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      location['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // Helper method to build driver markers with current rotation
  List<Marker> _buildDriverMarkers() {
    return drivers
        .where((driver) => driver['hasLocation'] == true)
        .map((driver) {
      final isSelected = driver['id'] == _selectedDriverId;
      return Marker(
        point: LatLng(driver['lat'], driver['lng']),
        width: 60,
        height: 70,
        rotate: false, // Disable built-in rotation
        child: Transform.rotate(
          angle: -_currentRotation *
              (math.pi / 180.0), // Convert to radians and negate
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDriverId = driver['id'];
              });
              _showDriverInfo(driver);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.amber.withOpacity(0.7)
                        : Colors.green.withOpacity(0.7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Colors.amber.withOpacity(0.5)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: isSelected ? 10 : 5,
                        spreadRadius: isSelected ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/forklift.png',
                    width: 24,
                    height: 24,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    driver['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  void _centerOnInitialLocation() {
    _mapController.move(
      LatLng(30.820321599306563, 29.547253161870877),
      18.0,
    );
  }

  void _showDriverInfo(Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/forklift.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['fullName'] ?? driver['name'],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Driver ID: ${driver['id']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Current Location'),
                subtitle: Text(
                  'Lat: ${driver['lat'].toStringAsFixed(6)}, Lng: ${driver['lng'].toStringAsFixed(6)}',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _mapController.move(
                    LatLng(driver['lat'], driver['lng']),
                    19.0, // Zoom in a bit more to see details
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Center on this Driver'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Get URL template based on map style
  String _getUrlTemplate(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$maptilerApiKey';
      case MapStyle.streets:
        return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$maptilerApiKey';
      case MapStyle.basic:
        return 'https://api.maptiler.com/maps/basic-v2/{z}/{x}/{y}.png?key=$maptilerApiKey';
      case MapStyle.outdoor:
        return 'https://api.maptiler.com/maps/outdoor-v2/{z}/{x}/{y}.png?key=$maptilerApiKey';
      case MapStyle.topo:
        return 'https://api.maptiler.com/maps/topo-v2/{z}/{x}/{y}.png?key=$maptilerApiKey';
    }
  }

  // Get display name for map style
  String _getStyleName(MapStyle style) {
    switch (style) {
      case MapStyle.satellite:
        return 'Satellite';
      case MapStyle.streets:
        return 'Streets';
      case MapStyle.basic:
        return 'Basic';
      case MapStyle.outdoor:
        return 'Outdoor';
      case MapStyle.topo:
        return 'Topographic';
    }
  }
}
