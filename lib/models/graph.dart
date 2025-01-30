import 'package:collection/collection.dart';

class WarehouseGraph {
  final Map<String, Map<String, double>> _graph = {};

  void addLocation(String location) {
    if (!_graph.containsKey(location)) {
      _graph[location] = {};
    }
  }

  void addPath(String from, String to, double distance) {
    if (_graph.containsKey(from) && _graph.containsKey(to)) {
      _graph[from]![to] = distance;
    }
  }

  Map<String, double> getPaths(String location) {
    return _graph[location] ?? {};
  }

  // Dijkstra's algorithm to find the shortest path
  Map<String, double> dijkstra(String start) {
    final distances = <String, double>{};
    final visited = <String>{};
    final priorityQueue = PriorityQueue<MapEntry<String, double>>(
      (a, b) => a.value.compareTo(b.value),
    );

    distances[start] = 0;
    priorityQueue.add(MapEntry(start, 0));

    while (priorityQueue.isNotEmpty) {
      final current = priorityQueue.removeFirst();
      final currentLocation = current.key;
      final currentDistance = current.value;

      if (visited.contains(currentLocation)) continue;
      visited.add(currentLocation);

      for (final neighbor in _graph[currentLocation]!.entries) {
        final newDistance = currentDistance + neighbor.value;
        if (!distances.containsKey(neighbor.key) ||
            newDistance < distances[neighbor.key]!) {
          distances[neighbor.key] = newDistance;
          priorityQueue.add(MapEntry(neighbor.key, newDistance));
        }
      }
    }

    return distances;
  }
}

final warehouseGraph = WarehouseGraph();

void initializeWarehouseGraph() {
  warehouseGraph.addLocation('A');
  warehouseGraph.addLocation('B');
  warehouseGraph.addLocation('C');
  warehouseGraph.addLocation('D');

  warehouseGraph.addPath('A', 'B', 10);
  warehouseGraph.addPath('B', 'C', 5);
  warehouseGraph.addPath('C', 'D', 8);
  warehouseGraph.addPath('A', 'D', 20);
}
