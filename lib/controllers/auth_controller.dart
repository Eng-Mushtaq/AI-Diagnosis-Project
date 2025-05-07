import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

// Authentication controller for managing user authentication
class AuthController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService();

  // Observable user
  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  UserModel? get user => _user.value;
  // Add currentUser getter to match the expected API
  Rx<UserModel?> get currentUser => _user;

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

    // Check if user is already logged in with Supabase
    _checkCurrentUser();
  }

  // Check if user is already logged in with Supabase
  Future<void> _checkCurrentUser() async {
    final authUser = _supabaseService.getCurrentAuthUser();
    if (authUser != null) {
      await getCurrentUser();
    }
  }

  // Get current user
  Future<void> getCurrentUser() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final authUser = _supabaseService.getCurrentAuthUser();
      if (authUser != null) {
        final user = await _supabaseService.getUserProfile(authUser.id);
        _user.value = user;
      }
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

      // Check if this is an admin login attempt
      if (email.toLowerCase().contains('admin')) {
        debugPrint(
          'Admin login attempt with email: $email and password: $password',
        );
      }

      // Use Supabase to login
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('Auth successful, user ID: ${response.user!.id}');

        // Get user profile from database
        final user = await _supabaseService.getUserProfile(response.user!.id);
        if (user != null) {
          _user.value = user;

          // Log user type for debugging
          debugPrint('User logged in as: ${user.userType}');

          // Special handling for admin users
          if (email.toLowerCase().contains('admin') &&
              user.userType != UserType.admin) {
            debugPrint('Forcing user type to admin');
            final updatedUser = user.copyWith(userType: UserType.admin);
            _user.value = updatedUser;
          }

          return true;
        } else {
          debugPrint(
            'User profile not found in database for ID: ${response.user!.id}',
          );

          // If this is an admin login attempt, try to create the admin profile
          if (email.toLowerCase().contains('admin')) {
            try {
              debugPrint('Attempting to create admin profile');
              await _supabaseService.createUserProfile(
                userId: response.user!.id,
                email: email,
                name: 'Admin User',
                userType: UserType.admin,
                additionalData: {
                  'adminRole': 'super_admin',
                  'permissions': [
                    'manage_users',
                    'manage_doctors',
                    'manage_content',
                    'view_analytics',
                    'create_admin',
                  ],
                },
              );

              // Try to get the profile again
              final newUser = await _supabaseService.getUserProfile(
                response.user!.id,
              );
              if (newUser != null) {
                _user.value = newUser;
                debugPrint('Admin profile created and login successful');
                return true;
              }
            } catch (profileError) {
              debugPrint('Error creating admin profile: $profileError');
            }
          }

          _errorMessage.value = 'User profile not found';
          return false;
        }
      } else {
        _errorMessage.value = 'Invalid email or password';
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage.value = e.message;
      return false;
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

      // Register user with Supabase
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        name: name,
        userType: userType,
        additionalData: additionalData,
      );

      if (response.user != null) {
        // Sign out after registration to force login
        await _supabaseService.signOut();
        return true;
      } else {
        _errorMessage.value = 'Registration failed';
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage.value = e.message;
      return false;
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
      await _supabaseService.signOut();
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
      // TODO: Implement profile update with Supabase
      // For now, just update the local user
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
