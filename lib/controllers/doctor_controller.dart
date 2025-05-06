import 'package:get/get.dart';
import '../models/doctor_model.dart';
import '../services/mock_data_service.dart';

// Doctor controller for managing doctor data
class DoctorController extends GetxController {
  final MockDataService _dataService = MockDataService();
  
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
      final doctorsList = await _dataService.getAllDoctors();
      _doctors.assignAll(doctorsList);
    } catch (e) {
      _errorMessage.value = 'Failed to get doctors: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get doctors by specialization
  Future<void> getDoctorsBySpecialization(String specialization) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      final doctorsList = await _dataService.getDoctorsBySpecialization(specialization);
      _doctors.assignAll(doctorsList);
    } catch (e) {
      _errorMessage.value = 'Failed to get doctors: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get doctor by ID
  Future<void> getDoctorById(String id) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      final doctor = await _dataService.getDoctorById(id);
      _selectedDoctor.value = doctor;
    } catch (e) {
      _errorMessage.value = 'Failed to get doctor: ${e.toString()}';
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
  
  // Get available specializations
  List<String> getAvailableSpecializations() {
    final specializations = _doctors.map((doctor) => doctor.specialization).toSet().toList();
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
    _doctors.sort((a, b) => ascending
        ? a.rating.compareTo(b.rating)
        : b.rating.compareTo(a.rating));
    _doctors.refresh();
  }
  
  // Sort doctors by experience
  void sortDoctorsByExperience(bool ascending) {
    _doctors.sort((a, b) => ascending
        ? a.experience.compareTo(b.experience)
        : b.experience.compareTo(a.experience));
    _doctors.refresh();
  }
  
  // Sort doctors by consultation fee
  void sortDoctorsByFee(bool ascending) {
    _doctors.sort((a, b) => ascending
        ? a.consultationFee.compareTo(b.consultationFee)
        : b.consultationFee.compareTo(a.consultationFee));
    _doctors.refresh();
  }
}
