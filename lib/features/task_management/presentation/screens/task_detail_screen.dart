import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/core/theme/app_theme.dart';
import 'package:total_flutter/core/utils/animation_utils.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/widgets/app_button.dart';
import 'package:total_flutter/core/widgets/status_badge.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/map/map_widget.dart';
import 'package:total_flutter/features/supervisor/data/supervisor_provider.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/task_management/domain/models/task_list.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  Task? _task;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final taskRepository = ref.read(taskRepositoryProvider);
      final task = await taskRepository.getTaskById(widget.taskId);

      if (task == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Task not found';
        });
        return;
      }

      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading task: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildTaskDetails(),
    );
  }

  Widget _buildTaskDetails() {
    if (_task == null) {
      return const Center(child: Text('Task data not available'));
    }

    final task = _task!;
    final statusColor = AppUtils.getTaskStatusColor(task.status.toJson());

    // Get driver information if task is assigned
    Driver? driver;
    if (task.assignedDriver != null) {
      // Try to get driver from supervisor provider's cache first
      final supervisorState = ref.watch(supervisorProvider);
      if (supervisorState.driverCache.containsKey(task.assignedDriver)) {
        driver = supervisorState.driverCache[task.assignedDriver];
      } else {
        // If not in cache, fetch it (this will update the cache)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(supervisorProvider.notifier).getDriver(task.assignedDriver!);
        });
      }
    }

    return AnimationUtils.animateFormItem(
      SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task header
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                StatusBadge(
                  text: task.status.toJson(),
                  color: statusColor,
                  isOutlined: true,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingM),

            // Map visualization
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppTheme.borderRadiusMedium),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Builder(
                builder: (context) {
                  // Get source and destination coordinates
                  final (sLat, sLng) =
                      TaskList.getCoordinates(task.source) as (double, double);
                  final (dLat, dLng) = TaskList.getCoordinates(task.destination)
                      as (double, double);

                  // Fallback to (0.0, 0.0) if coordinates are null
                  final sourceLocation = (sLat, sLng);
                  final destinationLocation = (dLat, dLng);

                  return MapWidget(
                    sourceLocation: sourceLocation,
                    destinationLocation: destinationLocation,
                    taskId: task.id,
                    driverId: task.assignedDriver,
                  );
                },
              ),
            ),

            const SizedBox(height: AppTheme.spacingM),

            // Location details
            _buildInfoSection(
              context,
              'Location',
              [
                _buildInfoRow(context, Icons.arrow_circle_up_outlined, 'From',
                    task.source),
                _buildInfoRow(context, Icons.arrow_circle_down_outlined, 'To',
                    task.destination),
              ],
            ),

            // Task details
            _buildInfoSection(
              context,
              'Task Details',
              [
                _buildInfoRow(
                    context, Icons.category_outlined, 'Type', task.type),
                _buildInfoRow(
                  context,
                  Icons.inventory_2_outlined,
                  'Number of Pallets',
                  task.numberOfPallets.toString(),
                ),
                _buildInfoRow(
                  context,
                  Icons.timer_outlined,
                  'Estimated Time',
                  '${task.estimatedTime} mins',
                ),
                if (task.startTime != null)
                  _buildInfoRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Start Time',
                    AppUtils.formatDateTime(task.startTime!),
                  ),
                if (task.endTime != null)
                  _buildInfoRow(
                    context,
                    Icons.event_available_outlined,
                    'End Time',
                    AppUtils.formatDateTime(task.endTime!),
                  ),
                if (task.duration > 0)
                  _buildInfoRow(
                    context,
                    Icons.timelapse_outlined,
                    'Duration',
                    AppUtils.formatDuration(task.duration),
                  ),
              ],
            ),

            // Driver details
            if (driver != null)
              _buildInfoSection(
                context,
                'Assigned Driver',
                [
                  _buildInfoRow(
                    context,
                    Icons.person_outline,
                    'Name',
                    driver.name,
                  ),
                  _buildInfoRow(
                    context,
                    Icons.phone_outlined,
                    'Phone',
                    driver.phoneNumber,
                  ),
                  _buildInfoRow(
                    context,
                    Icons.circle_outlined,
                    'Status',
                    driver.status.toJson(),
                    valueColor:
                        AppUtils.getDriverStatusColor(driver.status.toJson()),
                  ),
                ],
              ),

            // Action buttons
            const SizedBox(height: AppTheme.spacingL),
            Row(
              children: [
                if (task.status != TaskStatus.completed)
                  Expanded(
                    child: AppButton(
                      text: 'Reassign Driver',
                      type: AppButtonType.outline,
                      leadingIcon: Icons.person_add_alt,
                      isFullWidth: true,
                      onPressed: () {
                        // Handle reassignment
                      },
                    ),
                  ),
                if (task.status != TaskStatus.completed)
                  const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: AppButton(
                    text: task.status == TaskStatus.completed
                        ? 'Archive Task'
                        : 'Cancel Task',
                    type: task.status == TaskStatus.completed
                        ? AppButtonType.primary
                        : AppButtonType.secondary,
                    leadingIcon: task.status == TaskStatus.completed
                        ? Icons.archive_outlined
                        : Icons.cancel_outlined,
                    isFullWidth: true,
                    onPressed: () {
                      // Handle task cancellation or archiving
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      0,
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(width: AppTheme.spacingS),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: valueColor != null ? FontWeight.w600 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
