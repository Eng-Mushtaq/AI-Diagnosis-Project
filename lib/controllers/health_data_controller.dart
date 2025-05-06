import 'package:get/get.dart';
import '../models/health_data_model.dart';
import '../services/mock_data_service.dart';

// Health data controller for managing health data
class HealthDataController extends GetxController {
  final MockDataService _dataService = MockDataService();
  
  // Observable health data list
  final RxList<HealthDataModel> _healthDataList = <HealthDataModel>[].obs;
  List<HealthDataModel> get healthDataList => _healthDataList;
  
  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  
  // Get health data for user
  Future<void> getHealthData(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      final data = await _dataService.getHealthData(userId);
      _healthDataList.assignAll(data);
    } catch (e) {
      _errorMessage.value = 'Failed to get health data: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Add new health data
  Future<bool> addHealthData(HealthDataModel healthData) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      final newData = await _dataService.addHealthData(healthData);
      _healthDataList.add(newData);
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to add health data: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get latest health data
  HealthDataModel? getLatestHealthData() {
    if (_healthDataList.isEmpty) return null;
    
    // Sort by timestamp (newest first)
    final sortedList = List<HealthDataModel>.from(_healthDataList)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedList.first;
  }
  
  // Get health data by ID
  HealthDataModel? getHealthDataById(String id) {
    try {
      return _healthDataList.firstWhere((data) => data.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Check if health data is within normal range
  bool isTemperatureNormal(double? temperature) {
    if (temperature == null) return true;
    return temperature >= 36.1 && temperature <= 37.2;
  }
  
  bool isHeartRateNormal(int? heartRate) {
    if (heartRate == null) return true;
    return heartRate >= 60 && heartRate <= 100;
  }
  
  bool isBloodPressureNormal(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return true;
    return systolic < 130 && diastolic < 85;
  }
  
  bool isOxygenSaturationNormal(double? oxygenSaturation) {
    if (oxygenSaturation == null) return true;
    return oxygenSaturation >= 95;
  }
  
  // Get health status message
  String getHealthStatusMessage() {
    final latestData = getLatestHealthData();
    if (latestData == null) return 'No health data available';
    
    List<String> abnormalConditions = [];
    
    if (!isTemperatureNormal(latestData.temperature)) {
      abnormalConditions.add('Abnormal temperature');
    }
    
    if (!isHeartRateNormal(latestData.heartRate)) {
      abnormalConditions.add('Abnormal heart rate');
    }
    
    if (!isBloodPressureNormal(latestData.systolicBP, latestData.diastolicBP)) {
      abnormalConditions.add('Abnormal blood pressure');
    }
    
    if (!isOxygenSaturationNormal(latestData.oxygenSaturation)) {
      abnormalConditions.add('Low oxygen saturation');
    }
    
    if (abnormalConditions.isEmpty) {
      return 'Your vital signs are normal';
    } else {
      return 'Attention needed: ${abnormalConditions.join(', ')}';
    }
  }
}
