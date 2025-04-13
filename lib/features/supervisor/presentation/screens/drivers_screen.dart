import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/core/widgets/app_button.dart';
import 'package:total_flutter/core/widgets/entity_card.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/driver/presentation/screens/driver_details_screen.dart';
import 'package:total_flutter/features/supervisor/data/supervisor_provider.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverRepository = ref.watch(driverRepositoryProvider);
    final taskRepository = ref.watch(taskRepositoryProvider);
    final supervisorState = ref.watch(supervisorProvider);

    return StreamBuilder<List<Driver>>(
      stream: driverRepository.getAllDrivers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final drivers = snapshot.data!;

        if (drivers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No drivers found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];

            // Simplified details map with minimal information
            final Map<String, String> details = {
              'Status': driver.status.toJson(),
            };

            // Only show task info if driver has an active task
            if (driver.currentTask != null && driver.currentTask!.isNotEmpty) {
              return FutureBuilder<Task?>(
                future: taskRepository.getTaskById(driver.currentTask),
                builder: (context, taskSnapshot) {
                  if (taskSnapshot.connectionState == ConnectionState.waiting) {
                    // Show a loading indicator only for this card
                    return _buildDriverCard(context, driver, details, index);
                  }

                  if (taskSnapshot.hasData && taskSnapshot.data != null) {
                    details['Current Task'] = taskSnapshot.data!.name;
                  }

                  return _buildDriverCard(context, driver, details, index);
                },
              );
            }

            return _buildDriverCard(context, driver, details, index);
          },
        );
      },
    );
  }

  Widget _buildDriverCard(BuildContext context, Driver driver,
      Map<String, String> details, int index) {
    return EntityCard(
      title: driver.name,
      subtitle: driver.email,
      status: driver.status.toJson(),
      icon: Icons.person,
      details: details,
      index: index,
      actions: [
        AppButton(
          text: 'View Details',
          type: AppButtonType.outline,
          size: AppButtonSize.small,
          leadingIcon: Icons.visibility,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverDetailsScreen(driver: driver),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        AppButton(
          text: 'Assign Task',
          type: AppButtonType.primary,
          size: AppButtonSize.small,
          leadingIcon: Icons.assignment_add,
          onPressed: () {
            // Navigate to task assignment screen
          },
        ),
      ],
    );
  }
}
