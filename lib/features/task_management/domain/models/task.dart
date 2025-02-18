import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/interfaces/firebase_model.dart';

enum TaskStatus {
  pending,
  inProgress,
  completed;

  String toJson() {
    switch (this) {
      case TaskStatus.pending:
        return AppConstants.taskStatusPending;
      case TaskStatus.inProgress:
        return AppConstants.taskStatusInProgress;
      case TaskStatus.completed:
        return AppConstants.taskStatusCompleted;
    }
  }

  static TaskStatus fromJson(String status) {
    switch (status) {
      case AppConstants.taskStatusPending:
        return TaskStatus.pending;
      case AppConstants.taskStatusInProgress:
        return TaskStatus.inProgress;
      case AppConstants.taskStatusCompleted:
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }
}

class Task implements FirebaseModel {
  @override
  final String id;
  final String name;
  final String source;
  final String destination;
  final DocumentReference? assignedDriver;
  final DocumentReference createdBy;
  final TaskStatus status;
  final DateTime createdAt;
  final String type;
  final int numberOfPallets;
  final int estimatedTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final int duration;
  final bool isQueued;

  Task({
    required this.id,
    required this.name,
    required this.source,
    required this.destination,
    this.assignedDriver,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.type,
    required this.numberOfPallets,
    required this.estimatedTime,
    this.startTime,
    this.endTime,
    this.duration = 0,
    this.isQueued = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source': source,
      'destination': destination,
      'assignedDriver': assignedDriver,
      'createdBy': createdBy,
      'status': status.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'numberOfPallets': numberOfPallets,
      'estimatedTime': estimatedTime,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration,
      'isQueued': isQueued,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      name: map['name'] ?? '',
      source: map['source'] ?? '',
      destination: map['destination'] ?? '',
      assignedDriver: map['assignedDriver'] as DocumentReference?,
      createdBy: map['createdBy'],
      status:
          TaskStatus.fromJson(map['status'] ?? AppConstants.taskStatusPending),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      type: map['type'] ?? AppConstants.taskTypePickup,
      numberOfPallets: map['numberOfPallets'] ?? 0,
      estimatedTime: map['estimatedTime'] ?? 0,
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      endTime: map['endTime'] != null
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      duration: map['duration'] ?? 0,
      isQueued: map['isQueued'] ?? false,
    );
  }

  Task copyWith({
    String? id,
    String? name,
    String? source,
    String? destination,
    DocumentReference? assignedDriver,
    DocumentReference? createdBy,
    TaskStatus? status,
    DateTime? createdAt,
    String? type,
    int? numberOfPallets,
    int? estimatedTime,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    bool? isQueued,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      numberOfPallets: numberOfPallets ?? this.numberOfPallets,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isQueued: isQueued ?? this.isQueued,
    );
  }
}
