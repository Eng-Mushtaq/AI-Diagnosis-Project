import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final AdminNavigationController _navigationController =
      Get.find<AdminNavigationController>();

  // Settings state
  final RxBool _enableEmailNotifications = true.obs;
  final RxBool _enablePushNotifications = true.obs;
  final RxBool _enableDarkMode = false.obs;
  final RxBool _enableAutoApproval = false.obs;
  final RxBool _enableMaintenance = false.obs;
  final RxString _selectedLanguage = 'English'.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authController.logout();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin profile card
            _buildAdminProfileCard(),
            const SizedBox(height: 24),

            // Notification settings
            _buildSectionHeader('Notification Settings'),
            _buildSettingsCard([
              _buildSwitchTile(
                'Email Notifications',
                'Receive notifications via email',
                _enableEmailNotifications,
                (value) => _enableEmailNotifications.value = value,
                Icons.email,
              ),
              const Divider(),
              _buildSwitchTile(
                'Push Notifications',
                'Receive push notifications on your device',
                _enablePushNotifications,
                (value) => _enablePushNotifications.value = value,
                Icons.notifications,
              ),
            ]),
            const SizedBox(height: 24),

            // App settings
            _buildSectionHeader('App Settings'),
            _buildSettingsCard([
              _buildSwitchTile(
                'Dark Mode',
                'Enable dark theme for the app',
                _enableDarkMode,
                (value) => _enableDarkMode.value = value,
                Icons.dark_mode,
              ),
              const Divider(),
              _buildDropdownTile(
                'Language',
                'Select your preferred language',
                _selectedLanguage,
                ['English', 'Arabic', 'French', 'Spanish'],
                (value) => _selectedLanguage.value = value,
                Icons.language,
              ),
            ]),
            const SizedBox(height: 24),

            // System settings
            _buildSectionHeader('System Settings'),
            _buildSettingsCard([
              _buildSwitchTile(
                'Auto-Approval for Doctors',
                'Automatically approve new doctor registrations',
                _enableAutoApproval,
                (value) => _enableAutoApproval.value = value,
                Icons.verified_user,
              ),
              const Divider(),
              _buildSwitchTile(
                'Maintenance Mode',
                'Put the app in maintenance mode',
                _enableMaintenance,
                (value) {
                  _showMaintenanceModeDialog(value);
                },
                Icons.build,
              ),
            ]),
            const SizedBox(height: 24),

            // Admin actions
            _buildSectionHeader('Admin Actions'),
            _buildSettingsCard([
              _buildActionTile(
                'Backup Database',
                'Create a backup of the database',
                Icons.backup,
                _backupDatabase,
              ),
              const Divider(),
              _buildActionTile(
                'Clear Cache',
                'Clear application cache',
                Icons.cleaning_services,
                _clearCache,
              ),
              const Divider(),
              _buildActionTile(
                'System Logs',
                'View system logs and errors',
                Icons.list_alt,
                _viewSystemLogs,
              ),
              const Divider(),
              _buildActionTile(
                'Send Announcement',
                'Send an announcement to all users',
                Icons.campaign,
                _sendAnnouncement,
              ),
            ]),
            const SizedBox(height: 24),

            // Security settings
            _buildSectionHeader('Security'),
            _buildSettingsCard([
              _buildActionTile(
                'Change Password',
                'Update your admin password',
                Icons.lock,
                _changePassword,
              ),
              const Divider(),
              _buildActionTile(
                'Two-Factor Authentication',
                'Enable or disable 2FA',
                Icons.security,
                _configureTwoFactor,
              ),
              const Divider(),
              _buildActionTile(
                'API Keys',
                'Manage API keys and access tokens',
                Icons.vpn_key,
                _manageApiKeys,
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => AdminBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }

  // Build admin profile card
  Widget _buildAdminProfileCard() {
    final user = _authController.user;
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
              child:
                  user.profileImage == null
                      ? const Icon(Icons.admin_panel_settings, size: 40)
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.adminRole ?? 'Administrator',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryColor),
              onPressed: () {
                Get.snackbar(
                  'Coming Soon',
                  'Edit profile feature is not implemented yet',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  // Build settings card
  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  // Build switch tile
  Widget _buildSwitchTile(
    String title,
    String subtitle,
    RxBool rxValue,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Obx(
      () => SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: rxValue.value,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppColors.primaryColor),
      ),
    );
  }

  // Build dropdown tile
  Widget _buildDropdownTile(
    String title,
    String subtitle,
    RxString rxValue,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Obx(
      () => ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: rxValue.value,
                  isExpanded: true,
                  items:
                      options.map((option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        leading: Icon(icon, color: AppColors.primaryColor),
      ),
    );
  }

  // Build action tile
  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      leading: Icon(icon, color: AppColors.primaryColor),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // Show maintenance mode dialog
  void _showMaintenanceModeDialog(bool value) {
    if (value) {
      Get.dialog(
        AlertDialog(
          title: const Text('Enable Maintenance Mode'),
          content: const Text(
            'Enabling maintenance mode will make the app inaccessible to all users except administrators. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _enableMaintenance.value = true;
                Get.back();
                Get.snackbar(
                  'Maintenance Mode Enabled',
                  'The app is now in maintenance mode',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      _enableMaintenance.value = false;
      Get.snackbar(
        'Maintenance Mode Disabled',
        'The app is now accessible to all users',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  // Backup database
  void _backupDatabase() {
    Get.dialog(
      AlertDialog(
        title: const Text('Backup Database'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Creating backup...'),
          ],
        ),
      ),
    );

    // Simulate backup process
    Future.delayed(const Duration(seconds: 2), () {
      Get.back();
      Get.snackbar(
        'Backup Complete',
        'Database backup created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    });
  }

  // Clear cache
  void _clearCache() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear the application cache?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Cache Cleared',
                'Application cache has been cleared',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // View system logs
  void _viewSystemLogs() {
    Get.dialog(
      AlertDialog(
        title: const Text('System Logs'),
        content: const Text('This feature is not implemented yet.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  // Send announcement
  void _sendAnnouncement() {
    Get.dialog(
      AlertDialog(
        title: const Text('Send Announcement'),
        content: const Text('This feature is not implemented yet.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  // Change password
  void _changePassword() {
    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: const Text('This feature is not implemented yet.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  // Configure two-factor authentication
  void _configureTwoFactor() {
    Get.dialog(
      AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text('This feature is not implemented yet.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  // Manage API keys
  void _manageApiKeys() {
    Get.dialog(
      AlertDialog(
        title: const Text('API Keys'),
        content: const Text('This feature is not implemented yet.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }
}
