import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/features/supervisor/domain/supervisor.dart';
import 'package:total_flutter/features/supervisor/data/supervisor_repository.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';

// Supervisor state class to manage all supervisor-related state
class SupervisorState {
  final Supervisor? supervisor;
  final bool isLoading;
  final String? error;
  final List<Task> pendingTasks;
  final List<Task> inProgressTasks;
  final List<Task> completedTasks;
  final List<Driver> availableDrivers;
  final Map<String, Driver> driverCache; // For caching driver data

  SupervisorState({
    this.supervisor,
    this.isLoading = false,
    this.error,
    this.pendingTasks = const [],
    this.inProgressTasks = const [],
    this.completedTasks = const [],
    this.availableDrivers = const [],
    this.driverCache = const {},
  });

  SupervisorState copyWith({
    Supervisor? supervisor,
    bool? isLoading,
    String? error,
    List<Task>? pendingTasks,
    List<Task>? inProgressTasks,
    List<Task>? completedTasks,
    List<Driver>? availableDrivers,
    Map<String, Driver>? driverCache,
  }) {
    return SupervisorState(
      supervisor: supervisor ?? this.supervisor,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      driverCache: driverCache ?? this.driverCache,
    );
  }
}

// Supervisor notifier to manage the supervisor state
class SupervisorNotifier extends StateNotifier<SupervisorState> {
  final SupervisorRepository _supervisorRepository;
  final FirebaseFirestore _firestore;

  // Stream subscriptions to be disposed
  StreamSubscription? _supervisorSubscription;
  StreamSubscription? _pendingTasksSubscription;
  StreamSubscription? _inProgressTasksSubscription;
  StreamSubscription? _completedTasksSubscription;
  StreamSubscription? _availableDriversSubscription;

  SupervisorNotifier(this._supervisorRepository, this._firestore)
      : super(SupervisorState());

  // Initialize supervisor data with userId
  Future<void> initialize(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get supervisor data
      final supervisor = await _supervisorRepository.getSupervisorById(userId);
      if (supervisor == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Supervisor not found',
        );
        return;
      }

      // Set initial state with supervisor data
      state = state.copyWith(
        supervisor: supervisor,
        isLoading: false,
      );

      // Setup listeners for real-time updates
      _listenToSupervisorUpdates(userId);
      _listenToPendingTasks();
      _listenToInProgressTasks();
      _listenToCompletedTasks();
      _listenToAvailableDrivers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error initializing supervisor: $e',
      );
    }
  }

  // Listen to real-time supervisor updates
  void _listenToSupervisorUpdates(String supervisorId) {
    _supervisorSubscription?.cancel();
    _supervisorSubscription = _firestore
        .collection('supervisors')
        .doc(supervisorId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final updatedSupervisor = Supervisor.fromMap(
          snapshot.data() as Map<String, dynamic>,
          supervisorId,
        );
        state = state.copyWith(supervisor: updatedSupervisor);
      }
    }, onError: (error) {
      state = state.copyWith(error: 'Error in supervisor updates: $error');
    });
  }

  // Listen to pending tasks
  void _listenToPendingTasks() {
    _pendingTasksSubscription?.cancel();
    _pendingTasksSubscription = _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final pendingTasks = snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
      state = state.copyWith(pendingTasks: pendingTasks);
    }, onError: (error) {
      state = state.copyWith(error: 'Error fetching pending tasks: $error');
    });
  }

  // Listen to in-progress tasks
  void _listenToInProgressTasks() {
    _inProgressTasksSubscription?.cancel();
    _inProgressTasksSubscription = _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'in_progress')
        .orderBy('startTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      final inProgressTasks = snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
      state = state.copyWith(inProgressTasks: inProgressTasks);
    }, onError: (error) {
      state = state.copyWith(error: 'Error fetching in-progress tasks: $error');
    });
  }

  // Listen to completed tasks
  void _listenToCompletedTasks() {
    _completedTasksSubscription?.cancel();
    _completedTasksSubscription = _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .orderBy('endTime', descending: true)
        .limit(20) // Limit to avoid loading too much data
        .snapshots()
        .listen((snapshot) {
      final completedTasks = snapshot.docs.map((doc) {
        return Task.fromMap(doc.data(), doc.id);
      }).toList();
      state = state.copyWith(completedTasks: completedTasks);
    }, onError: (error) {
      state = state.copyWith(error: 'Error fetching completed tasks: $error');
    });
  }

  // Listen to available drivers
  void _listenToAvailableDrivers() {
    _availableDriversSubscription?.cancel();
    _availableDriversSubscription = _firestore
        .collection('drivers')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
      final availableDrivers = snapshot.docs.map((doc) {
        return Driver.fromMap(doc.data(), doc.id);
      }).toList();
      state = state.copyWith(availableDrivers: availableDrivers);
    }, onError: (error) {
      state = state.copyWith(error: 'Error fetching available drivers: $error');
    });
  }

  // Get a driver by ID with caching
  Future<Driver?> getDriver(String driverId) async {
    // Return from cache if available
    if (state.driverCache.containsKey(driverId)) {
      return state.driverCache[driverId];
    }

    try {
      // Fetch driver and update cache
      final driverDoc =
          await _firestore.collection('drivers').doc(driverId).get();
      if (driverDoc.exists) {
        final driver = Driver.fromMap(
          driverDoc.data() as Map<String, dynamic>,
          driverId,
        );

        // Update the cache with the new driver
        final updatedCache = Map<String, Driver>.from(state.driverCache);
        updatedCache[driverId] = driver;

        state = state.copyWith(driverCache: updatedCache);
        return driver;
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Error fetching driver: $e');
      return null;
    }
  }

  // Assign task to driver
  Future<void> assignTaskToDriver(String taskId, String driverId) async {
    try {
      // Update the task with the assigned driver
      await _firestore.collection('tasks').doc(taskId).update({
        'assignedDriver': driverId,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(error: 'Error assigning task: $e');
    }
  }

  // Create a new task
  Future<void> createTask(Map<String, dynamic> taskData) async {
    try {
      await _firestore.collection('tasks').add({
        ...taskData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(error: 'Error creating task: $e');
    }
  }

  // Update task
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      state = state.copyWith(error: 'Error updating task: $e');
    }
  }

  // Dispose of all stream subscriptions
  @override
  void dispose() {
    _supervisorSubscription?.cancel();
    _pendingTasksSubscription?.cancel();
    _inProgressTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();
    _availableDriversSubscription?.cancel();
    super.dispose();
  }
}

// Provider for the supervisor state
final supervisorProvider =
    StateNotifierProvider<SupervisorNotifier, SupervisorState>((ref) {
  final supervisorRepository = ref.watch(supervisorRepositoryProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return SupervisorNotifier(supervisorRepository, firestore);
});
