import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility class to fix data integrity issues between doctors and users tables
class DoctorIntegrityFixer {
  final SupabaseClient _supabase;

  DoctorIntegrityFixer(this._supabase);

  /// Fix data integrity issues between doctors and users tables
  Future<Map<String, dynamic>> fixDoctorUserIntegrity() async {
    debugPrint('==== DOCTOR INTEGRITY FIXER ====');
    debugPrint('Starting data integrity fix process');

    try {
      // 1. Get all doctors
      final allDoctors = await _supabase.from('doctors').select('id, verification_status');
      
      if (allDoctors.isEmpty) {
        debugPrint('No doctors found in the database');
        return {
          'success': false,
          'message': 'No doctors found in the database',
          'fixed_count': 0,
          'total_count': 0
        };
      }

      final doctorIds = allDoctors.map((d) => d['id'].toString()).toList();
      debugPrint('Found ${doctorIds.length} doctors in the database');
      
      // Log each doctor's ID and verification status
      for (var doctor in allDoctors) {
        debugPrint('Doctor ID: ${doctor['id']}, Status: ${doctor['verification_status'] ?? 'null'}');
      }

      // 2. Get all users with these doctor IDs
      final existingUsers = await _supabase
          .from('users')
          .select('id, user_type')
          .filter('id', 'in', doctorIds);
      
      debugPrint('Found ${existingUsers.length} existing user records for doctors');

      // 3. Identify doctors without corresponding user records
      final existingUserIds = existingUsers.map((u) => u['id'].toString()).toSet();
      final missingUserIds = doctorIds.where((id) => !existingUserIds.contains(id)).toList();
      
      debugPrint('Found ${missingUserIds.length} doctors without user records');
      if (missingUserIds.isNotEmpty) {
        debugPrint('Missing user records for doctor IDs: $missingUserIds');
      }

      // 4. Identify users with incorrect user_type
      final incorrectTypeUsers = existingUsers.where((u) => u['user_type'] != 'doctor').toList();
      final incorrectTypeIds = incorrectTypeUsers.map((u) => u['id'].toString()).toList();
      
      debugPrint('Found ${incorrectTypeIds.length} users with incorrect user_type');
      if (incorrectTypeIds.isNotEmpty) {
        debugPrint('Incorrect user_type for doctor IDs: $incorrectTypeIds');
      }

      // 5. Fix missing user records
      int createdCount = 0;
      for (final doctorId in missingUserIds) {
        try {
          // Create a new user record for this doctor
          await _supabase.from('users').insert({
            'id': doctorId,
            'name': 'Dr. Unknown', // Default name
            'email': 'doctor_${doctorId.substring(0, 8)}@example.com', // Default email
            'user_type': 'doctor',
            'profile_image': '', // Default empty profile image
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          
          debugPrint('Created new user record for doctor ID: $doctorId');
          createdCount++;
        } catch (e) {
          debugPrint('Error creating user record for doctor ID: $doctorId - $e');
        }
      }

      // 6. Fix incorrect user_type
      int updatedCount = 0;
      for (final userId in incorrectTypeIds) {
        try {
          await _supabase
              .from('users')
              .update({'user_type': 'doctor'})
              .eq('id', userId);
          
          debugPrint('Updated user_type to doctor for ID: $userId');
          updatedCount++;
        } catch (e) {
          debugPrint('Error updating user_type for ID: $userId - $e');
        }
      }

      // 7. Verify the fix
      final verifyUsers = await _supabase
          .from('users')
          .select('id, user_type')
          .filter('id', 'in', doctorIds);
      
      final verifyDoctorUserIds = verifyUsers
          .where((u) => u['user_type'] == 'doctor')
          .map((u) => u['id'].toString())
          .toSet();
      
      final stillMissingIds = doctorIds.where((id) => !verifyDoctorUserIds.contains(id)).toList();
      
      final fixedCount = createdCount + updatedCount;
      final success = stillMissingIds.isEmpty;
      
      debugPrint('==== FIX SUMMARY ====');
      debugPrint('Created $createdCount new user records');
      debugPrint('Updated $updatedCount existing user records');
      debugPrint('Total fixed: $fixedCount');
      debugPrint('Success: $success');
      
      if (!success) {
        debugPrint('Still missing user records for doctor IDs: $stillMissingIds');
      }
      
      return {
        'success': success,
        'message': success 
            ? 'Successfully fixed $fixedCount doctor-user integrity issues' 
            : 'Fixed $fixedCount issues but ${stillMissingIds.length} still remain',
        'fixed_count': fixedCount,
        'total_count': doctorIds.length,
        'still_missing': stillMissingIds,
      };
    } catch (e) {
      debugPrint('Error fixing doctor-user integrity: $e');
      return {
        'success': false,
        'message': 'Error fixing doctor-user integrity: $e',
        'fixed_count': 0,
        'total_count': 0,
      };
    }
  }
}
