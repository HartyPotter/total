import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/interfaces/firebase_model.dart';

enum ForkliftStatus {
  available,
  inUse,
  maintenance;

  String toJson() {
    switch (this) {
      case ForkliftStatus.available:
        return AppConstants.forkliftStatusAvailable;
      case ForkliftStatus.inUse:
        return AppConstants.forkliftStatusInUse;
      case ForkliftStatus.maintenance:
        return AppConstants.forkliftStatusMaintenance;
    }
  }

  static ForkliftStatus fromJson(String status) {
    switch (status) {
      case AppConstants.forkliftStatusAvailable:
        return ForkliftStatus.available;
      case AppConstants.forkliftStatusInUse:
        return ForkliftStatus.inUse;
      case AppConstants.forkliftStatusMaintenance:
        return ForkliftStatus.maintenance;
      default:
        return ForkliftStatus.available;
    }
  }
}

class Forklift implements FirebaseModel {
  @override
  final String id;
  final String model;
  final String serialNumber;
  final int capacity; // in kilograms
  final ForkliftStatus status;
  final DateTime lastMaintenance;
  final DateTime nextMaintenanceDue;
  final DocumentReference? currentOperator;
  final String location;
  final Map<String, dynamic>? specifications;
  final bool isOperational;

  Forklift({
    required this.id,
    required this.model,
    required this.serialNumber,
    required this.capacity,
    required this.status,
    required this.lastMaintenance,
    required this.nextMaintenanceDue,
    this.currentOperator,
    required this.location,
    this.specifications,
    required this.isOperational,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'serialNumber': serialNumber,
      'capacity': capacity,
      'status': status.toJson(),
      'lastMaintenance': Timestamp.fromDate(lastMaintenance),
      'nextMaintenanceDue': Timestamp.fromDate(nextMaintenanceDue),
      'currentOperator': currentOperator,
      'location': location,
      'specifications': specifications,
      'isOperational': isOperational,
    };
  }

  factory Forklift.fromMap(Map<String, dynamic> map, String id) {
    return Forklift(
      id: id,
      model: map['model'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      capacity: map['capacity'] ?? 0,
      status: ForkliftStatus.fromJson(
          map['status'] ?? AppConstants.forkliftStatusAvailable),
      lastMaintenance: (map['lastMaintenance'] as Timestamp).toDate(),
      nextMaintenanceDue: (map['nextMaintenanceDue'] as Timestamp).toDate(),
      currentOperator: map['currentOperator'] as DocumentReference?,
      location: map['location'] ?? '',
      specifications: map['specifications'],
      isOperational: map['isOperational'] ?? true,
    );
  }

  Forklift copyWith({
    String? id,
    String? model,
    String? serialNumber,
    int? capacity,
    ForkliftStatus? status,
    DateTime? lastMaintenance,
    DateTime? nextMaintenanceDue,
    DocumentReference? currentOperator,
    String? location,
    Map<String, dynamic>? specifications,
    bool? isOperational,
  }) {
    return Forklift(
      id: id ?? this.id,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenanceDue: nextMaintenanceDue ?? this.nextMaintenanceDue,
      currentOperator: currentOperator ?? this.currentOperator,
      location: location ?? this.location,
      specifications: specifications ?? this.specifications,
      isOperational: isOperational ?? this.isOperational,
    );
  }
}
