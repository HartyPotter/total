import 'package:total_flutter/models/user_role.dart';

class AppUser {
  final String id;
  final String email;
  final String fcmToken;
  final String name;
  final UserRole role;
  // final String? driverId;

  AppUser({
    required this.id,
    required this.email,
    required this.fcmToken,
    required this.name,
    required this.role,
    // this.driverId,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'],
      email: data['email'],
      fcmToken: data['fcmToken'],
      name: data['name'],
      role: UserRole.values.firstWhere((e) => e.toString() == 'UserRole.${data['role']}'),
      // driverId: data['driverId'],
    );
  }
}
