import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:total_flutter/core/theme/app_theme.dart';
import 'package:total_flutter/features/driver/data/driver_provider.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';

class MapWidget extends ConsumerStatefulWidget {
  final (double, double) sourceLocation; // Tuple for source location
  final (double, double) destinationLocation; // Tuple for destination location
  final String taskId;
  final String? driverId;

  const MapWidget({
    super.key,
    required this.sourceLocation,
    required this.destinationLocation,
    required this.taskId,
    this.driverId,
  });

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Extract latitude and longitude from the source and destination tuples
    final sourceLatLng =
        LatLng(widget.sourceLocation.$1, widget.sourceLocation.$2);
    final destLatLng =
        LatLng(widget.destinationLocation.$1, widget.destinationLocation.$2);

    // Add markers for source and destination
    _markers.add(
      Marker(
        point: sourceLatLng,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_pin,
          color: Colors.blue,
          size: 40,
        ),
      ),
    );

    _markers.add(
      Marker(
        point: destLatLng,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40,
        ),
      ),
    );

    // Add a polyline between source and destination
    _polylines.add(
      Polyline(
        points: [sourceLatLng, destLatLng],
        color: Colors.blue,
        strokeWidth: 4,
      ),
    );

    // Fit the map to show all markers and the route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([sourceLatLng, destLatLng]),
          padding: const EdgeInsets.all(50),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // If driverId is provided, get driver data from provider
    Driver? driver;
    if (widget.driverId != null) {
      final driverState = ref.watch(driverProvider);

      if (driverState.driver?.id == widget.driverId) {
        driver = driverState.driver;
      } else {
        // For tasks assigned to a different driver, the cache in supervisor provider would be used
        // This is handled in the TaskDetailScreen
      }

      // Add driver marker if location is available
      if (driver?.currentLocation != null) {
        final driverLatLng = LatLng(
          driver!.currentLocation!.latitude,
          driver.currentLocation!.longitude,
        );

        // Remove existing driver marker if any
        _markers.removeWhere((marker) =>
            marker.child is Icon &&
            (marker.child as Icon).color == Colors.green);

        // Add new driver marker
        _markers.add(
          Marker(
            point: driverLatLng,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.directions_car,
              color: Colors.green,
              size: 40,
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        // OpenStreetMap
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(widget.sourceLocation.$1,
                widget.sourceLocation.$2), // Initial map position
            initialZoom: 10,
            onMapReady: () {
              // Fit the map after it's ready
              _initializeMap();
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
              // subdomains: const ['a', 'b', 'c'],
            ),
            PolylineLayer(polylines: _polylines),
            MarkerLayer(markers: _markers),
          ],
        ),

        // Information overlay
        Positioned(
          left: AppTheme.spacingM,
          right: AppTheme.spacingM,
          bottom: AppTheme.spacingM,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color?.withOpacity(0.9),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Route',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        'Source: (${widget.sourceLocation.$1}, ${widget.sourceLocation.$2}) → Destination: (${widget.destinationLocation.$1}, ${widget.destinationLocation.$2})',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (driver != null) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Expanded(
                        child: Text(
                          'Driver is on route',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
