import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/theme/app_theme.dart';
import 'package:total_flutter/core/widgets/app_button.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/features/task_management/presentation/widgets/task_card.dart';
import 'package:total_flutter/core/utils/app_utils.dart';

class TaskListScreen extends StatefulWidget {
  final String? driverId;

  const TaskListScreen({super.key, this.driverId});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
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
    final taskRepository = Provider.of<TaskRepository>(context);
    final driverRepository = Provider.of<DriverRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
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
          _buildTaskList(
              widget.driverId != null ? driverRepository : taskRepository,
              null),
          // Pending Tasks
          _buildTaskList(
              widget.driverId != null ? driverRepository : taskRepository,
              AppConstants.taskStatusPending),
          // In Progress Tasks
          _buildTaskList(
              widget.driverId != null ? driverRepository : taskRepository,
              AppConstants.taskStatusInProgress),
          // Completed Tasks
          _buildTaskList(
              widget.driverId != null ? driverRepository : taskRepository,
              AppConstants.taskStatusCompleted),
        ],
      ),
    );
  }

  Widget _buildTaskList(dynamic repository, String? statusFilter) {
    return StreamBuilder<List<Task>>(
      stream: widget.driverId != null
          ? (repository as DriverRepository)
              .getAssignedTasksByStatus(widget.driverId!, statusFilter)
          : statusFilter != null
              ? (repository as TaskRepository).getTasksByStatus(statusFilter)
              : (repository as TaskRepository).getAllTasks(),
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
            return FutureBuilder<Driver?>(
              future: task.assignedDriver != null && widget.driverId == null
                  ? FirebaseFirestore.instance
                      .collection(AppConstants.driversCollection)
                      .doc(task.assignedDriver)
                      .get()
                      .then((doc) => doc.exists
                          ? Driver.fromMap(doc.data()!, doc.id)
                          : null)
                  : Future.value(null),
              builder: (context, driverSnapshot) {
                final driver = driverSnapshot.data;

                return TaskCard(
                  task: task,
                  driver: driver,
                  index: index,
                  showDriver: widget.driverId ==
                      null, // Only show driver in supervisor view
                  onTap: () {
                    // Show task details
                  },
                  actions: [
                    if (task.status == TaskStatus.pending &&
                        widget.driverId == null)
                      AppButton(
                        text: 'Reassign',
                        type: AppButtonType.secondary,
                        size: AppButtonSize.small,
                        leadingIcon: Icons.person_add_alt,
                        onPressed: () {
                          // Handle reassign
                        },
                      ),
                    const SizedBox(width: 8),
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
      },
    );
  }
}
