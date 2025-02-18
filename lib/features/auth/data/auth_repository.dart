import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:total_flutter/core/config/app_config.dart';
import 'package:total_flutter/features/driver_management/domain/models/driver.dart';
import 'package:total_flutter/features/supervisor_management/domain/models/supervisor.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String> getAccessToken() async {
    final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson(
      AppConfig.serviceAccountCredentials,
    );

    final client = await auth.clientViaServiceAccount(
      serviceAccountCredentials,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );

    return client.credentials.accessToken.data;
  }

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

    print('Error: role not recognized');
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
