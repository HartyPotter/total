import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:total_flutter/screens/home_screen.dart';
import 'package:total_flutter/screens/login_screen.dart';
import 'package:total_flutter/screens/task_assignment_screen.dart';
import 'package:total_flutter/screens/driver_home_screen.dart'; // Import the driver home screen
import 'package:total_flutter/screens/supervisor_home_screen.dart'; // Import the supervisor home screen
import 'package:total_flutter/services/notification_service.dart';
import 'package:total_flutter/src/settings/settings_controller.dart';
import 'package:total_flutter/src/settings/settings_service.dart';
import 'package:total_flutter/services/firebase_service.dart'; // Import FirebaseService
import 'package:total_flutter/themes/themes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');

  // Show a local notification
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    NotificationService.channelId, // Use the channel ID
    NotificationService.channelName, // Use the channel name
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: null, // Configure for iOS if needed
  );

  await FlutterLocalNotificationsPlugin().show(
    0, // Notification ID
    message.notification?.title, // Title
    message.notification?.body, // Body
    platformChannelSpecifics,
    payload: jsonEncode(message.data), // Pass any custom data
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set the background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification services
  final notificationService = NotificationService();
  notificationService.initialize();

  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  runApp(MyApp(
      settingsController: settingsController,
      navigatorKey: notificationService.navigatorKey));
}

class MyApp extends StatelessWidget {
  final SettingsController settingsController;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp(
      {super.key,
      required this.settingsController,
      required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Total App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
                    return DriverHomeScreen(
                      driverId: snapshot.data!.uid,
                      initialTabIndex: 0, // Default to the first tab
                    );
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
      routes: {
        '/taskRequests': (context) {
          // Retrieve arguments
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          final driverId = args?['driverId'] ?? '';
          final initialTabIndex = args?['initialTabIndex'] ?? 0;

          return DriverHomeScreen(
            driverId: driverId,
            initialTabIndex: initialTabIndex,
          );
        },
      },
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
