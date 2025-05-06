// Prediction result model for storing AI analysis results
class PredictionResultModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final List<DiseaseWithProbability> diseases;
  final String? healthDataId; // Reference to health data used for prediction
  final String? symptomId; // Reference to symptom data used for prediction
  final String? recommendedAction; // e.g., "Consult a doctor", "Monitor symptoms"
  final String? urgencyLevel; // e.g., "Low", "Medium", "High"

  PredictionResultModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.diseases,
    this.healthDataId,
    this.symptomId,
    this.recommendedAction,
    this.urgencyLevel,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'diseases': diseases.map((disease) => disease.toJson()).toList(),
      'healthDataId': healthDataId,
      'symptomId': symptomId,
      'recommendedAction': recommendedAction,
      'urgencyLevel': urgencyLevel,
    };
  }

  // Create model from JSON
  factory PredictionResultModel.fromJson(Map<String, dynamic> json) {
    return PredictionResultModel(
      id: json['id'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      diseases: (json['diseases'] as List)
          .map((disease) => DiseaseWithProbability.fromJson(disease))
          .toList(),
      healthDataId: json['healthDataId'],
      symptomId: json['symptomId'],
      recommendedAction: json['recommendedAction'],
      urgencyLevel: json['urgencyLevel'],
    );
  }

  // Get top disease
  DiseaseWithProbability get topDisease {
    return diseases.first;
  }

  // Get urgency color
  String get urgencyColor {
    switch (urgencyLevel) {
      case 'Low':
        return 'green';
      case 'Medium':
        return 'orange';
      case 'High':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Create a copy of the model with updated fields
  PredictionResultModel copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    List<DiseaseWithProbability>? diseases,
    String? healthDataId,
    String? symptomId,
    String? recommendedAction,
    String? urgencyLevel,
  }) {
    return PredictionResultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      diseases: diseases ?? this.diseases,
      healthDataId: healthDataId ?? this.healthDataId,
      symptomId: symptomId ?? this.symptomId,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
    );
  }
}

// Disease with probability model
class DiseaseWithProbability {
  final String diseaseId;
  final String name;
  final double probability;
  final String? description;
  final List<String>? symptoms;
  final String? specialistType;

  DiseaseWithProbability({
    required this.diseaseId,
    required this.name,
    required this.probability,
    this.description,
    this.symptoms,
    this.specialistType,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'diseaseId': diseaseId,
      'name': name,
      'probability': probability,
      'description': description,
      'symptoms': symptoms,
      'specialistType': specialistType,
    };
  }

  // Create model from JSON
  factory DiseaseWithProbability.fromJson(Map<String, dynamic> json) {
    return DiseaseWithProbability(
      diseaseId: json['diseaseId'],
      name: json['name'],
      probability: json['probability'].toDouble(),
      description: json['description'],
      symptoms: json['symptoms'] != null
          ? List<String>.from(json['symptoms'])
          : null,
      specialistType: json['specialistType'],
    );
  }

  // Get probability as percentage
  String get probabilityPercentage {
    return '${(probability * 100).toStringAsFixed(1)}%';
  }

  // Get color based on probability
  String get probabilityColor {
    if (probability < 0.3) return 'green';
    if (probability < 0.7) return 'orange';
    return 'red';
  }
}
