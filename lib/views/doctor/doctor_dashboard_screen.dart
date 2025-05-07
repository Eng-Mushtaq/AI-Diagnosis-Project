import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/doctor_analytics_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/patient_controller.dart';
import '../../constants/app_colors.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../widgets/custom_app_bar.dart';
import 'doctor_patients_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DoctorAnalyticsController _analyticsController =
      Get.find<DoctorAnalyticsController>();
  final AuthController _authController = Get.find<AuthController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final PatientController _patientController = Get.find<PatientController>();

  final RxBool _isRefreshing = false.obs;
  final RxString _timeRange = '30 Days'.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentUser = _authController.user;
    if (currentUser != null) {
      _isRefreshing.value = true;

      try {
        // Load analytics data
        await _analyticsController.getDoctorAnalyticsSummary(currentUser.id);

        // Load upcoming appointments
        await _appointmentController.getDoctorUpcomingAppointments(
          currentUser.id,
        );

        // Load patients
        await _patientController.getDoctorPatients(currentUser.id);
      } finally {
        _isRefreshing.value = false;
      }
    }
  }

  void _changeTimeRange(String range) {
    _timeRange.value = range;
    // In a real implementation, we would update the analytics data based on the selected time range
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard',
        showBackButton: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
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
                _buildWelcomeSection(),
                const SizedBox(height: 24),
                _buildTimeRangeSelector(),
                const SizedBox(height: 16),
                Obx(() {
                  if (_analyticsController.isLoading || _isRefreshing.value) {
                    return SizedBox(
                      height: 200,
                      child: Center(child: LoadingIndicator()),
                    );
                  }

                  if (_analyticsController.errorMessage.isNotEmpty) {
                    return ErrorMessage(
                      message: _analyticsController.errorMessage,
                      onRetry: _loadData,
                    );
                  }

                  return Column(
                    children: [
                      _buildStatisticsGrid(),
                      const SizedBox(height: 24),
                      _buildUpcomingAppointmentsSection(),
                      const SizedBox(height: 24),
                      _buildRecentPatientsSection(),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final currentUser = _authController.user;
    final greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Dr. ${currentUser?.name ?? 'Doctor'}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildTimeRangeButton('7 Days'),
          _buildTimeRangeButton('30 Days'),
          _buildTimeRangeButton('90 Days'),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String range) {
    return Expanded(
      child: Obx(() {
        final isSelected = _timeRange.value == range;

        return GestureDetector(
          onTap: () => _changeTimeRange(range),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatisticsGrid() {
    final summary = _analyticsController.analyticsSummary;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Appointments',
          value: summary['totalAppointments']?.toString() ?? '0',
          icon: Icons.calendar_today,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Patients',
          value: summary['totalPatients']?.toString() ?? '0',
          icon: Icons.people,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Completion Rate',
          value:
              '${((summary['completedAppointments'] ?? 0) / (summary['totalAppointments'] ?? 1) * 100).toStringAsFixed(1)}%',
          icon: Icons.check_circle,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Rating',
          value: '${summary['averageRating']?.toStringAsFixed(1) ?? '0.0'}/5',
          icon: Icons.star,
          color: Colors.amber,
        ),
        _buildStatCard(
          title: 'Video Calls',
          value: summary['totalVideoCalls']?.toString() ?? '0',
          icon: Icons.video_call,
          color: Colors.purple,
        ),
        _buildStatCard(
          title: 'New Patients',
          value: summary['newPatients']?.toString() ?? '0',
          icon: Icons.person_add,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(
              26,
            ), // 0.1 opacity = 26 alpha (255 * 0.1)
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(
                      26,
                    ), // 0.1 opacity = 26 alpha (255 * 0.1)
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Icon(Icons.more_horiz, color: Colors.grey[400], size: 20),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Appointments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to appointments screen
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (_appointmentController.isLoading) {
            return SizedBox(
              height: 100,
              child: Center(child: LoadingIndicator()),
            );
          }

          if (_appointmentController.errorMessage.isNotEmpty) {
            return ErrorMessage(
              message: _appointmentController.errorMessage,
              onRetry:
                  () => _appointmentController.getDoctorUpcomingAppointments(
                    _authController.user!.id,
                  ),
            );
          }

          final appointments = _appointmentController.upcomingAppointments;

          if (appointments.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_today,
              title: 'No Upcoming Appointments',
              message: 'You don\'t have any upcoming appointments.',
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length > 3 ? 3 : appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getAppointmentColor(appointment.status),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.patientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${appointment.formattedDate} • ${appointment.formattedTime}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getAppointmentColor(
                            appointment.status,
                          ).withAlpha(26), // 0.1 opacity = 26 alpha (255 * 0.1)
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appointment.type.capitalize!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getAppointmentColor(appointment.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildRecentPatientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Patients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Get.to(() => const DoctorPatientsScreen());
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (_patientController.isLoading) {
            return SizedBox(
              height: 100,
              child: Center(child: LoadingIndicator()),
            );
          }

          if (_patientController.errorMessage.isNotEmpty) {
            return ErrorMessage(
              message: _patientController.errorMessage,
              onRetry:
                  () => _patientController.getDoctorPatients(
                    _authController.user!.id,
                  ),
            );
          }

          final patients = _patientController.patients;

          if (patients.isEmpty) {
            return const EmptyState(
              icon: Icons.people,
              title: 'No Patients',
              message: 'You don\'t have any patients yet.',
            );
          }

          return SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: patients.length > 5 ? 5 : patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryColor.withAlpha(
                          51, // 0.2 opacity = 51 alpha (255 * 0.2)
                        ),
                        backgroundImage:
                            patient.profileImage != null &&
                                    patient.profileImage!.isNotEmpty
                                ? NetworkImage(patient.profileImage!)
                                : null,
                        child:
                            patient.profileImage == null ||
                                    patient.profileImage!.isEmpty
                                ? Text(
                                  patient.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        patient.name.split(' ')[0],
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  Color _getAppointmentColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
