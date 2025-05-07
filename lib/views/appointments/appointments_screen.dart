import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/doctor_controller.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/appointment_card.dart';

// Appointments screen to display user's appointments
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final DoctorController _doctorController = Get.find<DoctorController>();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use post-frame callback to ensure loading happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    // Stop real-time updates when the screen is disposed
    _appointmentController.stopAppointmentPolling();
    _tabController.dispose();
    super.dispose();
  }

  // Load appointments and doctors
  Future<void> _loadData() async {
    if (_authController.user != null) {
      await _appointmentController.getUserAppointments(
        _authController.user!.id,
      );
      await _doctorController.getAllDoctors();
      
      // Start real-time updates for appointments
      _appointmentController.startAppointmentPolling(_authController.user!.id);
    }
  }

  // Get doctor for appointment
  DoctorModel? _getDoctorForAppointment(AppointmentModel appointment) {
    try {
      return _doctorController.doctors.firstWhere(
        (doctor) => doctor.id == appointment.doctorId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Upcoming appointments tab
          RefreshIndicator(
            onRefresh: _loadData,
            child: Obx(() {
              if (_appointmentController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final upcomingAppointments =
                  _appointmentController.getUpcomingAppointments();

              if (upcomingAppointments.isEmpty) {
                return _buildEmptyState(
                  'No upcoming appointments',
                  'Book a consultation with a doctor',
                  true,
                );
              }

              // Sort by date (earliest first)
              upcomingAppointments.sort(
                (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
              );

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: upcomingAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = upcomingAppointments[index];
                  final doctor = _getDoctorForAppointment(appointment);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: AppointmentCard(
                      appointment: appointment,
                      doctor: doctor,
                      onTap: () {
                        _appointmentController.setSelectedAppointment(
                          appointment,
                        );
                        Get.toNamed(AppRoutes.appointmentDetail);
                      },
                    ),
                  );
                },
              );
            }),
          ),

          // Past appointments tab
          RefreshIndicator(
            onRefresh: _loadData,
            child: Obx(() {
              if (_appointmentController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final pastAppointments =
                  _appointmentController.getPastAppointments();

              if (pastAppointments.isEmpty) {
                return _buildEmptyState(
                  'No past appointments',
                  'Your appointment history will appear here',
                  false,
                );
              }

              // Sort by date (most recent first)
              pastAppointments.sort(
                (a, b) => b.appointmentDate.compareTo(a.appointmentDate),
              );

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pastAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = pastAppointments[index];
                  final doctor = _getDoctorForAppointment(appointment);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: AppointmentCard(
                      appointment: appointment,
                      doctor: doctor,
                      onTap: () {
                        _appointmentController.setSelectedAppointment(
                          appointment,
                        );
                        Get.toNamed(AppRoutes.appointmentDetail);
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.doctors);
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build empty state widget
  Widget _buildEmptyState(String title, String subtitle, bool showButton) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              if (showButton) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(AppRoutes.doctors);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Book Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
