import 'package:flutter/material.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/constants/app_constants.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(String) onStatusChange;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(task.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${task.source}'),
            Text('To: ${task.destination}'),
            Text('Status: ${task.status.toJson()}'),
            if (task.startTime != null)
              Text('Started: ${AppUtils.formatDateTime(task.startTime!)}'),
            if (task.endTime != null)
              Text('Completed: ${AppUtils.formatDateTime(task.endTime!)}'),
            if (task.duration > 0)
              Text('Duration: ${AppUtils.formatDuration(task.duration)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: onStatusChange,
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: AppConstants.taskStatusPending,
                child: const Text('Mark as Pending'),
              ),
              PopupMenuItem<String>(
                value: AppConstants.taskStatusInProgress,
                child: const Text('Mark as In Progress'),
              ),
              PopupMenuItem<String>(
                value: AppConstants.taskStatusCompleted,
                child: const Text('Mark as Completed'),
              ),
            ];
          },
        ),
      ),
    );
  }
}
