import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:total_flutter/services/firebase_service.dart';
import 'package:total_flutter/models/task.dart';
import 'package:total_flutter/screens/login_screen.dart' as login;

class DriverHomeScreen extends StatefulWidget {
  final String driverId;

  const DriverHomeScreen({Key? key, required this.driverId}) : super(key: key);

  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Update the location of the driver after the driver has accepted the task
  Future<void> _handleTaskResponse(Task task, bool accepted) async {
    if (accepted) {
      final status = TaskStatus.inProgress.toString().split('.').last;
      await _firebaseService.updateTaskStatus(
        task.id,
        status,
      );
      await _firebaseService.assignTaskToDriver(
        widget.driverId,
        task.location,
      );
    } else {
      final status = TaskStatus.assigned.toString().split('.').last;
      await _firebaseService.updateTaskStatus(
        task.id,
        status,
      );
    }
  }

  Future<void> _markTaskAsComplete(Task task) async {
    final status = TaskStatus.completed.toString().split('.').last;
    await _firebaseService.updateTaskStatus(
      task.id,
      status,
    );
    await _firebaseService.updateDriverStatus(
      widget.driverId,
      true,
    );
  }

  // Future<void> _handleTaskResponse(String taskId, bool accepted) async {
  //   if (accepted) {
  //     final status = TaskStatus.inProgress.toString().split('.').last;
  //     final task = await _firebaseService.updateTaskStatus(
  //       taskId,
  //       status,
  //     ).asStream();
  //     await _firebaseService.assignTaskToDriver(
  //       widget.driverId,
  //       task.location,
  //     );
  //   } else {
  //     final status = TaskStatus.assigned.toString().split('.').last;
  //     await _firebaseService.updateTaskStatus(
  //       taskId,
  //       status,
  //     );
  //   }
  // }

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
                    builder: (context) => const login.LoginScreen()),
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
          _buildTaskList(
              _firebaseService.getDriverTasks(widget.driverId, 'status', 'assigned')),
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
        print('Tasks loaded: ${tasks}');
        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks available'));
        }
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              title: Text(task.name),
              subtitle: Text(task.dispalayLocationName),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue,
                    ),
                    child: const Text('Accept'),
                    onPressed: () => _handleTaskResponse(task, true),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                    onPressed: () => _handleTaskResponse(task, false),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.green,
                    ),
                    child: const Text('Completed'),
                    onPressed: () => _markTaskAsComplete(task),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
