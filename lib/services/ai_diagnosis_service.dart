import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/health_data_model.dart';
import '../models/symptom_model.dart';
import '../models/disease_model.dart';
import '../models/prediction_result_model.dart';

/// Service for handling AI-based medical diagnosis
class AIDiagnosisService extends GetxService {
  // Singleton instance
  static final AIDiagnosisService _instance = AIDiagnosisService._internal();
  factory AIDiagnosisService() => _instance;
  AIDiagnosisService._internal();

  // These fields will be used when implementing the actual API integration
  // For now, they're commented out to avoid unused field warnings
  // final SupabaseService _supabaseService = Get.find<SupabaseService>();
  // final String _baseUrl = 'https://api.example.com/ai-diagnosis';
  // String? _apiKey;

  // Initialize the service
  Future<void> initialize() async {
    try {
      // In a real implementation, you might fetch the API key from Supabase or secure storage
      // _apiKey = 'your-api-key';
      debugPrint('AI Diagnosis Service initialized');
    } catch (e) {
      debugPrint('Error initializing AI Diagnosis Service: $e');
    }
  }

  /// Get disease predictions based on symptoms and health data
  Future<List<DiseaseModel>> getPredictions({
    required String symptomDescription,
    List<String>? bodyParts,
    int? severity,
    int? duration,
    List<String>? associatedFactors,
    HealthDataModel? healthData,
  }) async {
    try {
      // Prepare the request data
      final Map<String, dynamic> requestData = {
        'symptom_description': symptomDescription,
        'body_parts': bodyParts,
        'severity': severity,
        'duration': duration,
        'associated_factors': associatedFactors,
      };

      // Add health data if available
      if (healthData != null) {
        requestData['health_data'] = {
          'temperature': healthData.temperature,
          'heart_rate': healthData.heartRate,
          'systolic_bp': healthData.systolicBP,
          'diastolic_bp': healthData.diastolicBP,
          'respiratory_rate': healthData.respiratoryRate,
          'oxygen_saturation': healthData.oxygenSaturation,
          'blood_glucose': healthData.bloodGlucose,
        };
      }

      // For now, use a local prediction algorithm
      // In a real implementation, you would make an API call to your AI service
      return _localPredictionAlgorithm(requestData);

      // Uncomment this code when you have a real AI service endpoint
      /*
      // Make the API call
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestData),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the response
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Convert the response to a list of DiseaseModel objects
        final List<DiseaseModel> predictions = [];
        for (final disease in responseData['predictions']) {
          predictions.add(DiseaseModel.fromJson(disease));
        }

        return predictions;
      } else {
        throw Exception('Failed to get predictions: ${response.statusCode}');
      }
      */
    } catch (e) {
      debugPrint('Error getting predictions: $e');
      return [];
    }
  }

