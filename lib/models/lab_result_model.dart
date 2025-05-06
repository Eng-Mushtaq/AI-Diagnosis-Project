import 'package:intl/intl.dart';

// Lab result model for storing medical test results
class LabResultModel {
  final String id;
  final String userId;
  final String testName;
  final DateTime testDate;
  final String labName;
  final String resultUrl; // URL to the PDF or image file
  final String? doctorId; // ID of the doctor who ordered the test
  final String status; // 'pending', 'completed', 'reviewed'
  final Map<String, dynamic>? resultValues; // Key-value pairs of test parameters
  final String? notes;
  final DateTime uploadedAt;

  LabResultModel({
    required this.id,
    required this.userId,
    required this.testName,
    required this.testDate,
    required this.labName,
    required this.resultUrl,
    this.doctorId,
    required this.status,
    this.resultValues,
    this.notes,
    required this.uploadedAt,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'testName': testName,
      'testDate': testDate.toIso8601String(),
      'labName': labName,
      'resultUrl': resultUrl,
      'doctorId': doctorId,
      'status': status,
      'resultValues': resultValues,
      'notes': notes,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  // Create model from JSON
  factory LabResultModel.fromJson(Map<String, dynamic> json) {
    return LabResultModel(
      id: json['id'],
      userId: json['userId'],
      testName: json['testName'],
      testDate: DateTime.parse(json['testDate']),
      labName: json['labName'],
      resultUrl: json['resultUrl'],
      doctorId: json['doctorId'],
      status: json['status'],
      resultValues: json['resultValues'],
      notes: json['notes'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }

  // Get formatted test date
  String get formattedTestDate {
    return DateFormat('MMM dd, yyyy').format(testDate);
  }

  // Get formatted upload date
  String get formattedUploadDate {
    return DateFormat('MMM dd, yyyy').format(uploadedAt);
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'completed':
        return 'blue';
      case 'reviewed':
        return 'green';
      default:
        return 'grey';
    }
  }

  // Get file type
  String get fileType {
    if (resultUrl.toLowerCase().endsWith('.pdf')) {
      return 'pdf';
    } else if (resultUrl.toLowerCase().endsWith('.jpg') ||
        resultUrl.toLowerCase().endsWith('.jpeg') ||
        resultUrl.toLowerCase().endsWith('.png')) {
      return 'image';
    } else {
      return 'document';
    }
  }

  // Create a copy of the model with updated fields
  LabResultModel copyWith({
    String? id,
    String? userId,
    String? testName,
    DateTime? testDate,
    String? labName,
    String? resultUrl,
    String? doctorId,
    String? status,
    Map<String, dynamic>? resultValues,
    String? notes,
    DateTime? uploadedAt,
  }) {
    return LabResultModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testName: testName ?? this.testName,
      testDate: testDate ?? this.testDate,
      labName: labName ?? this.labName,
      resultUrl: resultUrl ?? this.resultUrl,
      doctorId: doctorId ?? this.doctorId,
      status: status ?? this.status,
      resultValues: resultValues ?? this.resultValues,
      notes: notes ?? this.notes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
