import 'package:flutter/material.dart';
import 'package:total_flutter/models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(TaskStatus) onStatusUpdate;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Location: ${task.location}'),
            Text('Status: ${task.status.toString().split('.').last}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status == TaskStatus.assigned)
                  ElevatedButton(
                    onPressed: () => onStatusUpdate(TaskStatus.inProgress),
                    child: const Text('Accept'),
                  ),
                if (task.status == TaskStatus.inProgress) ...[
                  ElevatedButton(
                    onPressed: () => onStatusUpdate(TaskStatus.completed),
                    child: const Text('Complete'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
