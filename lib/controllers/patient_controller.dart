import 'package:get/get.dart';
import '../models/user_model.dart';
import '../models/appointment_model.dart';
import '../models/health_data_model.dart';
import '../models/symptom_model.dart';
import '../models/prediction_result_model.dart';
import '../services/mock_data_service.dart';
import '../services/supabase_service.dart';

/// Controller for managing patient data for doctors
class PatientController extends GetxController {
  final MockDataService _dataService = MockDataService();
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // Observable patients list
  final RxList<UserModel> _patients = <UserModel>[].obs;
  List<UserModel> get patients => _patients;

  // Selected patient
  final Rx<UserModel?> _selectedPatient = Rx<UserModel?>(null);
  UserModel? get selectedPatient => _selectedPatient.value;

  // Patient appointments
  final RxList<AppointmentModel> _patientAppointments =
      <AppointmentModel>[].obs;
  List<AppointmentModel> get patientAppointments => _patientAppointments;

  // Patient health data
  final RxList<HealthDataModel> _patientHealthData = <HealthDataModel>[].obs;
  List<HealthDataModel> get patientHealthData => _patientHealthData;

  // Patient symptoms
  final RxList<SymptomModel> _patientSymptoms = <SymptomModel>[].obs;
  List<SymptomModel> get patientSymptoms => _patientSymptoms;

  // Patient prediction results
  final RxList<PredictionResultModel> _patientPredictions =
      <PredictionResultModel>[].obs;
  List<PredictionResultModel> get patientPredictions => _patientPredictions;

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // Get doctor's patients
  Future<void> getDoctorPatients(String doctorId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Try to get patients from Supabase
      try {
        final patients = await _supabaseService.getDoctorPatients(doctorId);
        _patients.assignAll(patients);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value =
            'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }

      // Fallback to mock data
      final allUsers = await _dataService.getAllUsers();
      final patientUsers =
          allUsers.where((user) => user.userType == UserType.patient).toList();
      _patients.assignAll(patientUsers);
    } catch (e) {
      _errorMessage.value = 'Failed to get patients: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Get patient by ID
  Future<void> getPatientById(String id) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Try to get patient from Supabase
      try {
        final patient = await _supabaseService.getUserProfile(id);
        if (patient != null && patient.userType == UserType.patient) {
          _selectedPatient.value = patient;
          return;
        } else if (patient != null) {
          _errorMessage.value = 'Selected user is not a patient';
          return;
        }
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value =
            'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }

      // Fallback to mock data
      final patient = await _dataService.getUserById(id);
      if (patient != null && patient.userType == UserType.patient) {
        _selectedPatient.value = patient;
      } else {
        _errorMessage.value = 'Patient not found';
      }
    } catch (e) {
      _errorMessage.value = 'Failed to get patient: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Set selected patient
  void setSelectedPatient(UserModel patient) {
    if (patient.userType == UserType.patient) {
      _selectedPatient.value = patient;
    } else {
      _errorMessage.value = 'Selected user is not a patient';
    }
  }

  // Clear selected patient
  void clearSelectedPatient() {
    _selectedPatient.value = null;
    _patientAppointments.clear();
    _patientHealthData.clear();
    _patientSymptoms.clear();
    _patientPredictions.clear();
  }

  // Get patient appointments
  Future<void> getPatientAppointments(String patientId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Try to get appointments from Supabase
      try {
        final appointments = await _supabaseService.getUserAppointments(
          patientId,
        );
        _patientAppointments.assignAll(appointments);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value =
            'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }

      // Fallback to mock data
      final appointments = await _dataService.getUserAppointments(patientId);
      _patientAppointments.assignAll(appointments);
    } catch (e) {
      _errorMessage.value =
          'Failed to get patient appointments: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Get patient health data
  Future<void> getPatientHealthData(String patientId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Try to get health data from Supabase
      try {
        final healthData = await _supabaseService.getHealthData(patientId);
        _patientHealthData.assignAll(healthData);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value =
            'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }

      // Fallback to mock data
      final healthData = await _dataService.getHealthData(patientId);
      _patientHealthData.assignAll(healthData);
    } catch (e) {
      _errorMessage.value =
          'Failed to get patient health data: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Get patient symptoms
  Future<void> getPatientSymptoms(String patientId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Try to get symptoms from Supabase
      try {
        final symptoms = await _supabaseService.getSymptoms(patientId);
        _patientSymptoms.assignAll(symptoms);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value =
            'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }

      // Fallback to mock data
      final symptoms = await _dataService.getSymptoms(patientId);
      _patientSymptoms.assignAll(symptoms);
    } catch (e) {
      _errorMessage.value = 'Failed to get patient symptoms: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Get patient prediction results
  Future<void> getPatientPredictions(String patientId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Try to get predictions from Supabase
      try {
        final predictions = await _supabaseService.getUserPredictions(
          patientId,
        );
        _patientPredictions.assignAll(predictions);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value =
            'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }

      // Fallback to mock data
      final predictions = await _dataService.getUserPredictions(patientId);
      _patientPredictions.assignAll(predictions);
    } catch (e) {
      _errorMessage.value =
          'Failed to get patient predictions: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Load all patient data
  Future<void> loadAllPatientData(String patientId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await getPatientById(patientId);
      await getPatientAppointments(patientId);
      await getPatientHealthData(patientId);
      await getPatientSymptoms(patientId);
      await getPatientPredictions(patientId);
    } catch (e) {
      _errorMessage.value = 'Failed to load patient data: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  // Search patients by name
  List<UserModel> searchPatientsByName(String query) {
    if (query.isEmpty) return patients;

    return patients
        .where(
          (patient) => patient.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
