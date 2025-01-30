import 'package:flutter/material.dart';
import 'package:total_flutter/models/driver.dart';
import 'package:total_flutter/models/forklift.dart';
import 'package:total_flutter/services/firebase_service.dart';

class DriversAndForkliftsScreen extends StatefulWidget {
  const DriversAndForkliftsScreen({super.key});

  @override
  _DriversAndForkliftsScreenState createState() =>
      _DriversAndForkliftsScreenState();
}

class _DriversAndForkliftsScreenState extends State<DriversAndForkliftsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final List<Forklift> forklifts = [];

  @override
  void initState() {
    super.initState();
    _initializeForklifts();
  }

  void _initializeForklifts() {
    // Initialize forklifts
    forklifts.addAll([
      Forklift(id: '1', name: 'Forklift 1', currentLocation: 'A'),
      Forklift(id: '2', name: 'Forklift 2', currentLocation: 'B'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Drivers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Driver>>(
            stream: _firebaseService.getDriversStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No drivers available'));
              }
              final drivers = snapshot.data!;
              return Column(
                children: drivers
                    .map((driver) => Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.person,
                              color: driver.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(driver.name),
                            subtitle: Text(
                              'Location: ${driver.currentLocation}\n'
                              'Status: ${driver.isAvailable ? "Available" : "Busy"}',
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Forklifts',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...forklifts.map((forklift) => Card(
                child: ListTile(
                  leading: const Icon(Icons.fork_right),
                  title: Text(forklift.name),
                  subtitle: Text('Location: ${forklift.currentLocation}'),
                ),
              )),
        ],
      ),
    );
  }
}