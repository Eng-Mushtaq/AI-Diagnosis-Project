import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/mock_data_service.dart';

/// Controller for managing user profile operations
class ProfileController extends GetxController {
  final MockDataService _dataService = MockDataService();

  // Observable variables
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  // Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Simulate profile update with mock data service
      await Future.delayed(const Duration(seconds: 1));
      await _dataService.updateUserProfile(updatedUser);
      return true;
    } catch (e) {
      _errorMessage.value = 'Profile update failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Validate inputs
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        _errorMessage.value = 'All fields are required';
        return false;
      }

      if (newPassword.length < 6) {
        _errorMessage.value = 'Password must be at least 6 characters';
        return false;
      }

      // Simulate password change
      await Future.delayed(const Duration(seconds: 1));
      // In a real app, this would call an API to change the password

      return true;
    } catch (e) {
      _errorMessage.value = 'Password change failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Upload profile image
  Future<bool> uploadProfileImage(String imagePath) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Simulate image upload
      await Future.delayed(const Duration(seconds: 2));
      // In a real app, this would upload the image to a server

      return true;
    } catch (e) {
      _errorMessage.value = 'Image upload failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
