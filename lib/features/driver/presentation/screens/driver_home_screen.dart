import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:total_flutter/features/driver/data/driver_provider.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:total_flutter/features/task_management/presentation/screens/driver_task_list_screen.dart';

class DriverHomeScreen extends ConsumerWidget {
  const DriverHomeScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppUtils.showConfirmationDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
    );

    if (!confirmed) return;

    try {
      // Access repositories using Riverpod
      final driverRepository = ref.read(driverRepositoryProvider);
      final authRepository = ref.read(authRepositoryProvider);
      final driverState = ref.read(driverProvider);

      // Update the forklift's currentOperator to null and driver status
      if (driverState.driver != null) {
        await driverRepository.logoutDriver(driverState.driver!.id);
      }

      await authRepository.signOut();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppUtils.showSnackBar(
          context,
          'Error during logout: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverState = ref.watch(driverProvider);

    // Show loading indicator while driver data is being loaded
    if (driverState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message if there was an error loading driver data
    if (driverState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: ${driverState.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _logout(context, ref),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    // Driver data is loaded successfully
    final driver = driverState.driver;
    if (driver == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Driver data not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _logout(context, ref),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        leading: IconButton(
          iconSize: 26,
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(
                  user: driver,
                  isDriver: true,
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
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: DriverTaskListScreen(driverId: driver.id),
    );
  }
}
