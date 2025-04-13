import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/features/forklift_management/domain/models/forklift.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/widgets/modern_card.dart';

class ForkliftsScreen extends ConsumerWidget {
  const ForkliftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forkliftRepository = ref.watch(forkliftRepositoryProvider);
    final driverRepository = ref.watch(driverRepositoryProvider);

    return StreamBuilder<List<Forklift>>(
      stream: forkliftRepository.getAllForkliftsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final forklifts = snapshot.data!;

        if (forklifts.isEmpty) {
          return const Center(child: Text('No forklifts found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: forklifts.length,
          itemBuilder: (context, index) {
            final forklift = forklifts[index];
            return ModernCard(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppUtils.getForkliftStatusColor(
                    forklift.status.toJson(),
                  ).withOpacity(0.1),
                  child: Icon(
                    Icons.precision_manufacturing,
                    color: AppUtils.getForkliftStatusColor(
                      forklift.status.toJson(),
                    ),
                  ),
                ),
                title: Text(
                  'Model: ${forklift.model}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('S/N: ${forklift.serialNumber}'),
                    Text('Location: ${forklift.location}'),
                    Text('Capacity: ${forklift.capacity} Pallets'),
                    if (forklift.currentOperator != null)
                      FutureBuilder<dynamic>(
                        future: driverRepository
                            .getDriverById(forklift.currentOperator!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Loading operator...');
                          }
                          if (snapshot.hasData) {
                            final driver = snapshot.data;
                            return Text('Operator: ${driver.name}');
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    Text(
                      'Last Maintenance: ${AppUtils.formatDate(forklift.lastMaintenance)}',
                    ),
                    Text(
                      'Next Due: ${AppUtils.formatDate(forklift.nextMaintenanceDue)}',
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppUtils.getForkliftStatusColor(
                                forklift.status.toJson())
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppUtils.getForkliftStatusColor(
                              forklift.status.toJson()),
                        ),
                      ),
                      child: Text(
                        'Status: ${forklift.status.toJson()}',
                        style: TextStyle(
                          color: AppUtils.getForkliftStatusColor(
                              forklift.status.toJson()),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
