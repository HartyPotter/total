import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:total_flutter/screens/driver_home_screen.dart';
import 'package:total_flutter/screens/supervisor_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Use a GlobalKey to access the navigator state
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Define your notification channel ID and name
  static const String channelId = 'driver_notifications';
  static const String channelName = 'Driver Notifications';

  Future<void> initialize() async {
    // Request notification permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Use your app's launcher icon
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: null, // Configure for iOS if needed
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick(response.payload);
      },
    );

    // Configure notification channel for Android
    await _configureNotificationChannel();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationClick(jsonEncode(message.data));
    });

    // Handle initial notification when the app is launched from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App launched from terminated state by a notification');
        _handleNotificationClick(jsonEncode(message.data));
      }
    });
  }

  void _handleNotificationClick(String? payload) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final role = await _getUserRole(userId);

      if (role == 'driver') {
        // Navigate to DriverHomeScreen
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DriverHomeScreen(
              driverId: userId,
              initialTabIndex: 2, // Switch to Task Requests tab
            ),
          ),
        );
      } else if (role == 'supervisor') {
        // Navigate to SupervisorHomeScreen
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => SupervisorHomeScreen(),
          ),
        );
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId, // Use the channel ID
      channelName, // Use the channel name
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: null, // Configure for iOS if needed
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      message.notification?.title, // Title
      message.notification?.body, // Body
      platformChannelSpecifics,
      payload: jsonEncode(message.data), // Pass any custom data
    );
  }

  Future<void> _configureNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId, // Use the channel ID
      channelName, // Use the channel name
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<String?> _getUserRole(String userId) async {
    final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(userId).get();
    if (driverDoc.exists) {
      return 'driver';
    }

    final supervisorDoc = await FirebaseFirestore.instance.collection('supervisors').doc(userId).get();
    if (supervisorDoc.exists) {
      return 'supervisor';
    }

    return null; // Role not found
  }
}