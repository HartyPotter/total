
import 'package:total_flutter/models/driver.dart';
import 'package:total_flutter/models/forklift.dart';
import 'package:total_flutter/services/firebase_service.dart';
final _firebaseService = FirebaseService();

final forklifts = [
  Forklift(id: '1', name: 'Forklift 1', currentLocation: 'A'),
  Forklift(id: '2', name: 'Forklift 2', currentLocation: 'B'),
];

final drivers = [
  _firebaseService.getDriversStream() as Iterable<Driver>,
];
