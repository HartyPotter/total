import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/interfaces/firebase_model.dart';

enum DriverStatus {
  active,
  inactive,
  busy;

  String toJson() {
    switch (this) {
      case DriverStatus.active:
        return AppConstants.driverStatusActive;
      case DriverStatus.inactive:
        return AppConstants.driverStatusInactive;
      case DriverStatus.busy:
        return AppConstants.driverStatusBusy;
    }
  }

  static DriverStatus fromJson(String status) {
    switch (status) {
      case AppConstants.driverStatusActive:
        return DriverStatus.active;
      case AppConstants.driverStatusInactive:
        return DriverStatus.inactive;
      case AppConstants.driverStatusBusy:
        return DriverStatus.busy;
      default:
        return DriverStatus.inactive;
    }
  }
}

class Driver implements FirebaseModel {
  @override
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final DriverStatus status;
  final String? fcmToken;
  final DocumentReference? currentTask;
  final DocumentReference? assignedForklift;
  final String? currentLocation;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.status,
    this.fcmToken,
    this.currentTask,
    this.assignedForklift,
    this.currentLocation,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'status': status.toJson(),
      'fcmToken': fcmToken,
      'currentTask': currentTask,
      'assignedForklift': assignedForklift,
      'currentLocation': currentLocation,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map, String id) {
    return Driver(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      status: DriverStatus.fromJson(
          map['status'] ?? AppConstants.driverStatusInactive),
      fcmToken: map['fcmToken'],
      currentTask: map['currentTask'] as DocumentReference?,
      assignedForklift: map['assignedForklift'] as DocumentReference?,
      currentLocation: map['currentLocation'],
    );
  }

  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    DriverStatus? status,
    String? fcmToken,
    DocumentReference? currentTask,
    DocumentReference? assignedForklift,
    String? currentLocation,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
      currentTask: currentTask ?? this.currentTask,
      assignedForklift: assignedForklift ?? this.assignedForklift,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}
