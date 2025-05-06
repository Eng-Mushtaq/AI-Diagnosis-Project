import 'package:intl/intl.dart';

// Health data model for storing vital signs
class HealthDataModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double? temperature; // in Celsius
  final int? heartRate; // beats per minute
  final int? systolicBP; // mmHg
  final int? diastolicBP; // mmHg
  final int? respiratoryRate; // breaths per minute
  final double? oxygenSaturation; // percentage
  final double? bloodGlucose; // mg/dL
  final String? notes;

  HealthDataModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.temperature,
    this.heartRate,
    this.systolicBP,
    this.diastolicBP,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.bloodGlucose,
    this.notes,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'temperature': temperature,
      'heartRate': heartRate,
      'systolicBP': systolicBP,
      'diastolicBP': diastolicBP,
      'respiratoryRate': respiratoryRate,
      'oxygenSaturation': oxygenSaturation,
      'bloodGlucose': bloodGlucose,
      'notes': notes,
    };
  }

  // Create model from JSON
  factory HealthDataModel.fromJson(Map<String, dynamic> json) {
    return HealthDataModel(
      id: json['id'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      temperature: json['temperature']?.toDouble(),
      heartRate: json['heartRate'],
      systolicBP: json['systolicBP'],
      diastolicBP: json['diastolicBP'],
      respiratoryRate: json['respiratoryRate'],
      oxygenSaturation: json['oxygenSaturation']?.toDouble(),
      bloodGlucose: json['bloodGlucose']?.toDouble(),
      notes: json['notes'],
    );
  }

  // Get formatted date
  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(timestamp);
  }

  // Get formatted time
  String get formattedTime {
    return DateFormat('hh:mm a').format(timestamp);
  }

  // Get blood pressure as string
  String get bloodPressure {
    if (systolicBP != null && diastolicBP != null) {
      return '$systolicBP/$diastolicBP mmHg';
    }
    return 'N/A';
  }

  // Create a copy of the model with updated fields
  HealthDataModel copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    double? temperature,
    int? heartRate,
    int? systolicBP,
    int? diastolicBP,
    int? respiratoryRate,
    double? oxygenSaturation,
    double? bloodGlucose,
    String? notes,
  }) {
    return HealthDataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      bloodGlucose: bloodGlucose ?? this.bloodGlucose,
      notes: notes ?? this.notes,
    );
  }
}
