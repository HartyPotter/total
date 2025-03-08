import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String driverId;

  LocationService(this.driverId);

  Future<void> startLocationTracking() async {
    // Check and request location permissions
    var status = await Permission.location.request();
    if (status.isGranted) {
      // Start listening to location updates
      Geolocator.getPositionStream(
          locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      )).listen((Position position) async {
        // Update driver's location in Firestore
        await _firestore.collection('drivers').doc(driverId).update({
          'currentLocation': "$position.latitude, $position.longitude",
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
    } else {
      // Handle the case when permissions are not granted
      print('Location permissions not granted');
    }
  }
}
