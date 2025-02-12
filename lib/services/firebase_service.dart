import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:total_flutter/models/driver.dart';
import 'package:total_flutter/models/supervisor.dart';
import 'package:total_flutter/models/task.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class FirebaseService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messaging = FirebaseMessaging.instance;

  // Authentication
  Future<UserCredential> signIn(
      String email, String password, String role) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final userId = userCredential.user?.uid;
    if (userId == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found',
      );
    }

    // Update FCM token
    await updateFCMToken(userId, role);

    // Query the appropriate collection based on the role
    final collection = role == 'driver' ? 'drivers' : 'supervisors';
    final userDoc = await _firestore.collection(collection).doc(userId).get();

    if (!userDoc.exists) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User not found in $collection collection',
      );
    }

    return userCredential;
  }

  Future<Object?> getCurrentUser(String userId, String role) async {
    final collection = role == 'driver' ? 'drivers' : 'supervisors';
    final doc = await _firestore.collection(collection).doc(userId).get();

    if (!doc.exists) {
      print("User found in $collection collection");

      return null;
    }

    if (role == 'driver') {
      print("User found in $role s collection.");
      return Driver.fromMap(doc.data()!..['id'] = userId, userId);
    } else if (role == 'supervisor') {
      print("User not found in $role collection.");

      return Supervisor.fromMap(doc.data()!..['id'] = userId, userId);
    } else {
      print('Error: role not recognized');
      return null;
    }
  }

  // Task management
  Stream<List<Task>> getTasksStream({String? driverId}) {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('tasks');

      if (driverId != null) {
        query = query.where('assignedDriverId', isEqualTo: driverId);
      }

      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Task(
            id: doc.id,
            name: data['name'],
            source: data['source'],
            destination: data['destination'],
            assignedDriverId: data['assignedDriverId'],
            status: TaskStatus.values.firstWhere(
              (status) => status.toString().split('.').last == data['status'],
            ),
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            type: data['type'],
            numberOfPallets: data['numberOfPallets'] as int,
            estimatedTime: data['estimatedTime'] as int,
            startTime: data['startTime'],
            endTime: data['endTime'],
            duration: data['duration'] as int,
          );
        }).toList();
      });
    } catch (e) {
      print('Error fetching tasks: $e');
      return Stream.empty();
    }
  }

  // Function to get the driver's tasks based on a filter
  Stream<List<Task>> getDriverTasks(
      String? driverId, String filter, dynamic value) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('tasks')
        .where('assignedDriverId', isEqualTo: driverId)
        .where(filter, isEqualTo: value);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Task.fromMap(data, doc.id); // Use the factory constructor
      }).toList();
    });
  }

  Future<List<Task>> getAllTasks() async {
    final querySnapshot = await _firestore.collection('tasks').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Task.fromMap(data, doc.id); // Use the factory constructor
    }).toList();
  }

  Future<void> createTask(Task task) async {
    final taskMap = task.toMap();

    final docRef = await _firestore.collection('tasks').add(taskMap);

    // Get driver's FCM token
    final driverDoc =
        await _firestore.collection('drivers').doc(task.assignedDriverId).get();
    final fcmToken = driverDoc.data()?['fcmToken'];

    if (fcmToken != null) {
      // Send notification using FCM
      await _sendNotificationToDriver(task.assignedDriverId, task.name);
    }
  }

  Future<String> _getAccessToken() async {
    //  Use the googleapis_auth package as you had originally intended
    final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
        ''); // Replace _firebaseServiceAccountCredentials with your credentials

    final client = await auth.clientViaServiceAccount(
      serviceAccountCredentials,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );

    return client.credentials.accessToken.data;
  }

  Future<void> _sendNotificationToDriver(
      String driverId, String taskName) async {
    final driverDoc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .get();
    final fcmToken = driverDoc.data()?['fcmToken'];

    if (fcmToken != null) {
      try {
        // Construct the FCM message payload.  Simplified using `notification` field
        final message = {
          "message": {
            "token": fcmToken,
            "notification": {
              "title": "New Task Assigned",
              "body": "You have a new task: $taskName",
            },
            "data": {
              // Include any custom data for handling in the app
              "taskName": taskName,
              "taskId": "task123" // Example - replace with actual task ID
            }
          }
        };

        // Send the HTTP request using the http package
        final response = await http.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/new-total-c0e19/messages:send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer ${await _getAccessToken()}', // Important: add access token
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

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': status,
    });
  }

  Future<void> updateTaskStartTime(String taskId, DateTime startTime) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'startTime':
          Timestamp.fromDate(startTime), // Convert DateTime to Timestamp
    });
  }

  Future<void> updateTaskEndTime(String taskId, DateTime endTime) async {
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    final startTime = taskDoc.data()?['startTime'] as Timestamp?;

    if (startTime == null) {
      throw Exception('Start time is not set for this task.');
    }

    final duration = endTime.difference(startTime.toDate()).inMinutes;

    await _firestore.collection('tasks').doc(taskId).update({
      'endTime': Timestamp.fromDate(endTime), // Convert DateTime to Timestamp
      'duration': duration,
    });
  }

  // FCM token management
  Future<void> updateFCMToken(String userId, String role) async {
    final token = await _messaging.getToken();

    print('FCM Token: $token');

    if (token != null) {
      final user = _auth.currentUser;
      if (user != null) {
        final collection = role == 'driver' ? 'drivers' : 'supervisors';
        await _firestore.collection(collection).doc(userId).update({
          'fcmToken': token,
        });
      }
    }
  }

  Stream<List<Driver>> getDriversStream() {
    try {
      return _firestore.collection('drivers').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Driver.fromMap(data, doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching drivers: $e');
      return Stream.empty();
    }
  }

  Stream<List<Driver>> getAvailableDriversStream() {
    try {
      return _firestore
          .collection('drivers')
          .where('isAvailable', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Driver.fromMap(data, doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching available drivers: $e');
      return Stream.empty();
    }
  }

  Future<List<Driver>> getAvailableDrivers() async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('isAvailable', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Driver.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching available drivers: $e');
      return [];
    }
  }

  Future<void> updateDriverStatus(String driverId, bool completed) async {
    await _firestore.collection('drivers').doc(driverId).update({
      'isAvailable': completed,
    });
  }

  Future<void> assignTaskToDriver(String driverId, String location) async {
    await _firestore.collection('drivers').doc(driverId).update({
      'currentLocation': location,
      'isAvailable': false,
    });
  }
}
