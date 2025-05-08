import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'widgets/home_menu_card.dart';

// Doctor home screen - main dashboard for doctors
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final DoctorNavigationController _navigationController =
      Get.find<DoctorNavigationController>();

  @override
  void initState() {
    super.initState();
    // Reset navigation index when returning to home
    _navigationController.resetIndex();

    // Load initial data
    _loadData();
  }

  // Load initial data
  Future<void> _loadData() async {
    if (_authController.user != null) {
      // Load doctor-specific data
      await _appointmentController.getUserAppointments(
        _authController.user!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
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
                // Doctor profile card
                _buildDoctorProfileCard(),
                const SizedBox(height: 24),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'View Appointments',
                        icon: Icons.calendar_today,
                        onPressed: () {
                          Get.toNamed(AppRoutes.appointments);
                        },
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Messages',
                        icon: Icons.message,
                        onPressed: () {
                          Get.toNamed(AppRoutes.messages);
                        },
                        backgroundColor: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Today's appointments
                const Text(
                  'Today\'s Appointments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTodayAppointments(),
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
                      title: 'Appointments',
                      icon: Icons.calendar_today,
                      color: Colors.purple,
                      onTap: () {
                        Get.toNamed(AppRoutes.appointments);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Patients',
                      icon: Icons.people,
                      color: Colors.blue,
                      onTap: () {
                        Get.toNamed(AppRoutes.patients);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Messages',
                      icon: Icons.message,
                      color: Colors.green,
                      onTap: () {
                        Get.toNamed(AppRoutes.messages);
                      },
                    ),
                    HomeMenuCard(
                      title: 'Profile',
                      icon: Icons.person,
                      color: Colors.orange,
                      onTap: () {
                        Get.toNamed(AppRoutes.doctorProfile);
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
        () => DoctorBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }

  // Build doctor profile card
  Widget _buildDoctorProfileCard() {
    final user = _authController.user;
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Get.toNamed(AppRoutes.doctorProfile);
        },
        borderRadius: BorderRadius.circular(16),
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
                      user.specialization ?? 'Doctor',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.hospital ?? 'Hospital not specified',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build today's appointments
  Widget _buildTodayAppointments() {
    return Obx(() {
      final appointments = _appointmentController.appointments;

      // Filter for today's appointments
      final today = DateTime.now();
      final todayAppointments =
          appointments.where((appointment) {
            final appointmentDate = appointment.appointmentDate;
            return appointmentDate.year == today.year &&
                appointmentDate.month == today.month &&
                appointmentDate.day == today.day;
          }).toList();

      if (todayAppointments.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No appointments scheduled for today',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: todayAppointments.length,
        itemBuilder: (context, index) {
          final appointment = todayAppointments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(appointment.reason ?? 'No reason provided'),
              subtitle: Text('${appointment.timeSlot} - ${appointment.type}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Navigate to appointment details
              },
            ),
          );
        },
      );
    });
  }
}
