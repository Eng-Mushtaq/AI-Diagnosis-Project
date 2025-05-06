import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/health_data_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/doctor_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'widgets/home_menu_card.dart';
import 'widgets/upcoming_appointment_widget.dart';
import 'widgets/health_status_widget.dart';

// Home screen - main dashboard of the app
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final HealthDataController _healthDataController =
      Get.find<HealthDataController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final DoctorController _doctorController = Get.find<DoctorController>();
  final PatientNavigationController _navigationController =
      Get.find<PatientNavigationController>();

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
    if (_authController.user != null) {
      await _healthDataController.getHealthData(_authController.user!.id);
      await _appointmentController.getUserAppointments(
        _authController.user!.id,
      );
      await _doctorController.getAllDoctors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnosist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
              Get.snackbar(
                'Coming Soon',
                'Notifications feature is not implemented yet',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting section
                Obx(
                  () => Text(
                    'Hello, ${_authController.user?.name.split(' ').first ?? 'User'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'How are you feeling today?',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Check Symptoms',
                        icon: Icons.medical_services,
                        onPressed: () {
                          Get.toNamed(AppRoutes.diagnosis);
                        },
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Book Doctor',
                        icon: Icons.calendar_today,
                        onPressed: () {
                          Get.toNamed(AppRoutes.doctors);
                        },
                        backgroundColor: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Health status card
                const HealthStatusWidget(),
                const SizedBox(height: 24),

                // Upcoming appointment
                const UpcomingAppointmentWidget(),
                const SizedBox(height: 24),

                // Menu section
                const Text(
                  'Services',
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
                      title: 'Health Data',
                      icon: Icons.favorite,
                      color: Colors.red,
                      onTap: () {
                        Get.toNamed(AppRoutes.healthData);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Symptoms',
                      icon: Icons.sick,
                      color: Colors.orange,
                      onTap: () {
                        Get.toNamed(AppRoutes.symptoms);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Doctors',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () {
                        Get.toNamed(AppRoutes.doctors);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Appointments',
                      icon: Icons.calendar_today,
                      color: Colors.purple,
                      onTap: () {
                        Get.toNamed(AppRoutes.appointments);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Lab Results',
                      icon: Icons.science,
                      color: Colors.teal,
                      onTap: () {
                        Get.toNamed(AppRoutes.labResults);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Diagnosis',
                      icon: Icons.medical_services,
                      color: AppColors.primaryColor,
                      onTap: () {
                        Get.toNamed(AppRoutes.diagnosis);
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
        () => PatientBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }
}
