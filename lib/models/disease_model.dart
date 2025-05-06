// Disease model for storing disease predictions
class DiseaseModel {
  final String id;
  final String name;
  final String description;
  final double probability; // 0.0 to 1.0
  final List<String> symptoms;
  final List<String> treatments;
  final String? specialistType; // Type of doctor to consult
  final String? riskLevel; // Low, Medium, High
  final String? additionalInfo;

  DiseaseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.probability,
    required this.symptoms,
    required this.treatments,
    this.specialistType,
    this.riskLevel,
    this.additionalInfo,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'probability': probability,
      'symptoms': symptoms,
      'treatments': treatments,
      'specialistType': specialistType,
      'riskLevel': riskLevel,
      'additionalInfo': additionalInfo,
    };
  }

  // Create model from JSON
  factory DiseaseModel.fromJson(Map<String, dynamic> json) {
    return DiseaseModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      probability: json['probability'].toDouble(),
      symptoms: List<String>.from(json['symptoms']),
      treatments: List<String>.from(json['treatments']),
      specialistType: json['specialistType'],
      riskLevel: json['riskLevel'],
      additionalInfo: json['additionalInfo'],
    );
  }

  // Get probability as percentage
  String get probabilityPercentage {
    return '${(probability * 100).toStringAsFixed(1)}%';
  }

  // Get color based on probability
  String get riskColor {
    if (probability < 0.3) return 'green';
    if (probability < 0.7) return 'orange';
    return 'red';
  }

  // Create a copy of the model with updated fields
  DiseaseModel copyWith({
    String? id,
    String? name,
    String? description,
    double? probability,
    List<String>? symptoms,
    List<String>? treatments,
    String? specialistType,
    String? riskLevel,
    String? additionalInfo,
  }) {
    return DiseaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      probability: probability ?? this.probability,
      symptoms: symptoms ?? this.symptoms,
      treatments: treatments ?? this.treatments,
      specialistType: specialistType ?? this.specialistType,
      riskLevel: riskLevel ?? this.riskLevel,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
