import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'widgets/home_menu_card.dart';

// Admin home screen - main dashboard for administrators
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final AdminNavigationController _navigationController =
      Get.find<AdminNavigationController>();
  final RxInt _totalUsers = 0.obs;
  final RxInt _totalDoctors = 0.obs;
  final RxInt _totalPatients = 0.obs;
  final RxInt _pendingApprovals = 0.obs;

  @override
  void initState() {
    super.initState();
    // Reset navigation index when returning to home
    _navigationController.resetIndex();

    // Use post-frame callback to ensure loading happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Load initial data
  Future<void> _loadData() async {
    // Simulate loading admin dashboard data
    await Future.delayed(const Duration(seconds: 1));
    _totalUsers.value = 125;
    _totalDoctors.value = 45;
    _totalPatients.value = 80;
    _pendingApprovals.value = 12;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin profile card
                _buildAdminProfileCard(),
                const SizedBox(height: 24),

                // Stats cards
                _buildStatsGrid(),
                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Manage Users',
                        icon: Icons.people,
                        onPressed: () {
                          Get.toNamed(AppRoutes.adminUsers);
                        },
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Pending Approvals',
                        icon: Icons.approval,
                        onPressed: () {
                          Get.toNamed(AppRoutes.adminDoctors);
                        },
                        backgroundColor: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Menu section
                const Text(
                  'Admin Tools',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Menu grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    HomeMenuCard(
                      title: 'User Management',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () {
                        Get.toNamed(AppRoutes.adminUsers);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Doctor Verification',
                      icon: Icons.verified_user,
                      color: Colors.green,
                      onTap: () {
                        Get.toNamed(AppRoutes.adminDoctors);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Messages',
                      icon: Icons.message,
                      color: Colors.orange,
                      onTap: () {
                        Get.toNamed(AppRoutes.adminMessages);
                      },
                    ),
                    HomeMenuCard(
                      title: 'System Settings',
                      icon: Icons.settings,
                      color: Colors.purple,
                      onTap: () {
                        Get.toNamed(AppRoutes.adminSettings);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              backgroundImage:
                  user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
              child:
                  user.profileImage == null
                      ? const Icon(Icons.person, size: 40)
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
          ],
        ),
      ),
    );
  }

  // Build stats grid
  Widget _buildStatsGrid() {
    return Obx(
      () => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard(
            title: 'Total Users',
            value: _totalUsers.value.toString(),
            icon: Icons.people,
            color: Colors.blue,
          ),
          _buildStatCard(
            title: 'Doctors',
            value: _totalDoctors.value.toString(),
            icon: Icons.medical_services,
            color: Colors.green,
          ),
          _buildStatCard(
            title: 'Patients',
            value: _totalPatients.value.toString(),
            icon: Icons.personal_injury,
            color: Colors.orange,
          ),
          _buildStatCard(
            title: 'Pending Approvals',
            value: _pendingApprovals.value.toString(),
            icon: Icons.approval,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // Build individual stat card
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
