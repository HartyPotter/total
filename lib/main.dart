import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:total_flutter/features/auth/domain/models/auth_state.dart';
import 'package:total_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:total_flutter/features/driver/presentation/screens/driver_home_screen.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/supervisor_home_screen.dart';
import 'package:total_flutter/features/notifications/data/notification_repository.dart';
import 'package:total_flutter/core/theme/app_theme.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:total_flutter/features/driver_management/domain/models/driver.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notificationRepo = NotificationRepository();
  await notificationRepo.initialize();
  await notificationRepo.showLocalNotification(
    title: message.notification?.title ?? 'New Notification',
    body: message.notification?.body ?? '',
    payload: message.data,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications
  final notificationRepo = NotificationRepository();
  await notificationRepo.initialize();

  // Set the background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    await notificationRepo.showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Total Flutter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Consumer<AuthState>(
        builder: (context, authState, _) {
          if (authState.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!authState.isAuthenticated) {
            return const LoginScreen();
          }

          // User is authenticated, show appropriate screen based on role
          switch (authState.userRole) {
            case AppConstants.roleDriver:
              return DriverHomeScreen(
                driver: Driver.fromMap(
                  authState.userData!,
                  authState.currentUser?.uid ?? '',
                ),
              );
            case AppConstants.roleSupervisor:
              return SupervisorHomeScreen(supervisor: authState.userData);
            default:
              // If role is not recognized, sign out and show login screen
              authState.signOut();
              return const LoginScreen();
          }
        },
      ),
    );
  }
}
