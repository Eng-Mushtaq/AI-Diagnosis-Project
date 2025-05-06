// App routes constants for navigation

class AppRoutes {
  // Auth routes
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String doctorProfile = '/doctor-profile';
  static const String doctorEditProfile = '/doctor-edit-profile';

  // Main routes for different user types
  static const String home = '/home'; // Patient home
  static const String doctorHome = '/doctor-home';
  static const String adminHome = '/admin-home';

  // Admin routes
  static const String adminUsers = '/admin-users';
  static const String adminDoctors = '/admin-doctors';
  static const String adminMessages = '/admin-messages';
  static const String adminSettings = '/admin-settings';

  // Health data routes
  static const String healthData = '/health-data';
  static const String addHealthData = '/add-health-data';

  // Symptom routes
  static const String symptoms = '/symptoms';
  static const String addSymptom = '/add-symptom';

  // Diagnosis routes
  static const String diagnosis = '/diagnosis';
  static const String diagnosisResult = '/diagnosis-result';

  // Doctor routes
  static const String doctors = '/doctors';
  static const String doctorDetails = '/doctor-details';

  // Appointment routes
  static const String appointments = '/appointments';
  static const String bookAppointment = '/book-appointment';

  // Lab results routes
  static const String labResults = '/lab-results';

  // Patient routes (for doctors)
  static const String patients = '/patients';
  static const String patientDetails = '/patient-details';

  // Message routes
  static const String messages = '/messages';
  static const String chatDetail = '/chat-detail';
}
