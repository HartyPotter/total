import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppUtils {
  // Date formatting
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  // Duration formatting
  static String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0) {
      return '$hours hr ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
    }
    return '$minutes min';
  }

  // Status color mapping
  static Color getTaskStatusColor(String status) {
    switch (status) {
      case AppConstants.taskStatusPending:
        return Colors.orange;
      case AppConstants.taskStatusInProgress:
        return Colors.blue;
      case AppConstants.taskStatusCompleted:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  static Color getDriverStatusColor(String status) {
    switch (status) {
      case AppConstants.driverStatusActive:
        return Colors.green;
      case AppConstants.driverStatusInactive:
        return Colors.red;
      case AppConstants.driverStatusBusy:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static Color getForkliftStatusColor(String status) {
    switch (status) {
      case AppConstants.forkliftStatusAvailable:
        return Colors.green;
      case AppConstants.forkliftStatusInUse:
        return Colors.orange;
      case AppConstants.forkliftStatusMaintenance:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Input validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.validationRequiredField;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return AppConstants.validationInvalidEmail;
    }
    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.validationRequiredField;
    }
    return null;
  }

  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppConstants.validationRequiredField;
    }
    if (int.tryParse(value) == null) {
      return AppConstants.validationInvalidNumber;
    }
    return null;
  }
}
