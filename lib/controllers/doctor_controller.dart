import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/doctor_model.dart';
import '../services/mock_data_service.dart';
import '../services/supabase_service.dart';

// Doctor controller for managing doctor data
class DoctorController extends GetxController {
  final MockDataService _mockDataService = MockDataService();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // Observable doctors list
  final RxList<DoctorModel> _doctors = <DoctorModel>[].obs;
  List<DoctorModel> get doctors => _doctors;

  // Selected doctor
  final Rx<DoctorModel?> _selectedDoctor = Rx<DoctorModel?>(null);
  DoctorModel? get selectedDoctor => _selectedDoctor.value;

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // Get all doctors
  Future<void> getAllDoctors() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Always clear the doctors list to ensure fresh data
      _doctors.clear();

      debugPrint('Fetching doctors from Supabase...');

      // Try to get doctors from Supabase
      // First, get all doctors to check what's in the database (using new data model)
      final allDoctors = await _supabaseService.supabaseClient
          .from('doctors_profile')
          .select('id, verification_status');

      debugPrint('Total doctors in database: ${allDoctors.length}');

      // Log all verification statuses to debug
      final statuses =
          allDoctors.map((d) => d['verification_status']).toSet().toList();
      debugPrint('Verification statuses in database: $statuses');

      // Log each doctor's ID and verification status for debugging
      for (var doctor in allDoctors) {
        debugPrint(
          'Doctor ID: ${doctor['id']}, Status: ${doctor['verification_status']}',
        );
      }

      // Get doctors with approved verification status (case insensitive)
      // Also check for capitalized "Approved" or any other case variations
      final doctorIds =
          allDoctors
              .where(
                (d) =>
                    d['verification_status'] != null &&
                    (d['verification_status'].toString().toLowerCase() ==
                            'approved' ||
                        d['verification_status'].toString() == 'Approved' ||
                        d['verification_status'].toString() == 'APPROVED'),
              )
              .map((d) => d['id'])
              .toList();

      if (doctorIds.isEmpty) {
        debugPrint('No approved doctors found after filtering');
        _errorMessage.value =
            'No approved doctors found. Try using "Fetch All Doctors" to see all doctors regardless of verification status.';

        // Try to fix any doctors with incorrect case in verification_status
        for (var doctor in allDoctors) {
          if (doctor['verification_status'] != null &&
              doctor['verification_status'].toString().toLowerCase() ==
                  'approved' &&
              doctor['verification_status'].toString() != 'approved') {
            debugPrint(
              'Found doctor with incorrect case: ${doctor['id']}, Status: ${doctor['verification_status']}',
            );
            // Try to fix the status
            try {
              await _supabaseService.updateDoctorVerificationStatus(
                doctor['id'],
                'approved',
              );
              debugPrint(
                'Fixed verification status for doctor: ${doctor['id']}',
              );
            } catch (e) {
              debugPrint('Error fixing verification status: $e');
            }
          }
        }
        _isLoading.value = false;
        return;
      }

      debugPrint('Found ${doctorIds.length} approved doctors: $doctorIds');

      // First, check if these doctor IDs exist in the users table
      // This is to verify data integrity between doctors and users tables
      final allUsers = await _supabaseService.supabaseClient
          .from('users')
          .select('id, user_type')
          .filter('id', 'in', doctorIds);

      debugPrint('Checking user records for approved doctors...');
      debugPrint('Found ${allUsers.length} total user records for doctor IDs');

      // Log each user record found
      for (var user in allUsers) {
        debugPrint('User ID: ${user['id']}, User Type: ${user['user_type']}');
      }

      // Filter to only include users with user_type = 'doctor'
      final users = allUsers.where((u) => u['user_type'] == 'doctor').toList();
      debugPrint(
        'Found ${users.length} doctor user records (with user_type = doctor)',
      );

