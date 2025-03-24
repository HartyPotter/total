import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:total_flutter/features/task_management/presentation/screens/driver_task_list_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final Driver driver;

  const DriverHomeScreen({super.key, required this.driver});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Future<void> _logout() async {
    final confirmed = await AppUtils.showConfirmationDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
    );

    if (!confirmed || !mounted) return;

    try {
      // Access repositories using Provider
      final driverRepository =
          Provider.of<DriverRepository>(context, listen: false);
      final authRepository =
          Provider.of<AuthRepository>(context, listen: false);

      // Update the forklift's currentOperator to null and driver status
      await driverRepository.logoutDriver(widget.driver.id);

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
                  user: widget.driver,
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
            onPressed: _logout,
          ),
        ],
      ),
      body: DriverTaskListScreen(driverId: widget.driver.id),
    );
  }
}
