import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../controllers/appointment_controller.dart';
import '../../controllers/doctor_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../widgets/custom_button.dart';
import 'dart:io';

// Screen to display appointment details
class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();
  final DoctorController _doctorController = Get.find<DoctorController>();
  final AuthController _authController = Get.find<AuthController>();

  String? _prescriptionUrl;
  bool _isLoadingPrescription = false;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  // Load prescription URL
  Future<void> _loadPrescription() async {
    final appointment = _appointmentController.selectedAppointment;
    if (appointment == null) return;

    setState(() {
      _isLoadingPrescription = true;
    });

    try {
      final url = await _appointmentController.getPrescriptionUrl(
        appointment.id,
      );
      setState(() {
        _prescriptionUrl = url;
        _isLoadingPrescription = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPrescription = false;
      });
      Get.snackbar(
        'Error',
        'Failed to load prescription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor,
        colorText: Colors.white,
      );
    }
  }

  // Open prescription
  Future<void> _openPrescription() async {
    if (_prescriptionUrl == null) return;

    try {
      final uri = Uri.parse(_prescriptionUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Get.snackbar(
          'Error',
          'Could not open prescription',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open prescription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor,
        colorText: Colors.white,
      );
    }
  }

  // Upload prescription
  Future<void> _uploadPrescription() async {
    final appointment = _appointmentController.selectedAppointment;
    if (appointment == null) return;

    try {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      // Close loading dialog
      Get.back();

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        // Show uploading dialog
        Get.dialog(
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Uploading prescription...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          barrierDismissible: false,
        );

        // Upload prescription
        final success = await _appointmentController.uploadPrescription(
          appointment.id,
          filePath,
        );

        // Close uploading dialog
        Get.back();

        if (success) {
          Get.snackbar(
            'Success',
            'Prescription uploaded successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.successColor,
            colorText: Colors.white,
          );

          // Reload prescription
          _loadPrescription();
        } else {
          Get.snackbar(
            'Error',
            'Failed to upload prescription',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.errorColor,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      // Close any open dialogs
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to upload prescription: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor,
        colorText: Colors.white,
      );
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

  // Build appointment status badge
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'scheduled':
        color = AppColors.primaryColor;
        text = 'Scheduled';
        break;
      case 'completed':
        color = AppColors.successColor;
        text = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.errorColor;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // Build appointment type badge
  Widget _buildTypeBadge(String type) {
    IconData icon;
    String text;

    switch (type.toLowerCase()) {
      case 'video':
        icon = Icons.videocam;
        text = 'Video Call';
        break;
      case 'chat':
        icon = Icons.chat;
        text = 'Chat';
        break;
      case 'in-person':
        icon = Icons.person;
        text = 'In-Person';
        break;
      default:
        icon = Icons.medical_services;
        text = type;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Build prescription section
  Widget _buildPrescriptionSection() {
    final appointment = _appointmentController.selectedAppointment;
    final isDoctor = appointment?.doctorId == _authController.user?.id;

    if (_isLoadingPrescription) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_prescriptionUrl != null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prescription',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'View Prescription',
                onPressed: _openPrescription,
                icon: Icons.description,
                width: double.infinity,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'No prescription available for this appointment.',
              style: TextStyle(color: Colors.grey),
            ),

            // Show upload button for doctors
            if (isDoctor && appointment?.status == 'completed') ...[
              const SizedBox(height: 16),
              CustomButton(
                text: 'Upload Prescription',
                onPressed: _uploadPrescription,
                icon: Icons.upload_file,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: Obx(() {
        final appointment = _appointmentController.selectedAppointment;

        if (appointment == null) {
          return const Center(child: Text('Appointment not found'));
        }

        final doctor = _getDoctorForAppointment(appointment);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor info
              if (doctor != null)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primaryColor.withAlpha(25),
                          child: Text(
                            doctor.name.substring(0, 1),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctor.specialization,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Appointment details
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Appointment Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildStatusBadge(appointment.status),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date and time
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            appointment.formattedDate,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Time slot
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            appointment.timeSlot,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Appointment type
                      Row(
                        children: [
                          const Icon(
                            Icons.medical_services,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          _buildTypeBadge(appointment.type),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Fee
                      Row(
                        children: [
                          const Icon(Icons.attach_money, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            '\$${appointment.fee.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),

                      if (appointment.reason != null &&
                          appointment.reason!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          appointment.reason!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Prescription section
              _buildPrescriptionSection(),
            ],
          ),
        );
      }),
    );
  }
}
