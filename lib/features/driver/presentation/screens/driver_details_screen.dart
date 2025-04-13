import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
// import 'package:total_flutter/core/widgets/entity_card.dart';
import 'package:total_flutter/core/widgets/info_section.dart';
// import 'package:total_flutter/core/widgets/app_button.dart';
// import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/forklift_management/domain/models/forklift.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';

class DriverDetailsScreen extends ConsumerWidget {
  final Driver driver;

  const DriverDetailsScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forkliftRepository = ref.watch(forkliftRepositoryProvider);
    final taskRepository = ref.watch(taskRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(driver.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit driver screen
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          // Safely handle nullable IDs
          driver.assignedForklift != null && driver.assignedForklift!.isNotEmpty
              ? forkliftRepository.getForkliftById(driver.assignedForklift)
              : Future.value(null),
          driver.currentTask != null && driver.currentTask!.isNotEmpty
              ? taskRepository.getTaskById(driver.currentTask)
              : Future.value(null),
          taskRepository.getDriverTasks(
              driver.id, AppConstants.taskStatusCompleted, 5),
        ],
            eagerError:
                false), // Don't fail the entire Future.wait on a single error
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get data from the future, handling potential errors
          Forklift? forklift;
          Task? currentTask;
          List<Task> completedTasks = [];

          if (snapshot.hasData) {
            try {
              if (driver.assignedForklift != null &&
                  snapshot.data![0] != null) {
                forklift = snapshot.data![0] as Forklift?;
              }

              if (driver.currentTask != null && snapshot.data![1] != null) {
                currentTask = snapshot.data![1] as Task?;
              }

              if (snapshot.data![2] != null) {
                completedTasks = snapshot.data![2] as List<Task>;
              }
            } catch (e) {
              print('Error parsing data: $e');
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDriverHeader(context),
                const SizedBox(height: 24),
                _buildPersonalInfoSection(),
                const SizedBox(height: 24),
                if (forklift != null) _buildForkliftSection(forklift),
                if (forklift != null) const SizedBox(height: 24),
                _buildStatusSection(),
                const SizedBox(height: 24),
                if (currentTask != null) _buildCurrentTaskSection(currentTask),
                if (currentTask != null) const SizedBox(height: 24),
                if (completedTasks.isNotEmpty)
                  _buildCompletedTasksSection(completedTasks),
                const SizedBox(height: 32),
                // _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriverHeader(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                driver.name.isNotEmpty
                    ? driver.name.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(driver.status.toJson())
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          driver.status.toJson(),
                          style: TextStyle(
                            color: _getStatusColor(driver.status.toJson()),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return InfoSection(
      title: 'Personal Information',
      icon: Icons.person,
      items: [
        InfoItem(label: 'Email', value: driver.email),
        InfoItem(label: 'Phone', value: driver.phoneNumber),
      ],
    );
  }

  Widget _buildForkliftSection(Forklift forklift) {
    return InfoSection(
      title: 'Assigned Forklift',
      icon: Icons.precision_manufacturing,
      items: [
        InfoItem(label: 'Model', value: forklift.model),
        InfoItem(label: 'Serial Number', value: forklift.serialNumber),
        InfoItem(label: 'Status', value: forklift.status.toJson()),
        if (forklift.lastMaintenance != null)
          InfoItem(
              label: 'Last Maintenance',
              value: AppUtils.formatDate(forklift.lastMaintenance)),
      ],
    );
  }

  Widget _buildStatusSection() {
    return InfoSection(
      title: 'Status Information',
      icon: Icons.info,
      items: [
        InfoItem(label: 'Current Status', value: driver.status.toJson()),
        if (driver.currentLocation != null)
          InfoItem(
              label: 'Last Known Location',
              value:
                  '${driver.currentLocation?.latitude.toStringAsFixed(6)}, ${driver.currentLocation?.longitude.toStringAsFixed(6)}'),
      ],
    );
  }

  Widget _buildCurrentTaskSection(Task task) {
    return InfoSection(
      title: 'Current Task',
      icon: Icons.assignment,
      items: [
        InfoItem(label: 'Task Name', value: task.name),
        InfoItem(label: 'Source', value: task.source),
        InfoItem(label: 'Destination', value: task.destination),
        InfoItem(label: 'Status', value: task.status.toJson()),
        InfoItem(label: 'Type', value: task.type),
        InfoItem(label: 'Pallets', value: task.numberOfPallets.toString()),
        if (task.startTime != null)
          InfoItem(
              label: 'Started',
              value: AppUtils.formatDateTime(task.startTime!)),
        if (task.estimatedTime > 0)
          InfoItem(
              label: 'Estimated Time', value: '${task.estimatedTime} minutes'),
      ],
    );
  }

  Widget _buildCompletedTasksSection(List<Task> tasks) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Recently Completed Tasks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...tasks.map((task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(task.name),
                  subtitle: Text('${task.source} → ${task.destination}'),
                  trailing: task.endTime != null
                      ? Text(AppUtils.formatDate(task.endTime!))
                      : null,
                )),
          ],
        ),
      ),
    );
  }

  // Widget _buildActionButtons(BuildContext context) {
  //   // final driverRepository = Provider.of<DriverRepository>(context);
  //   final forkliftRepository = Provider.of<ForkliftRepository>(context);

  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     children: [
  //       Expanded(
  //         child: AppButton(
  //           text: 'Assign Task',
  //           type: AppButtonType.primary,
  //           leadingIcon: Icons.assignment_add,
  //           onPressed: () {
  //             // Navigate to assign task screen
  //           },
  //         ),
  //       ),
  //       const SizedBox(width: 8),
  //       Expanded(
  //         child: AppButton(
  //           text: 'Assign Forklift',
  //           type: AppButtonType.outline,
  //           leadingIcon: Icons.precision_manufacturing,
  //           onPressed: () async {
  //             // Navigate to assign forklift screen or show forklift list
  //             final availableForklifts =
  //                 await forkliftRepository.getAvailableForklifts();
  //             if (!context.mounted) return;

  //             if (availableForklifts.isEmpty) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('No available forklifts'),
  //                 ),
  //               );
  //               return;
  //             }

  //             // Show forklift selection dialog
  //             // This would typically be implemented elsewhere
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
