import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_flutter/screens/task_assignment_screen.dart';
import 'package:total_flutter/screens/task_list_screen.dart';
import 'package:total_flutter/screens/drivers_and_forklifts_screen.dart';
import 'package:total_flutter/screens/login_screen.dart' as login;

class SupervisorHomeScreen extends StatelessWidget {
  const SupervisorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supervisor Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tasks'),
              Tab(text: 'Drivers & Forklifts'),
              Tab(text: 'Create Task'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (context) => const login.LoginScreen()),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            TaskListScreen(), // Tab 1: Display all tasks
            const DriversAndForkliftsScreen(), // Tab 2: Display drivers and forklifts
            const TaskAssignmentScreen(), // Tab 3: Create a new task
          ],
        ),
      ),
    );
  }
}
