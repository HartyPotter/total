import 'package:total_flutter/core/constants/app_constants.dart';

class LocationNode {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> connectedNodes;

  LocationNode({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.connectedNodes,
  });

  factory LocationNode.fromId(String nodeId) {
    final name = AppConstants.locationNodes[nodeId] ?? 'Unknown Location';
    final coordinates =
        AppConstants.locationCoordinates[nodeId] ?? {'lat': 0.0, 'lng': 0.0};

    // Define the connected nodes for each location
    // This could be moved to AppConstants if the connections are static
    final Map<String, List<String>> nodeConnections = {
      'A': ['B', 'C'], // IBCs Storage Area connects to Warehouse and Decanting
      'B': [
        'A',
        'D',
        'F'
      ], // Warehouse connects to IBCs, Loading Bay, and Raw Materials
      'C': ['A', 'G', 'H'], // Decanting connects to IBCs and Production Lines
      'D': ['B', 'E'], // Loading Bay connects to Warehouse and Finished Goods
      'E': ['D', 'J'], // Finished Goods connects to Loading Bay and Packaging
      'F': [
        'B',
        'G'
      ], // Raw Materials connects to Warehouse and Production Line 1
      'G': [
        'C',
        'F',
        'I'
      ], // Production Line 1 connects to Decanting, Raw Materials, and QC
      'H': ['C', 'I'], // Production Line 2 connects to Decanting and QC
      'I': [
        'G',
        'H',
        'J'
      ], // Quality Control connects to Production Lines and Packaging
      'J': ['E', 'I'], // Packaging connects to Finished Goods and QC
    };

    return LocationNode(
      id: nodeId,
      name: name,
      latitude: coordinates['lat'] ?? 0.0,
      longitude: coordinates['lng'] ?? 0.0,
      connectedNodes: nodeConnections[nodeId] ?? [],
    );
  }

  static List<LocationNode> getAllNodes() {
    return AppConstants.locationNodes.keys
        .map((nodeId) => LocationNode.fromId(nodeId))
        .toList();
  }

  static Map<String, LocationNode> getNodesMap() {
    return Map.fromEntries(
      AppConstants.locationNodes.keys.map(
        (nodeId) => MapEntry(nodeId, LocationNode.fromId(nodeId)),
      ),
    );
  }

  @override
  String toString() => name;

  String get displayName => '$id: $name';
}
