import 'package:flutter/material.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/features/driver_management/domain/models/driver.dart';

class DriverHomeScreen extends StatefulWidget {
  final Driver driver;

  const DriverHomeScreen({super.key, required this.driver});

  @override
  DriverHomeScreenState createState() => DriverHomeScreenState();
}

class DriverHomeScreenState extends State<DriverHomeScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  final AuthRepository _authRepository = AuthRepository();
  final DriverRepository _driverRepository = DriverRepository();

  String? _selectedFilter;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final supervisorNames = <DocumentReference, String>{};

  Future<void> _fetchSupervisorNames() async {
    final supervisorsSnapshot =
        await _firestore.collection(AppConstants.supervisorsCollection).get();

    for (final doc in supervisorsSnapshot.docs) {
      supervisorNames[doc.reference] = doc['name'];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSupervisorNames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.driver.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await AppUtils.showConfirmationDialog(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
              );

              if (!confirmed || !mounted) return;
              try {
                // Fetch the driver's assigned forklift
                final driverDoc = await _firestore
                    .collection(AppConstants.driversCollection)
                    .doc(widget.driver.id)
                    .get();

                if (!driverDoc.exists) {
                  if (!mounted) return;
                  AppUtils.showSnackBar(
                    context,
                    'Driver data not found',
                    isError: true,
                  );
                  return;
                }

                final driverData = driverDoc.data() as Map<String, dynamic>;
                final forkliftRef =
                    driverData['assignedForklift'] as DocumentReference?;

                if (forkliftRef != null) {
                  // Update the forklift's currentOperator to null
                  await forkliftRef.update({
                    'currentOperator': null,
                    'status': AppConstants.forkliftStatusAvailable,
                  });
                }

                // Update the driver's status to inactive
                await _firestore
                    .collection(AppConstants.driversCollection)
                    .doc(widget.driver.id)
                    .update({
                  'status': AppConstants.driverStatusInactive,
                  'assignedForklift': null, // Clear the assigned forklift
                });
              } catch (e) {
                if (!mounted) return;
                AppUtils.showSnackBar(
                  context,
                  'Error during logout: $e',
                  isError: true,
                );
              }
              await _authRepository.signOut();

              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'all',
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFilter = null;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _selectedFilter == AppConstants.taskStatusPending,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFilter = AppConstants.taskStatusPending;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('In Progress'),
                  selected:
                      _selectedFilter == AppConstants.taskStatusInProgress,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFilter = AppConstants.taskStatusInProgress;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Completed'),
                  selected: _selectedFilter == AppConstants.taskStatusCompleted,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFilter = AppConstants.taskStatusCompleted;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskRepository.getTasksStream(
                driverRef: _firestore
                    .collection(AppConstants.driversCollection)
                    .doc(widget.driver.id),
                status: _selectedFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data!;
                if (tasks.isEmpty) {
                  return const Center(child: Text('No tasks found'));
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(task.name,
                                style: const TextStyle(fontSize: 20)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('From: ${task.source}'),
                                Text('To: ${task.destination}'),
                                Text('Status: ${task.status.toJson()}'),
                                Text(
                                    'Assigned by: ${supervisorNames[task.createdBy] ?? 'Unknown Supervisor'}'), // Use pre-fetched name
                                if (task.startTime != null)
                                  Text(
                                      'Started: ${AppUtils.formatDateTime(task.startTime!)}'),
                                if (task.endTime != null)
                                  Text(
                                      'Completed: ${AppUtils.formatDateTime(task.endTime!)}'),
                                if (task.duration > 0)
                                  Text(
                                      'Duration: ${AppUtils.formatDuration(task.duration)}'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (task.status == TaskStatus.pending) ...[
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await _taskRepository.updateTaskStatus(
                                          task.id,
                                          AppConstants.taskStatusInProgress,
                                        );
                                        // Update the driver's status to busy
                                        await _driverRepository
                                            .updateDriverStatus(
                                                widget.driver.id,
                                                AppConstants.driverStatusBusy);
                                        await _taskRepository
                                            .updateTaskStartTime(
                                          task.id,
                                          DateTime.now(),
                                        );
                                        await _taskRepository
                                            .sendTaskUpdateNotification(task.name, AppConstants.taskStatusInProgress, task.createdBy);
                                        if (!mounted) return;
                                        AppUtils.showSnackBar(
                                          context,
                                          AppConstants.successTaskUpdated,
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        AppUtils.showSnackBar(
                                          context,
                                          '${AppConstants.errorTaskUpdate}: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                    ),
                                    child: const Text('Accept Task'),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (task.status == TaskStatus.inProgress)
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await _taskRepository.updateTaskStatus(
                                          task.id,
                                          AppConstants.taskStatusCompleted,
                                        );
                                        await _driverRepository
                                            .updateDriverStatus(
                                                widget.driver.id,
                                                AppConstants
                                                    .driverStatusActive);
                                        await _taskRepository.updateTaskEndTime(
                                          task.id,
                                          DateTime.now(),
                                        );
                                        await _taskRepository
                                            .sendTaskUpdateNotification(task.name, AppConstants.taskStatusCompleted, task.createdBy);
                                        if (!mounted) return;
                                        AppUtils.showSnackBar(
                                          context,
                                          AppConstants.successTaskUpdated,
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        AppUtils.showSnackBar(
                                          context,
                                          '${AppConstants.errorTaskUpdate}: $e',
                                          isError: true,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Complete Task'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
