import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/symptom_model.dart';
import '../services/mock_data_service.dart';
import '../services/supabase_service.dart';

// Symptom controller for managing symptom data
class SymptomController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final MockDataService _mockDataService = MockDataService();

  // Observable symptom list
  final RxList<SymptomModel> _symptomList = <SymptomModel>[].obs;
  List<SymptomModel> get symptomList => _symptomList;

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // Get symptoms for user
  Future<void> getSymptoms(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Use Supabase service to get symptoms
      final symptoms = await _supabaseService.getSymptoms(userId);
      _symptomList.assignAll(symptoms);
    } catch (e) {
      debugPrint('Error getting symptoms from Supabase: $e');
      _errorMessage.value = 'Failed to get symptoms: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        final mockSymptoms = await _mockDataService.getSymptoms(userId);
        _symptomList.assignAll(mockSymptoms);
        _errorMessage.value = ''; // Clear error if mock data succeeds
      } catch (mockError) {
        debugPrint('Error getting mock symptoms: $mockError');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Add new symptom
  Future<SymptomModel?> addSymptom(SymptomModel symptom) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Use Supabase service to add symptom
      final newSymptom = await _supabaseService.addSymptom(symptom);
      _symptomList.add(newSymptom);
      return newSymptom;
    } catch (e) {
      debugPrint('Error adding symptom to Supabase: $e');
      _errorMessage.value = 'Failed to add symptom: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        final mockSymptom = await _mockDataService.addSymptom(symptom);
        _symptomList.add(mockSymptom);
        return mockSymptom;
      } catch (mockError) {
        debugPrint('Error adding mock symptom: $mockError');
        return null;
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Get latest symptom
  SymptomModel? getLatestSymptom() {
    if (_symptomList.isEmpty) return null;

    // Sort by timestamp (newest first)
    final sortedList = List<SymptomModel>.from(_symptomList)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return sortedList.first;
  }

  // Get symptom by ID
  Future<SymptomModel?> getSymptomById(String id) async {
    try {
      // First check if it's in the local list
      try {
        return _symptomList.firstWhere((symptom) => symptom.id == id);
      } catch (_) {
        // If not found in local list, fetch from Supabase
        return await _supabaseService.getSymptomById(id);
      }
    } catch (e) {
      debugPrint('Error getting symptom by ID: $e');
      return null;
    }
  }

  // Get common body parts for dropdown
  List<String> getCommonBodyParts() {
    return [
      'Head',
      'Eyes',
      'Ears',
      'Nose',
      'Throat',
      'Chest',
      'Back',
      'Abdomen',
      'Arms',
      'Legs',
      'Joints',
      'Skin',
    ];
  }

  // Get common associated factors for dropdown
  List<String> getCommonAssociatedFactors() {
    return [
      'Stress',
      'Physical activity',
      'Food',
      'Medication',
      'Weather',
      'Sleep',
      'Allergies',
      'Screen time',
      'Travel',
      'Menstruation',
    ];
  }

  // Validate symptom description
  String? validateSymptomDescription(String? description) {
    if (description == null || description.isEmpty) {
      return 'Symptom description is required';
    }

    if (description.length < 10) {
      return 'Please provide a more detailed description';
    }

    return null;
  }

  // Validate symptom severity
  String? validateSymptomSeverity(int? severity) {
    if (severity == null) {
      return 'Severity rating is required';
    }

    if (severity < 1 || severity > 10) {
      return 'Severity must be between 1 and 10';
    }

    return null;
  }

  // Validate symptom duration
  String? validateSymptomDuration(int? duration) {
    if (duration == null) {
      return 'Duration is required';
    }

    if (duration < 1) {
      return 'Duration must be at least 1 day';
    }

    return null;
  }
}
