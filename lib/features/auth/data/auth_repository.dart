import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:total_flutter/core/config/app_config.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/supervisor/domain/supervisor.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/features/supervisor/data/supervisor_repository.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final TaskRepository _taskRepository;
  final DriverRepository _driverRepository;
  final SupervisorRepository _supervisorRepository;

  AuthRepository({
    required TaskRepository taskRepository,
    required DriverRepository driverRepository,
    required SupervisorRepository supervisorRepository,
  })  : _taskRepository = taskRepository,
        _driverRepository = driverRepository,
        _supervisorRepository = supervisorRepository;

  Future<String> getAccessToken() async {
    // TODO: Use secure storage for service account credentials
    final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
      AppConfig.serviceAccountCredentials,
    );

    final client = await auth.clientViaServiceAccount(
      serviceAccountCredentials,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );

    return client.credentials.accessToken.data;
  }

  Future<void> registerUser(
      String userType, Map<String, dynamic> userData) async {
    userData['createdAt'] = FieldValue.serverTimestamp();

    UserCredential userCredentials;
    try {
      userCredentials = await _auth.createUserWithEmailAndPassword(
        email: userData['email'],
        password: userData['password'],
      );
      userData['id'] = userCredentials.user!.uid;
    } catch (e) {
      print('Error creating user in Firebase: $e');
      rethrow;
    }

    try {
      if (userType == AppConstants.roleDriver) {
        await _driverRepository.createDriver(userData);
      } else if (userType == AppConstants.roleSupervisor) {
        await _supervisorRepository.createSupervisor(userData);
      } else {
        throw Exception('Invalid user type: $userType');
      }
    } catch (e) {
      // Clean up Firebase Auth user if Firestore operation fails
      await userCredentials.user?.delete();
      print('Error saving user data in Firestore: $e');
      rethrow;
    }
  }

  Future<UserCredential> signIn(
      String username, String password, String role) async {
    if (role != AppConstants.roleDriver &&
        role != AppConstants.roleSupervisor) {
      throw FirebaseAuthException(
        code: 'invalid-role',
        message: 'Invalid role: $role',
      );
    }

    final userCredential = await _auth.signInWithEmailAndPassword(
      email: '$username@gmail.com',
      password: password,
    );

    final userId = userCredential.user?.uid;
    if (userId == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: AppConstants.errorUserNotFound,
      );
    }

    // Update FCM token
    final fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      final collection = role == AppConstants.roleDriver
          ? AppConstants.driversCollection
          : AppConstants.supervisorsCollection;
      await _firestore.collection(collection).doc(userId).update({
        'fcmToken': fcmToken,
      });
    }

    // Query the appropriate collection based on the role
    final collection = role == AppConstants.roleDriver
        ? AppConstants.driversCollection
        : AppConstants.supervisorsCollection;
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
    if (role != AppConstants.roleDriver &&
        role != AppConstants.roleSupervisor) {
      print('Error: role not recognized');
      return null;
    }

    final collection = role == AppConstants.roleDriver
        ? AppConstants.driversCollection
        : AppConstants.supervisorsCollection;
    final doc = await _firestore.collection(collection).doc(userId).get();

    if (!doc.exists) {
      print("User not found in $collection collection");
      return null;
    }

    if (role == AppConstants.roleDriver) {
      return Driver.fromMap(doc.data()!, doc.id);
    } else if (role == AppConstants.roleSupervisor) {
      return Supervisor.fromMap(doc.data()!, doc.id);
    }

    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
