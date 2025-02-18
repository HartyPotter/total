import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/task_management/domain/models/location_node.dart';
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/utils/path_finding_utils.dart';
import 'package:total_flutter/core/widgets/modern_card.dart';

class TaskAssignmentScreen extends StatefulWidget {
  const TaskAssignmentScreen({super.key});

  @override
  TaskAssignmentScreenState createState() => TaskAssignmentScreenState();
}

class TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _taskRepository = TaskRepository();
  final DriverRepository _driverRepository = DriverRepository();

  final _nameController = TextEditingController();
  final _numberOfPalletsController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  String? _selectedSource;
  String? _selectedDestination;
  String _selectedTaskType = AppConstants.taskTypePickup;
  bool _isLoading = false;

  final List<LocationNode> _locationNodes = LocationNode.getAllNodes();

  @override
  void dispose() {
    _nameController.dispose();
    _numberOfPalletsController.dispose();
    _estimatedTimeController.dispose();
    super.dispose();
  }

  Future<void> _assignTask() async {
    if (_formKey.currentState!.validate() &&
        _selectedSource != null &&
        _selectedDestination != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        final supervisorId = currentUser?.uid; // Supervisor's ID
        if (supervisorId == null) {
          throw Exception('Supervisor not logged in');
        }
        final supervisorRef = _firestore
            .collection(AppConstants.supervisorsCollection)
            .doc(supervisorId); // supervisorId is a String

        final sourceNode = LocationNode.fromId(_selectedSource!);
        final destinationNode = LocationNode.fromId(_selectedDestination!);

        // Check if any drivers are available
        final driversAvailable = await _driverRepository.areDriversAvailable();
        String? assignedDriverId;

        if (driversAvailable) {
          // Get available drivers and their locations
          final availableDriversWithLocations =
              await _driverRepository.getAvailableDriversOnce(true);
          // final availableDriversWithLocations = availableDrivers['locations'] as Map<String, String>;
          // final driverLocations = await _driverRepository.getAvailableDriversOnce(true);

          // Find the nearest available driver
          assignedDriverId = PathFindingUtils.findNearestAvailableDriver(
            _selectedSource!,
            availableDriversWithLocations,
          );
        }

        final task = Task(
          id: '',
          name: _nameController.text,
          source: sourceNode.displayName,
          destination: destinationNode.displayName,
          assignedDriver: assignedDriverId != null
              ? _driverRepository.getDriver(assignedDriverId)
              : null,
          createdBy: supervisorRef,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
          type: _selectedTaskType,
          numberOfPallets: int.parse(_numberOfPalletsController.text),
          estimatedTime: int.parse(_estimatedTimeController.text),
          startTime: null,
          endTime: null,
          duration: 0,
          isQueued: assignedDriverId == null,
        );

        await _taskRepository.createTask(task);

        if (!mounted) return;
        AppUtils.showSnackBar(
          context,
          assignedDriverId != null
              ? '${AppConstants.successTaskCreated}\nAssigned to nearest available driver'
              : '${AppConstants.successTaskCreated}\nTask added to queue - will be assigned when a driver becomes available',
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        AppUtils.showSnackBar(
          context,
          '${AppConstants.errorTaskCreation}: $e',
          isError: true,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Task'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModernCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Task Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: AppUtils.validateRequired,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSource,
                        decoration: const InputDecoration(
                          labelText: 'Source Location',
                          border: OutlineInputBorder(),
                        ),
                        items: _locationNodes.map((node) {
                          return DropdownMenuItem(
                            value: node.id,
                            child: Text(node.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSource = value;
                          });
                        },
                        validator: AppUtils.validateRequired,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDestination,
                        decoration: const InputDecoration(
                          labelText: 'Destination Location',
                          border: OutlineInputBorder(),
                        ),
                        items: _locationNodes.map((node) {
                          return DropdownMenuItem(
                            value: node.id,
                            child: Text(node.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDestination = value;
                          });
                        },
                        validator: AppUtils.validateRequired,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ModernCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Configuration',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedTaskType,
                        decoration: const InputDecoration(
                          labelText: 'Task Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: AppConstants.taskTypePickup,
                            child: const Text('Pickup'),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.taskTypeDelivery,
                            child: const Text('Delivery'),
                          ),
                          DropdownMenuItem(
                            value: AppConstants.taskTypeTransfer,
                            child: const Text('Transfer'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTaskType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numberOfPalletsController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Pallets',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: AppUtils.validateNumber,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _estimatedTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Time (minutes)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: AppUtils.validateNumber,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _assignTask,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Assign Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
