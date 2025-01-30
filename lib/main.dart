import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:total_flutter/screens/home_screen.dart';
import 'package:total_flutter/screens/login_screen.dart';
import 'package:total_flutter/screens/task_assignment_screen.dart';
import 'package:total_flutter/screens/driver_home_screen.dart'; // Import the driver home screen
import 'package:total_flutter/screens/supervisor_home_screen.dart'; // Import the supervisor home screen
import 'package:total_flutter/src/settings/settings_controller.dart';
import 'package:total_flutter/src/settings/settings_service.dart';
import 'package:total_flutter/services/firebase_service.dart'; // Import FirebaseService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  runApp(MyApp(settingsController: settingsController));
}

class MyApp extends StatelessWidget {
  final SettingsController settingsController;

  const MyApp({super.key, required this.settingsController});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Total App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // User is logged in, determine their role and redirect accordingly
            return FutureBuilder<String?>(
              future: _getUserRole(snapshot.data!.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (roleSnapshot.hasData) {
                  final role = roleSnapshot.data;
                  if (role == 'supervisor') {
                    return const SupervisorHomeScreen();
                  } else if (role == 'driver') {
                    return DriverHomeScreen(driverId: snapshot.data!.uid);
                  } else {
                    return const LoginScreen(); // Fallback to login if role is unknown
                  }
                } else {
                  return const LoginScreen(); // Fallback to login if role cannot be determined
                }
              },
            );
          } else {
            // User is not logged in, show the login screen
            return const LoginScreen();
          }
        },
      ),
    );
  }

  // Helper function to get the user's role from Firestore
  Future<String?> _getUserRole(String userId) async {
    final firebaseService = FirebaseService();
    final driverDoc = await firebaseService.getCurrentUser(userId, 'driver');
    if (driverDoc != null) {
      return 'driver';
    }

    final supervisorDoc =
        await firebaseService.getCurrentUser(userId, 'supervisor');
    if (supervisorDoc != null) {
      return 'supervisor';
    }

    return null; // Role not found
  }
}

class MainScreen extends StatefulWidget {
  final SettingsController settingsController;

  const MainScreen({super.key, required this.settingsController});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(settingsController: widget.settingsController),
      const TaskAssignmentScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Task Assignment',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
