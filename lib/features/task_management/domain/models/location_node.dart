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
    final connectedNodes = AppConstants.graphEdges[nodeId] ?? [];

    return LocationNode(
      id: nodeId,
      name: name,
      latitude: coordinates['lat'] ?? 0.0,
      longitude: coordinates['lng'] ?? 0.0,
      connectedNodes: connectedNodes,
    );
  }

  // Get all nodes as a list
  static List<LocationNode> getAllNodes() {
    return AppConstants.locationNodes.keys
        .map((nodeId) => LocationNode.fromId(nodeId))
        .toList();
  }

  // Get all nodes as a map (node ID -> LocationNode)
  static Map<String, LocationNode> getNodesMap() {
    return Map.fromEntries(
      AppConstants.locationNodes.keys.map(
        (nodeId) => MapEntry(nodeId, LocationNode.fromId(nodeId)),
      ),
    );
  }

  // Convert LocationNode to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'connectedNodes': connectedNodes,
    };
  }

  // Create LocationNode from JSON
  factory LocationNode.fromJson(Map<String, dynamic> json) {
    return LocationNode(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Location',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      connectedNodes: List<String>.from(json['connectedNodes'] ?? []),
    );
  }

  @override
  String toString() => name;

  String get displayName => name;
  String get node => id;
}
