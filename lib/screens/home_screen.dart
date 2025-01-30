import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:total_flutter/models/app_user.dart';
import 'package:total_flutter/screens/login_screen.dart';
import 'package:total_flutter/services/firebase_service.dart';
import 'package:total_flutter/src/settings/settings_controller.dart';

class HomeScreen extends StatefulWidget {
  final SettingsController settingsController;

  const HomeScreen({super.key, required this.settingsController});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final firebaseServ = FirebaseService();
    final currentUser = FirebaseAuth.instance.currentUser;
    setState(() {
      user = currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${user?.email ?? 'User'}!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            const Text('Welcome to the Home Screen!'),
          ],
        ),
      ),
    );
  }
}