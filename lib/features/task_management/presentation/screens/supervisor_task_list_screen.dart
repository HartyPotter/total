import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/theme/app_theme.dart';
import 'package:total_flutter/core/utils/animation_utils.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/widgets/status_badge.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/task_management/presentation/screens/task_detail_screen.dart';

class SupervisorTaskListScreen extends StatefulWidget {
  const SupervisorTaskListScreen({super.key});

  @override
  State<SupervisorTaskListScreen> createState() =>
      _SupervisorTaskListScreenState();
}

class _SupervisorTaskListScreenState extends State<SupervisorTaskListScreen> {
  String? _selectedFilter;
  final _driverCache = <String, Driver>{};

  Future<Driver?> _fetchDriver(String driverId) async {
    // Check cache first
    if (_driverCache.containsKey(driverId)) {
      return _driverCache[driverId];
    }

    // Fetch from Firestore if not in cache
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.driversCollection)
        .doc(driverId)
        .get();

    if (doc.exists) {
      final driver = Driver.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      _driverCache[driverId] = driver; // Add to cache
      return driver;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final taskRepository = Provider.of<TaskRepository>(context);

    return Column(
      children: [
        // Status filter
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
          child: AnimationUtils.animateFormItem(
            Row(
              children: [
                Text(
                  'Status:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterOption(context, null, 'All'),
                        _buildFilterOption(
                            context, AppConstants.taskStatusPending, 'Pending'),
                        _buildFilterOption(context,
                            AppConstants.taskStatusInProgress, 'In Progress'),
                        _buildFilterOption(context,
                            AppConstants.taskStatusCompleted, 'Completed'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            0,
          ),
        ),

        const Divider(),

        // Task list
        Expanded(
          child: StreamBuilder<List<Task>>(
            stream: _selectedFilter != null
                ? taskRepository.getTasksByStatus(_selectedFilter!)
                : taskRepository.getAllTasks(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tasks = snapshot.data!;
              if (tasks.isEmpty) {
                return AnimationUtils.animateFormItem(
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'No tasks available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  0,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
                itemCount: tasks.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return AnimationUtils.animateListItem(
                    _buildTaskListItem(context, task, index),
                    index,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOption(BuildContext context, String? value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingS),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingXs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskListItem(BuildContext context, Task task, int index) {
    final statusColor = AppUtils.getTaskStatusColor(task.status.toJson());

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXs,
      ),
      onTap: () {
        Navigator.push(
          context,
          AnimationUtils.pageTransition(
            page: TaskDetailScreen(taskId: task.id),
            slideLeft: true,
          ),
        );
      },
      leading: Container(
        width: 4,
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
      ),
      title: Text(
        task.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${task.source} → ${task.destination}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (task.assignedDriver != null)
            FutureBuilder<Driver?>(
              future: _fetchDriver(task.assignedDriver!),
              builder: (context, snapshot) {
                final driverName = snapshot.data?.name ?? 'Loading...';
                return Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        driverName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StatusBadge(
            text: task.status.toJson(),
            color: statusColor,
            isOutlined: true,
          ),
          const SizedBox(height: 4),
          Text(
            task.startTime != null
                ? AppUtils.formatTime(task.startTime!)
                : 'Not started',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
