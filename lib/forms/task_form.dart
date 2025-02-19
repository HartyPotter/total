// ignore_for_file: prefer_final_fields

import 'package:flutter/material.dart';
import 'package:total_flutter/models/task.dart';

class TaskForm extends StatefulWidget {
  final Function(Task) onTaskCreated;

  const TaskForm({super.key, required this.onTaskCreated});

  @override
  // ignore: library_private_types_in_public_api
  _TaskFormState createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _palletsController = TextEditingController();
  String _selectedSource = "A"; // Default value
  String _selectedDestination = "B"; // Default value
  String _taskType = 'Loading'; // Default value

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Task Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a task name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _taskType,
            decoration: const InputDecoration(
              labelText: 'Task Type',
              border: OutlineInputBorder(),
            ),
            items: ['Loading', 'Unloading', 'Moving', 'Stacking']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _taskType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSource,
            decoration: const InputDecoration(
              labelText: 'Source Location',
              border: OutlineInputBorder(),
            ),
            items: locationMapping.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSource = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDestination,
            decoration: const InputDecoration(
              labelText: 'Destination Location',
              border: OutlineInputBorder(),
            ),
            items: locationMapping.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDestination = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _estimatedTimeController,
            decoration: const InputDecoration(
              labelText: 'Estimated Time (minutes)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter estimated time';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _palletsController,
            decoration: const InputDecoration(
              labelText: 'Number of Pallets',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter number of pallets';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final task = Task(
                  id: DateTime.now().toString(), // You might want to use UUID
                  name: _nameController.text,
                  type: _taskType,
                  source: _selectedSource, // New field
                  destination: _selectedDestination, // New field
                  numberOfPallets: int.parse(_palletsController.text),
                  estimatedTime: int.parse(_estimatedTimeController.text),
                  startTime: null, // Default start time
                  endTime: null, // Default end time
                  duration: 0, // Default duration
                  assignedDriverId: '', // Will be assigned later
                  status: TaskStatus.assigned,
                  createdAt: DateTime.now(),
                );
                widget.onTaskCreated(task);
                // Clear form
                _nameController.clear();
                _estimatedTimeController.clear();
                _palletsController.clear();
              }
            },
            child: const Text('Create Task'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    // _locationController.dispose();
    _estimatedTimeController.dispose();
    _palletsController.dispose();
    super.dispose();
  }
}
