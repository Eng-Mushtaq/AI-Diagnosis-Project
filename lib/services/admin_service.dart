import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';

/// Service class for handling admin-specific operations
class AdminService extends GetxService {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // Get Supabase client
  SupabaseClient get _supabase => _supabaseService.supabaseClient;

  // Get dashboard statistics
  Future<Map<String, int>> getDashboardStats() async {
    try {
      // First check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can access dashboard statistics');
        return {
          'totalUsers': 0,
          'totalDoctors': 0,
          'totalPatients': 0,
          'pendingApprovals': 0,
        };
      }

      // Get counts using manual counting approach
      // Get all users
      final users = await _supabase.from('users').select();
      final totalUsers = users.length;

      // Get doctors
      final doctors = await _supabase
          .from('users')
          .select()
          .eq('user_type', 'doctor');
      final totalDoctors = doctors.length;

      // Get patients
      final patients = await _supabase
          .from('users')
          .select()
          .eq('user_type', 'patient');
      final totalPatients = patients.length;

      // Get pending approvals
      final pendingApprovals = await _supabase
          .from('doctors')
          .select()
          .eq('verification_status', 'pending');
      final totalPendingApprovals = pendingApprovals.length;

      return {
        'totalUsers': totalUsers,
        'totalDoctors': totalDoctors,
        'totalPatients': totalPatients,
        'pendingApprovals': totalPendingApprovals,
      };
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return {
        'totalUsers': 0,
        'totalDoctors': 0,
        'totalPatients': 0,
        'pendingApprovals': 0,
      };
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      // Get current auth user
      final currentUser = _supabaseService.getCurrentAuthUser();
      if (currentUser == null) {
        debugPrint('isCurrentUserAdmin: No authenticated user found');
        return false;
      }

      debugPrint(
        'isCurrentUserAdmin: Checking admin status for user ID: ${currentUser.id}',
      );

      // First try to get the user from the AuthController
      try {
        // Use dynamic to avoid type issues
        final authController = Get.find<dynamic>();
        if (authController.isAdmin == true) {
          debugPrint(
            'isCurrentUserAdmin: User is admin according to AuthController',
          );
          return true;
        }
        debugPrint(
          'isCurrentUserAdmin: User is not admin according to AuthController, checking database',
        );
      } catch (e) {
        debugPrint(
          'isCurrentUserAdmin: AuthController not found or error: $e, checking database directly',
        );
      }

      // If AuthController doesn't confirm admin status, check the database directly
      try {
        final userData =
            await _supabase
                .from('users')
                .select('user_type, email')
                .eq('id', currentUser.id)
                .single();

        debugPrint(
          'isCurrentUserAdmin: User data from database: ${userData.toString()}',
        );

        // Check if user_type is admin
        final isAdmin = userData['user_type'] == 'admin';
        debugPrint(
          'isCurrentUserAdmin: User is${isAdmin ? '' : ' not'} admin according to database',
        );

        // Special case for admin email
        if (!isAdmin &&
            userData['email'] != null &&
            userData['email'].toString().toLowerCase().contains('admin')) {
          debugPrint(
            'isCurrentUserAdmin: User has admin email but not admin type, treating as admin',
          );
          return true;
        }

        return isAdmin;
      } catch (e) {
        debugPrint('isCurrentUserAdmin: Error querying database: $e');

        // As a fallback, check if the email contains 'admin'
        try {
          // Get the current user's email directly from auth
          final email = _supabase.auth.currentUser?.email;
          if (email != null && email.toLowerCase().contains('admin')) {
            debugPrint(
              'isCurrentUserAdmin: User has admin email, treating as admin',
            );
            return true;
          }
        } catch (emailError) {
          debugPrint(
            'isCurrentUserAdmin: Error getting user email: $emailError',
          );
        }

        return false;
      }
    } catch (e) {
      debugPrint('isCurrentUserAdmin: Unexpected error: $e');
      return false;
    }
  }

  // Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final users = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      List<UserModel> userModels = [];
      for (var user in users) {
        try {
          userModels.add(UserModel.fromJson(user));
        } catch (e) {
          debugPrint('Error parsing user: $e');
        }
      }

      return userModels;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Get all patients (for admin)
  Future<List<UserModel>> getAllPatients() async {
    try {
      final users = await _supabase
          .from('users')
          .select()
          .eq('user_type', 'patient')
          .order('created_at', ascending: false);

      List<UserModel> userModels = [];
      for (var user in users) {
        try {
          userModels.add(UserModel.fromJson(user));
        } catch (e) {
          debugPrint('Error parsing patient: $e');
        }
      }

      return userModels;
    } catch (e) {
      debugPrint('Error getting all patients: $e');
      return [];
    }
  }

  // Get all doctors (for admin)
  Future<List<UserModel>> getAllDoctors() async {
    try {
      final users = await _supabase
          .from('users')
          .select()
          .eq('user_type', 'doctor')
          .order('created_at', ascending: false);

      List<UserModel> userModels = [];
      for (var user in users) {
        try {
          userModels.add(UserModel.fromJson(user));
        } catch (e) {
          debugPrint('Error parsing doctor: $e');
        }
      }

      return userModels;
    } catch (e) {
      debugPrint('Error getting all doctors: $e');
      return [];
    }
  }

  // Create a new admin (only existing admins can do this)
  Future<bool> createAdmin(
    String name,
    String email,
    String password, [
    Map<String, dynamic>? additionalData,
  ]) async {
    try {
      // First check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can create other admins');
        return false;
      }

      // Prepare admin data
      final Map<String, dynamic> adminData = {
        'adminRole': 'content_admin',
        'permissions': ['view_users', 'view_doctors'],
      };

      // Merge with additional data if provided
      if (additionalData != null) {
        adminData.addAll(additionalData);
      }

      // Create user in auth
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        name: name,
        userType: UserType.admin,
        additionalData: adminData,
      );

      return response.user != null;
    } catch (e) {
      debugPrint('Error creating admin: $e');
      return false;
    }
  }

  // Create the first admin (no admin check required)
  Future<bool> createFirstAdmin(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Check if any admins exist
      final existingAdmins = await _supabase
          .from('users')
          .select('id')
          .eq('user_type', 'admin')
          .limit(1);

      if (existingAdmins.isNotEmpty) {
        debugPrint('Admin users already exist. Cannot create first admin.');
        return false;
      }

      // Create user in auth
      final response = await _supabaseService.signUp(
        email: email,
        password: password,
        name: name,
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

      return response.user != null;
    } catch (e) {
      debugPrint('Error creating first admin: $e');
      return false;
    }
  }

  // Update user information
  Future<bool> updateUser(UserModel user) async {
    try {
      // First check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can update users');
        return false;
      }

      // Update user in users table
      await _supabase
          .from('users')
          .update({
            'name': user.name,
            'phone': user.phone,
            'profile_image': user.profileImage,
          })
          .eq('id', user.id);

      // Update user in specific type table based on user type
      if (user.userType == UserType.patient) {
        // Update patient-specific fields if needed
        if (user.age != null ||
            user.gender != null ||
            user.bloodGroup != null) {
          await _supabase
              .from('patients')
              .update({
                if (user.age != null) 'age': user.age,
                if (user.gender != null) 'gender': user.gender,
                if (user.bloodGroup != null) 'blood_group': user.bloodGroup,
                if (user.height != null) 'height': user.height,
                if (user.weight != null) 'weight': user.weight,
              })
              .eq('id', user.id);
        }
      } else if (user.userType == UserType.doctor) {
        // Update doctor-specific fields if needed
        if (user.specialization != null || user.hospital != null) {
          await _supabase
              .from('doctors')
              .update({
                if (user.specialization != null)
                  'specialization': user.specialization,
                if (user.hospital != null) 'hospital': user.hospital,
                if (user.licenseNumber != null)
                  'license_number': user.licenseNumber,
                if (user.experience != null) 'experience': user.experience,
                if (user.isAvailableForChat != null)
                  'is_available_for_chat': user.isAvailableForChat,
                if (user.isAvailableForVideo != null)
                  'is_available_for_video': user.isAvailableForVideo,
              })
              .eq('id', user.id);
        }
      } else if (user.userType == UserType.admin) {
        // Update admin-specific fields
        if (user.adminRole != null) {
          await _supabase
              .from('admins')
              .update({'admin_role': user.adminRole})
              .eq('id', user.id);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  // Delete a user (admin only)
  Future<bool> deleteUser(String userId) async {
    try {
      // First check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can delete users');
        return false;
      }

      // Delete user from database tables based on user type
      final userData =
          await _supabase
              .from('users')
              .select('user_type')
              .eq('id', userId)
              .single();

      final userType = userData['user_type'];

      // Delete from specific type table
      if (userType == 'patient') {
        await _supabase.from('patients').delete().eq('id', userId);
      } else if (userType == 'doctor') {
        await _supabase.from('doctors').delete().eq('id', userId);
      } else if (userType == 'admin') {
        await _supabase.from('admins').delete().eq('id', userId);
      }

      // Delete from users table
      await _supabase.from('users').delete().eq('id', userId);

      // Note: This doesn't delete the auth user
      // For complete deletion, you'd need to use Supabase Functions or server-side code

      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }
}
