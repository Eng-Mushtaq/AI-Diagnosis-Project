// Symptom model for storing patient symptoms
class SymptomModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String description;
  final int severity; // 1-10 scale
  final int duration; // in days
  final List<String>? bodyParts;
  final List<String>? associatedFactors;
  final List<String>? images; // URLs to symptom images

  SymptomModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.description,
    required this.severity,
    required this.duration,
    this.bodyParts,
    this.associatedFactors,
    this.images,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
      'severity': severity,
      'duration': duration,
      'bodyParts': bodyParts,
      'associatedFactors': associatedFactors,
      'images': images,
    };
  }

  // Create model from JSON
  factory SymptomModel.fromJson(Map<String, dynamic> json) {
    return SymptomModel(
      id: json['id'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
      severity: json['severity'],
      duration: json['duration'],
      bodyParts: json['bodyParts'] != null
          ? List<String>.from(json['bodyParts'])
          : null,
      associatedFactors: json['associatedFactors'] != null
          ? List<String>.from(json['associatedFactors'])
          : null,
      images:
          json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  // Get severity text
  String get severityText {
    if (severity <= 3) return 'Mild';
    if (severity <= 6) return 'Moderate';
    return 'Severe';
  }

  // Create a copy of the model with updated fields
  SymptomModel copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    String? description,
    int? severity,
    int? duration,
    List<String>? bodyParts,
    List<String>? associatedFactors,
    List<String>? images,
  }) {
    return SymptomModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      duration: duration ?? this.duration,
      bodyParts: bodyParts ?? this.bodyParts,
      associatedFactors: associatedFactors ?? this.associatedFactors,
      images: images ?? this.images,
    );
  }
}
