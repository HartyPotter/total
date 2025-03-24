import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:total_flutter/features/map/map_page.dart';
import 'package:total_flutter/features/task_management/presentation/screens/supervisor_task_list_screen.dart';
import 'package:total_flutter/features/task_management/presentation/screens/task_assignment_screen.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/drivers_screen.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/forklifts_screen.dart';
import 'package:total_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:total_flutter/core/utils/app_utils.dart';

class SupervisorHomeScreen extends StatefulWidget {
  final dynamic supervisor;

  const SupervisorHomeScreen({super.key, required this.supervisor});

  @override
  State<SupervisorHomeScreen> createState() => _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends State<SupervisorHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authRepository = Provider.of<AuthRepository>(context);
    final taskRepository = Provider.of<TaskRepository>(context);
    final driverRepository = Provider.of<DriverRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: IconButton(
          iconSize: 26,
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => widget.supervisor is Map<String, dynamic>
                    ? ProfileScreen(
                        user: widget.supervisor as Map<String, dynamic>,
                        isDriver: false,
                        showBackButton: true,
                      )
                    : ProfileScreen(
                        user: widget.supervisor,
                        isDriver: false,
                        showBackButton: true,
                      ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            iconSize: 26,
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await AppUtils.showConfirmationDialog(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
              );

              if (!confirmed || !mounted) return;

              await authRepository.signOut();
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
                    builder: (context) => TaskAssignmentScreen(
                      taskRepository: taskRepository,
                      driverRepository: driverRepository,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed, // Needed for more than 3 items
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
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
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
      case 3:
        return 'Map';
      default:
        return 'Tasks';
    }
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return const SupervisorTaskListScreen();
      case 1:
        return DriversScreen();
      case 2:
        return ForkliftsScreen();
      case 3:
        return const MapScreen();
      default:
        return const SupervisorTaskListScreen();
    }
  }
}
