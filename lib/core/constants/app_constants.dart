class AppConstants {
  // Firebase Collections
  static const String driversCollection = 'drivers';
  static const String supervisorsCollection = 'supervisors';
  static const String tasksCollection = 'tasks';
  static const String forkliftsCollection = 'forklifts';

  // Task Status
  static const String taskStatusPending = 'pending';
  static const String taskStatusInProgress = 'in_progress';
  static const String taskStatusCompleted = 'completed';

  // Driver Status
  static const String driverStatusActive = 'active';
  static const String driverStatusInactive = 'inactive';
  static const String driverStatusBusy = 'busy';

  // Forklift Status
  static const String forkliftStatusAvailable = 'available';
  static const String forkliftStatusInUse = 'in_use';
  static const String forkliftStatusMaintenance = 'maintenance';

  // Task Types
  static const String taskTypePickup = 'pickup';
  static const String taskTypeDelivery = 'delivery';
  static const String taskTypeTransfer = 'transfer';

  // User Roles
  static const String roleDriver = 'driver';
  static const String roleSupervisor = 'supervisor';

  // Location Nodes
  static const Map<String, String> locationNodes = {
    'A': 'IBCs Storage Area',
    'B': 'Warehouse',
    'C': 'Decanting',
    'D': 'Loading Bay',
    'E': 'Finished Goods',
    'F': 'Raw Materials',
    'G': 'Production Line 1',
    'H': 'Production Line 2',
    'I': 'Quality Control',
    'J': 'Packaging',
  };

  // Location Coordinates (latitude, longitude)
  static const Map<String, Map<String, double>> locationCoordinates = {
    'A': {'lat': -26.2041, 'lng': 28.0473}, // Example coordinates
    'B': {'lat': -26.2042, 'lng': 28.0474},
    'C': {'lat': -26.2043, 'lng': 28.0475},
    'D': {'lat': -26.2044, 'lng': 28.0476},
    'E': {'lat': -26.2045, 'lng': 28.0477},
    'F': {'lat': -26.2046, 'lng': 28.0478},
    'G': {'lat': -26.2047, 'lng': 28.0479},
    'H': {'lat': -26.2048, 'lng': 28.0480},
    'I': {'lat': -26.2049, 'lng': 28.0481},
    'J': {'lat': -26.2050, 'lng': 28.0482},
  };

  // Notification Channel
  static const String notificationChannelId = 'high_importance_channel';
  static const String notificationChannelName = 'High Importance Notifications';
  static const String notificationChannelDescription =
      'This channel is used for important notifications.';

  // Error Messages
  static const String errorInvalidCredentials = 'Invalid email or password';
  static const String errorUserNotFound = 'User not found';
  static const String errorGeneric = 'An error occurred. Please try again.';
  static const String errorNoDriverSelected = 'Please select a driver';
  static const String errorTaskCreation = 'Error creating task';
  static const String errorTaskUpdate = 'Error updating task';

  // Success Messages
  static const String successTaskCreated = 'Task created successfully';
  static const String successTaskUpdated = 'Task updated successfully';
  static const String successLogin = 'Login successful';

  // Validation Messages
  static const String validationRequiredField = 'This field is required';
  static const String validationInvalidEmail = 'Please enter a valid email';
  static const String validationInvalidNumber = 'Please enter a valid number';

  // FCM Topics
  static const String fcmTopicAllDrivers = 'all_drivers';
  static const String fcmTopicAllSupervisors = 'all_supervisors';

  // API Endpoints
  // static const String fcmApiEndpoint =
  //     'https://fcm.googleapis.com/v1/projects/new-total-c0e19/messages:send';
}
