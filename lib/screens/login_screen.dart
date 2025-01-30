import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:total_flutter/models/user_role.dart';
import 'package:total_flutter/screens/driver_home_screen.dart';
import 'package:total_flutter/screens/supervisor_home_screen.dart';
import 'package:total_flutter/services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseService = FirebaseService();
  String _role = 'driver';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              DropdownButton<String>(
                value: _role,
                onChanged: (String? newValue) {
                  setState(() {
                    _role = newValue!;
                  });
                },
                items: <String>['driver', 'supervisor']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleLogin,
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userCredentials = await _firebaseService.signIn(
          _emailController.text,
          _passwordController.text,
          _role, // Pass the selected role
        );

        final userId = userCredentials.user?.uid;

        if (userId == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          );
        }

        final user = await _firebaseService.getCurrentUser(userId, _role);

        if (user != null) {
          print('User found: $user');
          // Update FCM token for notifications
          await _firebaseService.updateFCMToken(userId, _role);
          print('User can update FCMToken: $user');
          if (!mounted) return;

          // Navigate to appropriate screen based on role
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => _role == 'supervisor'
                  ? const SupervisorHomeScreen()
                  : DriverHomeScreen(driverId: userId),
            ),
          );
        } else {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          );
        }
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
