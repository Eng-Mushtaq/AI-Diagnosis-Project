import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import '../models/user_model.dart';
import '../models/health_data_model.dart';
import '../models/symptom_model.dart';
import '../models/prediction_result_model.dart';
import '../models/appointment_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/doctor_model.dart';

/// Service class for handling Supabase authentication and database operations
class SupabaseService {
  // Singleton instance
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Supabase client
  late final SupabaseClient _supabaseClient;
  SupabaseClient get supabaseClient => _supabaseClient;

  // Supabase storage bucket name
  final String _storageBucketName = 'img-bucket';
  String get storageBucketName => _storageBucketName;

  // Initialize Supabase
  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://yezjjsxqcarrgvutidwc.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inllempqc3hxY2Fycmd2dXRpZHdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY1MzUzMTgsImV4cCI6MjA2MjExMTMxOH0._CQTVkyhb8eeS9das-xI3Zx3cJy_a48uMWdN7KGB29M',
    );
    _supabaseClient = Supabase.instance.client;
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create user in Supabase Auth
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user profile in the database
        await createUserProfile(
          userId: response.user!.id,
          email: email,
          name: name,
          userType: userType,
          additionalData: additionalData,
        );
      }

      return response;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo:
            kIsWeb ? null : 'io.supabase.aidiagnosist://reset-callback/',
      );
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }

  // Get current user
  User? getCurrentAuthUser() {
    return _supabaseClient.auth.currentUser;
  }

  // Create user profile in the database using the new data model
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String name,
    required UserType userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('Creating user profile with new data model...');

      // Prepare the user data
      final userData = {
        'id': userId,
        'email': email,
        'name': name,
        'user_type': userType.toString().split('.').last,
        'phone': additionalData?['phone'] ?? '',
        'profile_image': additionalData?['profileImage'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert into users table
      await _supabaseClient.from('users').insert(userData);
      debugPrint(
        'Created user record with ID: $userId and type: ${userType.toString().split('.').last}',
      );

      // Insert into specific profile table based on userType
      switch (userType) {
        case UserType.patient:
          // Insert into patients_profile table
          await _supabaseClient.from('patients_profile').insert({
            'id': userId,
            'age': additionalData?['age'],
            'gender': additionalData?['gender'],
            'blood_group': additionalData?['bloodGroup'],
            'height': additionalData?['height'],
            'weight': additionalData?['weight'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint('Created patient profile with ID: $userId');
          break;
        case UserType.doctor:
          // Insert into doctors_profile table
          await _supabaseClient.from('doctors_profile').insert({
            'id': userId,
            'specialization':
                additionalData?['specialization'] ?? 'General Practitioner',
            'hospital': additionalData?['hospital'] ?? '',
            'license_number': additionalData?['licenseNumber'] ?? '',
            'experience': additionalData?['experience'] ?? 0,
            'is_available_for_chat':
                additionalData?['isAvailableForChat'] ?? false,
            'is_available_for_video':
                additionalData?['isAvailableForVideo'] ?? false,
            'verification_status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint('Created doctor profile with ID: $userId');
          break;
        case UserType.admin:
          // Insert into admins_profile table
          await _supabaseClient.from('admins_profile').insert({
            'id': userId,
            'admin_role': additionalData?['adminRole'] ?? 'content_admin',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint('Created admin profile with ID: $userId');
          break;
      }

      // Verify the user record exists and has the correct user_type
      final userCheck =
          await _supabaseClient
              .from('users')
              .select('id, user_type')
              .eq('id', userId)
              .single();

      debugPrint(
        'User verification: ID=${userCheck['id']}, Type=${userCheck['user_type']}',
      );
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get user profile from the database using the new data model
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      debugPrint('Getting user profile with new data model...');

      // Get user from users table
      final userData =
          await _supabaseClient
              .from('users')
              .select()
              .eq('id', userId)
              .single();

      // Parse user type
      final userType = UserType.values.firstWhere(
        (e) => e.toString().split('.').last == userData['user_type'],
        orElse: () => UserType.patient,
      );

      // Get additional data based on user type
      Map<String, dynamic> additionalData = {};

      switch (userType) {
        case UserType.patient:
          final patientData =
              await _supabaseClient
                  .from('patients_profile')
                  .select()
                  .eq('id', userId)
                  .maybeSingle();

          if (patientData != null) {
            additionalData = {
              'age': patientData['age'],
              'gender': patientData['gender'],
              'bloodGroup': patientData['blood_group'],
              'height': patientData['height'],
              'weight': patientData['weight'],
              'medicalHistory': patientData['medical_history'],
              'allergies': patientData['allergies'],
            };

            // Get allergies from the separate table if not in the profile
            if (additionalData['allergies'] == null) {
              final allergies = await _supabaseClient
                  .from('patient_allergies')
                  .select('allergy')
                  .eq('patient_id', userId);

              additionalData['allergies'] =
                  allergies.map((e) => e['allergy'] as String).toList();
            }

            // Get chronic conditions
            final conditions = await _supabaseClient
                .from('patient_chronic_conditions')
                .select('condition')
                .eq('patient_id', userId);

            additionalData['chronicConditions'] =
                conditions.map((e) => e['condition'] as String).toList();

            // Get medications
            final medications = await _supabaseClient
                .from('patient_medications')
                .select('medication')
                .eq('patient_id', userId);

            additionalData['medications'] =
                medications.map((e) => e['medication'] as String).toList();
          }
          break;
        case UserType.doctor:
          final doctorData =
              await _supabaseClient
                  .from('doctors_profile')
                  .select()
                  .eq('id', userId)
                  .maybeSingle();

          if (doctorData != null) {
            additionalData = {
              'specialization': doctorData['specialization'],
              'hospital': doctorData['hospital'],
              'licenseNumber': doctorData['license_number'],
              'experience': doctorData['experience'],
              'isAvailableForChat': doctorData['is_available_for_chat'],
              'isAvailableForVideo': doctorData['is_available_for_video'],
              'verificationStatus': doctorData['verification_status'],
              'consultationFee': doctorData['consultation_fee'],
              'rating': doctorData['rating'],
              'about': doctorData['about'],
              'city': doctorData['city'],
            };

            // Get qualifications
            final qualifications = await _supabaseClient
                .from('doctor_qualifications')
                .select('qualification')
                .eq('doctor_id', userId);

            additionalData['qualifications'] =
                qualifications
                    .map((e) => e['qualification'] as String)
                    .toList();
          } else {
            // Try the old table as fallback during migration
            final oldDoctorData =
                await _supabaseClient
                    .from('doctors')
                    .select()
                    .eq('id', userId)
                    .maybeSingle();

            if (oldDoctorData != null) {
              additionalData = {
                'specialization': oldDoctorData['specialization'],
                'hospital': oldDoctorData['hospital'],
                'licenseNumber': oldDoctorData['license_number'],
                'experience': oldDoctorData['experience'],
                'isAvailableForChat': oldDoctorData['is_available_for_chat'],
                'isAvailableForVideo': oldDoctorData['is_available_for_video'],
                'verificationStatus': oldDoctorData['verification_status'],
              };

              debugPrint('Using old doctors table data as fallback');
            }
          }
          break;
        case UserType.admin:
          final adminData =
              await _supabaseClient
                  .from('admins_profile')
                  .select()
                  .eq('id', userId)
                  .maybeSingle();

          if (adminData != null) {
            additionalData = {
              'adminRole': adminData['admin_role'],
              'permissions': adminData['permissions'],
            };

            // Get permissions from separate table if not in profile
            if (additionalData['permissions'] == null) {
              final permissions = await _supabaseClient
                  .from('admin_permissions')
                  .select('permission')
                  .eq('admin_id', userId);

              additionalData['permissions'] =
                  permissions.map((e) => e['permission'] as String).toList();
            }
          } else {
            // Try the old table as fallback during migration
            final oldAdminData =
                await _supabaseClient
                    .from('admins')
                    .select()
                    .eq('id', userId)
                    .maybeSingle();

            if (oldAdminData != null) {
              additionalData = {'adminRole': oldAdminData['admin_role']};
              debugPrint('Using old admins table data as fallback');
            }
          }
          break;
      }

      // Create UserModel with all the data
      return UserModel(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        phone: userData['phone'] ?? '',
        profileImage: userData['profile_image'],
        userType: userType,
        age: additionalData['age'],
        gender: additionalData['gender'],
        bloodGroup: additionalData['bloodGroup'],
        height: additionalData['height'],
        weight: additionalData['weight'],
        allergies: additionalData['allergies'],
        chronicConditions: additionalData['chronicConditions'],
        medications: additionalData['medications'],
        specialization: additionalData['specialization'],
        hospital: additionalData['hospital'],
        licenseNumber: additionalData['licenseNumber'],
        experience: additionalData['experience'],
        qualifications: additionalData['qualifications'],
        isAvailableForChat: additionalData['isAvailableForChat'],
        isAvailableForVideo: additionalData['isAvailableForVideo'],
        adminRole: additionalData['adminRole'],
        permissions: additionalData['permissions'],
      );
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // ==================== HEALTH DATA MANAGEMENT ====================

  /// Add new health data record
  Future<HealthDataModel> addHealthData(HealthDataModel healthData) async {
    try {
      // Prepare data for insertion
      final Map<String, dynamic> data = {
        'user_id': healthData.userId,
        'timestamp': healthData.timestamp.toIso8601String(),
        'temperature': healthData.temperature,
        'heart_rate': healthData.heartRate,
        'systolic_bp': healthData.systolicBP,
        'diastolic_bp': healthData.diastolicBP,
        'respiratory_rate': healthData.respiratoryRate,
        'oxygen_saturation': healthData.oxygenSaturation,
        'blood_glucose': healthData.bloodGlucose,
        'notes': healthData.notes,
      };

      // Insert data and get the result
      final response =
          await _supabaseClient
              .from('health_data')
              .insert(data)
              .select()
              .single();

      // Map the response to a HealthDataModel
      return HealthDataModel(
        id: response['id'],
        userId: response['user_id'],
        timestamp: DateTime.parse(response['timestamp']),
        temperature: response['temperature']?.toDouble(),
        heartRate: response['heart_rate'],
        systolicBP: response['systolic_bp'],
        diastolicBP: response['diastolic_bp'],
        respiratoryRate: response['respiratory_rate'],
        oxygenSaturation: response['oxygen_saturation']?.toDouble(),
        bloodGlucose: response['blood_glucose']?.toDouble(),
        notes: response['notes'],
      );
    } catch (e) {
      debugPrint('Error adding health data: $e');
      rethrow;
    }
  }

  /// Get health data for a specific user
  Future<List<HealthDataModel>> getHealthData(String userId) async {
    try {
      // Query health data for the user
      final response = await _supabaseClient
          .from('health_data')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      // Map the response to a list of HealthDataModel
      return response.map<HealthDataModel>((data) {
        return HealthDataModel(
          id: data['id'],
          userId: data['user_id'],
          timestamp: DateTime.parse(data['timestamp']),
          temperature: data['temperature']?.toDouble(),
          heartRate: data['heart_rate'],
          systolicBP: data['systolic_bp'],
          diastolicBP: data['diastolic_bp'],
          respiratoryRate: data['respiratory_rate'],
          oxygenSaturation: data['oxygen_saturation']?.toDouble(),
          bloodGlucose: data['blood_glucose']?.toDouble(),
          notes: data['notes'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting health data: $e');
      rethrow;
    }
  }

  /// Get health data by ID
  Future<HealthDataModel?> getHealthDataById(String id) async {
    try {
      // Query health data by ID
      final response =
          await _supabaseClient
              .from('health_data')
              .select()
              .eq('id', id)
              .maybeSingle();

      if (response == null) {
        return null;
      }

      // Map the response to a HealthDataModel
      return HealthDataModel(
        id: response['id'],
        userId: response['user_id'],
        timestamp: DateTime.parse(response['timestamp']),
        temperature: response['temperature']?.toDouble(),
        heartRate: response['heart_rate'],
        systolicBP: response['systolic_bp'],
        diastolicBP: response['diastolic_bp'],
        respiratoryRate: response['respiratory_rate'],
        oxygenSaturation: response['oxygen_saturation']?.toDouble(),
        bloodGlucose: response['blood_glucose']?.toDouble(),
        notes: response['notes'],
      );
    } catch (e) {
      debugPrint('Error getting health data by ID: $e');
      return null;
    }
  }

  // ==================== SYMPTOM MANAGEMENT ====================

  /// Add new symptom
  Future<SymptomModel> addSymptom(SymptomModel symptom) async {
    try {
      // Prepare data for insertion
      final Map<String, dynamic> data = {
        'user_id': symptom.userId,
        'timestamp': symptom.timestamp.toIso8601String(),
        'description': symptom.description,
        'severity': symptom.severity,
        'duration': symptom.duration,
        'notes':
            null, // Notes field is not in the model but exists in the database
      };

      // Insert the main symptom record and get the result
      final response =
          await _supabaseClient.from('symptoms').insert(data).select().single();

      final symptomId = response['id'];

      // Insert body parts if available
      if (symptom.bodyParts != null && symptom.bodyParts!.isNotEmpty) {
        await _supabaseClient
            .from('symptom_body_parts')
            .insert(
              symptom.bodyParts!
                  .map((part) => {'symptom_id': symptomId, 'body_part': part})
                  .toList(),
            );
      }

      // Insert associated factors if available
      if (symptom.associatedFactors != null &&
          symptom.associatedFactors!.isNotEmpty) {
        await _supabaseClient
            .from('symptom_associated_factors')
            .insert(
              symptom.associatedFactors!
                  .map((factor) => {'symptom_id': symptomId, 'factor': factor})
                  .toList(),
            );
      }

      // Insert images if available
      if (symptom.images != null && symptom.images!.isNotEmpty) {
        await _supabaseClient
            .from('symptom_images')
            .insert(
              symptom.images!
                  .map(
                    (imageUrl) => {
                      'symptom_id': symptomId,
                      'image_url': imageUrl,
                    },
                  )
                  .toList(),
            );
      }

      // Get the complete symptom with all related data
      return await getSymptomById(symptomId) ??
          SymptomModel(
            id: symptomId,
            userId: symptom.userId,
            timestamp: symptom.timestamp,
            description: symptom.description,
            severity: symptom.severity,
            duration: symptom.duration,
            bodyParts: symptom.bodyParts,
            associatedFactors: symptom.associatedFactors,
            images: symptom.images,
          );
    } catch (e) {
      debugPrint('Error adding symptom: $e');
      rethrow;
    }
  }

  /// Get symptoms for a specific user
  Future<List<SymptomModel>> getSymptoms(String userId) async {
    try {
      // Query symptoms for the user
      final response = await _supabaseClient
          .from('symptoms')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      // Create a list to store the complete symptom models
      List<SymptomModel> symptoms = [];

      // Process each symptom
      for (final symptomData in response) {
        final symptomId = symptomData['id'];

        // Get body parts
        final bodyPartsResponse = await _supabaseClient
            .from('symptom_body_parts')
            .select('body_part')
            .eq('symptom_id', symptomId);

        List<String> bodyParts =
            bodyPartsResponse
                .map<String>((item) => item['body_part'] as String)
                .toList();

        // Get associated factors
        final factorsResponse = await _supabaseClient
            .from('symptom_associated_factors')
            .select('factor')
            .eq('symptom_id', symptomId);

        List<String> associatedFactors =
            factorsResponse
                .map<String>((item) => item['factor'] as String)
                .toList();

        // Get images
        final imagesResponse = await _supabaseClient
            .from('symptom_images')
            .select('image_url')
            .eq('symptom_id', symptomId);

        List<String> images =
            imagesResponse
                .map<String>((item) => item['image_url'] as String)
                .toList();

        // Create the symptom model
        symptoms.add(
          SymptomModel(
            id: symptomId,
            userId: symptomData['user_id'],
            timestamp: DateTime.parse(symptomData['timestamp']),
            description: symptomData['description'],
            severity: symptomData['severity'],
            duration: symptomData['duration'],
            bodyParts: bodyParts.isNotEmpty ? bodyParts : null,
            associatedFactors:
                associatedFactors.isNotEmpty ? associatedFactors : null,
            images: images.isNotEmpty ? images : null,
          ),
        );
      }

      return symptoms;
    } catch (e) {
      debugPrint('Error getting symptoms: $e');
      rethrow;
    }
  }

  /// Get symptom by ID
  Future<SymptomModel?> getSymptomById(String id) async {
    try {
      // Query symptom by ID
      final response =
          await _supabaseClient
              .from('symptoms')
              .select()
              .eq('id', id)
              .maybeSingle();

      if (response == null) {
        return null;
      }

      final symptomId = response['id'];

      // Get body parts
      final bodyPartsResponse = await _supabaseClient
          .from('symptom_body_parts')
          .select('body_part')
          .eq('symptom_id', symptomId);

      List<String> bodyParts =
          bodyPartsResponse
              .map<String>((item) => item['body_part'] as String)
              .toList();

      // Get associated factors
      final factorsResponse = await _supabaseClient
          .from('symptom_associated_factors')
          .select('factor')
          .eq('symptom_id', symptomId);

      List<String> associatedFactors =
          factorsResponse
              .map<String>((item) => item['factor'] as String)
              .toList();

      // Get images
      final imagesResponse = await _supabaseClient
          .from('symptom_images')
          .select('image_url')
          .eq('symptom_id', symptomId);

      List<String> images =
          imagesResponse
              .map<String>((item) => item['image_url'] as String)
              .toList();

      // Create the symptom model
      return SymptomModel(
        id: symptomId,
        userId: response['user_id'],
        timestamp: DateTime.parse(response['timestamp']),
        description: response['description'],
        severity: response['severity'],
        duration: response['duration'],
        bodyParts: bodyParts.isNotEmpty ? bodyParts : null,
        associatedFactors:
            associatedFactors.isNotEmpty ? associatedFactors : null,
        images: images.isNotEmpty ? images : null,
      );
    } catch (e) {
      debugPrint('Error getting symptom by ID: $e');
      return null;
    }
  }

  // ==================== PREDICTION RESULTS MANAGEMENT ====================

  /// Save prediction result
  Future<PredictionResultModel> savePrediction(
    PredictionResultModel prediction,
  ) async {
    try {
      // First, check if we need to create disease records for any of the diseases
      for (final disease in prediction.diseases) {
        // Check if the disease already exists in the database
        final existingDisease =
            await _supabaseClient
                .from('diseases')
                .select('id')
                .eq('name', disease.name)
                .maybeSingle();

        if (existingDisease == null) {
          // Create a new disease record
          await _supabaseClient.from('diseases').insert({
            'id': disease.diseaseId,
            'name': disease.name,
            'description': disease.description ?? '',
            'specialist_type': disease.specialistType,
            'risk_level': _mapProbabilityToRiskLevel(disease.probability),
          });

          // Add symptoms if available
          if (disease.symptoms != null && disease.symptoms!.isNotEmpty) {
            await _supabaseClient
                .from('disease_symptoms')
                .insert(
                  disease.symptoms!
                      .map(
                        (symptom) => {
                          'disease_id': disease.diseaseId,
                          'symptom': symptom,
                        },
                      )
                      .toList(),
                );
          }
        }
      }

      // Insert the main prediction record
      final Map<String, dynamic> predictionData = {
        'user_id': prediction.userId,
        'timestamp': prediction.timestamp.toIso8601String(),
        'health_data_id': prediction.healthDataId,
        'symptom_id': prediction.symptomId,
        'recommended_action': prediction.recommendedAction,
        'urgency_level': prediction.urgencyLevel,
      };

      final response =
          await _supabaseClient
              .from('prediction_results')
              .insert(predictionData)
              .select()
              .single();

      final predictionId = response['id'];

      // Insert disease predictions
      for (final disease in prediction.diseases) {
        await _supabaseClient.from('disease_predictions').insert({
          'prediction_id': predictionId,
          'disease_id': disease.diseaseId,
          'probability': disease.probability,
        });
      }

      // Return the saved prediction with the generated ID
      return PredictionResultModel(
        id: predictionId,
        userId: prediction.userId,
        timestamp: prediction.timestamp,
        diseases: prediction.diseases,
        healthDataId: prediction.healthDataId,
        symptomId: prediction.symptomId,
        recommendedAction: prediction.recommendedAction,
        urgencyLevel: prediction.urgencyLevel,
      );
    } catch (e) {
      debugPrint('Error saving prediction: $e');
      rethrow;
    }
  }

  /// Get prediction results for a user
  Future<List<PredictionResultModel>> getUserPredictions(String userId) async {
    try {
      // Query prediction results for the user
      final response = await _supabaseClient
          .from('prediction_results')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      // Create a list to store the complete prediction models
      List<PredictionResultModel> predictions = [];

      // Process each prediction
      for (final predictionData in response) {
        final predictionId = predictionData['id'];

        // Get disease predictions
        final diseasePredictionsResponse = await _supabaseClient
            .from('disease_predictions')
            .select('*, diseases(*)')
            .eq('prediction_id', predictionId);

        List<DiseaseWithProbability> diseases = [];

        // Process each disease prediction
        for (final diseasePrediction in diseasePredictionsResponse) {
          final diseaseData = diseasePrediction['diseases'];
          final probability = diseasePrediction['probability'];

          // Get disease symptoms
          final symptomsResponse = await _supabaseClient
              .from('disease_symptoms')
              .select('symptom')
              .eq('disease_id', diseaseData['id']);

          List<String> symptoms =
              symptomsResponse
                  .map<String>((item) => item['symptom'] as String)
                  .toList();

          // Create disease with probability model
          diseases.add(
            DiseaseWithProbability(
              diseaseId: diseaseData['id'],
              name: diseaseData['name'],
              probability: probability,
              description: diseaseData['description'],
              symptoms: symptoms.isNotEmpty ? symptoms : null,
              specialistType: diseaseData['specialist_type'],
            ),
          );
        }

        // Sort diseases by probability (highest first)
        diseases.sort((a, b) => b.probability.compareTo(a.probability));

        // Create the prediction model
        predictions.add(
          PredictionResultModel(
            id: predictionId,
            userId: predictionData['user_id'],
            timestamp: DateTime.parse(predictionData['timestamp']),
            diseases: diseases,
            healthDataId: predictionData['health_data_id'],
            symptomId: predictionData['symptom_id'],
            recommendedAction: predictionData['recommended_action'],
            urgencyLevel: predictionData['urgency_level'],
          ),
        );
      }

      return predictions;
    } catch (e) {
      debugPrint('Error getting user predictions: $e');
      rethrow;
    }
  }

  /// Get prediction by ID
  Future<PredictionResultModel?> getPredictionById(String id) async {
    try {
      // Query prediction by ID
      final response =
          await _supabaseClient
              .from('prediction_results')
              .select()
              .eq('id', id)
              .maybeSingle();

      if (response == null) {
        return null;
      }

      final predictionId = response['id'];

      // Get disease predictions
      final diseasePredictionsResponse = await _supabaseClient
          .from('disease_predictions')
          .select('*, diseases(*)')
          .eq('prediction_id', predictionId);

      List<DiseaseWithProbability> diseases = [];

      // Process each disease prediction
      for (final diseasePrediction in diseasePredictionsResponse) {
        final diseaseData = diseasePrediction['diseases'];
        final probability = diseasePrediction['probability'];

        // Get disease symptoms
        final symptomsResponse = await _supabaseClient
            .from('disease_symptoms')
            .select('symptom')
            .eq('disease_id', diseaseData['id']);

        List<String> symptoms =
            symptomsResponse
                .map<String>((item) => item['symptom'] as String)
                .toList();

        // Create disease with probability model
        diseases.add(
          DiseaseWithProbability(
            diseaseId: diseaseData['id'],
            name: diseaseData['name'],
            probability: probability,
            description: diseaseData['description'],
            symptoms: symptoms.isNotEmpty ? symptoms : null,
            specialistType: diseaseData['specialist_type'],
          ),
        );
      }

      // Sort diseases by probability (highest first)
      diseases.sort((a, b) => b.probability.compareTo(a.probability));

      // Create the prediction model
      return PredictionResultModel(
        id: predictionId,
        userId: response['user_id'],
        timestamp: DateTime.parse(response['timestamp']),
        diseases: diseases,
        healthDataId: response['health_data_id'],
        symptomId: response['symptom_id'],
        recommendedAction: response['recommended_action'],
        urgencyLevel: response['urgency_level'],
      );
    } catch (e) {
      debugPrint('Error getting prediction by ID: $e');
      return null;
    }
  }

  // Helper method to map probability to risk level
  String _mapProbabilityToRiskLevel(double probability) {
    if (probability >= 0.7) return 'High';
    if (probability >= 0.4) return 'Medium';
    return 'Low';
  }

  // ==================== APPOINTMENT MANAGEMENT ====================

  /// Book a new appointment
  Future<AppointmentModel> bookAppointment(AppointmentModel appointment) async {
    try {
      // Prepare data for insertion
      final Map<String, dynamic> data = {
        'user_id': appointment.userId,
        'doctor_id': appointment.doctorId,
        'appointment_date':
            appointment.appointmentDate.toIso8601String().split(
              'T',
            )[0], // Get only the date part
        'time_slot': appointment.timeSlot,
        'type': appointment.type,
        'status': appointment.status,
        'reason': appointment.reason,
        'notes': appointment.notes,
        'fee': appointment.fee,
        'prescription_url': appointment.prescriptionUrl,
      };

      // Insert appointment and get the result
      final response =
          await _supabaseClient
              .from('appointments')
              .insert(data)
              .select()
              .single();

      final appointmentId = response['id'];

      // Insert attachments if available
      if (appointment.attachments != null &&
          appointment.attachments!.isNotEmpty) {
        await _supabaseClient
            .from('appointment_attachments')
            .insert(
              appointment.attachments!
                  .map(
                    (url) => {
                      'appointment_id': appointmentId,
                      'attachment_url': url,
                    },
                  )
                  .toList(),
            );
      }

      // Return the created appointment with the generated ID
      return AppointmentModel(
        id: appointmentId,
        userId: response['user_id'],
        doctorId: response['doctor_id'],
        appointmentDate: DateTime.parse(response['appointment_date']),
        timeSlot: response['time_slot'],
        type: response['type'],
        status: response['status'],
        reason: response['reason'],
        attachments: appointment.attachments,
        notes: response['notes'],
        fee: response['fee'].toDouble(),
        prescriptionUrl: response['prescription_url'],
        createdAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      rethrow;
    }
  }

  /// Get appointments for a specific user
  Future<List<AppointmentModel>> getUserAppointments(String userId) async {
    try {
      // Query appointments for the user
      final response = await _supabaseClient
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('appointment_date', ascending: true);

      // Create a list to store the complete appointment models
      List<AppointmentModel> appointments = [];

      // Process the response
      for (final item in response) {
        try {
          final appointment = AppointmentModel.fromJson(item);
          appointments.add(appointment);
        } catch (e) {
          debugPrint('Error parsing appointment: $e');
        }
      }

      return appointments;
    } catch (e) {
      debugPrint('Error getting user appointments: $e');
      rethrow;
    }
  }

  /// Get appointments for a specific doctor
  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId) async {
    try {
      // Query appointments for the doctor
      final response = await _supabaseClient
          .from('appointments')
          .select('''
            *,
            users:user_id (
              name,
              profile_image
            )
          ''')
          .eq('doctor_id', doctorId)
          .order('appointment_date', ascending: true);

      // Create a list to store the complete appointment models
      List<AppointmentModel> appointments = [];

      // Process each appointment
      for (final appointmentData in response) {
        try {
          final appointment = AppointmentModel.fromJson(appointmentData);

          // Add patient name from the joined user data
          if (appointmentData['users'] != null) {
            appointment.patientName =
                appointmentData['users']['name'] ?? 'Unknown Patient';
          } else {
            appointment.patientName = 'Patient';
          }

          appointments.add(appointment);
        } catch (e) {
          debugPrint('Error parsing doctor appointment: $e');
        }
      }

      return appointments;
    } catch (e) {
      debugPrint('Error getting doctor appointments: $e');
      rethrow;
    }
  }

  /// Update appointment status
  Future<AppointmentModel> updateAppointmentStatus(
    String id,
    String status,
  ) async {
    try {
      // Update appointment status
      final response =
          await _supabaseClient
              .from('appointments')
              .update({'status': status})
              .eq('id', id)
              .select()
              .single();

      // Get attachments
      final attachmentsResponse = await _supabaseClient
          .from('appointment_attachments')
          .select('attachment_url')
          .eq('appointment_id', id);

      List<String> attachments =
          attachmentsResponse
              .map<String>((item) => item['attachment_url'] as String)
              .toList();

      // Return the updated appointment
      return AppointmentModel(
        id: response['id'],
        userId: response['user_id'],
        doctorId: response['doctor_id'],
        appointmentDate: DateTime.parse(response['appointment_date']),
        timeSlot: response['time_slot'],
        type: response['type'],
        status: response['status'],
        reason: response['reason'],
        attachments: attachments.isNotEmpty ? attachments : null,
        notes: response['notes'],
        fee: response['fee'].toDouble(),
        prescriptionUrl: response['prescription_url'],
        createdAt: DateTime.parse(response['created_at']),
      );
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      rethrow;
    }
  }

  // ==================== CHAT AND MESSAGING ====================

  /// Create a new chat session between two users
  Future<ChatModel> createChatSession(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      // First, check if a chat already exists between these users
      final existingChatResponse = await _supabaseClient
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', currentUserId);

      final currentUserChats = existingChatResponse as List<dynamic>;

      for (final chatData in currentUserChats) {
        final chatId = chatData['chat_id'];

        // Check if the other user is also a participant in this chat
        final otherUserInChatResponse =
            await _supabaseClient
                .from('chat_participants')
                .select()
                .eq('chat_id', chatId)
                .eq('user_id', otherUserId)
                .maybeSingle();

        if (otherUserInChatResponse != null) {
          // Chat already exists, get the chat details
          final chatResponse =
              await _supabaseClient
                  .from('chats')
                  .select()
                  .eq('id', chatId)
                  .single();

          // Get the last message
          final lastMessageResponse =
              await _supabaseClient
                  .from('messages')
                  .select()
                  .eq('chat_id', chatId)
                  .order('timestamp', ascending: false)
                  .limit(1)
                  .maybeSingle();

          // Get unread count for current user
          final unreadCountResponse = await _supabaseClient
              .from('message_read_status')
              .select('*')
              .eq('user_id', currentUserId)
              .eq('is_read', false);

          final unreadCount = unreadCountResponse.length;

          // Create and return the chat model
          return ChatModel(
            id: chatId,
            participantIds: [currentUserId, otherUserId],
            createdAt: DateTime.parse(chatResponse['created_at']),
            lastMessageAt:
                lastMessageResponse != null
                    ? DateTime.parse(lastMessageResponse['timestamp'])
                    : DateTime.parse(chatResponse['created_at']),
            lastMessageContent:
                lastMessageResponse != null
                    ? lastMessageResponse['content']
                    : 'Chat started',
            lastMessageSenderId:
                lastMessageResponse != null
                    ? lastMessageResponse['sender_id']
                    : currentUserId,
            hasUnreadMessages: unreadCount > 0,
            unreadCount: unreadCount,
          );
        }
      }

      // No existing chat found, create a new one
      // 1. Create chat entry
      final chatResponse =
          await _supabaseClient.from('chats').insert({}).select().single();

      final chatId = chatResponse['id'];

      // 2. Add participants
      await _supabaseClient.from('chat_participants').insert([
        {'chat_id': chatId, 'user_id': currentUserId},
        {'chat_id': chatId, 'user_id': otherUserId},
      ]);

      // 3. Create and return the chat model
      return ChatModel(
        id: chatId,
        participantIds: [currentUserId, otherUserId],
        createdAt: DateTime.parse(chatResponse['created_at']),
        lastMessageAt: DateTime.parse(chatResponse['created_at']),
        lastMessageContent: 'Chat started',
        lastMessageSenderId: currentUserId,
        hasUnreadMessages: false,
        unreadCount: 0,
      );
    } catch (e) {
      debugPrint('Error creating chat session: $e');
      rethrow;
    }
  }

  /// Get all chats for a user
  Future<List<ChatModel>> getUserChats(String userId) async {
    try {
      // Get all chats where the user is a participant
      final chatParticipantsResponse = await _supabaseClient
          .from('chat_participants')
          .select('chat_id')
          .eq('user_id', userId);

      final chatIds =
          chatParticipantsResponse.map((item) => item['chat_id']).toList();

      if (chatIds.isEmpty) {
        return [];
      }

      // Get all chats
      final chatsResponse = await _supabaseClient
          .from('chats')
          .select()
          .filter('id', 'in', chatIds)
          .order('updated_at', ascending: false);

      // Create a list to store the complete chat models
      List<ChatModel> chats = [];

      // Process each chat
      for (final chatData in chatsResponse) {
        final chatId = chatData['id'];

        // Get participants
        final participantsResponse = await _supabaseClient
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chatId);

        List<String> participantIds =
            participantsResponse
                .map<String>((item) => item['user_id'] as String)
                .toList();

        // Get last message
        final lastMessageResponse =
            await _supabaseClient
                .from('messages')
                .select()
                .eq('chat_id', chatId)
                .order('timestamp', ascending: false)
                .limit(1)
                .maybeSingle();

        // Get unread count for current user
        final unreadMessagesResponse = await _supabaseClient
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .neq('sender_id', userId);

        final unreadMessagesIds =
            unreadMessagesResponse.map((item) => item['id']).toList();

        int unreadCount = 0;
        bool hasUnreadMessages = false;

        if (unreadMessagesIds.isNotEmpty) {
          final readStatusResponse = await _supabaseClient
              .from('message_read_status')
              .select('*')
              .filter('message_id', 'in', unreadMessagesIds)
              .eq('user_id', userId)
              .eq('is_read', false);

          unreadCount = readStatusResponse.length;
          hasUnreadMessages = unreadCount > 0;
        }

        // Create the chat model
        chats.add(
          ChatModel(
            id: chatId,
            participantIds: participantIds,
            createdAt: DateTime.parse(chatData['created_at']),
            lastMessageAt:
                lastMessageResponse != null
                    ? DateTime.parse(lastMessageResponse['timestamp'])
                    : DateTime.parse(chatData['created_at']),
            lastMessageContent:
                lastMessageResponse != null
                    ? lastMessageResponse['content']
                    : 'Chat started',
            lastMessageSenderId:
                lastMessageResponse != null
                    ? lastMessageResponse['sender_id']
                    : participantIds.first,
            hasUnreadMessages: hasUnreadMessages,
            unreadCount: unreadCount,
          ),
        );
      }

      return chats;
    } catch (e) {
      debugPrint('Error getting user chats: $e');
      rethrow;
    }
  }

  /// Get messages for a specific chat
  Future<List<MessageModel>> getChatMessages(String chatId) async {
    try {
      // Get all messages for the chat
      final messagesResponse = await _supabaseClient
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('timestamp', ascending: true);

      // Create a list to store the complete message models
      List<MessageModel> messages = [];

      // Process each message
      for (final messageData in messagesResponse) {
        final messageId = messageData['id'];

        // Get read status
        final currentUserId = _supabaseClient.auth.currentUser?.id;
        bool isRead = false;

        if (currentUserId != null) {
          final readStatusResponse =
              await _supabaseClient
                  .from('message_read_status')
                  .select()
                  .eq('message_id', messageId)
                  .eq('user_id', currentUserId)
                  .maybeSingle();

          isRead =
              readStatusResponse != null &&
              readStatusResponse['is_read'] == true;
        }

        // Determine receiver ID (the other participant)
        String receiverId = '';
        final participantsResponse = await _supabaseClient
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chatId);

        List<String> participantIds =
            participantsResponse
                .map<String>((item) => item['user_id'] as String)
                .toList();

        if (participantIds.length == 2) {
          receiverId = participantIds.firstWhere(
            (id) => id != messageData['sender_id'],
            orElse: () => '',
          );
        }

        // Create the message model
        messages.add(
          MessageModel(
            id: messageId,
            chatId: chatId,
            senderId: messageData['sender_id'],
            receiverId: receiverId,
            content: messageData['content'],
            timestamp: DateTime.parse(messageData['timestamp']),
            isRead: isRead,
            attachmentUrl: messageData['attachment_url'],
            attachmentType: messageData['attachment_type'],
          ),
        );
      }

      return messages;
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      rethrow;
    }
  }

  /// Send a message in a chat
  Future<MessageModel> sendMessage(MessageModel message) async {
    try {
      // Prepare data for insertion
      final Map<String, dynamic> data = {
        'chat_id': message.chatId,
        'sender_id': message.senderId,
        'content': message.content,
        'timestamp': message.timestamp.toIso8601String(),
        'attachment_url': message.attachmentUrl,
        'attachment_type': message.attachmentType,
      };

      // Insert message and get the result
      final response =
          await _supabaseClient.from('messages').insert(data).select().single();

      final messageId = response['id'];

      // Update chat's updated_at timestamp
      await _supabaseClient
          .from('chats')
          .update({'updated_at': message.timestamp.toIso8601String()})
          .eq('id', message.chatId);

      // Create read status entries for all participants
      final participantsResponse = await _supabaseClient
          .from('chat_participants')
          .select('user_id')
          .eq('chat_id', message.chatId);

      List<String> participantIds =
          participantsResponse
              .map<String>((item) => item['user_id'] as String)
              .toList();

      for (final participantId in participantIds) {
        await _supabaseClient.from('message_read_status').insert({
          'message_id': messageId,
          'user_id': participantId,
          'is_read':
              participantId == message.senderId, // Sender has read the message
          'read_at':
              participantId == message.senderId
                  ? message.timestamp.toIso8601String()
                  : null,
        });
      }

      // Return the created message with the generated ID
      return MessageModel(
        id: messageId,
        chatId: message.chatId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        content: message.content,
        timestamp: message.timestamp,
        isRead: false, // Only the sender has read it
        attachmentUrl: message.attachmentUrl,
        attachmentType: message.attachmentType,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Get all unread messages in the chat that were not sent by the current user
      final messagesResponse = await _supabaseClient
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .not('sender_id', 'eq', userId);

      final messageIds = messagesResponse.map((item) => item['id']).toList();

      if (messageIds.isEmpty) {
        return;
      }

      // Update read status for all these messages
      for (final messageId in messageIds) {
        await _supabaseClient
            .from('message_read_status')
            .update({
              'is_read': true,
              'read_at': DateTime.now().toIso8601String(),
            })
            .eq('message_id', messageId)
            .eq('user_id', userId);
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      rethrow;
    }
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      // Get chat data
      final chatResponse =
          await _supabaseClient
              .from('chats')
              .select()
              .eq('id', chatId)
              .maybeSingle();

      if (chatResponse == null) {
        return null;
      }

      // Get participants
      final participantsResponse = await _supabaseClient
          .from('chat_participants')
          .select('user_id')
          .eq('chat_id', chatId);

      List<String> participantIds =
          participantsResponse
              .map<String>((item) => item['user_id'] as String)
              .toList();

      // Get last message
      final lastMessageResponse =
          await _supabaseClient
              .from('messages')
              .select()
              .eq('chat_id', chatId)
              .order('timestamp', ascending: false)
              .limit(1)
              .maybeSingle();

      // Get unread count for current user
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      int unreadCount = 0;
      bool hasUnreadMessages = false;

      if (currentUserId != null) {
        final unreadMessagesResponse = await _supabaseClient
            .from('messages')
            .select('id')
            .eq('chat_id', chatId)
            .neq('sender_id', currentUserId);

        final unreadMessagesIds =
            unreadMessagesResponse.map((item) => item['id']).toList();

        if (unreadMessagesIds.isNotEmpty) {
          final readStatusResponse = await _supabaseClient
              .from('message_read_status')
              .select('*')
              .filter('message_id', 'in', unreadMessagesIds)
              .eq('user_id', currentUserId)
              .eq('is_read', false);

          unreadCount = readStatusResponse.length;
          hasUnreadMessages = unreadCount > 0;
        }
      }

      // Create and return the chat model
      return ChatModel(
        id: chatId,
        participantIds: participantIds,
        createdAt: DateTime.parse(chatResponse['created_at']),
        lastMessageAt:
            lastMessageResponse != null
                ? DateTime.parse(lastMessageResponse['timestamp'])
                : DateTime.parse(chatResponse['created_at']),
        lastMessageContent:
            lastMessageResponse != null
                ? lastMessageResponse['content']
                : 'Chat started',
        lastMessageSenderId:
            lastMessageResponse != null
                ? lastMessageResponse['sender_id']
                : participantIds.first,
        hasUnreadMessages: hasUnreadMessages,
        unreadCount: unreadCount,
      );
    } catch (e) {
      debugPrint('Error getting chat by ID: $e');
      return null;
    }
  }

  /// Get new messages for a chat since a specific timestamp
  Future<List<MessageModel>> getNewMessages(
    String chatId,
    DateTime since,
  ) async {
    try {
      // Get all messages for the chat since the given timestamp
      final messagesResponse = await _supabaseClient
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .gt('timestamp', since.toIso8601String())
          .order('timestamp', ascending: true);

      // Create a list to store the complete message models
      List<MessageModel> messages = [];

      // Process each message
      for (final messageData in messagesResponse) {
        final messageId = messageData['id'];

        // Determine receiver ID (the other participant)
        String receiverId = '';
        final participantsResponse = await _supabaseClient
            .from('chat_participants')
            .select('user_id')
            .eq('chat_id', chatId);

        List<String> participantIds =
            participantsResponse
                .map<String>((item) => item['user_id'] as String)
                .toList();

        if (participantIds.length == 2) {
          receiverId = participantIds.firstWhere(
            (id) => id != messageData['sender_id'],
            orElse: () => '',
          );
        }

        // Create the message model
        messages.add(
          MessageModel(
            id: messageId,
            chatId: chatId,
            senderId: messageData['sender_id'],
            receiverId: receiverId,
            content: messageData['content'],
            timestamp: DateTime.parse(messageData['timestamp']),
            isRead: false, // Assume new messages are unread
            attachmentUrl: messageData['attachment_url'],
            attachmentType: messageData['attachment_type'],
          ),
        );
      }

      return messages;
    } catch (e) {
      debugPrint('Error getting new messages: $e');
      rethrow;
    }
  }

  // ==================== FILE UPLOAD AND STORAGE ====================

  /// Upload a file to Supabase Storage
  Future<String> uploadFile(String filePath, String storagePath) async {
    try {
      final fileName = filePath.split('/').last;
      final fileExtension = fileName.split('.').last;
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final fullStoragePath = '$storagePath/$uniqueFileName';

      // Upload the file
      await _supabaseClient.storage
          .from(_storageBucketName)
          .upload(fullStoragePath, File(filePath));

      // Get the public URL
      final fileUrl = getPublicUrl(fullStoragePath);

      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Upload a file from bytes to Supabase Storage
  Future<String> uploadFileFromBytes(
    List<int> bytes,
    String storagePath,
    String fileExtension,
  ) async {
    try {
      final uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final fullStoragePath = '$storagePath/$uniqueFileName';

      // Convert List<int> to Uint8List
      final Uint8List uint8List = Uint8List.fromList(bytes);

      // Upload the file
      await _supabaseClient.storage
          .from(_storageBucketName)
          .uploadBinary(fullStoragePath, uint8List);

      // Get the public URL
      final fileUrl = getPublicUrl(fullStoragePath);

      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading file from bytes: $e');
      rethrow;
    }
  }

  /// Get a public URL for a file in Supabase Storage
  String getPublicUrl(String storagePath) {
    try {
      final response = _supabaseClient.storage
          .from(_storageBucketName)
          .getPublicUrl(storagePath);

      return response;
    } catch (e) {
      debugPrint('Error getting public URL: $e');
      rethrow;
    }
  }

  /// Upload a prescription file and attach it to an appointment
  Future<String> uploadPrescription(
    String filePath,
    String appointmentId,
  ) async {
    try {
      // Upload the file to the prescriptions folder
      final storagePath = 'prescriptions/$appointmentId';
      final fileUrl = await uploadFile(filePath, storagePath);

      // Update the appointment with the prescription URL
      await _supabaseClient
          .from('appointments')
          .update({'prescription_url': fileUrl})
          .eq('id', appointmentId);

      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading prescription: $e');
      rethrow;
    }
  }

  /// Upload a profile image and update the user's profile
  Future<String> uploadProfileImage(String filePath, String userId) async {
    try {
      // Upload the file to the profile_images folder
      final storagePath = 'profile_images/$userId';
      final fileUrl = await uploadFile(filePath, storagePath);

      // Update the user's profile with the new image URL
      await _supabaseClient
          .from('users')
          .update({'profile_image': fileUrl})
          .eq('id', userId);

      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Upload a profile image from bytes and update the user's profile
  Future<String> uploadProfileImageFromBytes(
    List<int> bytes,
    String userId,
    String fileExtension,
  ) async {
    try {
      // Upload the file to the profile_images folder
      final storagePath = 'profile_images/$userId';
      final fileUrl = await uploadFileFromBytes(
        bytes,
        storagePath,
        fileExtension,
      );

      // Update the user's profile with the new image URL
      await _supabaseClient
          .from('users')
          .update({'profile_image': fileUrl})
          .eq('id', userId);

      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading profile image from bytes: $e');
      rethrow;
    }
  }

  /// Get the prescription URL for an appointment
  Future<String?> getPrescriptionUrl(String appointmentId) async {
    try {
      final response =
          await _supabaseClient
              .from('appointments')
              .select('prescription_url')
              .eq('id', appointmentId)
              .single();

      return response['prescription_url'];
    } catch (e) {
      debugPrint('Error getting prescription URL: $e');
      return null;
    }
  }

  // ==================== DOCTOR TIME SLOTS MANAGEMENT ====================

  /// Get available days for a doctor
  Future<List<String>> getDoctorAvailableDays(String doctorId) async {
    try {
      final response = await _supabaseClient
          .from('doctor_available_days')
          .select('day')
          .eq('doctor_id', doctorId);

      return response.map<String>((item) => item['day'] as String).toList();
    } catch (e) {
      debugPrint('Error getting doctor available days: $e');
      rethrow;
    }
  }

  /// Add available day for a doctor
  Future<void> addDoctorAvailableDay(String doctorId, String day) async {
    try {
      // Check if day already exists
      final existingDay =
          await _supabaseClient
              .from('doctor_available_days')
              .select()
              .eq('doctor_id', doctorId)
              .eq('day', day)
              .maybeSingle();

      if (existingDay != null) {
        // Day already exists, no need to add
        return;
      }

      // Add new available day
      await _supabaseClient.from('doctor_available_days').insert({
        'doctor_id': doctorId,
        'day': day,
      });
    } catch (e) {
      debugPrint('Error adding doctor available day: $e');
      rethrow;
    }
  }

  /// Remove available day for a doctor
  Future<void> removeDoctorAvailableDay(String doctorId, String day) async {
    try {
      await _supabaseClient
          .from('doctor_available_days')
          .delete()
          .eq('doctor_id', doctorId)
          .eq('day', day);
    } catch (e) {
      debugPrint('Error removing doctor available day: $e');
      rethrow;
    }
  }

  /// Get time slots for a doctor on a specific day
  Future<List<Map<String, dynamic>>> getDoctorTimeSlots(
    String doctorId,
    String day,
  ) async {
    try {
      final response = await _supabaseClient
          .from('doctor_time_slots')
          .select('*')
          .eq('doctor_id', doctorId)
          .eq('day', day);

      return response
          .map<Map<String, dynamic>>(
            (item) => {
              'id': item['id'],
              'timeSlot': item['time_slot'],
              'isAvailable': item['is_available'],
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor time slots: $e');
      rethrow;
    }
  }

  /// Add time slot for a doctor
  Future<void> addDoctorTimeSlot(
    String doctorId,
    String day,
    String timeSlot,
    bool isAvailable,
  ) async {
    try {
      // Check if time slot already exists
      final existingTimeSlot =
          await _supabaseClient
              .from('doctor_time_slots')
              .select()
              .eq('doctor_id', doctorId)
              .eq('day', day)
              .eq('time_slot', timeSlot)
              .maybeSingle();

      if (existingTimeSlot != null) {
        // Time slot already exists, update availability
        await _supabaseClient
            .from('doctor_time_slots')
            .update({'is_available': isAvailable})
            .eq('id', existingTimeSlot['id']);
        return;
      }

      // Add new time slot
      await _supabaseClient.from('doctor_time_slots').insert({
        'doctor_id': doctorId,
        'day': day,
        'time_slot': timeSlot,
        'is_available': isAvailable,
      });
    } catch (e) {
      debugPrint('Error adding doctor time slot: $e');
      rethrow;
    }
  }

  /// Update time slot availability for a doctor
  Future<void> updateDoctorTimeSlotAvailability(
    String timeSlotId,
    bool isAvailable,
  ) async {
    try {
      await _supabaseClient
          .from('doctor_time_slots')
          .update({'is_available': isAvailable})
          .eq('id', timeSlotId);
    } catch (e) {
      debugPrint('Error updating doctor time slot availability: $e');
      rethrow;
    }
  }

  /// Remove time slot for a doctor
  Future<void> removeDoctorTimeSlot(String timeSlotId) async {
    try {
      await _supabaseClient
          .from('doctor_time_slots')
          .delete()
          .eq('id', timeSlotId);
    } catch (e) {
      debugPrint('Error removing doctor time slot: $e');
      rethrow;
    }
  }

  /// Get all time slots for a doctor
  Future<Map<String, List<String>>> getAllDoctorTimeSlots(
    String doctorId,
  ) async {
    try {
      // Get all available days
      final days = await getDoctorAvailableDays(doctorId);

      // Create a map to store time slots for each day
      Map<String, List<String>> timeSlots = {};

      // Get time slots for each day
      for (final day in days) {
        final slots = await getDoctorTimeSlots(doctorId, day);
        final availableSlots =
            slots
                .where((slot) => slot['isAvailable'])
                .map((slot) => slot['timeSlot'] as String)
                .toList();

        if (availableSlots.isNotEmpty) {
          timeSlots[day] = availableSlots;
        }
      }

      return timeSlots;
    } catch (e) {
      debugPrint('Error getting all doctor time slots: $e');
      rethrow;
    }
  }

  // ==================== DOCTOR QUALIFICATIONS MANAGEMENT ====================

  /// Get qualifications for a doctor
  Future<List<String>> getDoctorQualifications(String doctorId) async {
    try {
      final response = await _supabaseClient
          .from('doctor_qualifications')
          .select('qualification')
          .eq('doctor_id', doctorId);

      return response
          .map<String>((item) => item['qualification'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor qualifications: $e');
      rethrow;
    }
  }

  /// Add qualification for a doctor
  Future<void> addDoctorQualification(
    String doctorId,
    String qualification,
  ) async {
    try {
      // Check if qualification already exists
      final existingQualification =
          await _supabaseClient
              .from('doctor_qualifications')
              .select()
              .eq('doctor_id', doctorId)
              .eq('qualification', qualification)
              .maybeSingle();

      if (existingQualification != null) {
        // Qualification already exists, no need to add
        return;
      }

      // Add new qualification
      await _supabaseClient.from('doctor_qualifications').insert({
        'doctor_id': doctorId,
        'qualification': qualification,
      });
    } catch (e) {
      debugPrint('Error adding doctor qualification: $e');
      rethrow;
    }
  }

  /// Remove qualification for a doctor
  Future<void> removeDoctorQualification(
    String doctorId,
    String qualification,
  ) async {
    try {
      await _supabaseClient
          .from('doctor_qualifications')
          .delete()
          .eq('doctor_id', doctorId)
          .eq('qualification', qualification);
    } catch (e) {
      debugPrint('Error removing doctor qualification: $e');
      rethrow;
    }
  }

  /// Update doctor qualifications (replace all)
  Future<void> updateDoctorQualifications(
    String doctorId,
    List<String> qualifications,
  ) async {
    try {
      // Delete all existing qualifications
      await _supabaseClient
          .from('doctor_qualifications')
          .delete()
          .eq('doctor_id', doctorId);

      // Add new qualifications
      if (qualifications.isNotEmpty) {
        await _supabaseClient
            .from('doctor_qualifications')
            .insert(
              qualifications
                  .map(
                    (qualification) => {
                      'doctor_id': doctorId,
                      'qualification': qualification,
                    },
                  )
                  .toList(),
            );
      }
    } catch (e) {
      debugPrint('Error updating doctor qualifications: $e');
      rethrow;
    }
  }

  // ==================== DOCTOR LANGUAGES MANAGEMENT ====================

  /// Get languages for a doctor
  Future<List<String>> getDoctorLanguages(String doctorId) async {
    try {
      final response = await _supabaseClient
          .from('doctor_languages')
          .select('language')
          .eq('doctor_id', doctorId);

      return response
          .map<String>((item) => item['language'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error getting doctor languages: $e');
      rethrow;
    }
  }

  /// Update doctor languages (replace all)
  Future<void> updateDoctorLanguages(
    String doctorId,
    List<String> languages,
  ) async {
    try {
      // Delete all existing languages
      await _supabaseClient
          .from('doctor_languages')
          .delete()
          .eq('doctor_id', doctorId);

      // Add new languages
      if (languages.isNotEmpty) {
        await _supabaseClient
            .from('doctor_languages')
            .insert(
              languages
                  .map(
                    (language) => {'doctor_id': doctorId, 'language': language},
                  )
                  .toList(),
            );
      }
    } catch (e) {
      debugPrint('Error updating doctor languages: $e');
      rethrow;
    }
  }

  // ==================== DOCTOR VERIFICATION MANAGEMENT ====================

  /// Upload a verification document for a doctor
  Future<String> uploadVerificationDocument(
    String filePath,
    String doctorId,
    String documentType,
  ) async {
    try {
      // Upload the file to the verification_documents folder
      final storagePath = 'verification_documents/$doctorId';
      final fileUrl = await uploadFile(filePath, storagePath);

      // Add the document to the doctor_verification_documents table
      await _supabaseClient.from('doctor_verification_documents').insert({
        'doctor_id': doctorId,
        'document_type': documentType,
        'document_url': fileUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      // Update the doctor's verification status to 'pending'
      await updateDoctorVerificationStatus(doctorId, 'pending');

      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading verification document: $e');
      rethrow;
    }
  }

  /// Update doctor verification status
  Future<bool> updateDoctorVerificationStatus(
    String doctorId,
    String status, {
    String? rejectionReason,
    String? verifiedBy,
  }) async {
    try {
      debugPrint(
        'SupabaseService: Updating doctor verification status for doctor $doctorId to $status',
      );

      // Check if the doctor exists in the doctors_profile table
      bool doctorExists = true;
      try {
        // First, check if the doctor exists
        final doctorCheck =
            await _supabaseClient
                .from('doctors_profile')
                .select('id, verification_status')
                .eq('id', doctorId)
                .single();

        debugPrint(
          'SupabaseService: Doctor check result: ${doctorCheck.toString()}',
        );
      } catch (e) {
        debugPrint(
          'SupabaseService: Doctor not found in doctors_profile table: $e',
        );
        doctorExists = false;
      }

      // If doctor doesn't exist in the new profile table, check if they exist in the old table
      if (!doctorExists) {
        debugPrint(
          'SupabaseService: Doctor not found in doctors_profile table, checking old doctors table',
        );
        try {
          final oldDoctorData =
              await _supabaseClient
                  .from('doctors')
                  .select('*')
                  .eq('id', doctorId)
                  .single();

          // If found in old table, migrate to new table
          debugPrint(
            'SupabaseService: Doctor found in old table, migrating to new table',
          );

          await _supabaseClient.from('doctors_profile').insert({
            'id': doctorId,
            'specialization':
                oldDoctorData['specialization'] ?? 'General Practitioner',
            'hospital': oldDoctorData['hospital'] ?? '',
            'license_number': oldDoctorData['license_number'] ?? '',
            'experience': oldDoctorData['experience'] ?? 0,
            'rating': oldDoctorData['rating'] ?? 0,
            'consultation_fee': oldDoctorData['consultation_fee'] ?? 0,
            'is_available_for_chat':
                oldDoctorData['is_available_for_chat'] ?? false,
            'is_available_for_video':
                oldDoctorData['is_available_for_video'] ?? false,
            'verification_status': 'pending',
            'about': oldDoctorData['about'] ?? '',
            'city': oldDoctorData['city'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          doctorExists = true;
          debugPrint(
            'SupabaseService: Successfully migrated doctor to new profile table',
          );
        } catch (migrationError) {
          debugPrint(
            'SupabaseService: Error migrating doctor: $migrationError',
          );
        }
      }

      // Get all doctors to check verification statuses
      final allDoctors = await _supabaseClient
          .from('doctors_profile')
          .select('id, verification_status');

      debugPrint(
        'SupabaseService: All doctors in database: ${allDoctors.length}',
      );

      // Log each doctor's verification status
      for (var doctor in allDoctors) {
        debugPrint(
          'SupabaseService: Doctor ID: ${doctor['id']}, Status: ${doctor['verification_status']}',
        );
      }

      // Ensure consistent case for verification status
      String normalizedStatus = status.toLowerCase();
      debugPrint(
        'SupabaseService: Normalizing status from "$status" to "$normalizedStatus"',
      );

      final Map<String, dynamic> updateData = {
        'verification_status': normalizedStatus,
        'verification_date': DateTime.now().toIso8601String(),
      };

      if (rejectionReason != null) {
        updateData['rejection_reason'] = rejectionReason;
      } else if (normalizedStatus == 'approved') {
        // Clear rejection reason when approving
        updateData['rejection_reason'] = null;
      }

      if (verifiedBy != null) {
        updateData['verified_by'] = verifiedBy;
      } else {
        // Use current user ID if available
        final currentUser = _supabaseClient.auth.currentUser;
        if (currentUser != null) {
          updateData['verified_by'] = currentUser.id;
        }
      }

      // Try direct update with retry mechanism
      int retryCount = 0;
      bool updateSuccess = false;
      Exception? lastError;

      while (!updateSuccess && retryCount < 3) {
        try {
          retryCount++;

          // Update the doctor's verification status in the doctors_profile table
          await _supabaseClient
              .from('doctors_profile')
              .update(updateData)
              .eq('id', doctorId);

          // Verify the update was successful
          final verifyUpdate =
              await _supabaseClient
                  .from('doctors_profile')
                  .select('verification_status, rejection_reason')
                  .eq('id', doctorId)
                  .single();

          debugPrint(
            'SupabaseService: Verification after update (attempt $retryCount): ${verifyUpdate.toString()}',
          );

          if (verifyUpdate['verification_status'].toString().toLowerCase() ==
              normalizedStatus) {
            debugPrint(
              'SupabaseService: Update successful on attempt $retryCount',
            );
            updateSuccess = true;
            break;
          } else {
            debugPrint(
              'SupabaseService: Update did not take effect on attempt $retryCount. Expected: $normalizedStatus, Got: ${verifyUpdate['verification_status']}',
            );
            await Future.delayed(Duration(milliseconds: 500));
          }
        } catch (e) {
          lastError = e as Exception;
          debugPrint(
            'SupabaseService: Error updating doctor status (attempt $retryCount): $e',
          );
          await Future.delayed(Duration(milliseconds: 500));
        }
      }

      if (!updateSuccess && lastError != null) {
        throw lastError;
      }

      return updateSuccess;
    } catch (e) {
      debugPrint(
        'SupabaseService: Error updating doctor verification status: $e',
      );
      return false;
    }
  }

  /// Fix data integrity issues by creating missing user records for doctors
  Future<bool> fixDoctorUserRecords(List<String> doctorIds) async {
    try {
      debugPrint('==== DATA INTEGRITY FIX ====');
      debugPrint(
        'Attempting to fix data integrity for ${doctorIds.length} doctors',
      );
      debugPrint('Doctor IDs to fix: $doctorIds');

      int successCount = 0;
      List<String> failedIds = [];
      List<String> createdIds = [];
      List<String> updatedIds = [];

      for (final doctorId in doctorIds) {
        try {
          // Get doctor details to use for creating a better user record
          Map<String, dynamic>? doctorDetails;
          try {
            doctorDetails =
                await _supabaseClient
                    .from('doctors')
                    .select('specialization, hospital, verification_status')
                    .eq('id', doctorId)
                    .single();

            debugPrint(
              'Found doctor details for ID: $doctorId - ${doctorDetails.toString()}',
            );
          } catch (e) {
            debugPrint('Error getting doctor details: $e');
            // Continue anyway, we'll use default values
          }

          // Check if user record already exists
          final existingUser =
              await _supabaseClient
                  .from('users')
                  .select()
                  .eq('id', doctorId)
                  .maybeSingle();

          if (existingUser != null) {
            debugPrint('User record already exists for doctor ID: $doctorId');

            // If user exists but user_type is not doctor, update it
            if (existingUser['user_type'] != 'doctor') {
              await _supabaseClient
                  .from('users')
                  .update({'user_type': 'doctor'})
                  .eq('id', doctorId);
              debugPrint('Updated user_type to doctor for ID: $doctorId');
              updatedIds.add(doctorId);
            }

            successCount++;
            continue;
          }

          // Create a new user record for this doctor
          String specialization =
              doctorDetails?['specialization'] ?? 'General Practitioner';

          // Create a better default name based on specialization
          String defaultName = 'Dr. ${specialization.split(' ').first}';

          // Use RPC function to bypass RLS
          // This requires creating a stored procedure in Supabase
          try {
            // First try using an RPC function that has admin privileges
            await _supabaseClient.rpc(
              'admin_create_user_for_doctor',
              params: {
                'doctor_id': doctorId,
                'user_name': defaultName,
                'user_email': 'doctor_${doctorId.substring(0, 8)}@example.com',
              },
            );
            debugPrint('Created user record via RPC for doctor ID: $doctorId');
          } catch (rpcError) {
            debugPrint('RPC error: $rpcError');

            // Fallback: Try to create a temporary auth user and link it
            try {
              // Generate a random password
              final password = 'Temp${DateTime.now().millisecondsSinceEpoch}';
              final email = 'doctor_${doctorId.substring(0, 8)}@example.com';

              // Create a user in auth
              final authResponse = await _supabaseClient.auth.signUp(
                email: email,
                password: password,
              );

              if (authResponse.user != null) {
                // Now try to update the user ID to match the doctor ID
                await _supabaseClient.rpc(
                  'admin_update_user_id',
                  params: {'old_id': authResponse.user!.id, 'new_id': doctorId},
                );

                // Update user metadata
                await _supabaseClient.rpc(
                  'admin_update_user_type',
                  params: {'user_id': doctorId, 'user_type': 'doctor'},
                );

                debugPrint(
                  'Created user via auth API for doctor ID: $doctorId',
                );
              } else {
                throw Exception('Failed to create auth user');
              }
            } catch (authError) {
              debugPrint('Auth API error: $authError');
              throw Exception('Failed to create user record: $authError');
            }
          }

          debugPrint('Created new user record for doctor ID: $doctorId');
          createdIds.add(doctorId);
          successCount++;
        } catch (e) {
          final errorMsg =
              'Failed to fix user record for doctor ID: $doctorId - Error: $e';
          debugPrint('==== ERROR ====');
          debugPrint(errorMsg);
          debugPrint('===============');
          failedIds.add(doctorId);
        }
      }

      debugPrint('==== FIX SUMMARY ====');
      debugPrint('Fixed $successCount/${doctorIds.length} doctor records');
      debugPrint('Created ${createdIds.length} new user records: $createdIds');
      debugPrint(
        'Updated ${updatedIds.length} existing user records: $updatedIds',
      );

      if (failedIds.isNotEmpty) {
        debugPrint('Failed to fix ${failedIds.length} records: $failedIds');
      }
      debugPrint('=====================');

      return successCount > 0;
    } catch (e) {
      final errorMsg = 'Error fixing doctor user records: $e';
      debugPrint('==== ERROR ====');
      debugPrint(errorMsg);
      debugPrint('===============');
      return false;
    }
  }

  /// Automatically detect and fix all doctor-user integrity issues
  Future<Map<String, dynamic>> autoFixDoctorUserIntegrity() async {
    try {
      debugPrint('==== AUTO DATA INTEGRITY FIX ====');
      debugPrint('Starting automatic data integrity fix process');

      // 1. Get all doctors
      final allDoctors = await _supabaseClient
          .from('doctors')
          .select('id, verification_status');

      if (allDoctors.isEmpty) {
        debugPrint('No doctors found in the database');
        return {
          'success': false,
          'message': 'No doctors found in the database',
          'fixed_count': 0,
          'total_count': 0,
        };
      }

      final doctorIds = allDoctors.map((d) => d['id'].toString()).toList();
      debugPrint('Found ${doctorIds.length} doctors in the database');

      // Log each doctor's ID and verification status
      for (var doctor in allDoctors) {
        debugPrint(
          'Doctor ID: ${doctor['id']}, Status: ${doctor['verification_status'] ?? 'null'}',
        );
      }

      // 2. Get all users with these doctor IDs
      final existingUsers = await _supabaseClient
          .from('users')
          .select('id, user_type')
          .filter('id', 'in', doctorIds);

      debugPrint(
        'Found ${existingUsers.length} existing user records for doctors',
      );

      // 3. Identify doctors without corresponding user records
      final existingUserIds =
          existingUsers.map((u) => u['id'].toString()).toSet();
      final missingUserIds =
          doctorIds.where((id) => !existingUserIds.contains(id)).toList();

      debugPrint('Found ${missingUserIds.length} doctors without user records');
      if (missingUserIds.isNotEmpty) {
        debugPrint('Missing user records for doctor IDs: $missingUserIds');
      }

      // 4. Identify users with incorrect user_type
      final incorrectTypeUsers =
          existingUsers.where((u) => u['user_type'] != 'doctor').toList();
      final incorrectTypeIds =
          incorrectTypeUsers.map((u) => u['id'].toString()).toList();

      debugPrint(
        'Found ${incorrectTypeIds.length} users with incorrect user_type',
      );
      if (incorrectTypeIds.isNotEmpty) {
        debugPrint('Incorrect user_type for doctor IDs: $incorrectTypeIds');
      }

      // 5. Combine both lists for fixing
      final idsToFix = [...missingUserIds, ...incorrectTypeIds];

      if (idsToFix.isEmpty) {
        debugPrint('No data integrity issues found to fix');
        return {
          'success': true,
          'message': 'No data integrity issues found',
          'fixed_count': 0,
          'total_count': doctorIds.length,
        };
      }

      // 6. Fix the issues
      await fixDoctorUserRecords(idsToFix);

      // 7. Verify the fix
      final verifyUsers = await _supabaseClient
          .from('users')
          .select('id, user_type')
          .filter('id', 'in', doctorIds);

      final verifyDoctorUserIds =
          verifyUsers
              .where((u) => u['user_type'] == 'doctor')
              .map((u) => u['id'].toString())
              .toSet();

      final stillMissingIds =
          doctorIds.where((id) => !verifyDoctorUserIds.contains(id)).toList();

      final success = stillMissingIds.isEmpty;

      debugPrint('==== AUTO FIX SUMMARY ====');
      debugPrint('Total doctors: ${doctorIds.length}');
      debugPrint('Issues fixed: ${idsToFix.length - stillMissingIds.length}');
      debugPrint('Success: $success');

      if (!success) {
        debugPrint(
          'Still missing user records for doctor IDs: $stillMissingIds',
        );
      }

      return {
        'success': success,
        'message':
            success
                ? 'Successfully fixed all doctor-user integrity issues'
                : 'Fixed some issues but ${stillMissingIds.length} still remain',
        'fixed_count': idsToFix.length - stillMissingIds.length,
        'total_count': doctorIds.length,
        'still_missing': stillMissingIds,
      };
    } catch (e) {
      debugPrint('Error in autoFixDoctorUserIntegrity: $e');
      return {
        'success': false,
        'message': 'Error fixing doctor-user integrity: $e',
        'fixed_count': 0,
        'total_count': 0,
      };
    }
  }

  /// Upload a verification document from bytes for a doctor
  Future<String> uploadVerificationDocumentFromBytes(
    List<int> bytes,
    String doctorId,
    String documentType,
    String fileExtension,
  ) async {
    try {
      // Upload the file to the verification_documents folder
      final storagePath = 'verification_documents/$doctorId';
      final fileUrl = await uploadFileFromBytes(
        bytes,
        storagePath,
        fileExtension,
      );

      // Add the document to the doctor_verification_documents table
      await _supabaseClient.from('doctor_verification_documents').insert({
        'doctor_id': doctorId,
        'document_type': documentType,
        'document_url': fileUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
      });

      // Update the doctor's verification status to 'pending' in the new profile table
      await _supabaseClient
          .from('doctors_profile')
          .update({'verification_status': 'pending'})
          .eq('id', doctorId);

      return fileUrl;
    } catch (e) {
      debugPrint('Error uploading verification document from bytes: $e');
      rethrow;
    }
  }

  /// Get verification documents for a doctor
  Future<List<Map<String, dynamic>>> getVerificationDocuments(
    String doctorId,
  ) async {
    try {
      final response = await _supabaseClient
          .from('doctor_verification_documents')
          .select('*')
          .eq('doctor_id', doctorId);

      return response
          .map<Map<String, dynamic>>(
            (item) => {
              'id': item['id'],
              'documentType': item['document_type'],
              'documentUrl': item['document_url'],
              'uploadedAt': DateTime.parse(item['uploaded_at']),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting verification documents: $e');
      rethrow;
    }
  }

  // ==================== DOCTOR PROFILE MANAGEMENT ====================

  /// Update doctor profile
  Future<void> updateDoctorProfile(DoctorModel doctor) async {
    try {
      // Update doctor information in the doctors_profile table
      await _supabaseClient
          .from('doctors_profile')
          .update({
            'specialization': doctor.specialization,
            'hospital': doctor.hospital,
            'city': doctor.city,
            'experience': doctor.experience,
            'about': doctor.about,
            'consultation_fee': doctor.consultationFee,
            'is_available_for_chat': doctor.isAvailableForChat,
            'is_available_for_video': doctor.isAvailableForVideo,
          })
          .eq('id', doctor.id);

      // Update user information in the users table
      await _supabaseClient
          .from('users')
          .update({'name': doctor.name, 'profile_image': doctor.profileImage})
          .eq('id', doctor.id);

      // Update qualifications
      if (doctor.qualifications != null) {
        await updateDoctorQualifications(doctor.id, doctor.qualifications!);
      }

      // Update languages
      if (doctor.languages != null) {
        await updateDoctorLanguages(doctor.id, doctor.languages!);
      }

      // Update available days and time slots
      if (doctor.availableDays != null && doctor.availableTimeSlots != null) {
        // First, get current available days
        final currentDays = await getDoctorAvailableDays(doctor.id);

        // Remove days that are no longer available
        for (final day in currentDays) {
          if (!doctor.availableDays!.contains(day)) {
            await removeDoctorAvailableDay(doctor.id, day);
          }
        }

        // Add new available days
        for (final day in doctor.availableDays!) {
          await addDoctorAvailableDay(doctor.id, day);
        }

        // Update time slots for each day
        for (final day in doctor.availableDays!) {
          if (doctor.availableTimeSlots!.containsKey(day)) {
            // Get current time slots for this day
            final currentSlots = await getDoctorTimeSlots(doctor.id, day);

            // Add new time slots
            for (final timeSlot in doctor.availableTimeSlots![day]!) {
              await addDoctorTimeSlot(doctor.id, day, timeSlot, true);
            }

            // Remove time slots that are no longer available
            for (final slot in currentSlots) {
              if (!doctor.availableTimeSlots![day]!.contains(
                slot['timeSlot'],
              )) {
                await removeDoctorTimeSlot(slot['id']);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating doctor profile: $e');
      rethrow;
    }
  }

  // ==================== VIDEO CALL MANAGEMENT ====================

  /// Create a new video call
  Future<Map<String, dynamic>> createVideoCall({
    required String callerId,
    required String receiverId,
    String? appointmentId,
    String? notes,
  }) async {
    try {
      // Generate a unique channel name
      final channelName = 'channel_${DateTime.now().millisecondsSinceEpoch}';

      // Generate a token (in a real app, this would be generated by your token server)
      final callToken = 'token_${DateTime.now().millisecondsSinceEpoch}';

      // Insert the call record
      final response =
          await _supabaseClient
              .from('video_calls')
              .insert({
                'caller_id': callerId,
                'receiver_id': receiverId,
                'appointment_id': appointmentId,
                'call_token': callToken,
                'channel_name': channelName,
                'status': 'initiated',
                'notes': notes,
              })
              .select()
              .single();

      return {
        'id': response['id'],
        'callToken': callToken,
        'channelName': channelName,
      };
    } catch (e) {
      debugPrint('Error creating video call: $e');
      rethrow;
    }
  }

  /// Update video call status
  Future<void> updateVideoCallStatus({
    required String callId,
    required String status,
    DateTime? endTime,
    int? duration,
  }) async {
    try {
      final Map<String, dynamic> updateData = {'status': status};

      if (endTime != null) {
        updateData['end_time'] = endTime.toIso8601String();
      }

      if (duration != null) {
        updateData['duration'] = duration;
      }

      await _supabaseClient
          .from('video_calls')
          .update(updateData)
          .eq('id', callId);
    } catch (e) {
      debugPrint('Error updating video call status: $e');
      rethrow;
    }
  }

  /// Get video calls for a user
  Future<List<Map<String, dynamic>>> getUserVideoCalls(String userId) async {
    try {
      final response = await _supabaseClient
          .from('video_calls')
          .select('*, appointments(*)')
          .or('caller_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      return response.map<Map<String, dynamic>>((call) {
        return {
          'id': call['id'],
          'appointmentId': call['appointment_id'],
          'callerId': call['caller_id'],
          'receiverId': call['receiver_id'],
          'callToken': call['call_token'],
          'channelName': call['channel_name'],
          'startTime': call['start_time'],
          'endTime': call['end_time'],
          'duration': call['duration'],
          'status': call['status'],
          'notes': call['notes'],
          'createdAt': call['created_at'],
          'appointment': call['appointments'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting user video calls: $e');
      rethrow;
    }
  }

  /// Get video call by ID
  Future<Map<String, dynamic>?> getVideoCallById(String callId) async {
    try {
      final response =
          await _supabaseClient
              .from('video_calls')
              .select('*, appointments(*)')
              .eq('id', callId)
              .maybeSingle();

      if (response == null) {
        return null;
      }

      return {
        'id': response['id'],
        'appointmentId': response['appointment_id'],
        'callerId': response['caller_id'],
        'receiverId': response['receiver_id'],
        'callToken': response['call_token'],
        'channelName': response['channel_name'],
        'startTime': response['start_time'],
        'endTime': response['end_time'],
        'duration': response['duration'],
        'status': response['status'],
        'notes': response['notes'],
        'createdAt': response['created_at'],
        'appointment': response['appointments'],
      };
    } catch (e) {
      debugPrint('Error getting video call by ID: $e');
      return null;
    }
  }

  // ==================== DOCTOR DASHBOARD ANALYTICS ====================

  /// Get doctor analytics for a specific date range
  Future<List<Map<String, dynamic>>> getDoctorAnalytics(
    String doctorId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabaseClient
          .from('doctor_analytics')
          .select()
          .eq('doctor_id', doctorId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      return response.map<Map<String, dynamic>>((analytics) {
        return {
          'id': analytics['id'],
          'doctorId': analytics['doctor_id'],
          'date': analytics['date'],
          'appointmentsCount': analytics['appointments_count'],
          'completedAppointmentsCount':
              analytics['completed_appointments_count'],
          'cancelledAppointmentsCount':
              analytics['cancelled_appointments_count'],
          'newPatientsCount': analytics['new_patients_count'],
          'totalPatientsCount': analytics['total_patients_count'],
          'videoCallsCount': analytics['video_calls_count'],
          'videoCallsDuration': analytics['video_calls_duration'],
          'chatMessagesCount': analytics['chat_messages_count'],
          'averageRating': analytics['average_rating']?.toDouble() ?? 0.0,
          'reviewsCount': analytics['reviews_count'],
          'createdAt': analytics['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting doctor analytics: $e');
      rethrow;
    }
  }

  /// Get doctor analytics summary (last 30 days)
  Future<Map<String, dynamic>> getDoctorAnalyticsSummary(
    String doctorId,
  ) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final analytics = await getDoctorAnalytics(
        doctorId,
        startDate: startDate,
        endDate: endDate,
      );

      if (analytics.isEmpty) {
        return {
          'totalAppointments': 0,
          'completedAppointments': 0,
          'cancelledAppointments': 0,
          'totalPatients': 0,
          'newPatients': 0,
          'totalVideoCalls': 0,
          'totalVideoCallDuration': 0,
          'totalChatMessages': 0,
          'averageRating': 0.0,
          'totalReviews': 0,
        };
      }

      // Calculate totals
      int totalAppointments = 0;
      int completedAppointments = 0;
      int cancelledAppointments = 0;
      int newPatients = 0;
      int totalVideoCalls = 0;
      int totalVideoCallDuration = 0;
      int totalChatMessages = 0;

      for (final day in analytics) {
        totalAppointments += day['appointmentsCount'] as int;
        completedAppointments += day['completedAppointmentsCount'] as int;
        cancelledAppointments += day['cancelledAppointmentsCount'] as int;
        newPatients += day['newPatientsCount'] as int;
        totalVideoCalls += day['videoCallsCount'] as int;
        totalVideoCallDuration += day['videoCallsDuration'] as int;
        totalChatMessages += day['chatMessagesCount'] as int;
      }

      // Get latest values for some metrics
      final latestAnalytics = analytics.first;
      final totalPatients = latestAnalytics['totalPatientsCount'] as int;
      final averageRating = latestAnalytics['averageRating'] as double;
      final totalReviews = latestAnalytics['reviewsCount'] as int;

      return {
        'totalAppointments': totalAppointments,
        'completedAppointments': completedAppointments,
        'cancelledAppointments': cancelledAppointments,
        'totalPatients': totalPatients,
        'newPatients': newPatients,
        'totalVideoCalls': totalVideoCalls,
        'totalVideoCallDuration': totalVideoCallDuration,
        'totalChatMessages': totalChatMessages,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
      };
    } catch (e) {
      debugPrint('Error getting doctor analytics summary: $e');
      rethrow;
    }
  }

  /// Manually trigger analytics update for a doctor
  Future<void> updateDoctorAnalytics(String doctorId) async {
    try {
      // Get current date
      final currentDate = DateTime.now().toIso8601String().split('T')[0];

      // Check if analytics record exists for today
      final existingRecord =
          await _supabaseClient
              .from('doctor_analytics')
              .select('id')
              .eq('doctor_id', doctorId)
              .eq('date', currentDate)
              .maybeSingle();

      // Calculate analytics data
      final appointmentsCount =
          await _supabaseClient
              .from('appointments')
              .select('id')
              .eq('doctor_id', doctorId)
              .eq('appointment_date::date', currentDate)
              .count();

      final completedAppointmentsCount =
          await _supabaseClient
              .from('appointments')
              .select('id')
              .eq('doctor_id', doctorId)
              .eq('appointment_date::date', currentDate)
              .eq('status', 'completed')
              .count();

      final cancelledAppointmentsCount =
          await _supabaseClient
              .from('appointments')
              .select('id')
              .eq('doctor_id', doctorId)
              .eq('appointment_date::date', currentDate)
              .eq('status', 'cancelled')
              .count();

      final newPatientsCount =
          await _supabaseClient
              .from('doctor_patients')
              .select('id')
              .eq('doctor_id', doctorId)
              .eq('created_at::date', currentDate)
              .count();

      final totalPatientsCount =
          await _supabaseClient
              .from('doctor_patients')
              .select('id')
              .eq('doctor_id', doctorId)
              .count();

      final videoCallsCount =
          await _supabaseClient
              .from('video_calls')
              .select('id')
              .or('caller_id.eq.$doctorId,receiver_id.eq.$doctorId')
              .eq('created_at::date', currentDate)
              .count();

      final videoCallsDurationResponse = await _supabaseClient
          .from('video_calls')
          .select('duration')
          .or('caller_id.eq.$doctorId,receiver_id.eq.$doctorId')
          .eq('created_at::date', currentDate);

      int videoCallsDuration = 0;
      for (final call in videoCallsDurationResponse) {
        videoCallsDuration += (call['duration'] ?? 0) as int;
      }

      final chatMessagesCount =
          await _supabaseClient
              .from('messages')
              .select('id')
              .or('sender_id.eq.$doctorId,receiver_id.eq.$doctorId')
              .eq('created_at::date', currentDate)
              .count();

      // Get doctor rating from the new profile table
      double averageRating = 0.0;
      try {
        final doctorData =
            await _supabaseClient
                .from('doctors_profile')
                .select('rating')
                .eq('id', doctorId)
                .single();

        averageRating = doctorData['rating']?.toDouble() ?? 0.0;
      } catch (e) {
        debugPrint('Error getting doctor rating: $e');
        // Try the old table as fallback
        try {
          final oldDoctorData =
              await _supabaseClient
                  .from('doctors')
                  .select('rating')
                  .eq('id', doctorId)
                  .single();

          averageRating = oldDoctorData['rating']?.toDouble() ?? 0.0;
        } catch (fallbackError) {
          debugPrint(
            'Error getting doctor rating from old table: $fallbackError',
          );
        }
      }

      final reviewsCount =
          await _supabaseClient
              .from('doctor_reviews')
              .select('id')
              .eq('doctor_id', doctorId)
              .count();

      // Insert or update analytics record
      if (existingRecord == null) {
        await _supabaseClient.from('doctor_analytics').insert({
          'doctor_id': doctorId,
          'date': currentDate,
          'appointments_count': appointmentsCount.count,
          'completed_appointments_count': completedAppointmentsCount.count,
          'cancelled_appointments_count': cancelledAppointmentsCount.count,
          'new_patients_count': newPatientsCount.count,
          'total_patients_count': totalPatientsCount.count,
          'video_calls_count': videoCallsCount.count,
          'video_calls_duration': videoCallsDuration,
          'chat_messages_count': chatMessagesCount.count,
          'average_rating': averageRating,
          'reviews_count': reviewsCount.count,
        });
      } else {
        await _supabaseClient
            .from('doctor_analytics')
            .update({
              'appointments_count': appointmentsCount.count,
              'completed_appointments_count': completedAppointmentsCount.count,
              'cancelled_appointments_count': cancelledAppointmentsCount.count,
              'new_patients_count': newPatientsCount.count,
              'total_patients_count': totalPatientsCount.count,
              'video_calls_count': videoCallsCount.count,
              'video_calls_duration': videoCallsDuration,
              'chat_messages_count': chatMessagesCount.count,
              'average_rating': averageRating,
              'reviews_count': reviewsCount.count,
            })
            .eq('id', existingRecord['id']);
      }
    } catch (e) {
      debugPrint('Error updating doctor analytics: $e');
      rethrow;
    }
  }

  // ==================== DOCTOR RATINGS AND REVIEWS ====================

  /// Add a review for a doctor
  Future<Map<String, dynamic>> addDoctorReview({
    required String doctorId,
    required String patientId,
    String? appointmentId,
    required int rating,
    String? review,
    bool isAnonymous = false,
  }) async {
    try {
      // Insert the review
      final response =
          await _supabaseClient
              .from('doctor_reviews')
              .insert({
                'doctor_id': doctorId,
                'patient_id': patientId,
                'appointment_id': appointmentId,
                'rating': rating,
                'review': review,
                'is_anonymous': isAnonymous,
              })
              .select()
              .single();

      return {
        'id': response['id'],
        'doctorId': response['doctor_id'],
        'patientId': response['patient_id'],
        'appointmentId': response['appointment_id'],
        'rating': response['rating'],
        'review': response['review'],
        'isAnonymous': response['is_anonymous'],
        'isVerified': response['is_verified'],
        'createdAt': response['created_at'],
      };
    } catch (e) {
      debugPrint('Error adding doctor review: $e');
      rethrow;
    }
  }

  /// Update a doctor review
  Future<void> updateDoctorReview({
    required String reviewId,
    required int rating,
    String? review,
    bool? isAnonymous,
  }) async {
    try {
      final Map<String, dynamic> updateData = {'rating': rating};

      if (review != null) {
        updateData['review'] = review;
      }

      if (isAnonymous != null) {
        updateData['is_anonymous'] = isAnonymous;
      }

      await _supabaseClient
          .from('doctor_reviews')
          .update(updateData)
          .eq('id', reviewId);
    } catch (e) {
      debugPrint('Error updating doctor review: $e');
      rethrow;
    }
  }

  /// Get reviews for a doctor
  Future<List<Map<String, dynamic>>> getDoctorReviews(String doctorId) async {
    try {
      final response = await _supabaseClient
          .from('doctor_reviews')
          .select('*, appointments(*)')
          .eq('doctor_id', doctorId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> reviews = [];

      for (final reviewData in response) {
        // Get patient data if not anonymous
        String? patientName;
        String? patientImage;

        if (reviewData['is_anonymous'] == false) {
          try {
            final patientData =
                await _supabaseClient
                    .from('users')
                    .select('name, profile_image')
                    .eq('id', reviewData['patient_id'])
                    .single();

            patientName = patientData['name'];
            patientImage = patientData['profile_image'];
          } catch (e) {
            debugPrint('Error getting patient data for review: $e');
          }
        }

        reviews.add({
          'id': reviewData['id'],
          'doctorId': reviewData['doctor_id'],
          'patientId': reviewData['patient_id'],
          'appointmentId': reviewData['appointment_id'],
          'rating': reviewData['rating'],
          'review': reviewData['review'],
          'isAnonymous': reviewData['is_anonymous'],
          'isVerified': reviewData['is_verified'],
          'createdAt': reviewData['created_at'],
          'patientName': patientName,
          'patientImage': patientImage,
          'appointmentDate':
              reviewData['appointments'] != null
                  ? reviewData['appointments']['appointment_date']
                  : null,
        });
      }

      return reviews;
    } catch (e) {
      debugPrint('Error getting doctor reviews: $e');
      rethrow;
    }
  }

  /// Get patient's reviews
  Future<List<Map<String, dynamic>>> getPatientReviews(String patientId) async {
    try {
      final response = await _supabaseClient
          .from('doctor_reviews')
          .select('*, appointments(*)')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> reviews = [];

      for (final reviewData in response) {
        // Get doctor data
        String? doctorName;
        String? doctorImage;
        String? doctorSpecialization;

        try {
          final doctorUserData =
              await _supabaseClient
                  .from('users')
                  .select('name, profile_image')
                  .eq('id', reviewData['doctor_id'])
                  .single();

          final doctorData =
              await _supabaseClient
                  .from('doctors')
                  .select('specialization')
                  .eq('id', reviewData['doctor_id'])
                  .single();

          doctorName = doctorUserData['name'];
          doctorImage = doctorUserData['profile_image'];
          doctorSpecialization = doctorData['specialization'];
        } catch (e) {
          debugPrint('Error getting doctor data for review: $e');
        }

        reviews.add({
          'id': reviewData['id'],
          'doctorId': reviewData['doctor_id'],
          'patientId': reviewData['patient_id'],
          'appointmentId': reviewData['appointment_id'],
          'rating': reviewData['rating'],
          'review': reviewData['review'],
          'isAnonymous': reviewData['is_anonymous'],
          'isVerified': reviewData['is_verified'],
          'createdAt': reviewData['created_at'],
          'doctorName': doctorName,
          'doctorImage': doctorImage,
          'doctorSpecialization': doctorSpecialization,
          'appointmentDate':
              reviewData['appointments'] != null
                  ? reviewData['appointments']['appointment_date']
                  : null,
        });
      }

      return reviews;
    } catch (e) {
      debugPrint('Error getting patient reviews: $e');
      rethrow;
    }
  }

  /// Check if patient has reviewed a doctor
  Future<bool> hasPatientReviewedDoctor({
    required String patientId,
    required String doctorId,
    String? appointmentId,
  }) async {
    try {
      final query = _supabaseClient
          .from('doctor_reviews')
          .select('id')
          .eq('patient_id', patientId)
          .eq('doctor_id', doctorId);

      if (appointmentId != null) {
        query.eq('appointment_id', appointmentId);
      }

      final response = await query.maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking if patient has reviewed doctor: $e');
      return false;
    }
  }

  // ==================== DOCTOR-PATIENT RELATIONSHIP MANAGEMENT ====================

  /// Get patients for a doctor
  Future<List<UserModel>> getDoctorPatients(String doctorId) async {
    try {
      // Get all doctor-patient relationships for this doctor
      final relationships = await _supabaseClient
          .from('doctor_patients')
          .select('patient_id, relationship_type, notes')
          .eq('doctor_id', doctorId);

      if (relationships.isEmpty) {
        return [];
      }

      // Get patient IDs
      final patientIds = relationships.map((r) => r['patient_id']).toList();

      // Get patient data
      List<UserModel> patients = [];
      for (final patientId in patientIds) {
        final patient = await getUserProfile(patientId);
        if (patient != null) {
          // Add relationship info to the patient model
          final relationship = relationships.firstWhere(
            (r) => r['patient_id'] == patientId,
          );

          // Create a copy of the patient with relationship info
          final patientWithRelationship = patient.copyWith(
            additionalData: {
              'relationshipType': relationship['relationship_type'],
              'relationshipNotes': relationship['notes'],
            },
          );

          patients.add(patientWithRelationship);
        }
      }

      return patients;
    } catch (e) {
      debugPrint('Error getting doctor patients: $e');
      rethrow;
    }
  }

  /// Add a patient to a doctor's patient list
  Future<void> addDoctorPatient(
    String doctorId,
    String patientId, {
    String relationshipType = 'primary',
    String? notes,
  }) async {
    try {
      // Check if relationship already exists
      final existingRelationship =
          await _supabaseClient
              .from('doctor_patients')
              .select()
              .eq('doctor_id', doctorId)
              .eq('patient_id', patientId)
              .maybeSingle();

      if (existingRelationship != null) {
        // Update existing relationship
        await _supabaseClient
            .from('doctor_patients')
            .update({
              'relationship_type': relationshipType,
              'notes': notes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('doctor_id', doctorId)
            .eq('patient_id', patientId);
        return;
      }

      // Add new relationship
      await _supabaseClient.from('doctor_patients').insert({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'relationship_type': relationshipType,
        'notes': notes,
      });
    } catch (e) {
      debugPrint('Error adding doctor patient: $e');
      rethrow;
    }
  }

  /// Remove a patient from a doctor's patient list
  Future<void> removeDoctorPatient(String doctorId, String patientId) async {
    try {
      await _supabaseClient
          .from('doctor_patients')
          .delete()
          .eq('doctor_id', doctorId)
          .eq('patient_id', patientId);
    } catch (e) {
      debugPrint('Error removing doctor patient: $e');
      rethrow;
    }
  }

  /// Get doctors for a patient
  Future<List<DoctorModel>> getPatientDoctors(String patientId) async {
    try {
      // Get all doctor-patient relationships for this patient
      final relationships = await _supabaseClient
          .from('doctor_patients')
          .select('doctor_id, relationship_type, notes')
          .eq('patient_id', patientId);

      if (relationships.isEmpty) {
        return [];
      }

      // Get doctor IDs
      final doctorIds = relationships.map((r) => r['doctor_id']).toList();

      // Get doctor data
      List<DoctorModel> doctors = [];
      for (final doctorId in doctorIds) {
        // Get user data
        final userData =
            await _supabaseClient
                .from('users')
                .select()
                .eq('id', doctorId)
                .single();

        // Get doctor data from the new profile table
        final doctorData =
            await _supabaseClient
                .from('doctors_profile')
                .select()
                .eq('id', doctorId)
                .single();

        // Get qualifications
        final qualifications = await getDoctorQualifications(doctorId);

        // Get languages
        final languages = await getDoctorLanguages(doctorId);

        // Get available days and time slots
        final availableDays = await getDoctorAvailableDays(doctorId);
        Map<String, List<String>> availableTimeSlots = {};

        if (availableDays.isNotEmpty) {
          availableTimeSlots = await getAllDoctorTimeSlots(doctorId);
        }

        // Get relationship info
        final relationship = relationships.firstWhere(
          (r) => r['doctor_id'] == doctorId,
        );

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
          isAvailableForChat: doctorData['is_available_for_chat'] ?? false,
          isAvailableForVideo: doctorData['is_available_for_video'] ?? false,
          verificationStatus: doctorData['verification_status'] ?? 'pending',
          rejectionReason: doctorData['rejection_reason'],
          verificationDate:
              doctorData['verification_date'] != null
                  ? DateTime.parse(doctorData['verification_date'])
                  : null,
          verifiedBy: doctorData['verified_by'],
          relationshipType: relationship['relationship_type'],
          relationshipNotes: relationship['notes'],
        );

        doctors.add(doctor);
      }

      return doctors;
    } catch (e) {
      debugPrint('Error getting patient doctors: $e');
      rethrow;
    }
  }

  // ==================== REAL-TIME DATA SYNCHRONIZATION ====================

  /// Set up polling for appointment updates
  Timer? setupAppointmentPolling(
    String userId,
    Function(List<AppointmentModel>) onAppointmentsUpdated, {
    Duration interval = const Duration(seconds: 10),
  }) {
    // Set up a polling mechanism to check for appointment updates
    final timer = Timer.periodic(interval, (timer) async {
      try {
        // Get the latest appointments for the user
        final appointments = await getUserAppointments(userId);

        // Call the callback with the updated appointments
        onAppointmentsUpdated(appointments);
      } catch (e) {
        debugPrint('Error polling appointments: $e');
      }
    });

    return timer;
  }

  /// Set up polling for new messages in a chat
  Timer? setupChatPolling(
    String chatId,
    DateTime lastChecked,
    Function(List<MessageModel>) onNewMessages, {
    Duration interval = const Duration(seconds: 3),
  }) {
    // Set up a polling mechanism to check for new messages
    final timer = Timer.periodic(interval, (timer) async {
      try {
        // Get new messages since last check
        final messages = await getNewMessages(chatId, lastChecked);

        if (messages.isNotEmpty) {
          // Update last checked time
          lastChecked = messages.last.timestamp;

          // Call the callback with the new messages
          onNewMessages(messages);
        }
      } catch (e) {
        debugPrint('Error polling messages: $e');
      }
    });

    return timer;
  }
}
