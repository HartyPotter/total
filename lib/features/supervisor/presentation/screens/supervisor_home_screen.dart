import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/features/map/map_page.dart';
import 'package:total_flutter/features/task_management/presentation/screens/supervisor_task_list_screen.dart';
import 'package:total_flutter/features/task_management/presentation/screens/task_assignment_screen.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/drivers_screen.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/forklifts_screen.dart';
import 'package:total_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:total_flutter/features/supervisor/data/supervisor_provider.dart';
import 'package:total_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:total_flutter/core/utils/app_utils.dart';

class SupervisorHomeScreen extends ConsumerStatefulWidget {
  const SupervisorHomeScreen({super.key});

  @override
  ConsumerState<SupervisorHomeScreen> createState() =>
      _SupervisorHomeScreenState();
}

class _SupervisorHomeScreenState extends ConsumerState<SupervisorHomeScreen> {
  int _selectedIndex = 0;

  Future<void> _logout() async {
    final confirmed = await AppUtils.showConfirmationDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
    );

    if (!confirmed || !mounted) return;

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AppUtils.showSnackBar(
        context,
        'Error during logout: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supervisorState = ref.watch(supervisorProvider);

    // Show loading indicator while supervisor data is being loaded
    if (supervisorState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message if there was an error loading supervisor data
    if (supervisorState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: ${supervisorState.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    final supervisor = supervisorState.supervisor;

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
                builder: (context) => ProfileScreen(
                  user: supervisor,
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
            onPressed: _logout,
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
