import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/appointment_controller.dart';
import '../../../controllers/doctor_controller.dart';
import '../../../models/appointment_model.dart';
import '../../../models/doctor_model.dart';
import '../../../routes/app_routes.dart';

// Widget to display upcoming appointment on home screen
class UpcomingAppointmentWidget extends StatelessWidget {
  const UpcomingAppointmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AppointmentController appointmentController =
        Get.find<AppointmentController>();
    final DoctorController doctorController = Get.find<DoctorController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Appointment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Get.toNamed(AppRoutes.appointments);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          final upcomingAppointments =
              appointmentController.getUpcomingAppointments();

          if (appointmentController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (upcomingAppointments.isEmpty) {
            return _buildNoAppointmentCard();
          }

          // Sort by date (earliest first)
          upcomingAppointments.sort(
            (a, b) => a.appointmentDate.compareTo(b.appointmentDate),
          );

          // Get the next appointment
          final nextAppointment = upcomingAppointments.first;

          // Find the doctor for this appointment
          DoctorModel? doctor;
          try {
            doctor = doctorController.doctors.firstWhere(
              (d) => d.id == nextAppointment.doctorId,
            );
          } catch (e) {
            // Doctor not found
          }

          return _buildAppointmentCard(nextAppointment, doctor);
        }),
      ],
    );
  }

  Widget _buildNoAppointmentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.calendar_today, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No upcoming appointments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book a consultation with a doctor',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.doctors);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    AppointmentModel appointment,
    DoctorModel? doctor,
  ) {
    IconData typeIcon;
    switch (appointment.type) {
      case 'video':
        typeIcon = Icons.videocam;
        break;
      case 'chat':
        typeIcon = Icons.chat;
        break;
      case 'in-person':
        typeIcon = Icons.person;
        break;
      default:
        typeIcon = Icons.calendar_today;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Get.toNamed(AppRoutes.appointments);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(typeIcon, color: AppColors.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor?.name ?? 'Doctor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor?.specialization ?? 'Specialist',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        appointment.formattedDate,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        appointment.timeSlot,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        appointment.type.capitalizeFirst!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
