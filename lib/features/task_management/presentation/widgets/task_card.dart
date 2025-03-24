import 'package:flutter/material.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/widgets/status_badge.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Driver? driver;
  final int index;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final bool showDriver;

  const TaskCard({
    super.key,
    required this.task,
    this.driver,
    required this.index,
    this.onTap,
    required this.actions,
    this.showDriver = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTaskIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(
                              text: task.status.toJson(),
                              color: _getStatusColor(task.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLocationInfo(context),

              // Creator/Assignment info
              if (task.createdBy != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.person_outline,
                  'Assigned by: ${task.createdBy}',
                ),
              ],

              // Pallets and estimated time for active tasks
              if (task.status != TaskStatus.completed) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.inventory_2_outlined,
                  'Pallets: ${task.numberOfPallets}',
                ),
                if (task.estimatedTime > 0) ...[
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.timer_outlined,
                    'Est. time: ${task.estimatedTime} min',
                  ),
                ],
                // ignore: unnecessary_null_comparison
                if (task.createdAt != null) ...[
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Created: ${AppUtils.formatDateTime(task.createdAt)}',
                  ),
                ],
              ],

              // Driver info if needed
              if (showDriver && driver != null) ...[
                const SizedBox(height: 12),
                _buildDriverInfo(context),
              ],

              // Task timing info based on status
              if (task.status == TaskStatus.inProgress &&
                  task.startTime != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.play_arrow,
                  'Started: ${AppUtils.formatDateTime(task.startTime!)}',
                ),
              ] else if (task.status == TaskStatus.completed) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  Icons.inventory_2_outlined,
                  'Pallets: ${task.numberOfPallets}',
                ),
                // Show actual duration instead of estimate for completed tasks
                if (task.duration > 0) ...[
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.timer,
                    'Duration: ${AppUtils.formatDuration(task.duration)}',
                  ),
                ],
                if (task.startTime != null) ...[
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.play_arrow,
                    'Started: ${AppUtils.formatDateTime(task.startTime!)}',
                  ),
                ],
                if (task.endTime != null) ...[
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    context,
                    Icons.check_circle_outline,
                    'Completed: ${AppUtils.formatDateTime(task.endTime!)}',
                  ),
                ],
              ],

              // Actions
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskIcon() {
    IconData icon;
    Color color;

    switch (task.status) {
      case TaskStatus.pending:
        icon = Icons.pending_outlined;
        color = Colors.orange;
        break;
      case TaskStatus.inProgress:
        icon = Icons.directions_run;
        color = Colors.blue;
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(BuildContext context) {
    return _buildInfoRow(
      context,
      Icons.route,
      '${task.source} → ${task.destination}',
    );
  }

  Widget _buildDriverInfo(BuildContext context) {
    return _buildInfoRow(
      context,
      Icons.person_outline,
      'Driver: ${driver?.name ?? 'Unassigned'}',
    );
  }
}