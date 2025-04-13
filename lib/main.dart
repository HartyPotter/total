import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/providers/providers.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/auth/domain/models/auth_state.dart';
import 'package:total_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:total_flutter/features/driver/data/driver_provider.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/driver/presentation/screens/driver_home_screen.dart';
import 'package:total_flutter/features/supervisor/data/supervisor_provider.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/supervisor_home_screen.dart';
import 'package:total_flutter/features/notifications/data/notification_repository.dart';
import 'package:total_flutter/core/theme/app_theme.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  FirebaseFunctions.instanceFor(region: 'us-central1')
      .useFunctionsEmulator('10.0.2.2', 5001);

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
    const ProviderScope(
      child: TotalFlutterApp(),
    ),
  );
}

// Auth state provider
final authStateProvider = ChangeNotifierProvider<AuthState>((ref) {
  return AuthState();
});

class TotalFlutterApp extends ConsumerWidget {
  const TotalFlutterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final driverNotifier = ref.read(driverProvider.notifier);
    final supervisorNotifier = ref.read(supervisorProvider.notifier);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Total Flutter',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          if (authState.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!authState.isAuthenticated) {
            return const LoginScreen();
          }

          final userId = authState.currentUser?.uid ?? '';

          // User is authenticated, show appropriate screen based on role
          switch (authState.userRole) {
            case AppConstants.roleDriver:
              // Initialize driver provider with user ID
              WidgetsBinding.instance.addPostFrameCallback((_) {
                driverNotifier.initialize(userId);
              });

              return const DriverHomeScreen();

            case AppConstants.roleSupervisor:
              // Initialize supervisor provider with user ID
              WidgetsBinding.instance.addPostFrameCallback((_) {
                supervisorNotifier.initialize(userId);
              });

              return const SupervisorHomeScreen();

            default:
              // If role is not recognized, sign out and show login screen
              authState.signOut();
              return const LoginScreen();
          }
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
