import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/supervisor_management/domain/models/supervisor.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/config/app_config.dart';
import 'package:http/http.dart' as http;

class DriverRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _authRepository = AuthRepository();

  Stream<List<Map<String, dynamic>>> getAvailableDrivers() {
    return _firestore
        .collection(AppConstants.driversCollection)
        .where('status', whereIn: [
          AppConstants.driverStatusActive,
          AppConstants.driverStatusBusy
        ])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'status': data['status'] ?? AppConstants.driverStatusInactive,
            };
          }).toList();
        });
  }

  Future<void> sendNotificationToDriver(
      String driverId, String taskName, DocumentReference supervisorRef) async {
    final driverDoc = await _firestore
        .collection(AppConstants.driversCollection)
        .doc(driverId)
        .get();
    final fcmToken = driverDoc.data()?['fcmToken'];

    if (fcmToken != null) {
      try {
        // Fetch the supervisor's name using the DocumentReference
        final supervisorDoc = await supervisorRef.get();
        final supervisor = Supervisor.fromMap(
            supervisorDoc.data() as Map<String, dynamic>, supervisorDoc.id);
        final supervisorName = supervisor.name;

        final message = {
          "message": {
            "token": fcmToken,
            "notification": {
              "title": "New Task Assigned",
              "body": "You have a new task: $taskName from $supervisorName",
            },
            "data": {"taskName": taskName, "supervisorName": supervisorName}
          }
        };

        final response = await http.post(
          Uri.parse(AppConfig.fcmApiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await _authRepository.getAccessToken()}',
          },
          body: json.encode(message),
        );

        if (response.statusCode == 200) {
          print('Notification sent successfully');
        } else {
          print('Failed to send notification: ${response.body}');
        }
      } catch (e) {
        print('Error sending notification: $e');
      }
    } else {
      print('Driver FCM token not found');
    }
  }

  // Future<List<Map<String, dynamic>>> getAvailableDriversOnce() async {
  //   final snapshot = await _firestore
  //       .collection(AppConstants.driversCollection)
  //       .where('status', whereIn: [
  //     AppConstants.driverStatusActive,
  //     // AppConstants.driverStatusBusy
  //   ]).get();

  //   return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  // }

  Future<List<Map<String, dynamic>>> getAvailableDriversOnce(
      bool withLocation) async {
    final snapshot = await _firestore
        .collection(AppConstants.driversCollection)
        .where('status', whereIn: [
      AppConstants.driverStatusActive,
    ]).get();

    if (withLocation) {
      // Return a list of maps containing driver IDs and their locations
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'location': data.containsKey('currentLocation')
              ? data['currentLocation']
              : null,
        };
      }).toList();
    } else {
      // Return a list of maps containing all driver data
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    }
  }

  // Add a method to check driver availability
  Future<bool> areDriversAvailable() async {
    final availableDrivers = await getAvailableDriversOnce(false);
    return availableDrivers.isNotEmpty;
  }

  DocumentReference getDriver(String driverId) {
    return _firestore.collection(AppConstants.driversCollection).doc(driverId);
  }

  Future<void> updateDriverStatus(String driverId, String status) async {
    final driverDoc =
        _firestore.collection(AppConstants.driversCollection).doc(driverId);
    driverDoc.update({
      'status': status,
    });
  }
}
