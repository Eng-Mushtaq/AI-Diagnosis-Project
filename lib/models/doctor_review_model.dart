// Doctor review model for storing doctor ratings and reviews
class DoctorReviewModel {
  final String id;
  final String doctorId;
  final String patientId;
  final String? appointmentId;
  final int rating; // 1 to 5
  final String? review;
  final bool isAnonymous;
  final bool isVerified;
  final DateTime createdAt;
  
  // Additional fields for UI display
  final String? patientName;
  final String? patientImage;
  final DateTime? appointmentDate;

  DoctorReviewModel({
    required this.id,
    required this.doctorId,
    required this.patientId,
    this.appointmentId,
    required this.rating,
    this.review,
    required this.isAnonymous,
    required this.isVerified,
    required this.createdAt,
    this.patientName,
    this.patientImage,
    this.appointmentDate,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'appointmentId': appointmentId,
      'rating': rating,
      'review': review,
      'isAnonymous': isAnonymous,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'patientName': patientName,
      'patientImage': patientImage,
      'appointmentDate': appointmentDate?.toIso8601String(),
    };
  }

  // Create model from JSON
  factory DoctorReviewModel.fromJson(Map<String, dynamic> json) {
    return DoctorReviewModel(
      id: json['id'],
      doctorId: json['doctorId'],
      patientId: json['patientId'],
      appointmentId: json['appointmentId'],
      rating: json['rating'],
      review: json['review'],
      isAnonymous: json['isAnonymous'],
      isVerified: json['isVerified'],
      createdAt: DateTime.parse(json['createdAt']),
      patientName: json['patientName'],
      patientImage: json['patientImage'],
      appointmentDate: json['appointmentDate'] != null
          ? DateTime.parse(json['appointmentDate'])
          : null,
    );
  }

  // Create a copy of the model with updated fields
  DoctorReviewModel copyWith({
    String? id,
    String? doctorId,
    String? patientId,
    String? appointmentId,
    int? rating,
    String? review,
    bool? isAnonymous,
    bool? isVerified,
    DateTime? createdAt,
    String? patientName,
    String? patientImage,
    DateTime? appointmentDate,
  }) {
    return DoctorReviewModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      patientName: patientName ?? this.patientName,
      patientImage: patientImage ?? this.patientImage,
      appointmentDate: appointmentDate ?? this.appointmentDate,
    );
  }

  // Get display name based on anonymity setting
  String get displayName {
    if (isAnonymous) return 'Anonymous';
    return patientName ?? 'Patient';
  }

  // Get formatted date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  // Get formatted rating
  String get formattedRating {
    return '$rating/5';
  }
}
