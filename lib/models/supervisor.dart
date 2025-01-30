class Supervisor {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? fcmToken;

  Supervisor({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'fcmToken': fcmToken,
    };
  }

  factory Supervisor.fromMap(Map<String, dynamic> map, String id) {
    return Supervisor(
      id: id,
      name: map['name'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      fcmToken: map['fcmToken'],
    );
  }
}
