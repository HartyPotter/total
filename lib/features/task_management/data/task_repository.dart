import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/features/driver/data/driver_repository.dart';
import 'package:total_flutter/features/task_management/domain/models/task.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final DriverRepository _driverRepository;

  // Constructor to inject DriverRepository
  TaskRepository({required DriverRepository driverRepository})
      : _driverRepository = driverRepository;

  // 1. Create a Task
  Future<void> createTask(Task task) async {
    try {
      await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(task.id)
          .set(task.toMap());
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  // 2. Get a Task by ID
  Future<Task?> getTaskById(String taskId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .get();
      if (doc.exists) {
        return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching task by ID: $e');
      rethrow;
    }
  }

  // 3. Get All Tasks
  Stream<List<Task>> getAllTasks() {
    try {
      return _firestore
          .collection(AppConstants.tasksCollection)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching all tasks: $e');
      return Stream.empty();
    }
  }

  // 4. Update a Task
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .update(updates);
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  // 5. Delete a Task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .delete();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  // 6. Update Task Status
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .update({'status': status});
    } catch (e) {
      print('Error updating task status: $e');
      rethrow;
    }
  }

  // 7. Update Task Start Time
  Future<void> updateTaskStartTime(String taskId, DateTime startTime) async {
    try {
      await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .update({'startTime': Timestamp.fromDate(startTime)});
    } catch (e) {
      print('Error updating task start time: $e');
      rethrow;
    }
  }

  // 8. Update Task End Time
  Future<void> updateTaskEndTime(String taskId, DateTime endTime) async {
    try {
      await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .update({'endTime': Timestamp.fromDate(endTime)});
    } catch (e) {
      print('Error updating task end time: $e');
      rethrow;
    }
  }

  // 9. Get Tasks by Status
  Stream<List<Task>> getTasksByStatus(String status) {
    try {
      return _firestore
          .collection(AppConstants.tasksCollection)
          .where('status', isEqualTo: status)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Task.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching tasks by status: $e');
      return Stream.empty();
    }
  }

  // 10. Accept a Task
  Future<void> acceptTask(String taskId) async {
    try {
      // Get the task
      final task = await getTaskById(taskId);

      // Update task status to in progress and set a start time
      await updateTask(taskId, {
        "status": AppConstants.taskStatusInProgress,
        "startTime": Timestamp.now()
      });

      // Update driver status to busy and assign the task
      await _driverRepository.updateDriver(task?.assignedDriver,
          {"status": AppConstants.driverStatusBusy, "currentTask": taskId});
    } catch (e) {
      print('Error accepting task: $e');
      rethrow;
    }
  }

  // 10. Accept a Task
  Future<void> completeTask(String taskId) async {
    try {
      // Get the task
      final task = await getTaskById(taskId);

      // Update task status to in progress and set a start time
      await updateTask(taskId, {
        "status": AppConstants.taskStatusCompleted,
        "endTime": Timestamp.now()
      });

      // Update driver status to active and remove current task
      await _driverRepository.updateDriver(task?.assignedDriver,
          {"status": AppConstants.driverStatusActive, "currentTask": null});
    } catch (e) {
      print('Error completing task: $e');
      rethrow;
    }
  }
}
