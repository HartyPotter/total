import 'dart:math' as math;
import 'package:total_flutter/features/task_management/domain/models/location_node.dart';

class PathFindingUtils {
  static Map<String, double> _calculateDistances(
    LocationNode startNode,
    Map<String, LocationNode> allNodes,
  ) {
    Map<String, double> distances = {};
    Map<String, bool> visited = {};
    Map<String, String?> previousNodes = {};

    // Initialize distances
    for (var nodeId in allNodes.keys) {
      distances[nodeId] = double.infinity;
      visited[nodeId] = false;
    }
    distances[startNode.id] = 0;

    while (true) {
      String? currentNodeId;
      double minDistance = double.infinity;

      // Find unvisited node with minimum distance
      for (var nodeId in allNodes.keys) {
        if (!visited[nodeId]! && distances[nodeId]! < minDistance) {
          currentNodeId = nodeId;
          minDistance = distances[nodeId]!;
        }
      }

      if (currentNodeId == null) break;

      visited[currentNodeId] = true;
      final currentNode = allNodes[currentNodeId]!;

      // Update distances to connected nodes
      for (var connectedNodeId in currentNode.connectedNodes) {
        if (!visited[connectedNodeId]!) {
          final connectedNode = allNodes[connectedNodeId]!;
          final distance = _calculateDistance(
            currentNode.latitude,
            currentNode.longitude,
            connectedNode.latitude,
            connectedNode.longitude,
          );
          final totalDistance = distances[currentNodeId]! + distance;

          if (totalDistance < distances[connectedNodeId]!) {
            distances[connectedNodeId] = totalDistance;
            previousNodes[connectedNodeId] = currentNodeId;
          }
        }
      }
    }

    return distances;
  }

  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Using Euclidean distance for simplicity
    // In a real application, you might want to use Haversine formula for actual GPS coordinates
    final dx = lat2 - lat1;
    final dy = lon2 - lon1;
    return math.sqrt(dx * dx + dy * dy);
  }

  static String? findNearestAvailableDriver(
    String sourceLocationId,
    List<Map<String, dynamic>> availableDriversWithLocations,
  ) {
    final allNodes = LocationNode.getNodesMap();
    final sourceNode = allNodes[sourceLocationId];

    if (sourceNode == null) return null;

    String? nearestDriverId;
    double shortestDistance = double.infinity;

    // Calculate distances from source to all nodes
    final distances = _calculateDistances(sourceNode, allNodes);

    // Find the driver with the shortest distance to source
    for (var driver in availableDriversWithLocations) {
      final driverId = driver['id'] as String;
      final driverLocation = driver['location'];
      print('driverId: $driverId');
      print('driverLocation: $driverLocation');

      if (driverLocation != null) {
        final distance = distances[driverLocation] ?? double.infinity;
        if (distance < shortestDistance) {
          shortestDistance = distance;
          nearestDriverId = driverId;
        }
      }
    }

    return nearestDriverId;
  }
}
