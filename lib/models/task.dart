class Task {
  final String id;
  final String name;
  final String type;
  final String location;
  final int numberOfPallets;
  final int estimatedTime;
  final int actualTime;
  String assignedDriverId;
  TaskStatus status;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.name,
    required this.type,
    required this.numberOfPallets,
    required this.estimatedTime,
    required this.actualTime,
    required this.location,
    required this.assignedDriverId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'assignedDriverId': assignedDriverId,
      'status': status
          .toString()
          .split('.')
          .last, // Extract "assigned", "inProgress", etc.
      'createdAt': createdAt,
      'type': type,
      'numberOfPallets': numberOfPallets,
      'estimatedTime': estimatedTime,
      'actualTime': actualTime,
    };
  }

  String get dispalayLocationName {
    return locationMapping[location] ?? location;
  }
}

enum TaskStatus {
  assigned,
  inProgress,
  completed,
  unknown,
}


const Map<String, String> locationMapping = {
  'A': 'IBCs storage area',
  'B': 'Warehouse',
  'C': 'Empty packs warehouse',
  'D': 'Decanting',
  'E': 'FP Drums warehouse',
  'F': 'Production',
  'G': "Empty loading dock",
};