import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:total_flutter/core/config/app_config.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/supervisor_management/domain/models/supervisor.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/utils/path_finding_utils.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:http/http.dart' as http;

class TaskRepository {
  DriverRepository? _driverRepository;

  TaskRepository(this._driverRepository); // Inject DriverRepository

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepository _authRepository = AuthRepository();

  void setDriverRepository(DriverRepository driverRepository) {
    _driverRepository = driverRepository;
  }

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
    try {
      // Get Firebase Functions instance
      final functions = FirebaseFunctions.instance;

      // Convert the task to a map that can be sent to the function
      final taskData = task.toJson();

      print("------------------$taskData----------------");
      // Call the Cloud Function
      final result =
          await functions.httpsCallable('create_task').call(taskData);
      print("------------------${result.data}----------------");
      // Handle the response
      if (result.data[0]['success'] == true) {
        print('Task created successfully via Cloud Function');
      } else {
        throw Exception('Failed to create task: ${result.data['error']}');
      }
    } catch (e) {
      print('Error creating task: $e');
      throw e;
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
    print(
        '-------------------Task Update Notification Sent--------------------');
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

  Future<List<Task>> _fetchQueuedTasks() async {
    final queuedTasksSnapshot = await _firestore
        .collection(AppConstants.tasksCollection)
        .where('isQueued', isEqualTo: true)
        .orderBy('createdAt')
        .get();

    return queuedTasksSnapshot.docs.map((doc) {
      return Task.fromMap(doc.data(), doc.id);
    }).toList();
  }

  Future<void> processQueuedTasks() async {
    print(
        "---------------------------QUEUED TASKS ARE BEING PROCESSED---------------------------");
    final queuedTasks = await _fetchQueuedTasks();
    final availableDrivers =
        await _driverRepository?.getAvailableDriversOnce(true);

    if (availableDrivers!.isEmpty) return;

    for (var task in queuedTasks) {
      final sourceLocationId = task.source.split(':')[0].trim();

      final nearestDriverId = PathFindingUtils.findNearestAvailableDriver(
        sourceLocationId,
        availableDrivers,
      );

      if (nearestDriverId != null) {
        await _assignTaskToDriver(task.id, nearestDriverId, task);

        // Remove this driver from available drivers list
        availableDrivers
            .removeWhere((driver) => driver['id'] == nearestDriverId);
        if (availableDrivers.isEmpty) break;
      }
    }
  }

  // Helper function to assign a task to a driver
  Future<void> _assignTaskToDriver(
      String taskId, String driverId, Task task) async {
    try {
      // Update the task with the driver's ID
      await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .update({
        'assignedDriver': driverId, // Use ID instead of DocumentReference
        'isQueued': false,
      });

      // Send a notification to the driver
      // await _driverRepository?.sendNotificationToDriver(
      //   driverId,
      //   task.name,
      //   task.createdBy,
      // );

      print('Task $taskId assigned to driver $driverId');
    } catch (e) {
      print('Error assigning task to driver: $e');
    }
  }
}