      // With our database triggers and constraints, we should no longer have integrity issues
      // But we'll still check and log any issues for monitoring purposes
      if (users.isEmpty) {
        debugPrint('==== WARNING ====');
        debugPrint(
          'No user records found for approved doctors, attempting to continue anyway',
        );
        debugPrint(
          'This should not happen with the database triggers in place',
        );
        debugPrint(
          'Found ${doctorIds.length} approved doctors but 0 corresponding user records',
        );
        debugPrint('Doctor IDs: $doctorIds');
        debugPrint('===============');

        // Instead of just retrying, let's try to fix the issue by creating user records
        debugPrint(
          'Attempting to fix data integrity issue by creating missing user records...',
        );

        List<Map<String, dynamic>> createdUsers = [];

        for (final doctorId in doctorIds) {
          try {
            // Get doctor data
            final doctorData =
                await _supabaseService.supabaseClient
                    .from('doctors_profile')
                    .select()
                    .eq('id', doctorId)
                    .single();

            // Try to create a user record using the RPC function that bypasses RLS
            try {
              await _supabaseService.supabaseClient.rpc(
                'create_missing_user_record',
                params: {
                  'doctor_id': doctorId,
                  'doctor_email':
                      'doctor_${doctorId.toString().substring(0, 8)}@example.com',
                },
              );
              debugPrint('Created user record using RPC function');
            } catch (rpcError) {
              debugPrint(
                'RPC error: $rpcError, trying direct insert as fallback',
              );

              // Fallback to direct insert (might fail due to RLS)
              try {
                // Create a better doctor name using specialization, hospital, and city
                String doctorName = '';
                final specialization = doctorData['specialization'];
                final hospital = doctorData['hospital'];
                final city = doctorData['city'];

                if (specialization != null &&
                    specialization.toString().isNotEmpty) {
                  doctorName = 'Dr. $specialization';

                  // Add hospital if available
                  if (hospital != null && hospital.toString().isNotEmpty) {
                    doctorName += ' ($hospital';

                    // Add city if available
                    if (city != null && city.toString().isNotEmpty) {
                      doctorName += ', $city)';
                    } else {
                      doctorName += ')';
                    }
                  }
                  // Add city directly if no hospital
                  else if (city != null && city.toString().isNotEmpty) {
                    doctorName += ' ($city)';
                  }
                } else {
                  // Fallback if no specialization
                  if (hospital != null && hospital.toString().isNotEmpty) {
                    doctorName = 'Dr. $hospital';
                  } else if (city != null && city.toString().isNotEmpty) {
                    doctorName = 'Dr. $city';
                  } else {
                    doctorName = 'Dr. Unknown';
                  }
                }

                await _supabaseService.supabaseClient.from('users').insert({
                  'id': doctorId,
                  'name': doctorName,
                  'email':
                      'doctor_${doctorId.toString().substring(0, 8)}@example.com',
                  'user_type': 'doctor',
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });
              } catch (insertError) {
                debugPrint('Direct insert also failed: $insertError');

                // As a last resort, try to fix all integrity issues at once using a server function
                try {
                  final result = await _supabaseService.supabaseClient.rpc(
                    'fix_all_doctor_user_integrity',
                  );
                  debugPrint('Attempted to fix all integrity issues: $result');
                } catch (fixError) {
                  debugPrint('Failed to fix integrity issues: $fixError');
                  rethrow; // Re-throw to be caught by the outer catch block
                }
              }
            }

            // Create a better doctor name using specialization, hospital, and city
            String doctorName = '';
            final specialization = doctorData['specialization'];
            final hospital = doctorData['hospital'];
            final city = doctorData['city'];

            if (specialization != null &&
                specialization.toString().isNotEmpty) {
              doctorName = 'Dr. $specialization';

              // Add hospital if available
              if (hospital != null && hospital.toString().isNotEmpty) {
                doctorName += ' ($hospital';

                // Add city if available
                if (city != null && city.toString().isNotEmpty) {
                  doctorName += ', $city)';
                } else {
                  doctorName += ')';
                }
              }
              // Add city directly if no hospital
              else if (city != null && city.toString().isNotEmpty) {
                doctorName += ' ($city)';
              }
            } else {
              // Fallback if no specialization
              if (hospital != null && hospital.toString().isNotEmpty) {
                doctorName = 'Dr. $hospital';
              } else if (city != null && city.toString().isNotEmpty) {
                doctorName = 'Dr. $city';
              } else {
                doctorName = 'Dr. Unknown';
              }
            }

            // Add to our list of created users
            createdUsers.add({
              'id': doctorId,
              'name': doctorName,
              'user_type': 'doctor',
              'profile_image': null,
            });

            debugPrint('Created user record for doctor ID: $doctorId');
          } catch (e) {
            debugPrint(
              'Error creating user record for doctor ID $doctorId: $e',
            );
          }
        }

        if (createdUsers.isNotEmpty) {
          debugPrint('==== RECOVERY ====');
          debugPrint('Created ${createdUsers.length} user records for doctors');
          debugPrint('=================');
          users.clear();
          users.addAll(createdUsers);
        } else {
          // If we couldn't create any user records, try one more time to get existing ones
          await Future.delayed(const Duration(milliseconds: 500));

          final retryUsers = await _supabaseService.supabaseClient
              .from('users')
              .select('id, user_type, name, profile_image')
              .filter('id', 'in', doctorIds);

          if (retryUsers.isNotEmpty) {
            debugPrint('==== RECOVERY ====');
            debugPrint('Found ${retryUsers.length} user records after retry');
            debugPrint('=================');
            users.clear();
            users.addAll(retryUsers);
          } else {
            _errorMessage.value =
                'No doctor records found. Please try again later.';
            _isLoading.value = false;
            return;
          }
        }
      }

      if (users.length < doctorIds.length) {
        // Some doctors don't have corresponding user records
        final foundIds = users.map((u) => u['id']).toList();
        final missingIds =
            doctorIds.where((id) => !foundIds.contains(id)).toList();

        debugPrint('==== WARNING ====');
        debugPrint(
          'Some doctors are missing user records, but continuing with available data',
        );
        debugPrint(
          'Found ${users.length} user records out of ${doctorIds.length} approved doctors',
        );
        debugPrint('Missing user records for doctor IDs: $missingIds');
        debugPrint('=================');
      }

      List<DoctorModel> doctorsList = [];

      for (final userData in users) {
        try {
          // Get doctor data from the new profile table
          final doctorData =
              await _supabaseService.supabaseClient
                  .from('doctors_profile')
                  .select()
                  .eq('id', userData['id'])
                  .single();

          // Get qualifications
          final qualifications = await _supabaseService.getDoctorQualifications(
            userData['id'],
          );

          // Get languages
          final languages = await _supabaseService.getDoctorLanguages(
            userData['id'],
          );

          // Get available days and time slots
          final availableDays = await _supabaseService.getDoctorAvailableDays(
            userData['id'],
          );
          Map<String, List<String>> availableTimeSlots = {};

          if (availableDays.isNotEmpty) {
            availableTimeSlots = await _supabaseService.getAllDoctorTimeSlots(
              userData['id'],
            );
          }

          // Create doctor model
          final doctor = DoctorModel(
            id: userData['id'],
            name: userData['name'] ?? 'Unknown Doctor',
            specialization: doctorData['specialization'] ?? 'General',
            hospital: doctorData['hospital'] ?? '',
            city: doctorData['city'] ?? '',
            profileImage: userData['profile_image'] ?? '',
            rating: doctorData['rating']?.toDouble() ?? 0.0,
            experience: doctorData['experience'] ?? 0,
            about: doctorData['about'],
            languages: languages.isNotEmpty ? languages : null,
            qualifications: qualifications.isNotEmpty ? qualifications : null,
            availableDays: availableDays.isNotEmpty ? availableDays : null,
            availableTimeSlots:
                availableTimeSlots.isNotEmpty ? availableTimeSlots : null,
            consultationFee: doctorData['consultation_fee']?.toDouble() ?? 0.0,
            isAvailableForVideo: doctorData['is_available_for_video'] ?? false,
            isAvailableForChat: doctorData['is_available_for_chat'] ?? false,
            verificationStatus: doctorData['verification_status'] ?? 'pending',
            rejectionReason: doctorData['rejection_reason'],
            verificationDate:
                doctorData['verification_date'] != null
                    ? DateTime.parse(doctorData['verification_date'])
                    : null,
            verifiedBy: doctorData['verified_by'],
          );

          doctorsList.add(doctor);
          debugPrint(
            'Successfully created doctor model for: ${doctor.name} (${doctor.id})',
          );
        } catch (e) {
          debugPrint('Error getting doctor data: $e');
        }
      }

