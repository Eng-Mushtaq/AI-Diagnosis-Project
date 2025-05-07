import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../controllers/navigation_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ProfileController _profileController = Get.find<ProfileController>();
  final PatientNavigationController _navigationController =
      Get.find<PatientNavigationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
      body: Obx(() {
        final user = _authController.user;
        if (user == null) {
          return const Center(child: Text('User not found'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with image and name
              _buildProfileHeader(user),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              _buildInfoCard([
                _buildInfoRow('Name', user.name),
                _buildInfoRow('Email', user.email),
                _buildInfoRow('Phone', user.phone),
                if (user.age != null) _buildInfoRow('Age', '${user.age} years'),
                if (user.gender != null) _buildInfoRow('Gender', user.gender!),
              ]),
              const SizedBox(height: 16),

              // Health Information Section
              _buildSectionHeader('Health Information'),
              _buildInfoCard([
                if (user.bloodGroup != null)
                  _buildInfoRow('Blood Group', user.bloodGroup!),
                if (user.height != null)
                  _buildInfoRow('Height', '${user.height} cm'),
                if (user.weight != null)
                  _buildInfoRow('Weight', '${user.weight} kg'),
                if (user.allergies != null && user.allergies!.isNotEmpty)
                  _buildInfoRow('Allergies', user.allergies!.join(', ')),
                if (user.chronicConditions != null &&
                    user.chronicConditions!.isNotEmpty)
                  _buildInfoRow(
                    'Chronic Conditions',
                    user.chronicConditions!.join(', '),
                  ),
                if (user.medications != null && user.medications!.isNotEmpty)
                  _buildInfoRow('Medications', user.medications!.join(', ')),
              ]),
              const SizedBox(height: 24),

              // Edit Profile Button
              CustomButton(
                text: 'Edit Profile',
                icon: Icons.edit,
                onPressed: () {
                  Get.toNamed(AppRoutes.editProfile);
                },
                width: double.infinity,
              ),
              const SizedBox(height: 16),

              // Settings Section
              _buildSectionHeader('Settings'),
              _buildSettingsCard(),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(
        () => PatientBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }

  // Build profile header with image and name
  Widget _buildProfileHeader(user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                user.profileImage != null
                    ? NetworkImage(user.profileImage)
                    : null,
            child:
                user.profileImage == null
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            user.userType.toString().split('.').last.capitalize!,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
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

  // Build information card
  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  // Build information row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // Build settings card
  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile('Change Password', Icons.lock_outline, () {
            // TODO: Implement change password
            Get.snackbar(
              'Coming Soon',
              'Change password feature is not implemented yet',
              snackPosition: SnackPosition.BOTTOM,
            );
          }),
          const Divider(height: 1),
          _buildSettingsTile('Notifications', Icons.notifications_outlined, () {
            // TODO: Implement notifications settings
            Get.snackbar(
              'Coming Soon',
              'Notifications settings is not implemented yet',
              snackPosition: SnackPosition.BOTTOM,
            );
          }),
          const Divider(height: 1),
          _buildSettingsTile('Privacy & Security', Icons.security_outlined, () {
            // TODO: Implement privacy settings
            Get.snackbar(
              'Coming Soon',
              'Privacy settings is not implemented yet',
              snackPosition: SnackPosition.BOTTOM,
            );
          }),
          const Divider(height: 1),
          _buildSettingsTile('Help & Support', Icons.help_outline, () {
            // TODO: Implement help & support
            Get.snackbar(
              'Coming Soon',
              'Help & support is not implemented yet',
              snackPosition: SnackPosition.BOTTOM,
            );
          }),
        ],
      ),
    );
  }

  // Build settings tile
  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
