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

  // Location Nodes: Map node IDs to friendly names
  static const Map<String, String> locationNodes = {
    "C_K_11": "IBCs Storage Area",
    "C_K_9": "Warehouse",
    "J_B_12": "Dispatching",
    "J": "Decanting",
    "J_B_8": "FP drums WH",
    "J_B_3": "Empty Packs WH",
    "I_J_11": "Epty Drums WH",
    "I_J_14": "Production",
    "J_K_9": "FP WH",
    "K_H_9": "Old Dock",
  };

  // Location Coordinates: Map node IDs to latitude and longitude
  static const Map<String, Map<String, double>> locationCoordinates = {
    'A': {'lat': 30.820554604623414, 'lng': 29.546057483127896},
    'B': {'lat': 30.820260057121438, 'lng': 29.546270280117717},
    'C': {'lat': 30.819639025614194, 'lng': 29.54673734605301},
    'D': {'lat': 30.81944089144428, 'lng': 29.546910381899725},
    'E': {'lat': 30.81941010028658, 'lng': 29.54717383287354},
    'F': {'lat': 30.820099552109408, 'lng': 29.548369495002003},
    'G': {'lat': 30.820360605393255, 'lng': 29.54830558086204},
    'H': {'lat': 30.82045833284901, 'lng': 29.54824946112797},
    'I': {'lat': 30.821102260595847, 'lng': 29.547774002266603},
    'J': {'lat': 30.820669852207352, 'lng': 29.54700391479106},
    'K': {'lat': 30.82005135758362, 'lng': 29.547441960493085},
    'L': {'lat': 30.821219798821193, 'lng': 29.547916639191765},
  };

  // Graph edges: Map node IDs to their connected nodes
  static const Map<String, List<String>> graphEdges = {
    'A': ['B'],
    'B': ['A', 'C', 'J'],
    'C': ['B', 'D', 'K'],
    'D': ['C', 'E'],
    'E': ['D', 'F'],
    'F': ['E', 'G'],
    'G': ['F', 'H'],
    'H': ['G', 'I', 'K'],
    'I': ['H', 'L', 'J'],
    'J': ['B', 'I', 'K'],
    'K': ['C', 'H', 'J'],
    'L': ['I'],
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
