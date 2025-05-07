import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../controllers/navigation_controller.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ProfileController _profileController = Get.find<ProfileController>();
  final DoctorNavigationController _navigationController =
      Get.find<DoctorNavigationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
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

              // Professional Information Section
              _buildSectionHeader('Professional Information'),
              _buildInfoCard([
                _buildInfoRow('Name', user.name),
                _buildInfoRow('Email', user.email),
                _buildInfoRow('Phone', user.phone),
                if (user.specialization != null)
                  _buildInfoRow('Specialization', user.specialization!),
                if (user.hospital != null)
                  _buildInfoRow('Hospital', user.hospital!),
                if (user.licenseNumber != null)
                  _buildInfoRow('License Number', user.licenseNumber!),
                if (user.experience != null)
                  _buildInfoRow('Experience', '${user.experience} years'),
              ]),
              const SizedBox(height: 16),

              // Qualifications Section
              if (user.qualifications != null &&
                  user.qualifications!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Qualifications'),
                    _buildQualificationsCard(user.qualifications!),
                    const SizedBox(height: 16),
                  ],
                ),

              // Availability Section
              _buildSectionHeader('Availability'),
              _buildAvailabilityCard(
                user.isAvailableForChat ?? false,
                user.isAvailableForVideo ?? false,
              ),
              const SizedBox(height: 24),

              // Edit Profile Button
              CustomButton(
                text: 'Edit Profile',
                icon: Icons.edit,
                onPressed: () {
                  Get.toNamed(AppRoutes.doctorEditProfile);
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
        () => DoctorBottomNavBar(
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
            user.specialization ?? 'Doctor',
            style: TextStyle(fontSize: 18, color: AppColors.primaryColor),
          ),
          Text(
            user.hospital ?? '',
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

  // Build qualifications card
  Widget _buildQualificationsCard(List<String> qualifications) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              qualifications
                  .map(
                    (qualification) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.school,
                            color: AppColors.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              qualification,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  // Build availability card
  Widget _buildAvailabilityCard(
    bool isAvailableForChat,
    bool isAvailableForVideo,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAvailabilityRow(
              'Video Consultation',
              Icons.videocam,
              isAvailableForVideo,
            ),
            const SizedBox(height: 12),
            _buildAvailabilityRow(
              'Chat Consultation',
              Icons.chat,
              isAvailableForChat,
            ),
          ],
        ),
      ),
    );
  }

  // Build availability row
  Widget _buildAvailabilityRow(String label, IconData icon, bool isAvailable) {
    return Row(
      children: [
        Icon(icon, color: isAvailable ? AppColors.primaryColor : Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isAvailable ? 'Available' : 'Not Available',
            style: TextStyle(
              color: isAvailable ? Colors.green[800] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
