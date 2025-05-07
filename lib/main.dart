import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'constants/app_constants.dart';
import 'constants/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/health_data_controller.dart';
import 'controllers/symptom_controller.dart';
import 'controllers/disease_controller.dart';
import 'controllers/doctor_controller.dart';
import 'controllers/appointment_controller.dart';
import 'controllers/lab_result_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/patient_controller.dart';
import 'controllers/message_controller.dart';
import 'controllers/admin_controller.dart';
import 'controllers/admin_message_controller.dart';
import 'controllers/admin_setting_controller.dart';
import 'controllers/doctor_verification_controller.dart';
import 'controllers/video_call_controller.dart';
import 'controllers/doctor_review_controller.dart';
import 'controllers/doctor_analytics_controller.dart';
import 'services/supabase_service.dart';
import 'services/admin_service.dart';
import 'services/admin_message_service.dart';
import 'services/admin_setting_service.dart';
import 'services/doctor_verification_service.dart';
import 'services/ai_diagnosis_service.dart';
import 'services/gemini_health_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService().initialize();
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    _initControllers();
    return GetMaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      defaultTransition: Transition.fade,
      debugShowCheckedModeBanner: false,
    );
  }

  // Initialize all controllers
  void _initControllers() {
    // Register services
    Get.put(SupabaseService());
    Get.put(AdminService());
    Get.put(AdminMessageService());
    Get.put(AdminSettingService());
    Get.put(DoctorVerificationService());

    // Initialize AI Diagnosis Service
    final aiService = AIDiagnosisService();
    aiService.initialize();
    Get.put(aiService);

    // Initialize Gemini Health Service
    final geminiService = GeminiHealthService();
    geminiService.initialize();
    Get.put(geminiService);

    // Register controllers so they can be accessed anywhere in the app
    Get.put(AuthController());
    Get.put(HealthDataController());
    Get.put(SymptomController());
    Get.put(DiseaseController());
    Get.put(DoctorController());
    Get.put(AppointmentController());
    Get.put(LabResultController());
    Get.put(ProfileController());
    Get.put(PatientController());
    Get.put(MessageController());
    Get.put(AdminController());
    Get.put(AdminMessageController());
    Get.put(AdminSettingController());
    Get.put(DoctorVerificationController());
    Get.put(VideoCallController());
    Get.put(DoctorReviewController());
    Get.put(DoctorAnalyticsController());

    // Navigation controllers for different user types
    Get.put(PatientNavigationController(), permanent: true);
    Get.put(DoctorNavigationController(), permanent: true);
    Get.put(AdminNavigationController(), permanent: true);
  }
}
