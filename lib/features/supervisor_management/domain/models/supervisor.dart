import 'package:total_flutter/core/interfaces/firebase_model.dart';

class Supervisor implements FirebaseModel {
  @override
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? fcmToken;
  // final DateTime joinDate;
  // final List<String> managedAreas;
  // final List<String> permissions;
  // final Map<String, dynamic>? schedule;

  Supervisor({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.fcmToken,
    // required this.joinDate,
    // required this.managedAreas,
    // required this.permissions,
    // this.schedule,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'fcmToken': fcmToken,
    //   'joinDate': Timestamp.fromDate(joinDate),
    //   'managedAreas': managedAreas,
    //   'permissions': permissions,
    //   'schedule': schedule,
    };
  }

  factory Supervisor.fromMap(Map<String, dynamic> map, String id) {
    return Supervisor(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      fcmToken: map['fcmToken'],
      // joinDate: (map['joinDate'] as Timestamp).toDate(),
      // managedAreas: List<String>.from(map['managedAreas'] ?? []),
      // permissions: List<String>.from(map['permissions'] ?? []),
      // schedule: map['schedule'],
    );
  }

  Supervisor copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? fcmToken,
    // DateTime? joinDate,
    // List<String>? managedAreas,
    // List<String>? permissions,
    // Map<String, dynamic>? schedule,
  }) {
    return Supervisor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fcmToken: fcmToken ?? this.fcmToken,
      // joinDate: joinDate ?? this.joinDate,
      // managedAreas: managedAreas ?? this.managedAreas,
      // permissions: permissions ?? this.permissions,
      // schedule: schedule ?? this.schedule,
    );
  }
}
