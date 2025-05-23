import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../views/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/auth/onboarding_screen.dart';
import '../views/home/home_screen.dart';
import '../views/home/doctor_home_screen.dart';
import '../views/home/admin_home_screen.dart';
import '../views/health_data/health_data_screen.dart';
import '../views/health_data/add_health_data_screen.dart';
import '../views/diagnosis/diagnosis_screen.dart';
import '../views/diagnosis/diagnosis_result_screen.dart';
import '../views/doctors/doctors_screen.dart';
import '../views/doctors/doctor_details_screen.dart';
import '../views/appointments/appointments_screen.dart';
import '../views/appointments/book_appointment_screen.dart';
import '../views/appointments/appointment_detail_screen.dart';
import '../views/symptoms/symptoms_screen.dart';
import '../views/profile/profile_screen.dart';
import '../views/profile/edit_profile_screen.dart';
import '../views/profile/doctor_profile_screen.dart';
import '../views/profile/doctor_edit_profile_screen.dart';
import '../views/patients/patients_screen.dart';
import '../views/patients/patient_details_screen.dart';
import '../views/messages/messages_screen.dart';
import '../views/admin/admin_users_screen.dart';
import '../views/admin/admin_doctors_screen.dart';
import '../views/admin/admin_messages_screen_new.dart';
import '../views/admin/admin_settings_screen_new.dart';
import '../views/lab_results/lab_results_screen.dart';
import '../views/profile/doctor_time_slots_screen.dart';
import '../views/profile/doctor_qualifications_screen.dart';
import '../views/profile/doctor_verification_screen.dart';
import '../views/doctor/doctor_dashboard_screen.dart';
import '../views/doctor/doctor_patients_screen.dart';
import '../views/doctor/doctor_reviews_screen.dart';
import '../views/doctor/video_call_screen.dart';

class AppPages {
  static final List<GetPage> pages = [
    // Auth routes
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),

    // Main routes for different user types
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ), // Patient home
    GetPage(
      name: AppRoutes.doctorHome,
      page: () => const DoctorHomeScreen(),
    ), // Doctor home
    GetPage(
      name: AppRoutes.adminHome,
      page: () => const AdminHomeScreen(),
    ), // Admin home
    // Health data routes
    GetPage(name: AppRoutes.healthData, page: () => const HealthDataScreen()),
    GetPage(
      name: AppRoutes.addHealthData,
      page: () => const AddHealthDataScreen(),
    ),

    // Diagnosis routes
    GetPage(name: AppRoutes.diagnosis, page: () => const DiagnosisScreen()),
    GetPage(
      name: AppRoutes.diagnosisResult,
      page: () => const DiagnosisResultScreen(),
    ),

    // Doctor routes
    GetPage(name: AppRoutes.doctors, page: () => const DoctorsScreen()),
    GetPage(
      name: AppRoutes.doctorDetails,
      page: () => const DoctorDetailsScreen(),
    ),
    GetPage(
      name: AppRoutes.doctorTimeSlots,
      page: () => const DoctorTimeSlotsScreen(),
    ),
    GetPage(
      name: AppRoutes.doctorQualifications,
      page: () => const DoctorQualificationsScreen(),
    ),
    GetPage(
      name: AppRoutes.doctorVerification,
      page: () => const DoctorVerificationScreen(),
    ),

    // Appointment routes
    GetPage(
      name: AppRoutes.appointments,
      page: () => const AppointmentsScreen(),
    ),
    GetPage(
      name: AppRoutes.bookAppointment,
      page: () => const BookAppointmentScreen(),
    ),
    GetPage(
      name: AppRoutes.appointmentDetail,
      page: () => const AppointmentDetailScreen(),
    ),

    // Lab results routes
    GetPage(name: AppRoutes.labResults, page: () => const LabResultsScreen()),

    // Symptoms routes
    GetPage(name: AppRoutes.symptoms, page: () => const SymptomsScreen()),
    // TODO: Add add symptom route

    // Profile routes
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileScreen()),
    GetPage(
      name: AppRoutes.doctorProfile,
      page: () => const DoctorProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.doctorEditProfile,
      page: () => const DoctorEditProfileScreen(),
    ),

    // Patient routes (for doctors)
    GetPage(name: AppRoutes.patients, page: () => const PatientsScreen()),
    GetPage(
      name: AppRoutes.patientDetails,
      page: () => const PatientDetailsScreen(),
    ),

    // Message routes
    GetPage(name: AppRoutes.messages, page: () => const MessagesScreen()),

    // Doctor dashboard routes
    GetPage(
      name: AppRoutes.doctorDashboard,
      page: () => const DoctorDashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.doctorPatients,
      page: () => const DoctorPatientsScreen(),
    ),
    GetPage(
      name: AppRoutes.doctorReviews,
      page: () => const DoctorReviewsScreen(),
    ),
    // Note: VideoCallScreen requires parameters, so we'll handle it differently
    // This is a placeholder that will be replaced with actual parameters when navigating
    GetPage(
      name: AppRoutes.videoCall,
      page:
          () => const Scaffold(body: Center(child: Text('Video Call Screen'))),
    ),

    // Admin routes
    GetPage(name: AppRoutes.adminUsers, page: () => const AdminUsersScreen()),
    GetPage(
      name: AppRoutes.adminDoctors,
      page: () => const AdminDoctorsScreen(),
    ),
    GetPage(
      name: AppRoutes.adminMessages,
      page: () => const AdminMessagesScreen(),
    ),
    GetPage(
      name: AppRoutes.adminSettings,
      page: () => const AdminSettingsScreen(),
    ),
  ];
}
