import 'dart:async';
import 'dart:math';

import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/health_data_model.dart';
import '../models/symptom_model.dart';
import '../models/disease_model.dart';
import '../models/doctor_model.dart';
import '../models/appointment_model.dart';
import '../models/lab_result_model.dart';
import '../models/prediction_result_model.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';

// Mock data service to simulate API calls
class MockDataService {
  // Singleton instance
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Random generator for IDs
  final Random _random = Random();

  // Generate a random ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        _random.nextInt(10000).toString();
  }

  // Simulate API delay
  Future<T> _simulateApiCall<T>(T data) async {
    await Future.delayed(Duration(milliseconds: AppConstants.mockDataDelay));
    return data;
  }

  // Mock user data - Patient
  final UserModel _patientUser = UserModel(
    id: 'user123',
    name: 'Mohammed Al-Farsi',
    email: 'mohammed.alfarsi@example.com',
    phone: '+966 50 123 4567',
    profileImage: 'https://randomuser.me/api/portraits/men/32.jpg',
    userType: UserType.patient,
    age: 35,
    gender: 'Male',
    bloodGroup: 'O+',
    height: 175.0,
    weight: 78.5,
    allergies: ['Penicillin', 'Dust'],
    chronicConditions: ['Hypertension'],
    medications: ['Lisinopril 10mg'],
  );

  // Mock user data - Doctor
  final UserModel _doctorUser = UserModel(
    id: 'doctor123',
    name: 'Dr. Ahmed Al-Saud',
    email: 'ahmed.alsaud@example.com',
    phone: '+966 55 987 6543',
    profileImage: 'https://randomuser.me/api/portraits/men/42.jpg',
    userType: UserType.doctor,
    specialization: 'Neurologist',
    hospital: 'King Faisal Specialist Hospital',
    licenseNumber: 'MD12345',
    experience: 15,
    qualifications: [
      'MD, King Saud University',
      'Fellowship in Neurology, Johns Hopkins University',
      'Saudi Board of Neurology',
    ],
    isAvailableForChat: true,
    isAvailableForVideo: true,
  );

  // Mock user data - Admin
  final UserModel _adminUser = UserModel(
    id: 'admin123',
    name: 'Admin User',
    email: 'admin@aidiagnosist.com',
    phone: '+966 50 111 2222',
    profileImage: 'https://randomuser.me/api/portraits/men/1.jpg',
    userType: UserType.admin,
    adminRole: 'super_admin',
    permissions: [
      'manage_users',
      'manage_doctors',
      'manage_content',
      'view_analytics',
    ],
  );

  // Current user (default to patient for now)
  UserModel _currentUser = UserModel(
    id: 'user123',
    name: 'Mohammed Al-Farsi',
    email: 'mohammed.alfarsi@example.com',
    phone: '+966 50 123 4567',
    profileImage: 'https://randomuser.me/api/portraits/men/32.jpg',
    userType: UserType.patient,
    age: 35,
    gender: 'Male',
    bloodGroup: 'O+',
    height: 175.0,
    weight: 78.5,
    allergies: ['Penicillin', 'Dust'],
    chronicConditions: ['Hypertension'],
    medications: ['Lisinopril 10mg'],
  );

  // Get current user
  Future<UserModel> getCurrentUser() async {
    return _simulateApiCall(_currentUser);
  }

  // Login with email and password
  Future<UserModel?> login(String email, String password) async {
    // For demo purposes, use predefined users based on email
    if (email.contains('patient') || email == 'mohammed.alfarsi@example.com') {
      _currentUser = _patientUser;
      return _simulateApiCall(_patientUser);
    } else if (email.contains('doctor') ||
        email == 'ahmed.alsaud@example.com') {
      _currentUser = _doctorUser;
      return _simulateApiCall(_doctorUser);
    } else if (email.contains('admin') || email == 'admin@aidiagnosist.com') {
      _currentUser = _adminUser;
      return _simulateApiCall(_adminUser);
    }

    // Default to patient for demo
    return _simulateApiCall(_patientUser);
  }

  // Register new user
  Future<UserModel> register(
    String name,
    String email,
    String password,
    UserType userType, [
    Map<String, dynamic>? additionalData,
  ]) async {
    // Create a new user based on type
    late UserModel newUser;

    switch (userType) {
      case UserType.patient:
        newUser = UserModel(
          id: _generateId(),
          name: name,
          email: email,
          phone: '+966 5X XXX XXXX', // Placeholder
          userType: UserType.patient,
          age: 30, // Default
          gender: 'Not specified',
          bloodGroup: 'Unknown',
          height: 170.0, // Default
          weight: 70.0, // Default,
        );
        break;
      case UserType.doctor:
        // Use provided doctor data if available
        String specialization =
            additionalData?['specialization'] ?? 'General Practitioner';
        String hospital = additionalData?['hospital'] ?? 'Not specified';
        String licenseNumber =
            additionalData?['licenseNumber'] ?? 'Pending verification';
        int experience = additionalData?['experience'] ?? 0;
        bool isAvailableForChat =
            additionalData?['isAvailableForChat'] ?? false;
        bool isAvailableForVideo =
            additionalData?['isAvailableForVideo'] ?? false;

        newUser = UserModel(
          id: _generateId(),
          name: name,
          email: email,
          phone: '+966 5X XXX XXXX', // Placeholder
          userType: UserType.doctor,
          specialization: specialization,
          hospital: hospital,
          licenseNumber: licenseNumber,
          experience: experience,
          isAvailableForChat: isAvailableForChat,
          isAvailableForVideo: isAvailableForVideo,
        );
        break;
      case UserType.admin:
        newUser = UserModel(
          id: _generateId(),
          name: name,
          email: email,
          phone: '+966 5X XXX XXXX', // Placeholder
          userType: UserType.admin,
          adminRole: 'content_admin', // Default role
          permissions: [
            'view_users',
            'view_doctors',
          ], // Limited permissions by default
        );
        break;
    }

    // Set as current user
    _currentUser = newUser;
    return _simulateApiCall(newUser);
  }

  // Get all users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    return _simulateApiCall([_patientUser, _doctorUser, _adminUser]);
  }

  // Get user by ID
  Future<UserModel?> getUserById(String id) async {
    if (id == _patientUser.id) return _simulateApiCall(_patientUser);
    if (id == _doctorUser.id) return _simulateApiCall(_doctorUser);
    if (id == _adminUser.id) return _simulateApiCall(_adminUser);
    return _simulateApiCall(null);
  }

  // Update user
  Future<UserModel> updateUser(UserModel user) async {
    // In a real app, we would update the user in the database
    // For demo, just return the updated user
    _currentUser = user;
    return _simulateApiCall(user);
  }

  // Update user profile
  Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    // Update the current user with the new profile data
    _currentUser = updatedUser;

    // In a real app, we would update the user in the database
    // For demo, just return the updated user
    return _simulateApiCall(updatedUser);
  }

  // Mock health data
  final List<HealthDataModel> _healthData = [
    HealthDataModel(
      id: 'health001',
      userId: 'user123',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      temperature: 37.2,
      heartRate: 78,
      systolicBP: 128,
      diastolicBP: 85,
      respiratoryRate: 16,
      oxygenSaturation: 98.0,
      bloodGlucose: 95.0,
      notes: 'Feeling slightly tired',
    ),
    HealthDataModel(
      id: 'health002',
      userId: 'user123',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      temperature: 36.8,
      heartRate: 72,
      systolicBP: 120,
      diastolicBP: 80,
      respiratoryRate: 14,
      oxygenSaturation: 99.0,
      bloodGlucose: 90.0,
      notes: 'Normal day',
    ),
    HealthDataModel(
      id: 'health003',
      userId: 'user123',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      temperature: 38.1,
      heartRate: 88,
      systolicBP: 135,
      diastolicBP: 88,
      respiratoryRate: 18,
      oxygenSaturation: 97.0,
      bloodGlucose: 105.0,
      notes: 'Feeling unwell, slight fever',
    ),
  ];

  // Get health data for user
  Future<List<HealthDataModel>> getHealthData(String userId) async {
    final data = _healthData.where((data) => data.userId == userId).toList();
    return _simulateApiCall(data);
  }

  // Add health data
  Future<HealthDataModel> addHealthData(HealthDataModel healthData) async {
    final newHealthData = HealthDataModel(
      id: _generateId(),
      userId: healthData.userId,
      timestamp: healthData.timestamp,
      temperature: healthData.temperature,
      heartRate: healthData.heartRate,
      systolicBP: healthData.systolicBP,
      diastolicBP: healthData.diastolicBP,
      respiratoryRate: healthData.respiratoryRate,
      oxygenSaturation: healthData.oxygenSaturation,
      bloodGlucose: healthData.bloodGlucose,
      notes: healthData.notes,
    );
    _healthData.add(newHealthData);
    return _simulateApiCall(newHealthData);
  }

  // Mock symptoms data
  final List<SymptomModel> _symptoms = [
    SymptomModel(
      id: 'symptom001',
      userId: 'user123',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      description: 'Persistent headache with pressure behind eyes',
      severity: 7,
      duration: 3,
      bodyParts: ['Head', 'Eyes'],
      associatedFactors: ['Stress', 'Screen time'],
      images: ['https://example.com/headache1.jpg'],
    ),
    SymptomModel(
      id: 'symptom002',
      userId: 'user123',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      description: 'Dry cough with mild chest pain',
      severity: 5,
      duration: 4,
      bodyParts: ['Chest', 'Throat'],
      associatedFactors: ['Dust', 'Air conditioning'],
      images: [],
    ),
  ];

  // Get symptoms for user
  Future<List<SymptomModel>> getSymptoms(String userId) async {
    final data =
        _symptoms.where((symptom) => symptom.userId == userId).toList();
    return _simulateApiCall(data);
  }

  // Add symptom
  Future<SymptomModel> addSymptom(SymptomModel symptom) async {
    final newSymptom = SymptomModel(
      id: _generateId(),
      userId: symptom.userId,
      timestamp: symptom.timestamp,
      description: symptom.description,
      severity: symptom.severity,
      duration: symptom.duration,
      bodyParts: symptom.bodyParts,
      associatedFactors: symptom.associatedFactors,
      images: symptom.images,
    );
    _symptoms.add(newSymptom);
    return _simulateApiCall(newSymptom);
  }

  // Mock disease data
  final List<DiseaseModel> _diseases = [
    DiseaseModel(
      id: 'disease001',
      name: 'Migraine',
      description:
          'A neurological condition characterized by recurrent headaches that are moderate to severe.',
      probability: 0.75,
      symptoms: [
        'Throbbing headache',
        'Sensitivity to light',
        'Nausea',
        'Visual disturbances',
      ],
      treatments: [
        'Pain relievers',
        'Triptans',
        'Anti-nausea medications',
        'Preventive medications',
      ],
      specialistType: 'Neurologist',
      riskLevel: 'Medium',
      additionalInfo:
          'Migraines can be triggered by stress, certain foods, or hormonal changes.',
    ),
    DiseaseModel(
      id: 'disease002',
      name: 'Tension Headache',
      description:
          'The most common type of headache that causes mild to moderate pain.',
      probability: 0.60,
      symptoms: [
        'Dull, aching head pain',
        'Tightness around the forehead',
        'Tenderness in scalp, neck, and shoulder muscles',
      ],
      treatments: [
        'Over-the-counter pain relievers',
        'Stress management',
        'Relaxation techniques',
      ],
      specialistType: 'General Practitioner',
      riskLevel: 'Low',
      additionalInfo: 'Often caused by stress, poor posture, or eye strain.',
    ),
    DiseaseModel(
      id: 'disease003',
      name: 'Sinusitis',
      description: 'Inflammation of the sinuses, often due to infection.',
      probability: 0.45,
      symptoms: [
        'Facial pain or pressure',
        'Nasal congestion',
        'Headache',
        'Thick nasal discharge',
      ],
      treatments: [
        'Antibiotics (if bacterial)',
        'Nasal decongestants',
        'Nasal corticosteroids',
        'Saline nasal irrigation',
      ],
      specialistType: 'Otolaryngologist (ENT)',
      riskLevel: 'Low',
      additionalInfo: 'Can be acute (short-term) or chronic (long-lasting).',
    ),
    DiseaseModel(
      id: 'disease004',
      name: 'Bronchitis',
      description: 'Inflammation of the lining of the bronchial tubes.',
      probability: 0.65,
      symptoms: [
        'Persistent cough',
        'Chest discomfort',
        'Fatigue',
        'Mild fever and chills',
      ],
      treatments: [
        'Rest and fluids',
        'Over-the-counter pain relievers',
        'Cough medicine',
        'Humidifier',
      ],
      specialistType: 'Pulmonologist',
      riskLevel: 'Medium',
      additionalInfo:
          'Acute bronchitis is usually caused by viruses, while chronic bronchitis is often due to smoking.',
    ),
    DiseaseModel(
      id: 'disease005',
      name: 'Common Cold',
      description: 'A viral infection of the upper respiratory tract.',
      probability: 0.40,
      symptoms: [
        'Runny or stuffy nose',
        'Sore throat',
        'Cough',
        'Congestion',
        'Mild body aches',
      ],
      treatments: [
        'Rest',
        'Hydration',
        'Over-the-counter cold medications',
        'Throat lozenges',
      ],
      specialistType: 'General Practitioner',
      riskLevel: 'Low',
      additionalInfo: 'Usually resolves within 7-10 days.',
    ),
  ];

  // Get disease predictions based on symptoms
  Future<List<DiseaseModel>> getPredictions(String symptomDescription) async {
    // Simple mock logic to return diseases based on keywords in the symptom description
    final List<DiseaseModel> predictions = [];

    final description = symptomDescription.toLowerCase();

    if (description.contains('headache')) {
      predictions.add(_diseases.firstWhere((d) => d.id == 'disease001'));
      predictions.add(_diseases.firstWhere((d) => d.id == 'disease002'));
      if (description.contains('nasal') || description.contains('congestion')) {
        predictions.add(_diseases.firstWhere((d) => d.id == 'disease003'));
      }
    }

    if (description.contains('cough')) {
      predictions.add(_diseases.firstWhere((d) => d.id == 'disease004'));
      predictions.add(_diseases.firstWhere((d) => d.id == 'disease005'));
    }

    if (predictions.isEmpty) {
      // Return random diseases if no matches
      predictions.addAll(_diseases.take(3));
    }

    // Sort by probability
    predictions.sort((a, b) => b.probability.compareTo(a.probability));

    return _simulateApiCall(predictions);
  }

  // Mock doctor data
  final List<DoctorModel> _doctors = [
    DoctorModel(
      id: 'doctor001',
      name: 'Dr. Ahmed Al-Saud',
      specialization: 'Neurologist',
      hospital: 'King Faisal Specialist Hospital',
      city: 'Riyadh',
      profileImage: 'https://randomuser.me/api/portraits/men/42.jpg',
      rating: 4.8,
      experience: 15,
      about:
          'Dr. Ahmed is a board-certified neurologist specializing in headache disorders and stroke management.',
      languages: ['Arabic', 'English'],
      qualifications: [
        'MD, King Saud University',
        'Fellowship in Neurology, Johns Hopkins University',
        'Saudi Board of Neurology',
      ],
      availableDays: ['Monday', 'Wednesday', 'Thursday'],
      availableTimeSlots: {
        'Monday': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM', '03:00 PM'],
        'Wednesday': ['10:00 AM', '11:00 AM', '12:00 PM', '01:00 PM'],
        'Thursday': [
          '09:00 AM',
          '10:00 AM',
          '02:00 PM',
          '03:00 PM',
          '04:00 PM',
        ],
      },
      consultationFee: 500.0,
      isAvailableForVideo: true,
      isAvailableForChat: true,
    ),
    DoctorModel(
      id: 'doctor002',
      name: 'Dr. Fatima Al-Qahtani',
      specialization: 'Pulmonologist',
      hospital: 'Saudi German Hospital',
      city: 'Jeddah',
      profileImage: 'https://randomuser.me/api/portraits/women/36.jpg',
      rating: 4.7,
      experience: 12,
      about:
          'Dr. Fatima is a pulmonary specialist with expertise in respiratory infections and chronic lung diseases.',
      languages: ['Arabic', 'English', 'French'],
      qualifications: [
        'MBBS, King Abdulaziz University',
        'Saudi Board of Internal Medicine',
        'Fellowship in Pulmonology, University of Toronto',
      ],
      availableDays: ['Sunday', 'Tuesday', 'Thursday'],
      availableTimeSlots: {
        'Sunday': ['10:00 AM', '11:00 AM', '12:00 PM', '04:00 PM', '05:00 PM'],
        'Tuesday': ['09:00 AM', '10:00 AM', '11:00 AM', '02:00 PM'],
        'Thursday': ['02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM'],
      },
      consultationFee: 450.0,
      isAvailableForVideo: true,
      isAvailableForChat: false,
    ),
    DoctorModel(
      id: 'doctor003',
      name: 'Dr. Khalid Al-Otaibi',
      specialization: 'General Practitioner',
      hospital: 'Dallah Hospital',
      city: 'Riyadh',
      profileImage: 'https://randomuser.me/api/portraits/men/55.jpg',
      rating: 4.5,
      experience: 8,
      about:
          'Dr. Khalid is a family medicine physician providing comprehensive primary care for patients of all ages.',
      languages: ['Arabic', 'English'],
      qualifications: [
        'MBBS, Imam Muhammad Ibn Saud Islamic University',
        'Saudi Board of Family Medicine',
      ],
      availableDays: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday'],
      availableTimeSlots: {
        'Sunday': ['09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM'],
        'Monday': ['09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM'],
        'Tuesday': ['02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM'],
        'Wednesday': ['02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM'],
        'Thursday': ['09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM'],
      },
      consultationFee: 300.0,
      isAvailableForVideo: true,
      isAvailableForChat: true,
    ),
    DoctorModel(
      id: 'doctor004',
      name: 'Dr. Noura Al-Zahrani',
      specialization: 'ENT Specialist',
      hospital: 'Dr. Sulaiman Al Habib Medical Group',
      city: 'Riyadh',
      profileImage: 'https://randomuser.me/api/portraits/women/65.jpg',
      rating: 4.6,
      experience: 10,
      about:
          'Dr. Noura specializes in the diagnosis and treatment of ear, nose, and throat disorders.',
      languages: ['Arabic', 'English'],
      qualifications: [
        'MD, King Saud University',
        'Saudi Board of Otolaryngology',
        'Fellowship in Rhinology, University of Pennsylvania',
      ],
      availableDays: ['Monday', 'Tuesday', 'Wednesday'],
      availableTimeSlots: {
        'Monday': ['10:00 AM', '11:00 AM', '12:00 PM', '01:00 PM'],
        'Tuesday': ['02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM'],
        'Wednesday': ['10:00 AM', '11:00 AM', '03:00 PM', '04:00 PM'],
      },
      consultationFee: 400.0,
      isAvailableForVideo: true,
      isAvailableForChat: true,
    ),
    DoctorModel(
      id: 'doctor005',
      name: 'Dr. Saad Al-Ghamdi',
      specialization: 'Cardiologist',
      hospital: 'King Fahad Medical City',
      city: 'Riyadh',
      profileImage: 'https://randomuser.me/api/portraits/men/67.jpg',
      rating: 4.9,
      experience: 18,
      about:
          'Dr. Saad is a highly experienced cardiologist specializing in interventional cardiology and heart failure management.',
      languages: ['Arabic', 'English'],
      qualifications: [
        'MD, King Saud University',
        'Saudi Board of Cardiology',
        'Fellowship in Interventional Cardiology, Cleveland Clinic',
      ],
      availableDays: ['Sunday', 'Tuesday', 'Thursday'],
      availableTimeSlots: {
        'Sunday': ['09:00 AM', '10:00 AM', '11:00 AM'],
        'Tuesday': ['02:00 PM', '03:00 PM', '04:00 PM'],
        'Thursday': ['09:00 AM', '10:00 AM', '02:00 PM'],
      },
      consultationFee: 600.0,
      isAvailableForVideo: false,
      isAvailableForChat: true,
    ),
  ];

  // Get all doctors
  Future<List<DoctorModel>> getAllDoctors() async {
    // Add verification status to mock doctors (all approved for simplicity)
    final approvedDoctors =
        _doctors.map((doctor) {
          return doctor.copyWith(verificationStatus: 'approved');
        }).toList();

    return _simulateApiCall(approvedDoctors);
  }

  // Get doctors by specialization
  Future<List<DoctorModel>> getDoctorsBySpecialization(
    String specialization,
  ) async {
    // Filter by specialization and set all as approved
    final filteredDoctors =
        _doctors
            .where((doctor) => doctor.specialization == specialization)
            .map((doctor) => doctor.copyWith(verificationStatus: 'approved'))
            .toList();

    return _simulateApiCall(filteredDoctors);
  }

  // Get doctor by ID
  Future<DoctorModel?> getDoctorById(String id) async {
    try {
      final doctor = _doctors.firstWhere((doctor) => doctor.id == id);
      // Set verification status to approved
      final approvedDoctor = doctor.copyWith(verificationStatus: 'approved');
      return _simulateApiCall(approvedDoctor);
    } catch (e) {
      return _simulateApiCall(null);
    }
  }

  // Mock appointment data
  final List<AppointmentModel> _appointments = [
    AppointmentModel(
      id: 'appointment001',
      userId: 'user123',
      doctorId: 'doctor001',
      appointmentDate: DateTime.now().add(const Duration(days: 3)),
      timeSlot: '10:00 AM',
      type: 'video',
      status: 'scheduled',
      reason: 'Recurring headaches',
      attachments: [],
      notes: 'First consultation for headaches',
      fee: 500.0,
      prescriptionUrl: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppointmentModel(
      id: 'appointment002',
      userId: 'user123',
      doctorId: 'doctor003',
      appointmentDate: DateTime.now().subtract(const Duration(days: 5)),
      timeSlot: '02:00 PM',
      type: 'in-person',
      status: 'completed',
      reason: 'Annual check-up',
      attachments: [],
      notes: 'Regular health check-up',
      fee: 300.0,
      prescriptionUrl: 'https://example.com/prescriptions/rx12345.pdf',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  // Get appointments for user
  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    final userAppointments =
        _appointments
            .where((appointment) => appointment.userId == userId)
            .toList();
    return _simulateApiCall(userAppointments);
  }

  // Get appointments for doctor
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    final doctorAppointments =
        _appointments
            .where((appointment) => appointment.doctorId == doctorId)
            .toList();

    // Add patient names to appointments
    for (final appointment in doctorAppointments) {
      try {
        final patient = _patientUser;
        if (patient.id == appointment.userId) {
          appointment.patientName = patient.name;
        } else {
          appointment.patientName = 'Patient';
        }
      } catch (e) {
        appointment.patientName = 'Unknown Patient';
      }
    }

    return _simulateApiCall(doctorAppointments);
  }

  // Book appointment
  Future<AppointmentModel> bookAppointment(AppointmentModel appointment) async {
    final newAppointment = AppointmentModel(
      id: _generateId(),
      userId: appointment.userId,
      doctorId: appointment.doctorId,
      appointmentDate: appointment.appointmentDate,
      timeSlot: appointment.timeSlot,
      type: appointment.type,
      status: 'scheduled',
      reason: appointment.reason,
      attachments: appointment.attachments,
      notes: appointment.notes,
      fee: appointment.fee,
      prescriptionUrl: null,
      createdAt: DateTime.now(),
    );
    _appointments.add(newAppointment);
    return _simulateApiCall(newAppointment);
  }

  // Mock lab results data
  final List<LabResultModel> _labResults = [
    LabResultModel(
      id: 'lab001',
      userId: 'user123',
      testName: 'Complete Blood Count (CBC)',
      testDate: DateTime.now().subtract(const Duration(days: 15)),
      labName: 'Al-Borg Medical Laboratories',
      resultUrl: 'https://example.com/lab_results/cbc12345.pdf',
      doctorId: 'doctor003',
      status: 'reviewed',
      resultValues: {
        'WBC': '7.5 x10^9/L',
        'RBC': '5.2 x10^12/L',
        'Hemoglobin': '14.2 g/dL',
        'Hematocrit': '42%',
        'Platelets': '250 x10^9/L',
      },
      notes: 'All values within normal range',
      uploadedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    LabResultModel(
      id: 'lab002',
      userId: 'user123',
      testName: 'Lipid Profile',
      testDate: DateTime.now().subtract(const Duration(days: 30)),
      labName: 'Saudi German Hospital Lab',
      resultUrl: 'https://example.com/lab_results/lipid12345.pdf',
      doctorId: 'doctor003',
      status: 'reviewed',
      resultValues: {
        'Total Cholesterol': '195 mg/dL',
        'HDL': '45 mg/dL',
        'LDL': '120 mg/dL',
        'Triglycerides': '150 mg/dL',
      },
      notes: 'LDL slightly elevated, recommend dietary changes',
      uploadedAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
  ];

  // Get lab results for user
  Future<List<LabResultModel>> getUserLabResults(String userId) async {
    final userLabResults =
        _labResults.where((result) => result.userId == userId).toList();
    return _simulateApiCall(userLabResults);
  }

  // Upload lab result
  Future<LabResultModel> uploadLabResult(LabResultModel labResult) async {
    final newLabResult = LabResultModel(
      id: _generateId(),
      userId: labResult.userId,
      testName: labResult.testName,
      testDate: labResult.testDate,
      labName: labResult.labName,
      resultUrl: labResult.resultUrl,
      doctorId: labResult.doctorId,
      status: 'pending',
      resultValues: labResult.resultValues,
      notes: labResult.notes,
      uploadedAt: DateTime.now(),
    );
    _labResults.add(newLabResult);
    return _simulateApiCall(newLabResult);
  }

  // Mock prediction results
  final List<PredictionResultModel> _predictionResults = [
    PredictionResultModel(
      id: 'prediction001',
      userId: 'user123',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      diseases: [
        DiseaseWithProbability(
          diseaseId: 'disease001',
          name: 'Migraine',
          probability: 0.75,
          description:
              'A neurological condition characterized by recurrent headaches.',
          symptoms: ['Throbbing headache', 'Sensitivity to light', 'Nausea'],
          specialistType: 'Neurologist',
        ),
        DiseaseWithProbability(
          diseaseId: 'disease002',
          name: 'Tension Headache',
          probability: 0.60,
          description:
              'The most common type of headache that causes mild to moderate pain.',
          symptoms: ['Dull, aching head pain', 'Tightness around the forehead'],
          specialistType: 'General Practitioner',
        ),
        DiseaseWithProbability(
          diseaseId: 'disease003',
          name: 'Sinusitis',
          probability: 0.45,
          description: 'Inflammation of the sinuses, often due to infection.',
          symptoms: ['Facial pain or pressure', 'Nasal congestion', 'Headache'],
          specialistType: 'Otolaryngologist (ENT)',
        ),
      ],
      symptomId: 'symptom001',
      recommendedAction: 'Consult a neurologist',
      urgencyLevel: 'Medium',
    ),
    PredictionResultModel(
      id: 'prediction002',
      userId: 'user123',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      diseases: [
        DiseaseWithProbability(
          diseaseId: 'disease004',
          name: 'Bronchitis',
          probability: 0.65,
          description: 'Inflammation of the lining of the bronchial tubes.',
          symptoms: ['Persistent cough', 'Chest discomfort', 'Fatigue'],
          specialistType: 'Pulmonologist',
        ),
        DiseaseWithProbability(
          diseaseId: 'disease005',
          name: 'Common Cold',
          probability: 0.40,
          description: 'A viral infection of the upper respiratory tract.',
          symptoms: ['Runny or stuffy nose', 'Sore throat', 'Cough'],
          specialistType: 'General Practitioner',
        ),
      ],
      symptomId: 'symptom002',
      recommendedAction: 'Rest and monitor symptoms',
      urgencyLevel: 'Low',
    ),
  ];

  // Get prediction results for user
  Future<List<PredictionResultModel>> getUserPredictions(String userId) async {
    final userPredictions =
        _predictionResults
            .where((prediction) => prediction.userId == userId)
            .toList();
    return _simulateApiCall(userPredictions);
  }

  // Create prediction result
  Future<PredictionResultModel> createPrediction(
    String userId,
    String symptomDescription,
  ) async {
    // Get disease predictions based on symptom description
    final diseases = await getPredictions(symptomDescription);

    // Convert to DiseaseWithProbability list
    final diseasesWithProbability =
        diseases.map((disease) {
          return DiseaseWithProbability(
            diseaseId: disease.id,
            name: disease.name,
            probability: disease.probability,
            description: disease.description,
            symptoms: disease.symptoms,
            specialistType: disease.specialistType,
          );
        }).toList();

    // Sort by probability
    diseasesWithProbability.sort(
      (a, b) => b.probability.compareTo(a.probability),
    );

    // Determine urgency level based on highest probability
    String urgencyLevel = 'Low';
    if (diseasesWithProbability.first.probability > 0.7) {
      urgencyLevel = 'High';
    } else if (diseasesWithProbability.first.probability > 0.4) {
      urgencyLevel = 'Medium';
    }

    // Determine recommended action
    String recommendedAction = 'Monitor symptoms';
    if (urgencyLevel == 'High') {
      recommendedAction =
          'Consult a ${diseasesWithProbability.first.specialistType} immediately';
    } else if (urgencyLevel == 'Medium') {
      recommendedAction =
          'Consult a ${diseasesWithProbability.first.specialistType}';
    }

    // Create new prediction result
    final newPrediction = PredictionResultModel(
      id: _generateId(),
      userId: userId,
      timestamp: DateTime.now(),
      diseases: diseasesWithProbability,
      healthDataId: null,
      symptomId: null,
      recommendedAction: recommendedAction,
      urgencyLevel: urgencyLevel,
    );

    _predictionResults.add(newPrediction);
    return _simulateApiCall(newPrediction);
  }

  // Mock chat data
  final List<ChatModel> _chats = [
    ChatModel(
      id: 'chat001',
      participantIds: ['doctor123', 'user123'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastMessageContent:
          'Thank you for the information, I will review your symptoms.',
      lastMessageSenderId: 'doctor123',
      hasUnreadMessages: true,
      unreadCount: 1,
    ),
    ChatModel(
      id: 'chat002',
      participantIds: ['doctor123', 'user456'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
      lastMessageContent: 'Your lab results look normal. No need to worry.',
      lastMessageSenderId: 'doctor123',
      hasUnreadMessages: false,
      unreadCount: 0,
    ),
    ChatModel(
      id: 'chat003',
      participantIds: ['doctor456', 'user123'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      lastMessageAt: DateTime.now().subtract(const Duration(days: 3)),
      lastMessageContent: 'Please take the prescribed medication for 7 days.',
      lastMessageSenderId: 'doctor456',
      hasUnreadMessages: false,
      unreadCount: 0,
    ),
  ];

  // Mock message data
  final List<MessageModel> _messages = [
    // Chat 001 messages
    MessageModel(
      id: 'msg001',
      chatId: 'chat001',
      senderId: 'user123',
      receiverId: 'doctor123',
      content:
          'Hello doctor, I have been experiencing severe headaches for the past week.',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      attachmentUrl: null,
      attachmentType: null,
    ),
    MessageModel(
      id: 'msg002',
      chatId: 'chat001',
      senderId: 'doctor123',
      receiverId: 'user123',
      content: 'I understand. Can you describe the pain and its location?',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
      attachmentUrl: null,
      attachmentType: null,
    ),
    MessageModel(
      id: 'msg003',
      chatId: 'chat001',
      senderId: 'user123',
      receiverId: 'doctor123',
      content:
          'It\'s a throbbing pain on the right side of my head, and it gets worse with light and sound.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
      attachmentUrl: null,
      attachmentType: null,
    ),
    MessageModel(
      id: 'msg004',
      chatId: 'chat001',
      senderId: 'doctor123',
      receiverId: 'user123',
      content: 'Thank you for the information, I will review your symptoms.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      attachmentUrl: null,
      attachmentType: null,
    ),

    // Chat 002 messages
    MessageModel(
      id: 'msg005',
      chatId: 'chat002',
      senderId: 'user456',
      receiverId: 'doctor123',
      content: 'Doctor, I received my lab results. Should I be concerned?',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
      attachmentUrl: 'https://example.com/lab_results/user456_labs.pdf',
      attachmentType: 'document',
    ),
    MessageModel(
      id: 'msg006',
      chatId: 'chat002',
      senderId: 'doctor123',
      receiverId: 'user456',
      content: 'Your lab results look normal. No need to worry.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      attachmentUrl: null,
      attachmentType: null,
    ),

    // Chat 003 messages
    MessageModel(
      id: 'msg007',
      chatId: 'chat003',
      senderId: 'user123',
      receiverId: 'doctor456',
      content: 'I have a sore throat and fever. What should I do?',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
      attachmentUrl: null,
      attachmentType: null,
    ),
    MessageModel(
      id: 'msg008',
      chatId: 'chat003',
      senderId: 'doctor456',
      receiverId: 'user123',
      content:
          'It sounds like you might have a viral infection. I\'ll prescribe some medication.',
      timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
      isRead: true,
      attachmentUrl: null,
      attachmentType: null,
    ),
    MessageModel(
      id: 'msg009',
      chatId: 'chat003',
      senderId: 'doctor456',
      receiverId: 'user123',
      content: 'Please take the prescribed medication for 7 days.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      attachmentUrl: 'https://example.com/prescriptions/user123_rx.pdf',
      attachmentType: 'document',
    ),
  ];

  // Get chats for user
  Future<List<ChatModel>> getUserChats(String userId) async {
    final userChats =
        _chats.where((chat) => chat.participantIds.contains(userId)).toList();

    // Sort by last message timestamp (newest first)
    userChats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    return _simulateApiCall(userChats);
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final chat = _chats.firstWhere((chat) => chat.id == chatId);
      return _simulateApiCall(chat);
    } catch (e) {
      return _simulateApiCall(null);
    }
  }

  // Get messages for chat
  Future<List<MessageModel>> getChatMessages(String chatId) async {
    final chatMessages =
        _messages.where((message) => message.chatId == chatId).toList();

    // Sort by timestamp (oldest first)
    chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return _simulateApiCall(chatMessages);
  }

  // Send message
  Future<MessageModel> sendMessage(MessageModel message) async {
    final newMessage = MessageModel(
      id: _generateId(),
      chatId: message.chatId,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      timestamp: DateTime.now(),
      isRead: false,
      attachmentUrl: message.attachmentUrl,
      attachmentType: message.attachmentType,
    );

    _messages.add(newMessage);

    // Update chat with new message
    final chatIndex = _chats.indexWhere((chat) => chat.id == message.chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessageAt: newMessage.timestamp,
        lastMessageContent: newMessage.content,
        lastMessageSenderId: newMessage.senderId,
      );
    }

    return _simulateApiCall(newMessage);
  }

  // Create chat
  Future<ChatModel> createChat(String currentUserId, String otherUserId) async {
    // Check if chat already exists
    for (final chat in _chats) {
      if (chat.participantIds.contains(currentUserId) &&
          chat.participantIds.contains(otherUserId)) {
        return _simulateApiCall(chat);
      }
    }

    // Create new chat
    final newChat = ChatModel(
      id: _generateId(),
      participantIds: [currentUserId, otherUserId],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      lastMessageContent: 'Chat started',
      lastMessageSenderId: currentUserId,
      hasUnreadMessages: false,
      unreadCount: 0,
    );

    _chats.add(newChat);
    return _simulateApiCall(newChat);
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].chatId == chatId && !_messages[i].isRead) {
        _messages[i] = _messages[i].copyWith(isRead: true);
      }
    }

    // Update chat unread status
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        hasUnreadMessages: false,
        unreadCount: 0,
      );
    }

    return _simulateApiCall(null);
  }
}
