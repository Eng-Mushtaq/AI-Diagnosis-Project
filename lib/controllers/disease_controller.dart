import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/disease_model.dart';
import '../models/prediction_result_model.dart';
import '../models/symptom_model.dart';
import '../models/health_data_model.dart';
import '../services/mock_data_service.dart';
import '../services/ai_diagnosis_service.dart';
import '../services/supabase_service.dart';
import '../services/gemini_health_service.dart';

// Disease controller for managing disease predictions
class DiseaseController extends GetxController {
  final MockDataService _mockDataService = MockDataService();
  final AIDiagnosisService _aiService = Get.find<AIDiagnosisService>();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final GeminiHealthService _geminiService = Get.find<GeminiHealthService>();

  // Observable disease predictions list
  final RxList<DiseaseModel> _diseasePredictions = <DiseaseModel>[].obs;
  List<DiseaseModel> get diseasePredictions => _diseasePredictions;

  // Observable prediction results list
  final RxList<PredictionResultModel> _predictionResults =
      <PredictionResultModel>[].obs;
  List<PredictionResultModel> get predictionResults => _predictionResults;

  // Current prediction result
  final Rx<PredictionResultModel?> _currentPrediction =
      Rx<PredictionResultModel?>(null);
  PredictionResultModel? get currentPrediction => _currentPrediction.value;

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // Get disease predictions based on symptoms
  Future<void> getPredictions(
    String symptomDescription, {
    List<String>? bodyParts,
    int? severity,
    int? duration,
    List<String>? associatedFactors,
    HealthDataModel? healthData,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Use AI service for predictions
      final predictions = await _aiService.getPredictions(
        symptomDescription: symptomDescription,
        bodyParts: bodyParts,
        severity: severity,
        duration: duration,
        associatedFactors: associatedFactors,
        healthData: healthData,
      );

      // If AI service fails or returns empty, fall back to mock data
      if (predictions.isEmpty) {
        debugPrint(
          'AI service returned no predictions, falling back to mock data',
        );
        final mockPredictions = await _mockDataService.getPredictions(
          symptomDescription,
        );
        _diseasePredictions.assignAll(mockPredictions);
      } else {
        _diseasePredictions.assignAll(predictions);
      }
    } catch (e) {
      debugPrint('Error in AI predictions, falling back to mock data: $e');
      try {
        // Fallback to mock data service
        final predictions = await _mockDataService.getPredictions(
          symptomDescription,
        );
        _diseasePredictions.assignAll(predictions);
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get predictions: ${mockError.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Create prediction result using AI service
  Future<bool> createPrediction(
    String userId,
    String symptomDescription, {
    SymptomModel? symptom,
    HealthDataModel? healthData,
    bool useGemini = true, // Flag to use Gemini API
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      PredictionResultModel? prediction;

      // If we have a symptom model and useGemini is true, use the Gemini service
      if (symptom != null && useGemini) {
        try {
          prediction = await _geminiService.createHealthInfoResult(
            userId: userId,
            symptomDescription: symptomDescription,
            symptom: symptom,
            healthData: healthData,
          );

          if (prediction != null) {
            debugPrint('Successfully created prediction using Gemini API');
          }
        } catch (geminiError) {
          debugPrint('Error using Gemini API: $geminiError');
          // Continue to fallback options
        }
      }

      // If Gemini fails or is not used, try the AI service
      if (prediction == null && symptom != null) {
        try {
          prediction = await _aiService.createPrediction(
            userId: userId,
            symptomDescription: symptomDescription,
            symptom: symptom,
            healthData: healthData,
          );

          if (prediction != null) {
            debugPrint('Successfully created prediction using AI service');
          }
        } catch (aiError) {
          debugPrint('Error using AI service: $aiError');
          // Continue to fallback options
        }
      }

      // If both services fail or we don't have a symptom model, fall back to mock data
      if (prediction == null) {
        debugPrint(
          'AI services failed to create prediction, falling back to mock data',
        );
        prediction = await _mockDataService.createPrediction(
          userId,
          symptomDescription,
        );
      }

      // Save prediction to Supabase
      try {
        final savedPrediction = await _supabaseService.savePrediction(
          prediction,
        );
        _currentPrediction.value = savedPrediction;
        _predictionResults.add(savedPrediction);
        debugPrint('Successfully saved prediction to Supabase');
      } catch (saveError) {
        debugPrint('Error saving prediction to Supabase: $saveError');
        // Continue with the prediction even if saving to Supabase fails
        _currentPrediction.value = prediction;
        _predictionResults.add(prediction);
      }
      return true;
    } catch (e) {
      debugPrint('Error creating prediction, falling back to mock: $e');
      try {
        // Fallback to mock data service
        final prediction = await _mockDataService.createPrediction(
          userId,
          symptomDescription,
        );
        _currentPrediction.value = prediction;
        _predictionResults.add(prediction);
        return true;
      } catch (mockError) {
        _errorMessage.value =
            'Failed to create prediction: ${mockError.toString()}';
        return false;
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Get user prediction history
  Future<void> getUserPredictions(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Fetch predictions from Supabase
      final predictions = await _supabaseService.getUserPredictions(userId);
      _predictionResults.assignAll(predictions);
      debugPrint(
        'Successfully retrieved ${predictions.length} predictions from Supabase',
      );
    } catch (e) {
      debugPrint('Error getting predictions from Supabase: $e');
      _errorMessage.value = 'Failed to get prediction history from Supabase';

      // Fallback to mock data service if Supabase fails
      try {
        final mockPredictions = await _mockDataService.getUserPredictions(
          userId,
        );
        _predictionResults.assignAll(mockPredictions);
        _errorMessage.value = ''; // Clear error if mock data succeeds
        debugPrint(
          'Successfully retrieved ${mockPredictions.length} predictions from mock data',
        );
      } catch (mockError) {
        debugPrint('Error getting mock predictions: $mockError');
        _errorMessage.value =
            'Failed to get prediction history: ${mockError.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Get prediction by ID
  Future<PredictionResultModel?> getPredictionById(String id) async {
    try {
      // First check if it's in the local list
      try {
        return _predictionResults.firstWhere(
          (prediction) => prediction.id == id,
        );
      } catch (_) {
        // If not found in local list, fetch from Supabase
        debugPrint(
          'Prediction not found in local list, fetching from Supabase',
        );
        return await _supabaseService.getPredictionById(id);
      }
    } catch (e) {
      debugPrint('Error getting prediction by ID: $e');
      return null;
    }
  }

  // Get latest prediction
  Future<PredictionResultModel?> getLatestPrediction(String userId) async {
    if (_predictionResults.isEmpty) {
      // If local list is empty, try to fetch from Supabase
      try {
        await getUserPredictions(userId);
      } catch (e) {
        debugPrint('Error fetching predictions for latest: $e');
      }
    }

    if (_predictionResults.isEmpty) return null;

    // Sort by timestamp (newest first)
    final sortedList = List<PredictionResultModel>.from(_predictionResults)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return sortedList.first;
  }

  // Get color for probability
  String getProbabilityColor(double probability) {
    if (probability < 0.3) return 'green';
    if (probability < 0.7) return 'orange';
    return 'red';
  }

  // Get recommended specialists based on top diseases
  List<String> getRecommendedSpecialists() {
    if (_diseasePredictions.isEmpty) return [];

    final specialists =
        _diseasePredictions
            .where((disease) => disease.specialistType != null)
            .map((disease) => disease.specialistType!)
            .toSet()
            .toList();

    return specialists;
  }
}
