import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/features/driver_management/domain/models/driver.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/forklift_management/domain/models/forklift.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/widgets/modern_card.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  Future<Task?> _fetchCurrentTask(DocumentReference reference) async {
    final doc = await reference.get();
    if (doc.exists) {
      return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<Forklift?> _fetchForklift(DocumentReference reference) async {
    final doc = await reference.get();
    if (doc.exists) {
      return Forklift.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.driversCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final drivers = snapshot.data!.docs;

        if (drivers.isEmpty) {
          return const Center(child: Text('No drivers found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = Driver.fromMap(
              drivers[index].data() as Map<String, dynamic>,
              drivers[index].id,
            );
            return ModernCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppUtils.getDriverStatusColor(
                        driver.status.toJson(),
                      ).withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: AppUtils.getDriverStatusColor(
                          driver.status.toJson(),
                        ),
                      ),
                    ),
                    title: Text(
                      driver.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.email),
                        Text(driver.phoneNumber),
                        if (driver.currentLocation != null) ...[
                          const SizedBox(height: 4),
                          Text('Current Location: ${driver.currentLocation}'),
                        ],
                        if (driver.assignedForklift != null) ...[
                          const SizedBox(height: 4),
                          FutureBuilder<Forklift?>(
                            future: _fetchForklift(driver.assignedForklift!),
                            builder: (context, forkliftSnapshot) {
                              print('Driver: ${driver.name}');
                              print(
                                  'Assigned Forklift Reference: ${driver.assignedForklift}');
                              print('Forklift Data: ${forkliftSnapshot.data}');
                              if (forkliftSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text('Loading forklift info...');
                              }
                              final forklift = forkliftSnapshot.data;
                              if (forklift == null) {
                                print('No forklift data found');

                                return const SizedBox.shrink();
                              }
                              print(
                                  'Forklift Details - Model: ${forklift.model}, Serial: ${forklift.serialNumber}');

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppUtils.getForkliftStatusColor(
                                    forklift.status.toJson(),
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppUtils.getForkliftStatusColor(
                                      forklift.status.toJson(),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Assigned Forklift: ${forklift.model} (${forklift.serialNumber})',
                                  style: TextStyle(
                                    color: AppUtils.getForkliftStatusColor(
                                      forklift.status.toJson(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppUtils.getDriverStatusColor(
                                    driver.status.toJson())
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppUtils.getDriverStatusColor(
                                  driver.status.toJson()),
                            ),
                          ),
                          child: Text(
                            'Status: ${driver.status.toJson()}',
                            style: TextStyle(
                              color: AppUtils.getDriverStatusColor(
                                  driver.status.toJson()),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                  if (driver.currentTask != null) ...[
                    const SizedBox(height: 4),
                    FutureBuilder<Task?>(
                      future: _fetchCurrentTask(driver.currentTask!),
                      builder: (context, taskSnapshot) {
                        if (taskSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final task = taskSnapshot.data;
                        if (task == null) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              Text(
                                'Current Task',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text('Task: ${task.name}'),
                              Text('From: ${task.source}'),
                              Text('To: ${task.destination}'),
                              Text('Status: ${task.status.toJson()}'),
                              if (task.startTime != null)
                                Text(
                                    'Started: ${AppUtils.formatDateTime(task.startTime!)}'),
                              if (task.estimatedTime > 0)
                                Text(
                                    'Estimated Time: ${task.estimatedTime} minutes'),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
