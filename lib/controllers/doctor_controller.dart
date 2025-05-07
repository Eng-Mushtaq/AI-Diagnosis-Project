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
      // Try to get doctors from Supabase
      // First, get doctors with approved verification status
      final doctorIds = await _supabaseService.supabaseClient
          .from('doctors')
          .select('id')
          .eq('verification_status', 'approved');

      if (doctorIds.isEmpty) {
        _doctors.clear();
        debugPrint('No approved doctors found');
        return;
      }

      final ids = doctorIds.map((item) => item['id']).toList();
      debugPrint('Found ${ids.length} approved doctors');

      // Get user data for approved doctors
      final users = await _supabaseService.supabaseClient
          .from('users')
          .select()
          .eq('user_type', 'doctor')
          .filter('id', 'in', ids);

      List<DoctorModel> doctorsList = [];

      for (final userData in users) {
        try {
          // Get doctor data
          final doctorData =
              await _supabaseService.supabaseClient
                  .from('doctors')
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
      final doctorIds = await _supabaseService.supabaseClient
          .from('doctors')
          .select('id')
          .eq('specialization', specialization)
          .eq('verification_status', 'approved');

      if (doctorIds.isEmpty) {
        _doctors.clear();
        debugPrint(
          'No approved doctors found with specialization: $specialization',
        );
        return;
      }

      final ids = doctorIds.map((item) => item['id']).toList();
      debugPrint(
        'Found ${ids.length} approved doctors with specialization: $specialization',
      );

      // Use filter to match IDs
      final users = await _supabaseService.supabaseClient
          .from('users')
          .select()
          .filter('id', 'in', ids);

      List<DoctorModel> doctorsList = [];

      for (final userData in users) {
        try {
          // Get doctor data
          final doctorData =
              await _supabaseService.supabaseClient
                  .from('doctors')
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
      // Get user data
      final userData =
          await _supabaseService.supabaseClient
              .from('users')
              .select()
              .eq('id', id)
              .single();

      // Get doctor data
      final doctorData =
          await _supabaseService.supabaseClient
              .from('doctors')
              .select()
              .eq('id', id)
              .single();

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
