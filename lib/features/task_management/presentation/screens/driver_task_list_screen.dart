import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/theme/app_theme.dart';
import 'package:total_flutter/core/widgets/app_button.dart';
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/task_management/presentation/widgets/task_card.dart';
import 'package:total_flutter/core/utils/app_utils.dart';

class DriverTaskListScreen extends StatefulWidget {
  final String driverId; // Driver ID is now required

  const DriverTaskListScreen({super.key, required this.driverId});

  @override
  State<DriverTaskListScreen> createState() => _DriverTaskListScreenState();
}

class _DriverTaskListScreenState extends State<DriverTaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverRepository = Provider.of<DriverRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Tasks
          _buildTaskList(driverRepository, null),
          // Pending Tasks
          _buildTaskList(driverRepository, AppConstants.taskStatusPending),
          // In Progress Tasks
          _buildTaskList(driverRepository, AppConstants.taskStatusInProgress),
          // Completed Tasks
          _buildTaskList(driverRepository, AppConstants.taskStatusCompleted),
        ],
      ),
    );
  }

  Widget _buildTaskList(DriverRepository driverRepository, String? statusFilter) {
    return StreamBuilder<List<Task>>(
      stream: driverRepository.getAssignedTasksByStatus(
          widget.driverId, statusFilter),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'No tasks available',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  statusFilter != null
                      ? 'No $statusFilter tasks'
                      : 'Wait for new tasks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            top: AppTheme.spacingS,
            bottom: AppTheme.spacingL,
          ),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              driver: null, // No need to fetch driver details in Driver View
              index: index,
              showDriver: false, // Hide driver details in Driver View
              onTap: () {
                // Show task details
              },
              actions: [
                if (task.status != TaskStatus.completed)
                  AppButton(
                    text: task.status == TaskStatus.pending
                        ? 'Start Task'
                        : 'Complete Task',
                    type: AppButtonType.primary,
                    size: AppButtonSize.small,
                    leadingIcon: task.status == TaskStatus.pending
                        ? Icons.play_arrow
                        : Icons.check,
                    onPressed: () async {
                      try {
                        final taskRepository = Provider.of<TaskRepository>(
                            context,
                            listen: false);
                        if (task.status == TaskStatus.pending) {
                          await taskRepository.acceptTask(task.id);
                        } else if (task.status == TaskStatus.inProgress) {
                          await taskRepository.completeTask(task.id);
                        }

                        if (!mounted) return;
                        AppUtils.showSnackBar(
                          context,
                          'Task updated successfully',
                        );
                      } catch (e) {
                        if (!mounted) return;
                        AppUtils.showSnackBar(
                          context,
                          'Error updating task: $e',
                          isError: true,
                        );
                      }
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }
}