  /// Create a prediction result based on symptoms and health data
  Future<PredictionResultModel?> createPrediction({
    required String userId,
    required String symptomDescription,
    required SymptomModel symptom,
    HealthDataModel? healthData,
  }) async {
    try {
      // Get disease predictions
      final diseases = await getPredictions(
        symptomDescription: symptomDescription,
        bodyParts: symptom.bodyParts,
        severity: symptom.severity,
        duration: symptom.duration,
        associatedFactors: symptom.associatedFactors,
        healthData: healthData,
      );

      if (diseases.isEmpty) {
        return null;
      }

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

      // Create prediction result
      final prediction = PredictionResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        timestamp: DateTime.now(),
        diseases: diseasesWithProbability,
        healthDataId: healthData?.id,
        symptomId: symptom.id,
        recommendedAction: recommendedAction,
        urgencyLevel: urgencyLevel,
      );

      // In a real implementation, you would save this to Supabase
      // await _supabaseService.savePrediction(prediction);

      return prediction;
    } catch (e) {
      debugPrint('Error creating prediction: $e');
      return null;
    }
  }

  /// Local prediction algorithm (temporary until real AI service is integrated)
  Future<List<DiseaseModel>> _localPredictionAlgorithm(
    Map<String, dynamic> data,
  ) async {
    // This is a more advanced version of the keyword matching algorithm
    // It takes into account more factors than just the symptom description

    final String description = data['symptom_description'].toLowerCase();
    final List<String>? bodyParts = data['body_parts']?.cast<String>();
    final int? severity = data['severity'];
    final Map<String, dynamic>? healthData = data['health_data'];

    final List<DiseaseModel> predictions = [];
    double probabilityModifier = 0.0;

    // Adjust probability based on severity
    if (severity != null) {
      if (severity > 7) {
        probabilityModifier += 0.1;
      } else if (severity < 3) {
        probabilityModifier -= 0.1;
      }
    }

    // Check for headache-related conditions
    if (description.contains('headache') ||
        (bodyParts != null && bodyParts.contains('Head'))) {
      // Migraine indicators
      if (description.contains('throbbing') ||
          description.contains('pulsating') ||
          description.contains('light sensitivity') ||
          description.contains('sound sensitivity') ||
          description.contains('nausea')) {
        double probability = 0.75 + probabilityModifier;

        // Adjust based on health data
        if (healthData != null) {
          if (healthData['blood_pressure'] != null &&
              healthData['systolic_bp'] > 140) {
            probability += 0.05;
          }
        }

        predictions.add(
          DiseaseModel(
            id: 'disease001',
            name: 'Migraine',
            description:
                'A neurological condition characterized by recurrent headaches that are moderate to severe.',
            probability: probability.clamp(0.0, 1.0),
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
          ),
        );
      }

      // Tension headache indicators
      if (description.contains('pressure') ||
          description.contains('tight') ||
          description.contains('band') ||
          description.contains('stress')) {
        predictions.add(
          DiseaseModel(
            id: 'disease002',
            name: 'Tension Headache',
            description:
                'The most common type of headache that causes mild to moderate pain.',
            probability: (0.60 + probabilityModifier).clamp(0.0, 1.0),
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
          ),
        );
      }

      // Sinusitis indicators
      if (description.contains('sinus') ||
          description.contains('nasal') ||
          description.contains('congestion') ||
          description.contains('facial pain') ||
          (bodyParts != null && bodyParts.contains('Nose'))) {
        predictions.add(
          DiseaseModel(
            id: 'disease003',
            name: 'Sinusitis',
            description: 'Inflammation of the sinuses, often due to infection.',
            probability: (0.45 + probabilityModifier).clamp(0.0, 1.0),
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
          ),
        );
      }
    }

    // Check for respiratory conditions
    if (description.contains('cough') ||
        description.contains('breath') ||
        description.contains('chest') ||
        (bodyParts != null &&
            (bodyParts.contains('Chest') || bodyParts.contains('Throat')))) {
      // Bronchitis indicators
      if (description.contains('cough') &&
          (description.contains('phlegm') ||
              description.contains('mucus') ||
              description.contains('chest discomfort'))) {
        double probability = 0.65 + probabilityModifier;

        // Adjust based on health data
        if (healthData != null) {
          if (healthData['temperature'] != null &&
              healthData['temperature'] > 37.5) {
            probability += 0.1;
          }
          if (healthData['respiratory_rate'] != null &&
              healthData['respiratory_rate'] > 20) {
            probability += 0.1;
          }
        }

        predictions.add(
          DiseaseModel(
            id: 'disease004',
            name: 'Bronchitis',
            description: 'Inflammation of the lining of the bronchial tubes.',
            probability: probability.clamp(0.0, 1.0),
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
          ),
        );
      }

      // Common cold indicators
      if (description.contains('runny nose') ||
          description.contains('stuffy nose') ||
          description.contains('sore throat') ||
          description.contains('sneezing')) {
        predictions.add(
          DiseaseModel(
            id: 'disease005',
            name: 'Common Cold',
            description: 'A viral infection of the upper respiratory tract.',
            probability: (0.40 + probabilityModifier).clamp(0.0, 1.0),
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
          ),
        );
      }
    }

    // If no specific conditions matched, return some general possibilities
    if (predictions.isEmpty) {
      predictions.add(
        DiseaseModel(
          id: 'disease006',
          name: 'General Fatigue',
          description:
              'Feeling of tiredness or exhaustion that can be caused by various factors.',
          probability: 0.30,
          symptoms: ['Tiredness', 'Lack of energy', 'Difficulty concentrating'],
          treatments: ['Rest', 'Proper nutrition', 'Stress management'],
          specialistType: 'General Practitioner',
          riskLevel: 'Low',
        ),
      );
    }

    // Sort by probability
    predictions.sort((a, b) => b.probability.compareTo(a.probability));

    return predictions;
  }
}
