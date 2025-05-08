import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/doctor_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

// Screen to book an appointment with a doctor
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final DoctorController _doctorController = Get.find<DoctorController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();

  final TextEditingController _reasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final RxString _selectedAppointmentType = 'video'.obs;

  @override
  void initState() {
    super.initState();
    // Load doctor's existing appointments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctorAppointments();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Load doctor's existing appointments
  Future<void> _loadDoctorAppointments() async {
    final doctor = _doctorController.selectedDoctor;
    if (doctor != null) {
      try {
        // Get user appointments to check for conflicts
        await _appointmentController.getUserAppointments(
          _authController.user!.id,
        );

        // Set initial date to next available date
        final nextAvailableDate = _appointmentController.getNextAvailableDate(
          doctor,
        );
        if (nextAvailableDate != null) {
          _appointmentController.setSelectedDate(nextAvailableDate);
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to load doctor\'s schedule. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
        );
      }
    }
  }

  // Handle book appointment button press
  Future<void> _handleBookAppointment() async {
    if (_formKey.currentState!.validate()) {
      final doctor = _doctorController.selectedDoctor;
      if (doctor == null) {
        Get.snackbar(
          'Error',
          'Doctor information not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
        );
        return;
      }

      if (_appointmentController.selectedTimeSlot.isEmpty) {
        Get.snackbar(
          'Error',
          'Please select a time slot',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
        );
        return;
      }

      // Book appointment
      final success = await _appointmentController.bookAppointment(
        userId: _authController.user!.id,
        doctorId: doctor.id,
        appointmentDate: _appointmentController.selectedDate,
        timeSlot: _appointmentController.selectedTimeSlot,
        type: _selectedAppointmentType.value,
        reason: _reasonController.text.trim(),
        fee: doctor.consultationFee,
      );

      if (success) {
        Get.offAllNamed(AppRoutes.appointments);
        Get.snackbar(
          'Success',
          'Appointment booked successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.successColor,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          _appointmentController.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
        );
      }
    }
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Build date selector
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Obx(() {
            final doctor = _doctorController.selectedDoctor;
            if (doctor == null) return const SizedBox.shrink();

            // Get next 14 days
            final List<DateTime> dates = [];
            final now = DateTime.now();
            for (int i = 0; i < 14; i++) {
              dates.add(now.add(Duration(days: i)));
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = _isSameDay(
                  date,
                  _appointmentController.selectedDate,
                );
                final isAvailable = _appointmentController.isDateAvailable(
                  doctor,
                  date,
                );

                return GestureDetector(
                  onTap:
                      isAvailable
                          ? () {
                            _appointmentController.setSelectedDate(date);
                          }
                          : null,
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primaryColor
                              : isAvailable
                              ? AppColors.primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : isAvailable
                                ? AppColors.primaryColor.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : isAvailable
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? Colors.white
                                    : isAvailable
                                    ? Colors.black
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected
                                    ? Colors.white
                                    : isAvailable
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  // Build time slot selector
  Widget _buildTimeSlotSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final doctor = _doctorController.selectedDoctor;
          if (doctor == null) return const SizedBox.shrink();

          final timeSlots = _appointmentController.getAvailableTimeSlots(
            doctor,
          );

          if (timeSlots.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No time slots available for selected date',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                timeSlots.map((slot) {
                  final isSelected =
                      _appointmentController.selectedTimeSlot == slot;

                  return GestureDetector(
                    onTap: () {
                      _appointmentController.setSelectedTimeSlot(slot);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primaryColor
                                : AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          );
        }),
      ],
    );
  }

  // Build appointment type selector
  Widget _buildAppointmentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consultation Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Obx(() {
          final doctor = _doctorController.selectedDoctor;
          if (doctor == null) return const SizedBox.shrink();

          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap:
                      doctor.isAvailableForVideo
                          ? () {
                            _selectedAppointmentType.value = 'video';
                          }
                          : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _selectedAppointmentType.value == 'video' &&
                                  doctor.isAvailableForVideo
                              ? AppColors.primaryColor
                              : doctor.isAvailableForVideo
                              ? AppColors.primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _selectedAppointmentType.value == 'video' &&
                                    doctor.isAvailableForVideo
                                ? AppColors.primaryColor
                                : doctor.isAvailableForVideo
                                ? AppColors.primaryColor.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.videocam,
                          color:
                              _selectedAppointmentType.value == 'video' &&
                                      doctor.isAvailableForVideo
                                  ? Colors.white
                                  : doctor.isAvailableForVideo
                                  ? AppColors.primaryColor
                                  : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video Call',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                _selectedAppointmentType.value == 'video' &&
                                        doctor.isAvailableForVideo
                                    ? Colors.white
                                    : doctor.isAvailableForVideo
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.isAvailableForVideo
                              ? 'Available'
                              : 'Not Available',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _selectedAppointmentType.value == 'video' &&
                                        doctor.isAvailableForVideo
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : doctor.isAvailableForVideo
                                    ? AppColors.primaryColor.withValues(
                                      alpha: 0.8,
                                    )
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap:
                      doctor.isAvailableForChat
                          ? () {
                            _selectedAppointmentType.value = 'chat';
                          }
                          : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _selectedAppointmentType.value == 'chat' &&
                                  doctor.isAvailableForChat
                              ? AppColors.primaryColor
                              : doctor.isAvailableForChat
                              ? AppColors.primaryColor.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _selectedAppointmentType.value == 'chat' &&
                                    doctor.isAvailableForChat
                                ? AppColors.primaryColor
                                : doctor.isAvailableForChat
                                ? AppColors.primaryColor.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat,
                          color:
                              _selectedAppointmentType.value == 'chat' &&
                                      doctor.isAvailableForChat
                                  ? Colors.white
                                  : doctor.isAvailableForChat
                                  ? AppColors.primaryColor
                                  : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                _selectedAppointmentType.value == 'chat' &&
                                        doctor.isAvailableForChat
                                    ? Colors.white
                                    : doctor.isAvailableForChat
                                    ? AppColors.primaryColor
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doctor.isAvailableForChat
                              ? 'Available'
                              : 'Not Available',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _selectedAppointmentType.value == 'chat' &&
                                        doctor.isAvailableForChat
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : doctor.isAvailableForChat
                                    ? AppColors.primaryColor.withValues(
                                      alpha: 0.8,
                                    )
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor info
                Obx(() {
                  final doctor = _doctorController.selectedDoctor;
                  if (doctor == null) {
                    return const Center(child: Text('Doctor not found'));
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(doctor.profileImage),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctor.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.specialization,
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  doctor.hospital,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                doctor.formattedConsultationFee,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'per session',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),

                // Date selector
                _buildDateSelector(),
                const SizedBox(height: 24),

                // Time slot selector
                _buildTimeSlotSelector(),
                const SizedBox(height: 24),

                // Appointment type selector
                _buildAppointmentTypeSelector(),
                const SizedBox(height: 24),

                // Reason for appointment
                CustomTextField(
                  label: 'Reason for Appointment',
                  hint:
                      'Briefly describe your symptoms or reason for consultation',
                  controller: _reasonController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a reason for the appointment';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Book appointment button
                Obx(
                  () => CustomButton(
                    text: 'Book Appointment',
                    onPressed: _handleBookAppointment,
                    isLoading: _appointmentController.isLoading,
                    width: double.infinity,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
