import 'package:flutter/material.dart';
import 'package:total_flutter/forms/task_form.dart';
import 'package:total_flutter/models/task.dart';
import 'package:total_flutter/models/driver.dart';
import 'package:total_flutter/models/graph.dart';
import 'package:total_flutter/services/firebase_service.dart';

class TaskAssignmentScreen extends StatefulWidget {
  const TaskAssignmentScreen({super.key});

  @override
  _TaskAssignmentScreenState createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final WarehouseGraph warehouseGraph = WarehouseGraph();

  @override
  void initState() {
    super.initState();
    _initializeWarehouseGraph();
  }

  void _initializeWarehouseGraph() {
    warehouseGraph.addLocation('A');
    warehouseGraph.addLocation('B');
    warehouseGraph.addLocation('C');
    warehouseGraph.addLocation('D');

    warehouseGraph.addPath('A', 'B', 10);
    warehouseGraph.addPath('B', 'A', 10);
    warehouseGraph.addPath('B', 'C', 5);
    warehouseGraph.addPath('C', 'B', 5);
    warehouseGraph.addPath('C', 'D', 8);
    warehouseGraph.addPath('D', 'C', 8);
    warehouseGraph.addPath('A', 'D', 20);
    warehouseGraph.addPath('D', 'A', 20);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Assignment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Valid locations are: A, B, C, D',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            TaskForm(
              onTaskCreated: (Task task) async {
                final nearestDriver = await _findNearestDriver(task.source);
                if (nearestDriver != null) {
                  task = Task(
                    id: task.id,
                    name: task.name,
                    source: task.source,
                    destination: task.destination,
                    assignedDriverId: nearestDriver.id,
                    status: TaskStatus.assigned,
                    createdAt: task.createdAt,
                    type: task.type,
                    numberOfPallets: task.numberOfPallets,
                    estimatedTime: task.estimatedTime,
                    startTime: task.startTime,
                    endTime: task.endTime,
                    duration: task.duration,
                  );

                  await _firebaseService.createTask(task);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task assigned to ${nearestDriver.name}'),
                      ),
                    );
                  }
                } else {
                  // Check if the widget is still mounted before showing the snackbar
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No available drivers')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<Driver?> _findNearestDriver(String taskLocation) async {
    try {
      final distances = warehouseGraph.dijkstra(taskLocation.toUpperCase());
      print('Distances: $distances'); // Debug log

      Driver? nearestDriver;
      double minDistance = double.infinity;

      List<Driver> drivers = await _firebaseService.getAvailableDrivers();
      for (final driver in drivers) {
        print(
            'Driver: ${driver.name}, Location: ${driver.currentLocation}, Available: ${driver.isAvailable}'); // Debug log
        if (driver.isAvailable &&
            distances.containsKey(driver.currentLocation)) {
          final distance = distances[driver.currentLocation]!;
          print('Distance for ${driver.name}: $distance'); // Debug log

          if (distance < minDistance) {
            minDistance = distance;
            nearestDriver = driver;
          }
        }
      }

      return nearestDriver;
    } catch (e) {
      debugPrint('Error finding nearest driver: ${e.toString()}');
      return null;
    }
  }
}
