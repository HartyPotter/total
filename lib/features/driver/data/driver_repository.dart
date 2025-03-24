import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';

class DriverRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructor
  DriverRepository();

  // 1. Create a Driver
  Future<void> createDriver(Map<String, dynamic> driver) async {
    try {
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driver["id"])
          .set(driver);
    } catch (e) {
      print('Error creating driver: $e');
      rethrow;
    }
  }

  // 2. Get a Driver by ID
  Future<Driver?> getDriverById(String driverId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .get();
      if (doc.exists) {
        return Driver.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching driver by ID: $e');
      rethrow;
    }
  }

  // 3. Get All Drivers
  Stream<List<Driver>> getAllDrivers() {
    try {
      return _firestore
          .collection(AppConstants.driversCollection)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Driver.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching all drivers: $e');
      return Stream.empty();
    }
  }

  // 4. Update a Driver
  Future<void> updateDriver(
      String? driverId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .update(updates);
    } catch (e) {
      print('Error updating driver: $e');
      rethrow;
    }
  }

  // 5. Delete a Driver
  Future<void> deleteDriver(String driverId) async {
    try {
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .delete();
    } catch (e) {
      print('Error deleting driver: $e');
      rethrow;
    }
  }

  // 6. Update Driver Status
  Future<void> updateDriverStatus(String driverId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .update({'status': status});
    } catch (e) {
      print('Error updating driver status: $e');
      rethrow;
    }
  }

  // 7. Get Drivers by Status
  Stream<List<Driver>> getDriversByStatus(String status) {
    try {
      return _firestore
          .collection(AppConstants.driversCollection)
          .where('status', isEqualTo: status)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Driver.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching drivers by status: $e');
      return Stream.empty();
    }
  }

  // 8. Update Driver Location
  Future<void> updateDriverLocation(String driverId, GeoPoint location) async {
    try {
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .update({
        'currentLocation': location,
        'lastUpdated': FieldValue.serverTimestamp()
      });
    } catch (e) {
      print('Error updating driver location: $e');
      rethrow;
    }
  }

  // 9. Get Assigned Tasks
  Stream<List<Task>> getAssignedTasks(String driverId) {
    try {
      return _firestore
          .collection(AppConstants.tasksCollection)
          .where('assignedDriver', isEqualTo: driverId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching assigned tasks: $e');
      return Stream.empty();
    }
  }

  // 9. Get Assigned Tasks
  Stream<List<Task>> getAssignedTasksByStatus(String driverId, String? status) {
    try {
      return _firestore
          .collection(AppConstants.tasksCollection)
          .where('assignedDriver', isEqualTo: driverId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching assigned tasks: $e');
      return Stream.empty();
    }
  }

  // 10.Login Driver
  Future<void> loginDriver(String driverId, forkliftId) async {
    try {
      // Update driver status to active and assign forklift
      await updateDriver(driverId, {
        'status': AppConstants.driverStatusActive,
        'assignedForklift': forkliftId
      });

      // Update forklift status to in use and assign driver
      await _firestore
          .collection(AppConstants.forkliftsCollection)
          .doc(forkliftId)
          .update({
        'status': AppConstants.forkliftStatusInUse,
        'currentOperator': driverId
      });
    } catch (e) {
      print('Error logging in driver: $e');
      rethrow;
    }
  }

  // 11. Assign Forklift to Driver
  Future<void> assignForkliftToDriver(
      String driverId, String forkliftId) async {
    try {
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .update({'assignedForklift': forkliftId});
      await _firestore
          .collection(AppConstants.forkliftsCollection)
          .doc(forkliftId)
          .update({
        'status': AppConstants.forkliftStatusInUse,
        "assignedDriver": driverId
      });
    } catch (e) {
      print('Error assigning forklift to driver: $e');
      rethrow;
    }
  }

  // 12. Unassign Forklift from Driver
  Future<void> unassignForkliftFromDriver(String driverId) async {
    try {
      final assignedForkliftId = await getAssignedForklift(driverId);

      // Update driver's assigned forklift to null
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .update({'assignedForklift': null});

      // Update forklift status to available and remove assigned driver
      await _firestore
          .collection(AppConstants.forkliftsCollection)
          .doc(assignedForkliftId)
          .update({
        "status": AppConstants.forkliftStatusAvailable,
        "assignedDriver": null
      });
    } catch (e) {
      print('Error unassigning forklift from driver: $e');
      rethrow;
    }
  }

  // 13. Get Assigned Forklift
  Future<String?> getAssignedForklift(String driverId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .get();
      if (doc.exists) {
        return doc.data()?['assignedForklift'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching assigned forklift: $e');
      rethrow;
    }
  }

  // 14. Logout Driver
  Future<void> logoutDriver(String driverId) async {
    try {
      // Fetch the driver's assigned forklift
      String? forkliftId = await getAssignedForklift(driverId);
      // Update driver status to inactive and remove assigned forklift
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .update({
        'status': AppConstants.driverStatusInactive,
        "assignedForklift": null
      });

      // Update forklift status to available and remove assigned driver
      await _firestore
          .collection(AppConstants.forkliftsCollection)
          .doc(forkliftId)
          .update({
        'status': AppConstants.forkliftStatusAvailable,
        "currentOperator": null
      });
    } catch (e) {
      print('Error logging out driver: $e');
      rethrow;
    }
  }

  // 15. Search Drivers by Name
  Stream<List<Driver>> searchDriversByName(String name) {
    try {
      return _firestore
          .collection(AppConstants.driversCollection)
          .where('name', isGreaterThanOrEqualTo: name)
          .where('name', isLessThan: '${name}z')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Driver.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error searching drivers by name: $e');
      return Stream.empty();
    }
  }

  // 16. Update Driver Profile
  Future<void> updateDriverProfile(
      String driverId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(AppConstants.driversCollection)
          .doc(driverId)
          .update(updates);
    } catch (e) {
      print('Error updating driver profile: $e');
      rethrow;
    }
  }
}
