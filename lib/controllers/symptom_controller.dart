import 'package:get/get.dart';
import '../models/symptom_model.dart';
import '../services/mock_data_service.dart';

// Symptom controller for managing symptom data
class SymptomController extends GetxController {
  final MockDataService _dataService = MockDataService();
  
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
      final symptoms = await _dataService.getSymptoms(userId);
      _symptomList.assignAll(symptoms);
    } catch (e) {
      _errorMessage.value = 'Failed to get symptoms: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Add new symptom
  Future<bool> addSymptom(SymptomModel symptom) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      final newSymptom = await _dataService.addSymptom(symptom);
      _symptomList.add(newSymptom);
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to add symptom: ${e.toString()}';
      return false;
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
  SymptomModel? getSymptomById(String id) {
    try {
      return _symptomList.firstWhere((symptom) => symptom.id == id);
    } catch (e) {
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
