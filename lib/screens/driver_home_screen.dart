import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:total_flutter/services/firebase_service.dart';
import 'package:total_flutter/models/task.dart';
import 'package:total_flutter/screens/login_screen.dart' as login;

class DriverHomeScreen extends StatefulWidget {
  final String driverId;
  final int initialTabIndex; // Add initialTabIndex parameter

  const DriverHomeScreen({
    super.key,
    required this.driverId,
    this.initialTabIndex = 0, // Default to the first tab
  });

  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, String> _taskStatus = {}; // Map to track task status
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize TabController with initialTabIndex
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex, // Use initialTabIndex here
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Method to switch to the task requests tab
  void switchToTaskRequestsTab() {
    setState(() {
      _tabController.index = 2; // Switch to the second tab (Task Requests)
    });
  }

  // Update the location of the driver after the driver has accepted the task
  Future<void> _handleTaskResponse(Task task, bool accepted) async {
    setState(() {
      _taskStatus[task.id] = accepted ? 'accepted' : 'rejected';
    });

    final status = accepted
        ? TaskStatus.inProgress.toString().split('.').last
        : TaskStatus.assigned.toString().split('.').last;

    await _firebaseService.updateTaskStatus(task.id, status);

    if (accepted) {
      final startTime = DateTime.now();
      await _firebaseService.assignTaskToDriver(widget.driverId, task.source);
      await _firebaseService.updateTaskStartTime(task.id, startTime);
    } else {
      await _firebaseService.updateDriverStatus(widget.driverId, false);
    }
  }

  Future<void> _markTaskAsComplete(Task task) async {
    setState(() {
      _taskStatus[task.id] = 'completed';
    });
    final endTime = DateTime.now(); // End time of the task
    final status = TaskStatus.completed.toString().split('.').last;
    await _firebaseService.updateTaskStatus(task.id, status);
    await _firebaseService.updateDriverStatus(widget.driverId, true);
    await _firebaseService.updateTaskEndTime(task.id, endTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const login.LoginScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current tasks'),
            Tab(text: 'Task requests'),
            Tab(text: 'Completed Tasks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(_firebaseService.getDriverTasks(
              widget.driverId, 'status', 'inProgress')),
          _buildTaskList(_firebaseService.getDriverTasks(
              widget.driverId, 'status', 'assigned')),
          _buildTaskList(_firebaseService.getDriverTasks(
              widget.driverId, 'status', 'completed')),
        ],
      ),
    );
  }

  Widget _buildTaskList(Stream<List<Task>> taskStream) {
    return StreamBuilder<List<Task>>(
      stream: taskStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          print('Loading tasks...');
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snapshot.data!;
        print('Tasks loaded: $tasks');
        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks available'));
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final status = _taskStatus[task.id];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('From: ${task.displayLocationName(task.source)}'),
                    Text('To: ${task.displayLocationName(task.destination)}'),
                    Text('Number of Pallets: ${task.numberOfPallets}'),
                    if (task.startTime != null)
                      Text('Start Time: ${task.startTime!.toLocal()}'),
                    if (task.endTime != null)
                      Text('End Time: ${task.endTime!.toLocal()}'),
                    if (task.startTime != null && task.endTime != null)
                      Text(
                          'Duration: ${task.endTime!.difference(task.startTime!).inMinutes} minutes'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_tabController.index == 1) ...[
                          // Task Requests Tab
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _handleTaskResponse(task, true),
                            child: const Text('Accept'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _handleTaskResponse(task, false),
                            child: const Text('Reject'),
                          ),
                        ] else if (_tabController.index == 0) ...[
                          // Current Tasks Tab
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _markTaskAsComplete(task),
                            child: const Text('Complete'),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
