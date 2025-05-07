import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

import '../models/health_data_model.dart';
import '../models/symptom_model.dart';
import '../models/disease_model.dart';
import '../models/prediction_result_model.dart';

/// Service for providing health information using Gemini API
class GeminiHealthService extends GetxService {
  // Singleton instance
  static final GeminiHealthService _instance = GeminiHealthService._internal();
  factory GeminiHealthService() => _instance;
  GeminiHealthService._internal();
  
  // Gemini API credentials
  final String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  final String _apiKey = 'AIzaSyCNqtCG8M1i8SIKSrDu7Grmq9o0zlyPkOo';
  final String _model = 'gemini-2.0-flash';
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      debugPrint('Gemini Health Service initialized');
    } catch (e) {
      debugPrint('Error initializing Gemini Health Service: $e');
    }
  }
  
  /// Get health information based on symptoms
  Future<List<DiseaseModel>> getHealthInformation({
    required String symptomDescription,
    List<String>? bodyParts,
    int? severity,
    int? duration,
    HealthDataModel? healthData,
  }) async {
    try {
      // Create a generalized, anonymized prompt
      final String prompt = _buildHealthInfoPrompt(
        symptomDescription: symptomDescription,
        bodyParts: bodyParts,
        severity: severity,
        duration: duration,
        healthData: healthData,
      );
      
      // Make the API call to Gemini
      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Parse the health information from the response
        return _parseHealthInformation(responseData);
      } else {
        debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get health information: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting health information: $e');
      return [];
    }
  }
  
  /// Build a structured prompt for health information
  String _buildHealthInfoPrompt({
    required String symptomDescription,
    List<String>? bodyParts,
    int? severity,
    int? duration,
    HealthDataModel? healthData,
  }) {
    StringBuffer prompt = StringBuffer();
    
    prompt.writeln("You are a health information assistant providing educational content only. You are NOT providing medical diagnosis or advice.");
    prompt.writeln("\nA person is interested in learning about possible health conditions related to these symptoms:");
    prompt.writeln("- $symptomDescription");
    
    if (bodyParts != null && bodyParts.isNotEmpty) {
      prompt.writeln("- Area of the body: ${bodyParts.join(', ')}");
    }
    
    if (severity != null) {
      prompt.writeln("- Reported severity level (1-10): $severity");
    }
    
    if (duration != null) {
      prompt.writeln("- Duration of symptoms: $duration days");
    }
    
    if (healthData != null) {
      prompt.writeln("\nGeneral health metrics:");
      if (healthData.temperature != null) {
        prompt.writeln("- Temperature: ${healthData.temperature}°C");
      }
      if (healthData.heartRate != null) {
        prompt.writeln("- Heart Rate: ${healthData.heartRate} bpm");
      }
      if (healthData.systolicBP != null && healthData.diastolicBP != null) {
        prompt.writeln("- Blood Pressure: ${healthData.systolicBP}/${healthData.diastolicBP} mmHg");
      }
      if (healthData.respiratoryRate != null) {
        prompt.writeln("- Respiratory Rate: ${healthData.respiratoryRate} breaths/min");
      }
      if (healthData.oxygenSaturation != null) {
        prompt.writeln("- Oxygen Saturation: ${healthData.oxygenSaturation}%");
      }
    }
    
    prompt.writeln("\nInstructions:");
    prompt.writeln("1. Provide educational information about 3-5 possible health conditions that might be associated with these symptoms.");
    prompt.writeln("2. For each condition, include:");
    prompt.writeln("   a) Name of the condition");
    prompt.writeln("   b) Brief description");
    prompt.writeln("   c) Common symptoms");
    prompt.writeln("   d) When someone should consider seeing a doctor");
    prompt.writeln("   e) Type of doctor typically consulted for this condition");
    prompt.writeln("   f) Assign a relevance score from 0.1 to 0.9 based on how closely the condition matches the described symptoms");
    prompt.writeln("3. Format your response in a structured way using the following format for each condition:");
    prompt.writeln("CONDITION: [Name]");
    prompt.writeln("DESCRIPTION: [Brief description]");
    prompt.writeln("SYMPTOMS: [List of common symptoms]");
    prompt.writeln("WHEN_TO_SEE_DOCTOR: [When to seek medical attention]");
    prompt.writeln("SPECIALIST: [Type of doctor]");
    prompt.writeln("RELEVANCE: [Score between 0.1-0.9]");
    prompt.writeln("4. Include a clear disclaimer at the beginning and end of your response.");
    
    return prompt.toString();
  }
  
  /// Parse the health information from the Gemini API response
  List<DiseaseModel> _parseHealthInformation(Map<String, dynamic> responseData) {
    try {
      final String content = responseData['candidates'][0]['content']['parts'][0]['text'] ?? '';
      
      // Extract conditions using regex
      final List<DiseaseModel> conditions = [];
      
      // Regex to extract structured information
      final RegExp conditionRegex = RegExp(
        r'CONDITION:\s*(.*?)\s*\n'
        r'DESCRIPTION:\s*(.*?)\s*\n'
        r'SYMPTOMS:\s*(.*?)\s*\n'
        r'WHEN_TO_SEE_DOCTOR:\s*(.*?)\s*\n'
        r'SPECIALIST:\s*(.*?)\s*\n'
        r'RELEVANCE:\s*(0\.\d)',
        dotAll: true
      );
      
      final matches = conditionRegex.allMatches(content);
      
      for (final match in matches) {
        final name = match.group(1)?.trim() ?? '';
        final description = match.group(2)?.trim() ?? '';
        final symptomsText = match.group(3)?.trim() ?? '';
        final whenToSeeDoctor = match.group(4)?.trim() ?? '';
        final specialist = match.group(5)?.trim() ?? '';
        final relevanceStr = match.group(6) ?? '0.5';
        
        // Parse symptoms into a list
        final List<String> symptoms = symptomsText
            .split(RegExp(r'(?:\n|•|-)'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        
        // Parse relevance score
        double relevance = double.tryParse(relevanceStr) ?? 0.5;
        
        if (name.isNotEmpty) {
          conditions.add(DiseaseModel(
            id: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_'),
            name: name,
            description: description,
            probability: relevance,
            symptoms: symptoms,
            treatments: [whenToSeeDoctor],
            specialistType: specialist,
            riskLevel: _mapRelevanceToRiskLevel(relevance),
          ));
        }
      }
      
      // Sort by relevance (probability)
      conditions.sort((a, b) => b.probability.compareTo(a.probability));
      
      return conditions;
    } catch (e) {
      debugPrint('Error parsing health information: $e');
      return [];
    }
  }
  
  /// Map relevance score to risk level
  String _mapRelevanceToRiskLevel(double relevance) {
    if (relevance >= 0.7) return 'High';
    if (relevance >= 0.4) return 'Medium';
    return 'Low';
  }
  
  /// Create an educational health information result
  Future<PredictionResultModel?> createHealthInfoResult({
    required String userId,
    required String symptomDescription,
    required SymptomModel symptom,
    HealthDataModel? healthData,
  }) async {
    try {
      // Get health information
      final conditions = await getHealthInformation(
        symptomDescription: symptomDescription,
        bodyParts: symptom.bodyParts,
        severity: symptom.severity,
        duration: symptom.duration,
        healthData: healthData,
      );
      
      if (conditions.isEmpty) {
        return null;
      }
      
      // Convert to DiseaseWithProbability list
      final diseasesWithProbability = conditions.map((condition) {
        return DiseaseWithProbability(
          diseaseId: condition.id,
          name: condition.name,
          probability: condition.probability,
          description: condition.description,
          symptoms: condition.symptoms,
          specialistType: condition.specialistType,
        );
      }).toList();
      
      // Determine urgency level based on highest probability
      String urgencyLevel = 'Low';
      if (diseasesWithProbability.first.probability > 0.7) {
        urgencyLevel = 'High';
      } else if (diseasesWithProbability.first.probability > 0.4) {
        urgencyLevel = 'Medium';
      }
      
      // Create prediction result
      final result = PredictionResultModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        timestamp: DateTime.now(),
        diseases: diseasesWithProbability,
        healthDataId: healthData?.id,
        symptomId: symptom.id,
        recommendedAction: "This information is for educational purposes only. Please consult a healthcare professional for proper diagnosis and treatment.",
        urgencyLevel: urgencyLevel,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error creating health information result: $e');
      return null;
    }
  }
}
