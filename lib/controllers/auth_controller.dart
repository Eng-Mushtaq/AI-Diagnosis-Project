import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/mock_data_service.dart';

// Authentication controller for managing user authentication
class AuthController extends GetxController {
  final MockDataService _dataService = MockDataService();

  // Observable user
  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  UserModel? get user => _user.value;

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // Check if user is logged in
  bool get isLoggedIn => _user.value != null;

  @override
  void onInit() {
    super.onInit();
    // No auto login - user must always go through the login screen
    // Reset user to ensure they're logged out
    _user.value = null;
  }

  // Get current user
  Future<void> getCurrentUser() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final user = await _dataService.getCurrentUser();
      _user.value = user;
    } catch (e) {
      _errorMessage.value = 'Failed to get user: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        _errorMessage.value = 'Email and password are required';
        return false;
      }

      if (password.length < 6) {
        _errorMessage.value = 'Password must be at least 6 characters';
        return false;
      }

      // Use the mock service to login with different user types
      final user = await _dataService.login(email, password);

      if (user != null) {
        _user.value = user;
        return true;
      } else {
        _errorMessage.value = 'Invalid email or password';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Login failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Get user type
  UserType get userType => _user.value?.userType ?? UserType.patient;

  // Check if user is a patient
  bool get isPatient => _user.value?.userType == UserType.patient;

  // Check if user is a doctor
  bool get isDoctor => _user.value?.userType == UserType.doctor;

  // Check if user is an admin
  bool get isAdmin => _user.value?.userType == UserType.admin;

  // Register new user
  Future<bool> register(
    String name,
    String email,
    String password, [
    UserType userType = UserType.patient,
    Map<String, dynamic>? additionalData,
  ]) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Validate inputs
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        _errorMessage.value = 'All fields are required';
        return false;
      }

      if (password.length < 6) {
        _errorMessage.value = 'Password must be at least 6 characters';
        return false;
      }

      // Register user with the specified type and additional data
      final user = await _dataService.register(
        name,
        email,
        password,
        userType,
        additionalData,
      );
      _user.value = user;

      return true;
    } catch (e) {
      _errorMessage.value = 'Registration failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading.value = true;

    try {
      // Simulate logout
      await Future.delayed(const Duration(seconds: 1));
      _user.value = null;
    } catch (e) {
      _errorMessage.value = 'Logout failed: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Simulate profile update
      await Future.delayed(const Duration(seconds: 1));
      _user.value = updatedUser;
      return true;
    } catch (e) {
      _errorMessage.value = 'Profile update failed: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
