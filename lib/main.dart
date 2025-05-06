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

void main() {
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

    // Navigation controllers for different user types
    Get.put(PatientNavigationController(), permanent: true);
    Get.put(DoctorNavigationController(), permanent: true);
    Get.put(AdminNavigationController(), permanent: true);
  }
}
