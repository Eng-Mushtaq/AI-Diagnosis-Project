import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../controllers/doctor_controller.dart';
import '../../controllers/appointment_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

// Doctor details screen to display detailed information about a doctor
class DoctorDetailsScreen extends StatefulWidget {
  const DoctorDetailsScreen({super.key});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  final DoctorController _doctorController = Get.find<DoctorController>();
  final AppointmentController _appointmentController =
      Get.find<AppointmentController>();

  @override
  void initState() {
    super.initState();
    // Reset appointment date and time slot
    _appointmentController.setSelectedDate(DateTime.now());
    _appointmentController.setSelectedTimeSlot('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final doctor = _doctorController.selectedDoctor;

        if (doctor == null) {
          return const Center(child: Text('Doctor not found'));
        }

        return CustomScrollView(
          slivers: [
            // App bar with doctor image
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: doctor.profileImage,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),
            ),

            // Doctor details
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor name and specialization
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rating and experience
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doctor.formattedRating,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.work,
                                color: AppColors.secondaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor.experience} years',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                color: AppColors.accentColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                doctor.formattedConsultationFee,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // About
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor.about ?? 'No information available',
                      style: TextStyle(color: Colors.grey[700], height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // Hospital and location
                    const Text(
                      'Hospital',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          color: AppColors.secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doctor.hospital,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          doctor.city,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Qualifications
                    if (doctor.qualifications != null &&
                        doctor.qualifications!.isNotEmpty) ...[
                      const Text(
                        'Qualifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...doctor.qualifications!.map((qualification) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.school,
                                color: AppColors.primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(qualification)),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Languages
                    if (doctor.languages != null &&
                        doctor.languages!.isNotEmpty) ...[
                      const Text(
                        'Languages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            doctor.languages!.map((language) {
                              return Chip(
                                label: Text(language),
                                backgroundColor: AppColors.primaryLightColor
                                    .withValues(alpha: 0.2),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Available days
                    if (doctor.availableDays != null &&
                        doctor.availableDays!.isNotEmpty) ...[
                      const Text(
                        'Available Days',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            doctor.availableDays!.map((day) {
                              return Chip(
                                label: Text(day),
                                backgroundColor: AppColors.secondaryLightColor
                                    .withValues(alpha: 0.2),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Consultation types
                    const Text(
                      'Consultation Types',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildConsultationTypeCard(
                            'Video Consultation',
                            Icons.videocam,
                            doctor.isAvailableForVideo,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildConsultationTypeCard(
                            'Chat Consultation',
                            Icons.chat,
                            doctor.isAvailableForChat,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Book appointment button
                    CustomButton(
                      text: 'Book Appointment',
                      icon: Icons.calendar_today,
                      onPressed: () {
                        Get.toNamed(AppRoutes.bookAppointment);
                      },
                      width: double.infinity,
                      height: 56,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // Build consultation type card
  Widget _buildConsultationTypeCard(
    String title,
    IconData icon,
    bool isAvailable,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isAvailable
                ? AppColors.successColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? AppColors.successColor : Colors.grey,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isAvailable ? AppColors.successColor : Colors.grey,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAvailable ? AppColors.successColor : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isAvailable ? 'Available' : 'Not Available',
            style: TextStyle(
              fontSize: 12,
              color: isAvailable ? AppColors.successColor : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
