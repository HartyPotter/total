import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/driver_management/domain/models/driver.dart';
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/widgets/modern_card.dart';

class TaskListScreen extends StatelessWidget {
  final TaskRepository _taskRepository = TaskRepository();

  TaskListScreen({super.key});

  Future<Driver?> _fetchDriver(DocumentReference reference) async {
    final doc = await reference.get();
    if (doc.exists) {
      return Driver.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      stream: _taskRepository.getTasksStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks available.'));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ModernCard(
              padding: const EdgeInsets.all(16.0),
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              AppUtils.getTaskStatusColor(task.status.toJson())
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppUtils.getTaskStatusColor(
                                task.status.toJson()),
                          ),
                        ),
                        child: Text(
                          task.status.toJson(),
                          style: TextStyle(
                            color: AppUtils.getTaskStatusColor(
                                task.status.toJson()),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Source: ${task.source}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Destination: ${task.destination}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Type: ${task.type}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Estimated Time: ${task.estimatedTime} mins',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Number of Pallets: ${task.numberOfPallets}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (task.assignedDriver != null)
                    FutureBuilder<Driver?>(
                      future: _fetchDriver(task.assignedDriver!),
                      builder: (context, driverSnapshot) {
                        if (driverSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Loading driver info...');
                        }
                        final driver = driverSnapshot.data;
                        if (driver == null) {
                          return const Text('Driver not found');
                        }
                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppUtils.getDriverStatusColor(
                              driver.status.toJson(),
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppUtils.getDriverStatusColor(
                                driver.status.toJson(),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: AppUtils.getDriverStatusColor(
                                  driver.status.toJson(),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Assigned to: ${driver.name}',
                                style: TextStyle(
                                  color: AppUtils.getDriverStatusColor(
                                    driver.status.toJson(),
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (task.assignedDriver == null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Queued: Waiting for driver availability',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (task.startTime != null)
                    Text(
                      'Started: ${AppUtils.formatDateTime(task.startTime!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (task.endTime != null)
                    Text(
                      'Completed: ${AppUtils.formatDateTime(task.endTime!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (task.duration > 0)
                    Text(
                      'Duration: ${AppUtils.formatDuration(task.duration)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