      if (doctorsList.isEmpty && users.isNotEmpty) {
        debugPrint(
          'Failed to create any doctor models despite finding user records',
        );
        _errorMessage.value =
            'Failed to load doctor details. Please try "Fetch All Doctors" instead.';
      } else {
        debugPrint('Successfully loaded ${doctorsList.length} doctors');
        _doctors.assignAll(doctorsList);
      }
    } catch (e) {
      debugPrint('Exception in getAllDoctors: ${e.toString()}');
      _errorMessage.value = 'Failed to get doctors: ${e.toString()}';

      // Fallback to mock data
      try {
        final mockDoctorsList = await _mockDataService.getAllDoctors();
        _doctors.assignAll(mockDoctorsList);
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get doctors: ${e.toString()}. Mock data error: ${mockError.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Get doctors by specialization
  Future<void> getDoctorsBySpecialization(String specialization) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Try to get doctors from Supabase
      // Only get approved doctors with the specified specialization
      // Use ilike for case-insensitive matching of verification_status
      final doctorIds = await _supabaseService.supabaseClient
          .from('doctors_profile')
          .select('id, verification_status')
          .eq('specialization', specialization)
          .or(
            'verification_status.ilike.approved,verification_status.eq.Approved,verification_status.eq.APPROVED',
          );

      // Filter to only include doctors with approved status (case insensitive)
      final approvedDoctorIds =
          doctorIds
              .where(
                (d) =>
                    d['verification_status'] != null &&
                    d['verification_status'].toString().toLowerCase() ==
                        'approved',
              )
              .map((d) => d['id'])
              .toList();

      if (approvedDoctorIds.isEmpty) {
        _doctors.clear();
        debugPrint(
          'No approved doctors found with specialization: $specialization',
        );
        return;
      }

      final ids = approvedDoctorIds;
      debugPrint(
        'Found ${ids.length} approved doctors with specialization: $specialization',
      );

      // Use filter to match IDs
      final users = await _supabaseService.supabaseClient
          .from('users')
          .select()
          .filter('id', 'in', ids);

      // Check if we found all the user records
      if (users.isEmpty) {
        debugPrint('==== WARNING ====');
        debugPrint(
          'No user records found for approved doctors with specialization: $specialization',
        );
        debugPrint(
          'This should not happen with the database triggers in place',
        );
        debugPrint(
          'Found ${ids.length} approved doctors but 0 corresponding user records',
        );
        debugPrint('Doctor IDs: $ids');
        debugPrint('===============');

        // Try to get the user records again after a short delay
        await Future.delayed(const Duration(milliseconds: 500));

        final retryUsers = await _supabaseService.supabaseClient
            .from('users')
            .select('id, user_type, name, profile_image')
            .filter('id', 'in', ids);

        if (retryUsers.isNotEmpty) {
          debugPrint('==== RECOVERY ====');
          debugPrint('Found ${retryUsers.length} user records after retry');
          debugPrint('=================');
          users.clear();
          users.addAll(retryUsers);
        } else {
          _errorMessage.value =
              'No doctors found with specialization: $specialization';
          _isLoading.value = false;
          return;
        }
      }

      if (users.length < ids.length) {
        // Some doctors don't have corresponding user records
        final foundIds = users.map((u) => u['id']).toList();
        final missingIds = ids.where((id) => !foundIds.contains(id)).toList();

        debugPrint('==== WARNING ====');
        debugPrint(
          'Some doctors are missing user records, but continuing with available data',
        );
        debugPrint(
          'Found ${users.length} user records out of ${ids.length} approved doctors',
        );
        debugPrint('Missing user records for doctor IDs: $missingIds');
        debugPrint('=================');
      }

      List<DoctorModel> doctorsList = [];

      for (final userData in users) {
        try {
          // Get doctor data from the new profile table
          final doctorData =
              await _supabaseService.supabaseClient
                  .from('doctors_profile')
                  .select()
                  .eq('id', userData['id'])
                  .single();

          // Get qualifications
          final qualifications = await _supabaseService.getDoctorQualifications(
            userData['id'],
          );

          // Get languages
          final languages = await _supabaseService.getDoctorLanguages(
            userData['id'],
          );

          // Get available days and time slots
          final availableDays = await _supabaseService.getDoctorAvailableDays(
            userData['id'],
          );
          Map<String, List<String>> availableTimeSlots = {};

          if (availableDays.isNotEmpty) {
            availableTimeSlots = await _supabaseService.getAllDoctorTimeSlots(
              userData['id'],
            );
          }

          // Create doctor model
          final doctor = DoctorModel(
            id: userData['id'],
            name: userData['name'],
            specialization: doctorData['specialization'],
            hospital: doctorData['hospital'] ?? '',
            city: doctorData['city'] ?? '',
            profileImage: userData['profile_image'] ?? '',
            rating: doctorData['rating']?.toDouble() ?? 0.0,
            experience: doctorData['experience'] ?? 0,
            about: doctorData['about'],
            languages: languages.isNotEmpty ? languages : null,
            qualifications: qualifications.isNotEmpty ? qualifications : null,
            availableDays: availableDays.isNotEmpty ? availableDays : null,
            availableTimeSlots:
                availableTimeSlots.isNotEmpty ? availableTimeSlots : null,
            consultationFee: doctorData['consultation_fee']?.toDouble() ?? 0.0,
            isAvailableForVideo: doctorData['is_available_for_video'] ?? false,
            isAvailableForChat: doctorData['is_available_for_chat'] ?? false,
            verificationStatus: doctorData['verification_status'] ?? 'pending',
            rejectionReason: doctorData['rejection_reason'],
            verificationDate:
                doctorData['verification_date'] != null
                    ? DateTime.parse(doctorData['verification_date'])
                    : null,
            verifiedBy: doctorData['verified_by'],
          );

          doctorsList.add(doctor);
        } catch (e) {
          debugPrint('Error getting doctor data: $e');
        }
      }

      _doctors.assignAll(doctorsList);
    } catch (e) {
      _errorMessage.value = 'Failed to get doctors: ${e.toString()}';

      // Fallback to mock data
      try {
        final mockDoctorsList = await _mockDataService
            .getDoctorsBySpecialization(specialization);
        _doctors.assignAll(mockDoctorsList);
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get doctors: ${e.toString()}. Mock data error: ${mockError.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Get doctor by ID
  Future<void> getDoctorById(String id) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Get doctor data first to ensure it exists (using new data model)
      final doctorData =
          await _supabaseService.supabaseClient
              .from('doctors_profile')
              .select()
              .eq('id', id)
              .single();

      // With our database triggers, this should automatically create a user record if missing

      // Get user data
      Map<String, dynamic> userData;
      try {
        userData =
            await _supabaseService.supabaseClient
                .from('users')
                .select()
                .eq('id', id)
                .single();
      } catch (e) {
        debugPrint('==== WARNING ====');
        debugPrint('User record not found for doctor ID: $id');
        debugPrint(
          'This should not happen with the database triggers in place',
        );
        debugPrint('Error: $e');
        debugPrint('===============');

        // Try to get the user record again after a short delay
        await Future.delayed(const Duration(milliseconds: 500));

        try {
          userData =
              await _supabaseService.supabaseClient
                  .from('users')
                  .select()
                  .eq('id', id)
                  .single();

          debugPrint('==== RECOVERY ====');
          debugPrint('Found user record after retry');
          debugPrint('=================');
        } catch (retryError) {
          // Create a default user data object
          debugPrint('==== FALLBACK ====');
          debugPrint('Creating default user data for doctor ID: $id');
          debugPrint('=================');

          // Create a better doctor name using specialization, hospital, and city
          String doctorName = '';
          final specialization = doctorData['specialization'];
          final hospital = doctorData['hospital'];
          final city = doctorData['city'];

          if (specialization != null && specialization.toString().isNotEmpty) {
            doctorName = 'Dr. $specialization';

            // Add hospital if available
            if (hospital != null && hospital.toString().isNotEmpty) {
              doctorName += ' ($hospital';

              // Add city if available
              if (city != null && city.toString().isNotEmpty) {
                doctorName += ', $city)';
              } else {
                doctorName += ')';
              }
            }
            // Add city directly if no hospital
            else if (city != null && city.toString().isNotEmpty) {
              doctorName += ' ($city)';
            }
          } else {
            // Fallback if no specialization
            if (hospital != null && hospital.toString().isNotEmpty) {
              doctorName = 'Dr. $hospital';
            } else if (city != null && city.toString().isNotEmpty) {
              doctorName = 'Dr. $city';
            } else {
              doctorName = 'Dr. Unknown';
            }
          }

          userData = {
            'id': id,
            'name': doctorName,
            'profile_image': '',
            'user_type': 'doctor',
          };
        }
      }

      // Get qualifications
      final qualifications = await _supabaseService.getDoctorQualifications(id);

      // Get languages
      final languages = await _supabaseService.getDoctorLanguages(id);

      // Get available days and time slots
      final availableDays = await _supabaseService.getDoctorAvailableDays(id);
      Map<String, List<String>> availableTimeSlots = {};

      if (availableDays.isNotEmpty) {
        availableTimeSlots = await _supabaseService.getAllDoctorTimeSlots(id);
      }

      // Create doctor model
      final doctor = DoctorModel(
        id: userData['id'],
        name: userData['name'],
        specialization: doctorData['specialization'],
        hospital: doctorData['hospital'] ?? '',
        city: doctorData['city'] ?? '',
        profileImage: userData['profile_image'] ?? '',
        rating: doctorData['rating']?.toDouble() ?? 0.0,
        experience: doctorData['experience'] ?? 0,
        about: doctorData['about'],
        languages: languages.isNotEmpty ? languages : null,
        qualifications: qualifications.isNotEmpty ? qualifications : null,
        availableDays: availableDays.isNotEmpty ? availableDays : null,
        availableTimeSlots:
            availableTimeSlots.isNotEmpty ? availableTimeSlots : null,
        consultationFee: doctorData['consultation_fee']?.toDouble() ?? 0.0,
        isAvailableForVideo: doctorData['is_available_for_video'] ?? false,
        isAvailableForChat: doctorData['is_available_for_chat'] ?? false,
        verificationStatus: doctorData['verification_status'] ?? 'pending',
        rejectionReason: doctorData['rejection_reason'],
        verificationDate:
            doctorData['verification_date'] != null
                ? DateTime.parse(doctorData['verification_date'])
                : null,
        verifiedBy: doctorData['verified_by'],
      );

      _selectedDoctor.value = doctor;
    } catch (e) {
      _errorMessage.value = 'Failed to get doctor: ${e.toString()}';

      // Fallback to mock data
      try {
        final mockDoctor = await _mockDataService.getDoctorById(id);
        _selectedDoctor.value = mockDoctor;
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get doctor: ${e.toString()}. Mock data error: ${mockError.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Set selected doctor
  void setSelectedDoctor(DoctorModel doctor) {
    _selectedDoctor.value = doctor;
  }

  // Clear selected doctor
  void clearSelectedDoctor() {
    _selectedDoctor.value = null;
  }

  // Force refresh doctors list
  Future<void> refreshDoctors() async {
    debugPrint('Forcing refresh of doctors list');
    _doctors.clear();
    _errorMessage.value = '';
    await getAllDoctors();

    // Log the results after refresh
    if (_doctors.isEmpty) {
      debugPrint('After refresh: No doctors found');
    } else {
      debugPrint('After refresh: Found ${_doctors.length} doctors');
      for (var doctor in _doctors) {
        debugPrint(
          'Doctor: ${doctor.name}, ID: ${doctor.id}, Status: ${doctor.verificationStatus}',
        );
      }
    }
  }

  // Get all doctors regardless of verification status
  Future<void> getAllDoctorsRegardlessOfStatus() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Always clear the doctors list to ensure fresh data
      _doctors.clear();

      debugPrint('Fetching ALL doctors from Supabase regardless of status...');

      // Get all doctors from the database (using new data model)
      final allDoctors = await _supabaseService.supabaseClient
          .from('doctors_profile')
          .select('id, verification_status');

      if (allDoctors.isEmpty) {
        debugPrint('No doctors found in the database');
        _errorMessage.value = 'No doctors found in the database';
        _isLoading.value = false;
        return;
      }

      // Log all verification statuses to debug
      final statuses =
          allDoctors.map((d) => d['verification_status']).toSet().toList();
      debugPrint('Verification statuses in database: $statuses');

      // Log each doctor's ID and verification status for debugging
      for (var doctor in allDoctors) {
        debugPrint(
          'Doctor ID: ${doctor['id']}, Status: ${doctor['verification_status'] ?? 'null'}',
        );
      }

      final doctorIds = allDoctors.map((d) => d['id']).toList();
      debugPrint('Found ${doctorIds.length} total doctors: $doctorIds');

      // First check if these doctor IDs exist in the users table at all
      final allUsers = await _supabaseService.supabaseClient
          .from('users')
          .select('id, user_type')
          .filter('id', 'in', doctorIds);

      debugPrint(
        'Found ${allUsers.length} total user records for all doctor IDs',
      );

      // Check for missing user records
      if (allUsers.isEmpty) {
        final errorMsg =
            'DATA INTEGRITY ISSUE: No user records found for any doctors';
        debugPrint('==== ERROR ====');
        debugPrint(errorMsg);
        debugPrint(
          'Found ${doctorIds.length} total doctors but 0 corresponding user records',
        );
        debugPrint('Doctor IDs: $doctorIds');
        debugPrint('===============');

        // Instead of just returning an error, let's try to fix the issue by creating user records
        debugPrint(
          'Attempting to fix data integrity issue by creating missing user records...',
        );

        List<Map<String, dynamic>> createdUsers = [];

        for (final doctorId in doctorIds) {
          try {
            // Get doctor data
            final doctorData =
                await _supabaseService.supabaseClient
                    .from('doctors_profile')
                    .select()
                    .eq('id', doctorId)
                    .single();

            // Try to create a user record using the RPC function that bypasses RLS
            try {
              await _supabaseService.supabaseClient.rpc(
                'create_missing_user_record',
                params: {
                  'doctor_id': doctorId,
                  'doctor_email':
                      'doctor_${doctorId.toString().substring(0, 8)}@example.com',
                },
              );
              debugPrint('Created user record using RPC function');
            } catch (rpcError) {
              debugPrint(
                'RPC error: $rpcError, trying direct insert as fallback',
              );

              // Fallback to direct insert (might fail due to RLS)
              try {
                // Create a better doctor name using specialization, hospital, and city
                String doctorName = '';
                final specialization = doctorData['specialization'];
                final hospital = doctorData['hospital'];
                final city = doctorData['city'];

                if (specialization != null &&
                    specialization.toString().isNotEmpty) {
                  doctorName = 'Dr. $specialization';

                  // Add hospital if available
                  if (hospital != null && hospital.toString().isNotEmpty) {
                    doctorName += ' ($hospital';

                    // Add city if available
                    if (city != null && city.toString().isNotEmpty) {
                      doctorName += ', $city)';
                    } else {
                      doctorName += ')';
                    }
                  }
                  // Add city directly if no hospital
                  else if (city != null && city.toString().isNotEmpty) {
                    doctorName += ' ($city)';
                  }
                } else {
                  // Fallback if no specialization
                  if (hospital != null && hospital.toString().isNotEmpty) {
                    doctorName = 'Dr. $hospital';
                  } else if (city != null && city.toString().isNotEmpty) {
                    doctorName = 'Dr. $city';
                  } else {
                    doctorName = 'Dr. Unknown';
                  }
                }

                await _supabaseService.supabaseClient.from('users').insert({
                  'id': doctorId,
                  'name': doctorName,
                  'email':
                      'doctor_${doctorId.toString().substring(0, 8)}@example.com',
                  'user_type': 'doctor',
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });
              } catch (insertError) {
                debugPrint('Direct insert also failed: $insertError');

                // As a last resort, try to fix all integrity issues at once using a server function
                try {
                  final result = await _supabaseService.supabaseClient.rpc(
                    'fix_all_doctor_user_integrity',
                  );
                  debugPrint('Attempted to fix all integrity issues: $result');
                } catch (fixError) {
                  debugPrint('Failed to fix integrity issues: $fixError');
                  rethrow; // Re-throw to be caught by the outer catch block
                }
              }
            }

            // Create a better doctor name using specialization, hospital, and city
            String doctorName = '';
            final specialization = doctorData['specialization'];
            final hospital = doctorData['hospital'];
            final city = doctorData['city'];

            if (specialization != null &&
                specialization.toString().isNotEmpty) {
              doctorName = 'Dr. $specialization';

              // Add hospital if available
              if (hospital != null && hospital.toString().isNotEmpty) {
                doctorName += ' ($hospital';

                // Add city if available
                if (city != null && city.toString().isNotEmpty) {
                  doctorName += ', $city)';
                } else {
                  doctorName += ')';
                }
              }
              // Add city directly if no hospital
              else if (city != null && city.toString().isNotEmpty) {
                doctorName += ' ($city)';
              }
            } else {
              // Fallback if no specialization
              if (hospital != null && hospital.toString().isNotEmpty) {
                doctorName = 'Dr. $hospital';
              } else if (city != null && city.toString().isNotEmpty) {
                doctorName = 'Dr. $city';
              } else {
                doctorName = 'Dr. Unknown';
              }
            }

            // Add to our list of created users
            createdUsers.add({
              'id': doctorId,
              'name': doctorName,
              'user_type': 'doctor',
            });

            debugPrint('Created user record for doctor ID: $doctorId');
          } catch (e) {
            debugPrint(
              'Error creating user record for doctor ID $doctorId: $e',
            );
          }
        }

        if (createdUsers.isEmpty) {
          // If we couldn't create any user records, return with an error
          _errorMessage.value =
              'Data integrity issue: Could not create missing user records for doctors. Please check database consistency.';
          _isLoading.value = false;
          return;
        }

        // Use the created users instead of the empty allUsers
        debugPrint('Created ${createdUsers.length} user records for doctors');
        allUsers.clear();
        allUsers.addAll(createdUsers);
      }

      if (allUsers.length < doctorIds.length) {
        // Some doctors don't have corresponding user records
        final foundIds = allUsers.map((u) => u['id']).toList();
        final missingIds =
            doctorIds.where((id) => !foundIds.contains(id)).toList();

        debugPrint('==== WARNING ====');
        debugPrint(
          'PARTIAL DATA INTEGRITY ISSUE: Some doctors are missing user records',
        );
        debugPrint(
          'Found ${allUsers.length} user records out of ${doctorIds.length} total doctors',
        );
        debugPrint('Missing user records for doctor IDs: $missingIds');
        debugPrint(
          'This indicates a data integrity issue between doctors and users tables',
        );
        debugPrint('=================');
      }

      // Filter to only include users with user_type = 'doctor'
      final users = allUsers.where((u) => u['user_type'] == 'doctor').toList();
      debugPrint(
        'Found ${users.length} doctor user records (with user_type = doctor)',
      );

      if (users.isEmpty) {
        final errorMsg =
            'DATA INTEGRITY ISSUE: Found user records but none with user_type = doctor';
        debugPrint('==== ERROR ====');
        debugPrint(errorMsg);
        debugPrint(
          'Found ${allUsers.length} user records but none have user_type = doctor',
        );
        debugPrint('User IDs: ${allUsers.map((u) => u['id']).toList()}');
        debugPrint(
          'User types: ${allUsers.map((u) => u['user_type']).toList()}',
        );
        debugPrint('===============');
        _errorMessage.value =
            'Data integrity issue: Found user records for doctors but none have user_type = doctor. Please check database consistency.';
        _isLoading.value = false;
        return;
      }

      List<DoctorModel> doctorsList = [];

      for (final userData in users) {
        try {
          // Get doctor data from the new profile table
          final doctorData =
              await _supabaseService.supabaseClient
                  .from('doctors_profile')
                  .select()
                  .eq('id', userData['id'])
                  .single();

          // Get qualifications
          final qualifications = await _supabaseService.getDoctorQualifications(
            userData['id'],
          );

          // Get languages
          final languages = await _supabaseService.getDoctorLanguages(
            userData['id'],
          );

          // Get available days and time slots
          final availableDays = await _supabaseService.getDoctorAvailableDays(
            userData['id'],
          );
          Map<String, List<String>> availableTimeSlots = {};

          if (availableDays.isNotEmpty) {
            availableTimeSlots = await _supabaseService.getAllDoctorTimeSlots(
              userData['id'],
            );
          }

          // Create doctor model
          final doctor = DoctorModel(
            id: userData['id'],
            name: userData['name'] ?? 'Unknown Doctor',
            specialization: doctorData['specialization'] ?? 'General',
            hospital: doctorData['hospital'] ?? '',
            city: doctorData['city'] ?? '',
            profileImage: userData['profile_image'] ?? '',
            rating: doctorData['rating']?.toDouble() ?? 0.0,
            experience: doctorData['experience'] ?? 0,
            about: doctorData['about'],
            languages: languages.isNotEmpty ? languages : null,
            qualifications: qualifications.isNotEmpty ? qualifications : null,
            availableDays: availableDays.isNotEmpty ? availableDays : null,
            availableTimeSlots:
                availableTimeSlots.isNotEmpty ? availableTimeSlots : null,
            consultationFee: doctorData['consultation_fee']?.toDouble() ?? 0.0,
            isAvailableForVideo: doctorData['is_available_for_video'] ?? false,
            isAvailableForChat: doctorData['is_available_for_chat'] ?? false,
            verificationStatus: doctorData['verification_status'] ?? 'pending',
            rejectionReason: doctorData['rejection_reason'],
            verificationDate:
                doctorData['verification_date'] != null
                    ? DateTime.parse(doctorData['verification_date'])
                    : null,
            verifiedBy: doctorData['verified_by'],
          );

          doctorsList.add(doctor);
          debugPrint(
            'Successfully created doctor model for: ${doctor.name} (${doctor.id})',
          );
        } catch (e) {
          debugPrint('Error getting doctor data for ${userData['id']}: $e');
        }
      }

      if (doctorsList.isEmpty && users.isNotEmpty) {
        debugPrint(
          'Failed to create any doctor models despite finding user records',
        );
        _errorMessage.value =
            'Failed to load doctor details. Please check database consistency.';
      } else {
        debugPrint(
          'Successfully loaded ${doctorsList.length} doctors with all statuses',
        );
        _doctors.assignAll(doctorsList);

        // Log the results
        for (var doctor in _doctors) {
          debugPrint(
            'Doctor: ${doctor.name}, ID: ${doctor.id}, Status: ${doctor.verificationStatus}',
          );
        }
      }
    } catch (e) {
      debugPrint(
        'Exception in getAllDoctorsRegardlessOfStatus: ${e.toString()}',
      );
      _errorMessage.value = 'Failed to get all doctors: ${e.toString()}';

      // Fallback to mock data
      try {
        final mockDoctorsList = await _mockDataService.getAllDoctors();
        _doctors.assignAll(mockDoctorsList);
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get all doctors: ${e.toString()}. Mock data error: ${mockError.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Update doctor profile
  Future<bool> updateDoctorProfile(DoctorModel doctor) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.updateDoctorProfile(doctor);

      // Update selected doctor
      if (_selectedDoctor.value != null &&
          _selectedDoctor.value!.id == doctor.id) {
        _selectedDoctor.value = doctor;
      }

      // Update doctor in the list
      final index = _doctors.indexWhere((d) => d.id == doctor.id);
      if (index != -1) {
        _doctors[index] = doctor;
        _doctors.refresh();
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to update doctor profile: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Add doctor qualification
  Future<bool> addDoctorQualification(
    String doctorId,
    String qualification,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.addDoctorQualification(doctorId, qualification);

      // Update selected doctor
      if (_selectedDoctor.value != null &&
          _selectedDoctor.value!.id == doctorId) {
        final qualifications = _selectedDoctor.value!.qualifications ?? [];
        if (!qualifications.contains(qualification)) {
          final updatedQualifications = List<String>.from(qualifications)
            ..add(qualification);
          _selectedDoctor.value = _selectedDoctor.value!.copyWith(
            qualifications: updatedQualifications,
          );
        }
      }

      // Update doctor in the list
      final index = _doctors.indexWhere((d) => d.id == doctorId);
      if (index != -1) {
        final doctor = _doctors[index];
        final qualifications = doctor.qualifications ?? [];
        if (!qualifications.contains(qualification)) {
          final updatedQualifications = List<String>.from(qualifications)
            ..add(qualification);
          _doctors[index] = doctor.copyWith(
            qualifications: updatedQualifications,
          );
          _doctors.refresh();
        }
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to add qualification: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Remove doctor qualification
  Future<bool> removeDoctorQualification(
    String doctorId,
    String qualification,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.removeDoctorQualification(doctorId, qualification);

      // Update selected doctor
      if (_selectedDoctor.value != null &&
          _selectedDoctor.value!.id == doctorId) {
        final qualifications = _selectedDoctor.value!.qualifications ?? [];
        if (qualifications.contains(qualification)) {
          final updatedQualifications = List<String>.from(qualifications)
            ..remove(qualification);
          _selectedDoctor.value = _selectedDoctor.value!.copyWith(
            qualifications:
                updatedQualifications.isEmpty ? null : updatedQualifications,
          );
        }
      }

      // Update doctor in the list
      final index = _doctors.indexWhere((d) => d.id == doctorId);
      if (index != -1) {
        final doctor = _doctors[index];
        final qualifications = doctor.qualifications ?? [];
        if (qualifications.contains(qualification)) {
          final updatedQualifications = List<String>.from(qualifications)
            ..remove(qualification);
          _doctors[index] = doctor.copyWith(
            qualifications:
                updatedQualifications.isEmpty ? null : updatedQualifications,
          );
          _doctors.refresh();
        }
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to remove qualification: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update doctor qualifications (replace all)
  Future<bool> updateDoctorQualifications(
    String doctorId,
    List<String> qualifications,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.updateDoctorQualifications(
        doctorId,
        qualifications,
      );

      // Update selected doctor
      if (_selectedDoctor.value != null &&
          _selectedDoctor.value!.id == doctorId) {
        _selectedDoctor.value = _selectedDoctor.value!.copyWith(
          qualifications: qualifications.isEmpty ? null : qualifications,
        );
      }

      // Update doctor in the list
      final index = _doctors.indexWhere((d) => d.id == doctorId);
      if (index != -1) {
        _doctors[index] = _doctors[index].copyWith(
          qualifications: qualifications.isEmpty ? null : qualifications,
        );
        _doctors.refresh();
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to update qualifications: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Add available day for a doctor
  Future<bool> addDoctorAvailableDay(String doctorId, String day) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.addDoctorAvailableDay(doctorId, day);

      // Update selected doctor
      if (_selectedDoctor.value != null &&
          _selectedDoctor.value!.id == doctorId) {
        final availableDays = _selectedDoctor.value!.availableDays ?? [];
        if (!availableDays.contains(day)) {
          final updatedDays = List<String>.from(availableDays)..add(day);
          _selectedDoctor.value = _selectedDoctor.value!.copyWith(
            availableDays: updatedDays,
          );
        }
      }

      // Update doctor in the list
      final index = _doctors.indexWhere((d) => d.id == doctorId);
      if (index != -1) {
        final doctor = _doctors[index];
        final availableDays = doctor.availableDays ?? [];
        if (!availableDays.contains(day)) {
          final updatedDays = List<String>.from(availableDays)..add(day);
          _doctors[index] = doctor.copyWith(availableDays: updatedDays);
          _doctors.refresh();
        }
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to add available day: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Remove available day for a doctor
  Future<bool> removeDoctorAvailableDay(String doctorId, String day) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.removeDoctorAvailableDay(doctorId, day);

      // Update selected doctor
      if (_selectedDoctor.value != null &&
          _selectedDoctor.value!.id == doctorId) {
        final availableDays = _selectedDoctor.value!.availableDays ?? [];
        if (availableDays.contains(day)) {
          final updatedDays = List<String>.from(availableDays)..remove(day);

          // Also remove time slots for this day
          final availableTimeSlots = Map<String, List<String>>.from(
            _selectedDoctor.value!.availableTimeSlots ?? {},
          );
          availableTimeSlots.remove(day);

          _selectedDoctor.value = _selectedDoctor.value!.copyWith(
            availableDays: updatedDays.isEmpty ? null : updatedDays,
            availableTimeSlots:
                availableTimeSlots.isEmpty ? null : availableTimeSlots,
          );
        }
      }

      // Update doctor in the list
      final index = _doctors.indexWhere((d) => d.id == doctorId);
      if (index != -1) {
        final doctor = _doctors[index];
        final availableDays = doctor.availableDays ?? [];
        if (availableDays.contains(day)) {
          final updatedDays = List<String>.from(availableDays)..remove(day);

          // Also remove time slots for this day
          final availableTimeSlots = Map<String, List<String>>.from(
            doctor.availableTimeSlots ?? {},
          );
          availableTimeSlots.remove(day);

          _doctors[index] = doctor.copyWith(
            availableDays: updatedDays.isEmpty ? null : updatedDays,
            availableTimeSlots:
                availableTimeSlots.isEmpty ? null : availableTimeSlots,
          );
          _doctors.refresh();
        }
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to remove available day: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Add time slot for a doctor
  Future<bool> addDoctorTimeSlot(
    String doctorId,
    String day,
    String timeSlot,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.addDoctorTimeSlot(doctorId, day, timeSlot, true);

      // Update selected doctor
      if (_selectedDoctor.value != null &&
          _selectedDoctor.value!.id == doctorId) {
        final availableTimeSlots = Map<String, List<String>>.from(
          _selectedDoctor.value!.availableTimeSlots ?? {},
        );

        if (!availableTimeSlots.containsKey(day)) {
          availableTimeSlots[day] = [timeSlot];
        } else if (!availableTimeSlots[day]!.contains(timeSlot)) {
          availableTimeSlots[day] = List<String>.from(availableTimeSlots[day]!)
            ..add(timeSlot);
        }

        _selectedDoctor.value = _selectedDoctor.value!.copyWith(
          availableTimeSlots: availableTimeSlots,
        );
      }

      // Update doctor in the list
      final index = _doctors.indexWhere((d) => d.id == doctorId);
      if (index != -1) {
        final doctor = _doctors[index];
        final availableTimeSlots = Map<String, List<String>>.from(
          doctor.availableTimeSlots ?? {},
        );

        if (!availableTimeSlots.containsKey(day)) {
          availableTimeSlots[day] = [timeSlot];
        } else if (!availableTimeSlots[day]!.contains(timeSlot)) {
          availableTimeSlots[day] = List<String>.from(availableTimeSlots[day]!)
            ..add(timeSlot);
        }

        _doctors[index] = doctor.copyWith(
          availableTimeSlots: availableTimeSlots,
        );
        _doctors.refresh();
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to add time slot: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Remove time slot for a doctor
  Future<bool> removeDoctorTimeSlot(
    String doctorId,
    String day,
    String timeSlot,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // First, get the time slot ID
      final timeSlots = await _supabaseService.getDoctorTimeSlots(
        doctorId,
        day,
      );
      final timeSlotData = timeSlots.firstWhere(
        (slot) => slot['timeSlot'] == timeSlot,
        orElse: () => {'id': ''},
      );

      if (timeSlotData['id'] != '') {
        await _supabaseService.removeDoctorTimeSlot(timeSlotData['id']);

        // Update selected doctor
        if (_selectedDoctor.value != null &&
            _selectedDoctor.value!.id == doctorId) {
          final availableTimeSlots = Map<String, List<String>>.from(
            _selectedDoctor.value!.availableTimeSlots ?? {},
          );

          if (availableTimeSlots.containsKey(day) &&
              availableTimeSlots[day]!.contains(timeSlot)) {
            availableTimeSlots[day] = List<String>.from(
              availableTimeSlots[day]!,
            )..remove(timeSlot);

            if (availableTimeSlots[day]!.isEmpty) {
              availableTimeSlots.remove(day);
            }

            _selectedDoctor.value = _selectedDoctor.value!.copyWith(
              availableTimeSlots:
                  availableTimeSlots.isEmpty ? null : availableTimeSlots,
            );
          }
        }

        // Update doctor in the list
        final index = _doctors.indexWhere((d) => d.id == doctorId);
        if (index != -1) {
          final doctor = _doctors[index];
          final availableTimeSlots = Map<String, List<String>>.from(
            doctor.availableTimeSlots ?? {},
          );

          if (availableTimeSlots.containsKey(day) &&
              availableTimeSlots[day]!.contains(timeSlot)) {
            availableTimeSlots[day] = List<String>.from(
              availableTimeSlots[day]!,
            )..remove(timeSlot);

            if (availableTimeSlots[day]!.isEmpty) {
              availableTimeSlots.remove(day);
            }

            _doctors[index] = doctor.copyWith(
              availableTimeSlots:
                  availableTimeSlots.isEmpty ? null : availableTimeSlots,
            );
            _doctors.refresh();
          }
        }
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to remove time slot: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Get available specializations
  List<String> getAvailableSpecializations() {
    final specializations =
        _doctors.map((doctor) => doctor.specialization).toSet().toList();
    specializations.sort();
    return specializations;
  }

  // Get available cities
  List<String> getAvailableCities() {
    final cities = _doctors.map((doctor) => doctor.city).toSet().toList();
    cities.sort();
    return cities;
  }

  // Filter doctors by city
  List<DoctorModel> filterDoctorsByCity(String city) {
    return _doctors.where((doctor) => doctor.city == city).toList();
  }

  // Filter doctors by availability (video/chat)
  List<DoctorModel> filterDoctorsByAvailability(bool video, bool chat) {
    return _doctors.where((doctor) {
      if (video && chat) {
        return doctor.isAvailableForVideo && doctor.isAvailableForChat;
      } else if (video) {
        return doctor.isAvailableForVideo;
      } else if (chat) {
        return doctor.isAvailableForChat;
      } else {
        return true;
      }
    }).toList();
  }

  // Sort doctors by rating
  void sortDoctorsByRating(bool ascending) {
    _doctors.sort(
      (a, b) =>
          ascending
              ? a.rating.compareTo(b.rating)
              : b.rating.compareTo(a.rating),
    );
    _doctors.refresh();
  }

  // Sort doctors by experience
  void sortDoctorsByExperience(bool ascending) {
    _doctors.sort(
      (a, b) =>
          ascending
              ? a.experience.compareTo(b.experience)
              : b.experience.compareTo(a.experience),
    );
    _doctors.refresh();
  }

  // Sort doctors by consultation fee
  void sortDoctorsByFee(bool ascending) {
    _doctors.sort(
      (a, b) =>
          ascending
              ? a.consultationFee.compareTo(b.consultationFee)
              : b.consultationFee.compareTo(a.consultationFee),
    );
    _doctors.refresh();
  }
}
