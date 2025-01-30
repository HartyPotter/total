class Driver {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  late final String currentLocation;
  late final bool isAvailable;
  final String? fcmToken;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.currentLocation,
    required this.isAvailable,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'currentLocation': currentLocation,
      'isAvailable': isAvailable,
      'fcmToken': fcmToken,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map, String id) {
    return Driver(
      id: id,
      name: map['name'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      currentLocation: map['currentLocation'] ?? 'Unknown',
      isAvailable: map['isAvailable'] ?? true,
      fcmToken: map['fcmToken'],
    );
  }
}
