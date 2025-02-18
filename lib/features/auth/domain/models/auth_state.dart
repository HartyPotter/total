import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:total_flutter/core/constants/app_constants.dart';

class AuthState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => _auth.currentUser != null;
  User? get currentUser => _auth.currentUser;

  String _userRole = '';
  String get userRole => _userRole;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  AuthState() {
    _initialize();
  }

  Future<void> _initialize() async {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await _loadUserData();
      } else {
        _userData = null;
        _userRole = '';
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check in drivers collection first
      var driverDoc = await _firestore
          .collection(AppConstants.driversCollection)
          .doc(user.uid)
          .get();

      if (driverDoc.exists) {
        _userData = driverDoc.data();
        _userRole = AppConstants.roleDriver;
        return;
      }

      // If not found in drivers, check supervisors collection
      var supervisorDoc = await _firestore
          .collection(AppConstants.supervisorsCollection)
          .doc(user.uid)
          .get();

      if (supervisorDoc.exists) {
        _userData = supervisorDoc.data();
        _userRole = AppConstants.roleSupervisor;
        return;
      }

      // If user not found in either collection, sign them out
      await signOut();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      await signOut();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUserData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userData = null;
      _userRole = '';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
