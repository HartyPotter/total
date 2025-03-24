import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
// import 'package:total_flutter/features/driver/data/driver_repository.dart';
// import 'package:total_flutter/features/task_management/domain/models/task.dart';
import 'package:total_flutter/features/forklift_management/domain/models/forklift.dart';

class ForkliftRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ForkliftRepository();

  Future<void> createForklift(Map<String, dynamic> forkliftData) async {
    try {
      await _firestore.collection('forklifts').add(forkliftData);
    } catch (e) {
      print('Error creating forklift: $e');
      rethrow;
    }
  }

  Future<void> updateForklift(
      String forkliftId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(AppConstants.forkliftsCollection)
          .doc(forkliftId)
          .update(updates);
    } catch (e) {
      print('Error updating forklift: $e');
      rethrow;
    }
  }

  Future<Forklift?> getForkliftById(String? forkliftId) async {
    try {
      // Return null if forkliftId is null or empty
      if (forkliftId == null || forkliftId.isEmpty) {
        return null;
      }

      final doc = await _firestore
          .collection(AppConstants.forkliftsCollection)
          .doc(forkliftId)
          .get();
      if (doc.exists) {
        return Forklift.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching forklift by ID: $e');
      return null;
    }
  }

  Future<List<Forklift>> getAllForklifts() async {
    try {
      final querySnapshot =
          await _firestore.collection(AppConstants.forkliftsCollection).get();

      return querySnapshot.docs
          .map((doc) => Forklift.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching all forklifts: $e');
      rethrow;
    }
  }

  Future<void> updateForkliftStatus(String forkliftId, String status) async {
    await _firestore
        .collection(AppConstants.forkliftsCollection)
        .doc(forkliftId)
        .update({
      'status': status,
    });
  }

  Future<List<Forklift>> getAvailableForklifts() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.forkliftsCollection)
          .where('status', isEqualTo: AppConstants.forkliftStatusAvailable)
          .get();
      return querySnapshot.docs
          .map((doc) => Forklift.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching available forklifts: $e');
      rethrow;
    }
  }

  Stream<Forklift> getForkliftStream() {
    return _firestore
        .collection(AppConstants.forkliftsCollection)
        .doc()
        .snapshots()
        .map((doc) => Forklift.fromMap(doc.data()!, doc.id));
  }
}
