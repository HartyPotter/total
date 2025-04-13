import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/supervisor/data/supervisor_repository.dart';
import 'package:total_flutter/features/task_management/data/task_repository.dart';
import 'package:total_flutter/features/forklift_management/data/forklift_repository.dart';
import 'package:total_flutter/features/notifications/data/notification_repository.dart';

// Firebase providers
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Repository providers
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

final supervisorRepositoryProvider = Provider<SupervisorRepository>((ref) {
  return SupervisorRepository();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final driverRepository = ref.watch(driverRepositoryProvider);
  return TaskRepository(driverRepository: driverRepository);
});

final forkliftRepositoryProvider = Provider<ForkliftRepository>((ref) {
  return ForkliftRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  final driverRepository = ref.watch(driverRepositoryProvider);
  final supervisorRepository = ref.watch(supervisorRepositoryProvider);

  return AuthRepository(
    taskRepository: taskRepository,
    driverRepository: driverRepository,
    supervisorRepository: supervisorRepository,
  );
});
