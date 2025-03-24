import 'package:flutter/material.dart';
// import 'package:total_flutter/core/theme/app_theme.dart';
import 'package:total_flutter/core/utils/app_utils.dart';
import 'package:total_flutter/features/driver/domain/driver.dart';
import 'package:total_flutter/features/supervisor/domain/supervisor.dart';

class ProfileScreen extends StatelessWidget {
  final dynamic user;
  final bool isDriver;
  final bool showBackButton;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.isDriver,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract common user information
    String name;
    String email;
    String phone;

    if (isDriver) {
      name = (user as Driver).name;
      email = (user as Driver).email;
      phone = (user as Driver).phoneNumber;
    } else {
      // Handle when user is a Supervisor or Map<String, dynamic>
      if (user is Supervisor) {
        name = user.name;
        email = user.email;
        phone = user.phoneNumber;
      } else if (user is Map<String, dynamic>) {
        name = user['name'] ?? '';
        email = user['email'] ?? '';
        phone = user['phoneNumber'] ?? '';
      } else {
        name = 'Unknown';
        email = 'Unknown';
        phone = 'Unknown';
      }
    }

    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              title: Text(isDriver ? 'Driver Profile' : 'Supervisor Profile'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    isDriver ? 'Driver' : 'Supervisor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact information
            _buildSection(
              context,
              title: 'Contact Information',
              children: [
                _buildInfoTile(context, 'Email', email, Icons.email_outlined),
                _buildInfoTile(context, 'Phone', phone, Icons.phone_outlined),
              ],
            ),

            const SizedBox(height: 16),

            // Driver-specific information
            if (isDriver) ...[
              _buildSection(
                context,
                title: 'Work Information',
                children: [
                  _buildInfoTile(
                    context,
                    'Status',
                    (user as Driver).status.toJson(),
                    Icons.info_outline,
                    isStatus: true,
                    statusValue: (user as Driver).status.toJson(),
                  ),
                  if ((user as Driver).assignedForklift != null)
                    _buildInfoTile(
                      context,
                      'Assigned Forklift',
                      (user as Driver).assignedForklift!,
                      Icons.precision_manufacturing_outlined,
                    ),
                  if ((user as Driver).currentTask != null)
                    _buildInfoTile(
                      context,
                      'Current Task',
                      (user as Driver).currentTask!,
                      Icons.assignment_outlined,
                    ),
                ],
              ),
            ],

            // Supervisor-specific information
            if (!isDriver) ...[
              _buildSection(
                context,
                title: 'Work Information',
                children: [
                  // Add supervisor-specific information here
                ],
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isStatus = false,
    String? statusValue,
  }) {
    Color? statusColor;

    if (isStatus && statusValue != null) {
      statusColor = AppUtils.getColorForStatus(statusValue);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color:
                isStatus ? statusColor : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isStatus ? statusColor : null,
                        fontWeight: isStatus ? FontWeight.bold : null,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
