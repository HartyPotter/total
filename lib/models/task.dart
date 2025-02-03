import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String name;
  final String type;
  final String source; // New field
  final String destination; // New field
  final int numberOfPallets;
  final int estimatedTime;
  final DateTime? startTime; // Updated to nullable
  final DateTime? endTime; // Updated to nullable
  final int? duration; // New field
  String assignedDriverId;
  TaskStatus status;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.name,
    required this.type,
    required this.source, // New field
    required this.destination, // New field
    required this.numberOfPallets,
    required this.estimatedTime,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.assignedDriverId,
    required this.status,
    required this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> data, String id) {
    return Task(
      id: id,
      name: data['name'],
      type: data['type'],
      source: data['source'],
      destination: data['destination'],
      numberOfPallets: data['numberOfPallets'],
      estimatedTime: data['estimatedTime'],
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp)
              .toDate() // Convert Timestamp to DateTime
          : null,
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp)
              .toDate() // Convert Timestamp to DateTime
          : null,
      duration: data['duration'],
      assignedDriverId: data['assignedDriverId'],
      status: TaskStatus.values.firstWhere(
        (status) => status.toString().split('.').last == data['status'],
        orElse: () => TaskStatus.unknown,
      ),
      createdAt: (data['createdAt'] as Timestamp)
          .toDate(), // Convert Timestamp to DateTime
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'source': source, // New field
      'destination': destination, // New field
      'numberOfPallets': numberOfPallets,
      'estimatedTime': estimatedTime,
      'startTime': startTime,
      'endTime': endTime,
      'duration': duration,
      'assignedDriverId': assignedDriverId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
    };
  }

  String displayLocationName(String location) {
    return locationMapping[location] ?? location;
  }

  String get taskCompletionTime {
    if (endTime == null || startTime == null) {
      return '0'; // Return '0' if either startTime or endTime is null
    }
    return endTime!.difference(startTime!).inMinutes.toString();
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
