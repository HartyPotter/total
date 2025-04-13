import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';

// Driver state class to manage all driver-related state
class DriverState {
  final Driver? driver;
  final bool isLoading;
  final String? error;
  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final GeoPoint? currentLocation;
  final bool isLocationUpdating;

  DriverState({
    this.driver,
    this.isLoading = false,
    this.error,
    this.activeTasks = const [],
    this.completedTasks = const [],
    this.currentLocation,
    this.isLocationUpdating = false,
  });

  DriverState copyWith({
    Driver? driver,
    bool? isLoading,
    String? error,
    List<Task>? activeTasks,
    List<Task>? completedTasks,
    GeoPoint? currentLocation,
    bool? isLocationUpdating,
  }) {
    return DriverState(
      driver: driver ?? this.driver,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeTasks: activeTasks ?? this.activeTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      currentLocation: currentLocation ?? this.currentLocation,
      isLocationUpdating: isLocationUpdating ?? this.isLocationUpdating,
    );
  }
}

// Driver notifier to manage the driver state
class DriverNotifier extends StateNotifier<DriverState> {
  final DriverRepository _driverRepository;
  final FirebaseFirestore _firestore;

  // Stream subscriptions to be disposed
  StreamSubscription? _driverSubscription;
  StreamSubscription? _activeTasksSubscription;
  StreamSubscription? _completedTasksSubscription;

  DriverNotifier(this._driverRepository, this._firestore)
      : super(DriverState());

  // Initialize driver data with userId
  Future<void> initialize(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get driver data
      final driver = await _driverRepository.getDriverById(userId);
      if (driver == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Driver not found',
        );
        return;
      }

      // Set initial state with driver data
      state = state.copyWith(
        driver: driver,
        currentLocation: driver.currentLocation,
        isLoading: false,
      );

      // Setup listeners for real-time updates
      _listenToDriverUpdates(userId);
      _listenToActiveTasks(userId);
      _listenToCompletedTasks(userId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error initializing driver: $e',
      );
    }
  }

  // Listen to real-time driver updates
  void _listenToDriverUpdates(String driverId) {
    _driverSubscription?.cancel();
    _driverSubscription = _firestore
        .collection('drivers')
        .doc(driverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final updatedDriver = Driver.fromMap(
          snapshot.data() as Map<String, dynamic>,
          driverId,
        );
        state = state.copyWith(
          driver: updatedDriver,
          currentLocation: updatedDriver.currentLocation,
        );
      }
    }, onError: (error) {
      state = state.copyWith(error: 'Error in driver updates: $error');
    });
  }

  // Listen to active tasks
  void _listenToActiveTasks(String driverId) {
    _activeTasksSubscription?.cancel();
    _activeTasksSubscription = _driverRepository
        .getAssignedTasksByStatus(driverId, 'in_progress')
        .listen((tasks) {
      state = state.copyWith(activeTasks: tasks);
    }, onError: (error) {
      state = state.copyWith(error: 'Error fetching active tasks: $error');
    });
  }

  // Listen to completed tasks
  void _listenToCompletedTasks(String driverId) {
    _completedTasksSubscription?.cancel();
    _completedTasksSubscription = _driverRepository
        .getAssignedTasksByStatus(driverId, 'completed')
        .listen((tasks) {
      state = state.copyWith(completedTasks: tasks);
    }, onError: (error) {
      state = state.copyWith(error: 'Error fetching completed tasks: $error');
    });
  }

  // Update driver location
  Future<void> updateLocation(GeoPoint location) async {
    if (state.driver == null) return;

    state = state.copyWith(isLocationUpdating: true);
    try {
      await _driverRepository.updateDriverLocation(state.driver!.id, location);
      state = state.copyWith(
        currentLocation: location,
        isLocationUpdating: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error updating location: $e',
        isLocationUpdating: false,
      );
    }
  }

  // Update driver status
  Future<void> updateStatus(DriverStatus status) async {
    if (state.driver == null) return;

    try {
      await _driverRepository.updateDriverStatus(
        state.driver!.id,
        status.toJson(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Error updating status: $e');
    }
  }

  // Start a task
  Future<void> startTask(String taskId) async {
    if (state.driver == null) return;

    try {
      // Update driver status to busy
      await _driverRepository.updateDriverStatus(
        state.driver!.id,
        DriverStatus.busy.toJson(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Error starting task: $e');
    }
  }

  // Complete a task
  Future<void> completeTask(String taskId) async {
    if (state.driver == null) return;

    try {
      // Update driver status to active
      await _driverRepository.updateDriverStatus(
        state.driver!.id,
        DriverStatus.active.toJson(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Error completing task: $e');
    }
  }

  // Dispose of all stream subscriptions
  @override
  void dispose() {
    _driverSubscription?.cancel();
    _activeTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();
    super.dispose();
  }
}

// Provider for the driver state
final driverProvider =
    StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  final driverRepository = ref.watch(driverRepositoryProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  return DriverNotifier(driverRepository, firestore);
});
