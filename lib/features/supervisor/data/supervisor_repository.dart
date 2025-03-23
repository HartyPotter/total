import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/features/supervisor/domain/supervisor.dart';

class SupervisorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Create a Supervisor
  Future<void> createSupervisor(Map<String, dynamic> supervisor) async {
    try {
      await _firestore
          .collection(AppConstants.supervisorsCollection)
          .doc(supervisor["id"])
          .set(supervisor);
    } catch (e) {
      print('Error creating supervisor: $e');
      rethrow;
    }
  }

  // 2. Get a Supervisor by ID
  Future<Supervisor?> getSupervisorById(String supervisorId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.supervisorsCollection)
          .doc(supervisorId)
          .get();
      if (doc.exists) {
        return Supervisor.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching supervisor by ID: $e');
      rethrow;
    }
  }

  // 3. Get All Supervisors
  Stream<List<Supervisor>> getAllSupervisors() {
    try {
      return _firestore
          .collection(AppConstants.supervisorsCollection)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Supervisor.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching all supervisors: $e');
      return Stream.empty();
    }
  }

  // 4. Update a Supervisor
  Future<void> updateSupervisor(
      String supervisorId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(AppConstants.supervisorsCollection)
          .doc(supervisorId)
          .update(updates);
    } catch (e) {
      print('Error updating supervisor: $e');
      rethrow;
    }
  }

  // 5. Delete a Supervisor
  Future<void> deleteSupervisor(String supervisorId) async {
    try {
      await _firestore
          .collection(AppConstants.supervisorsCollection)
          .doc(supervisorId)
          .delete();
    } catch (e) {
      print('Error deleting supervisor: $e');
      rethrow;
    }
  }

  // Future<void> logoutSupervisor(String supervisorId) async {
  //   try {
  //     await _firestore
  //         .collection(AppConstants.supervisorsCollection)
  //         .doc(supervisorId);
  //   } catch (e) {
  //     print('Error logging out supervisor: $e');
  //     rethrow;
  //   }
  // }
}
