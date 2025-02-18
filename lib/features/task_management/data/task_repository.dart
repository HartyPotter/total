import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/config/app_config.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/supervisor_management/domain/models/supervisor.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/utils/path_finding_utils.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:http/http.dart' as http;

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DriverRepository _driverRepository = DriverRepository();
  final AuthRepository _authRepository = AuthRepository();

  Stream<List<Task>> getTasksStream(
      {DocumentReference? driverRef, String? status}) {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(AppConstants.tasksCollection);

      if (driverRef != null) {
        query = query.where('assignedDriver', isEqualTo: driverRef);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Task.fromMap(data, doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      return Stream.empty();
    }
  }

  Future<void> createTask(Task task) async {
    final taskMap = task.toMap();

    await _firestore.collection(AppConstants.tasksCollection).add(taskMap);

    // Only send notification if a driver is assigned
    if (task.assignedDriver != null) {
      final driverDoc = await task.assignedDriver!.get();
      final data = driverDoc.data() as Map<String, dynamic>;
      final fcmToken = data['fcmToken'];

      if (fcmToken != null) {
        await _driverRepository.sendNotificationToDriver(
            task.assignedDriver!.id, task.name, task.createdBy);
      }
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore
        .collection(AppConstants.tasksCollection)
        .doc(taskId)
        .update({
      'status': status,
    });
  }

  Future<void> updateTaskStartTime(String taskId, DateTime startTime) async {
    await _firestore
        .collection(AppConstants.tasksCollection)
        .doc(taskId)
        .update({
      'startTime': Timestamp.fromDate(startTime),
    });
  }

  Future<void> sendTaskUpdateNotification(
      String taskName, String status, DocumentReference supervisorRef) async {
        
    final supervisorDoc = await supervisorRef.get();
    final supervisor = Supervisor.fromMap(
        supervisorDoc.data() as Map<String, dynamic>, supervisorDoc.id);
    final supervisorFCMToken = supervisor.fcmToken;
    print('---------Supervistor FCM Token: $supervisorFCMToken ----------');

    if (supervisorFCMToken != null) {
      try {
        final message = {
          "message": {
            "token": supervisorFCMToken,
            "notification": {
              "title": "There is an update to a task!",
              "body": "Your task: $taskName has been updated. Status: $status",
            },
            "data": {"taskName": taskName, "status": status}
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
        print('Response Status Code: $response.statusCode');
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

  Future<void> updateTaskEndTime(String taskId, DateTime endTime) async {
    final taskDoc = await _firestore
        .collection(AppConstants.tasksCollection)
        .doc(taskId)
        .get();
    final startTime = taskDoc.data()?['startTime'] as Timestamp?;

    if (startTime == null) {
      throw Exception('Start time is not set for this task.');
    }

    final duration = endTime.difference(startTime.toDate()).inMinutes;

    await _firestore
        .collection(AppConstants.tasksCollection)
        .doc(taskId)
        .update({
      'endTime': Timestamp.fromDate(endTime),
      'duration': duration,
    });
  }

  Stream<List<Task>> getQueuedTasks() {
    return _firestore
        .collection(AppConstants.tasksCollection)
        .where('isQueued', isEqualTo: true)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> processQueuedTasks() async {
    final queuedTasksSnapshot = await _firestore
        .collection(AppConstants.tasksCollection)
        .where('isQueued', isEqualTo: true)
        .orderBy('createdAt')
        .get();

    if (queuedTasksSnapshot.docs.isEmpty) return;

    final availableDrivers = await _driverRepository.getAvailableDriversOnce(true);
    if (availableDrivers.isEmpty) return;

    // final driverLocations = await _driverRepository.getDriverLocations();

    for (var doc in queuedTasksSnapshot.docs) {
      final task = Task.fromMap(doc.data(), doc.id);
      final sourceLocationId = task.source.split(':')[0].trim();

      final nearestDriverId = PathFindingUtils.findNearestAvailableDriver(
        sourceLocationId,
        availableDrivers,
      );

      if (nearestDriverId != null) {
        // Update task with assigned driver and remove from queue
        await _firestore
            .collection(AppConstants.tasksCollection)
            .doc(doc.id)
            .update({
          'assignedDriverId': nearestDriverId,
          'isQueued': false,
        });

        // Send notification to the assigned driver
        await _driverRepository.sendNotificationToDriver(
            nearestDriverId, task.name, task.createdBy);

        // Update driver status to busy
        await _firestore
            .collection(AppConstants.driversCollection)
            .doc(nearestDriverId)
            .update({
          'status': AppConstants.driverStatusBusy,
        });

        // Remove this driver from available drivers list
        availableDrivers
            .removeWhere((driver) => driver['id'] == nearestDriverId);
        if (availableDrivers.isEmpty) break;
      }
    }
  }
}
