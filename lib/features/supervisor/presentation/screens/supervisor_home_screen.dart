import 'package:flutter/material.dart';
import 'package:total_flutter/features/task_management/presentation/screens/task_list_screen.dart';
import 'package:total_flutter/features/task_management/presentation/screens/task_assignment_screen.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/drivers_screen.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/forklifts_screen.dart';
import 'package:total_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/core/utils/app_utils.dart';

class SupervisorHomeScreen extends StatefulWidget {
  final dynamic supervisor;

  const SupervisorHomeScreen({super.key, required this.supervisor});

  @override
  State<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen> {
  final AuthRepository _authRepository = AuthRepository();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await AppUtils.showConfirmationDialog(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
              );

              if (!confirmed || !mounted) return;

              await _authRepository.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _getBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskAssignmentScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Drivers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: 'Forklifts',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Tasks';
      case 1:
        return 'Drivers';
      case 2:
        return 'Forklifts';
      default:
        return 'Supervisor Dashboard';
    }
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return TaskListScreen();
      case 1:
        return const DriversScreen();
      case 2:
        return const ForkliftsScreen();
      default:
        return TaskListScreen();
    }
  }
}
