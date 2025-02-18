import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/features/driver_management/domain/models/driver.dart';
import 'package:total_flutter/features/forklift_management/domain/models/forklift.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/core/constants/app_constants.dart';

class DriversAndForkliftsScreen extends StatelessWidget {
  const DriversAndForkliftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Drivers & Forklifts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Drivers'),
              Tab(text: 'Forklifts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DriversTab(),
            _ForkliftsTab(),
          ],
        ),
      ),
    );
  }
}

class _DriversTab extends StatelessWidget {
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
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = Driver.fromMap(
              drivers[index].data() as Map<String, dynamic>,
              drivers[index].id,
            );
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(driver.name),
                subtitle: Text(driver.email),
                trailing: Text(
                  driver.status.toJson(),
                  style: TextStyle(
                    color:
                        AppUtils.getDriverStatusColor(driver.status.toJson()),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ForkliftsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.forkliftsCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final forklifts = snapshot.data!.docs;

        if (forklifts.isEmpty) {
          return const Center(child: Text('No forklifts found'));
        }

        return ListView.builder(
          itemCount: forklifts.length,
          itemBuilder: (context, index) {
            final forklift = Forklift.fromMap(
              forklifts[index].data() as Map<String, dynamic>,
              forklifts[index].id,
            );
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.precision_manufacturing),
                ),
                title: Text(forklift.model),
                subtitle: Text('S/N: ${forklift.serialNumber}'),
                trailing: Text(
                  forklift.status.toJson(),
                  style: TextStyle(
                    color: AppUtils.getForkliftStatusColor(
                        forklift.status.toJson()),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
