class TaskList {
  // Location Nodes: Map node IDs to friendly names
  static const Map<String, String> taskNodes = {
    "IBCs Storage Area": "C_K_11",
    "Warehouse": "C_K_9",
    "Dispatching": "J_B_12",
    "Decanting": "J",
    "FP drums WH": "J_B_8",
    "Empty Packs WH": "J_B_3",
    "Empty Drums WH": "I_J_11",
    "Production": "I_J_14",
    "FP WH": "J_K_9",
    "Old Dock": "K_H_9",
  };

  // Location Coordinates: Map node IDs to latitude and longitude
  static const Map<String, dynamic> taskCoordinates = {
    "IBCs Storage Area": (30.819891006262175, 29.54716794376639),
    "Warehouse": (30.81984519159891, 29.547089653273048),
    "Dispatching": (30.82039665548341, 29.54651482500883),
    "Decanting": (30.820669852207352, 29.54700391479106),
    "FP drums WH": (30.820487721058058, 29.54667785493624),
    "Empty Packs WH": (30.820601553026368, 29.546881642345504),
    "Empty Drums WH": (30.820822466932704, 29.547275710370663),
    "Production": (30.820746159570028, 29.547139812580863),
    "FP WH": (30.82034241387714, 29.54723582133919),
    "Old Dock": (30.820266815077062, 29.5478694608292),
  };

  // Getter for task names
  static List<String> get getTaskNames => taskNodes.keys.toList();

  // Getter for task coordinates
  static Map<String, dynamic> get coordinates => taskCoordinates;

  // Method to get the node ID for a specific task name
  static String? getNodeId(String taskName) {
    return taskNodes[taskName];
  }

  // Method to get the coordinates for a specific task name
  static dynamic getCoordinates(String taskName) {
    return taskCoordinates[taskName];
  }
}