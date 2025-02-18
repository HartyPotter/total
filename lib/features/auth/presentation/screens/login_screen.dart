// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:total_flutter/features/driver/presentation/screens/driver_home_screen.dart';
import 'package:total_flutter/features/supervisor/presentation/screens/supervisor_home_screen.dart';
import 'package:total_flutter/features/auth/data/auth_repository.dart';
import 'package:total_flutter/features/driver_management/domain/models/driver.dart';
import 'package:total_flutter/features/forklift_management/domain/models/forklift.dart';
import 'package:total_flutter/core/constants/app_constants.dart';
import 'package:total_flutter/core/utils/app_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  final _firestore = FirebaseFirestore.instance;
  String _selectedRole = 'driver';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<DocumentReference?> _selectForklift(BuildContext context) async {
    if (!mounted) return null;
    final forkliftsSnapshot = await _firestore
        .collection(AppConstants.forkliftsCollection)
        .where('status', isEqualTo: AppConstants.forkliftStatusAvailable)
        .get();

    if (!mounted) return null;

    final forkliftRef = await showDialog<DocumentReference>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Forklift'),
          content: SizedBox(
            width: double.maxFinite,
            child: forkliftsSnapshot.docs.isEmpty
                ? const Text('No available forklifts')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: forkliftsSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      final forklift = Forklift.fromMap(
                        forkliftsSnapshot.docs[index].data(),
                        forkliftsSnapshot.docs[index].id,
                      );
                      return ListTile(
                        leading: const Icon(Icons.precision_manufacturing),
                        title: Text(forklift.model),
                        subtitle: Text('S/N: ${forklift.serialNumber}'),
                        onTap: () {
                          Navigator.of(context).pop(
                            _firestore
                                .collection(AppConstants.forkliftsCollection)
                                .doc(forklift.id),
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            if (forkliftsSnapshot.docs.isEmpty)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
          ],
        );
      },
    );

    return forkliftRef;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await _authRepository.signIn(
          _emailController.text,
          _passwordController.text,
          _selectedRole,
        );

        if (!mounted) return;

        final user = await _authRepository.getCurrentUser(
          userCredential.user!.uid,
          _selectedRole,
        );

        if (!mounted) return;

        if (user != null) {
          if (_selectedRole == 'driver') {
            // Show forklift selection dialog for drivers
            final forkliftRef = await _selectForklift(context);

            if (!mounted) return;

            if (forkliftRef == null) {
              AppUtils.showSnackBar(
                context,
                'Please select a forklift to continue',
                isError: true,
              );
              return;
            }

            // Update driver's assigned forklift in Firestore
            await _firestore
                .collection(AppConstants.driversCollection)
                .doc(userCredential.user!.uid)
                .update({
              'assignedForklift': forkliftRef,
              'status': AppConstants.driverStatusActive,
            });

            // Update forklift status and current operator
            await forkliftRef.update({
              'status': AppConstants.forkliftStatusInUse,
              'currentOperator': _firestore
                  .collection(AppConstants.driversCollection)
                  .doc(userCredential.user!.uid),
            });

            // Refresh driver data with updated forklift
            final updatedDriver = await _authRepository.getCurrentUser(
              userCredential.user!.uid,
              _selectedRole,
            ) as Driver;

            if (!mounted) return;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DriverHomeScreen(driver: updatedDriver),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SupervisorHomeScreen(supervisor: user),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome Back',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate().fadeIn().slideY(
                                  begin: -0.3,
                                  duration: const Duration(milliseconds: 500),
                                ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ).animate().fadeIn().slideX(
                                  begin: -0.3,
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 100),
                                ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.lock),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ).animate().fadeIn().slideX(
                                  begin: 0.3,
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 200),
                                ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.person),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'driver',
                                  child: Text('Driver'),
                                ),
                                DropdownMenuItem(
                                  value: 'supervisor',
                                  child: Text('Supervisor'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ).animate().fadeIn().slideX(
                                  begin: -0.3,
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 300),
                                ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text(
                                        'Login',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ).animate().fadeIn().slideY(
                                  begin: 0.3,
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 400),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
