import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';

/// Base navigation controller for managing bottom navigation
class NavigationController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;

  void changePage(int index) {
    if (_currentIndex.value != index) {
      _currentIndex.value = index;
      navigateToPage(index);
    }
  }

  void navigateToPage(int index) {
    // To be implemented by subclasses
  }
}

/// Patient navigation controller
class PatientNavigationController extends NavigationController {
  @override
  void navigateToPage(int index) {
    // Use a post-frame callback to ensure navigation happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (index) {
        case 0: // Home
          Get.offAllNamed(AppRoutes.home);
          break;
        case 1: // Health
          Get.toNamed(AppRoutes.healthData);
          break;
        case 2: // Diagnosis
          Get.toNamed(AppRoutes.diagnosis);
          break;
        case 3: // Doctors
          Get.toNamed(AppRoutes.doctors);
          break;
        case 4: // Profile
          Get.toNamed(AppRoutes.profile);
          break;
      }
    });
  }

  // Reset index when returning to home
  void resetIndex() {
    _currentIndex.value = 0;
  }
}

/// Doctor navigation controller
class DoctorNavigationController extends NavigationController {
  @override
  void navigateToPage(int index) {
    // Use a post-frame callback to ensure navigation happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (index) {
        case 0: // Home
          Get.offAllNamed(AppRoutes.doctorHome);
          break;
        case 1: // Appointments
          Get.toNamed(AppRoutes.appointments);
          break;
        case 2: // Patients
          Get.toNamed(AppRoutes.patients);
          break;
        case 3: // Messages
          Get.toNamed(AppRoutes.messages);
          break;
        case 4: // Profile
          Get.toNamed(AppRoutes.doctorProfile);
          break;
      }
    });
  }

  // Reset index when returning to home
  void resetIndex() {
    _currentIndex.value = 0;
  }
}

/// Admin navigation controller
class AdminNavigationController extends NavigationController {
  @override
  void navigateToPage(int index) {
    // Use a post-frame callback to ensure navigation happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (index) {
        case 0: // Dashboard
          Get.offAllNamed(AppRoutes.adminHome);
          break;
        case 1: // Users
          Get.toNamed(AppRoutes.adminUsers);
          break;
        case 2: // Doctors
          Get.toNamed(AppRoutes.adminDoctors);
          break;
        case 3: // Messages
          Get.toNamed(AppRoutes.adminMessages);
          break;
        case 4: // Settings
          Get.toNamed(AppRoutes.adminSettings);
          break;
      }
    });
  }

  // Reset index when returning to home
  void resetIndex() {
    _currentIndex.value = 0;
  }
}
