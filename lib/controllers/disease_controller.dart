import 'package:get/get.dart';
import '../models/disease_model.dart';
import '../models/prediction_result_model.dart';
import '../services/mock_data_service.dart';

// Disease controller for managing disease predictions
class DiseaseController extends GetxController {
  final MockDataService _dataService = MockDataService();
  
  // Observable disease predictions list
  final RxList<DiseaseModel> _diseasePredictions = <DiseaseModel>[].obs;
  List<DiseaseModel> get diseasePredictions => _diseasePredictions;
  
  // Observable prediction results list
  final RxList<PredictionResultModel> _predictionResults = <PredictionResultModel>[].obs;
  List<PredictionResultModel> get predictionResults => _predictionResults;
  
  // Current prediction result
  final Rx<PredictionResultModel?> _currentPrediction = Rx<PredictionResultModel?>(null);
  PredictionResultModel? get currentPrediction => _currentPrediction.value;
  
  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  
  // Get disease predictions based on symptoms
  Future<void> getPredictions(String symptomDescription) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      final predictions = await _dataService.getPredictions(symptomDescription);
      _diseasePredictions.assignAll(predictions);
    } catch (e) {
      _errorMessage.value = 'Failed to get predictions: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Create prediction result
  Future<bool> createPrediction(String userId, String symptomDescription) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      final prediction = await _dataService.createPrediction(userId, symptomDescription);
      _currentPrediction.value = prediction;
      _predictionResults.add(prediction);
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to create prediction: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get user prediction history
  Future<void> getUserPredictions(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      final predictions = await _dataService.getUserPredictions(userId);
      _predictionResults.assignAll(predictions);
    } catch (e) {
      _errorMessage.value = 'Failed to get prediction history: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get prediction by ID
  PredictionResultModel? getPredictionById(String id) {
    try {
      return _predictionResults.firstWhere((prediction) => prediction.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get latest prediction
  PredictionResultModel? getLatestPrediction() {
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
    
    final specialists = _diseasePredictions
        .where((disease) => disease.specialistType != null)
        .map((disease) => disease.specialistType!)
        .toSet()
        .toList();
    
    return specialists;
  }
}
