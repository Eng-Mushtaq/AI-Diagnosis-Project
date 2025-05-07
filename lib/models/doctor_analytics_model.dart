// Doctor analytics model for storing doctor dashboard analytics
class DoctorAnalyticsModel {
  final String id;
  final String doctorId;
  final DateTime date;
  final int appointmentsCount;
  final int completedAppointmentsCount;
  final int cancelledAppointmentsCount;
  final int newPatientsCount;
  final int totalPatientsCount;
  final int videoCallsCount;
  final int videoCallsDuration; // in seconds
  final int chatMessagesCount;
  final double averageRating;
  final int reviewsCount;
  final DateTime createdAt;

  DoctorAnalyticsModel({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.appointmentsCount,
    required this.completedAppointmentsCount,
    required this.cancelledAppointmentsCount,
    required this.newPatientsCount,
    required this.totalPatientsCount,
    required this.videoCallsCount,
    required this.videoCallsDuration,
    required this.chatMessagesCount,
    required this.averageRating,
    required this.reviewsCount,
    required this.createdAt,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'date': date.toIso8601String(),
      'appointmentsCount': appointmentsCount,
      'completedAppointmentsCount': completedAppointmentsCount,
      'cancelledAppointmentsCount': cancelledAppointmentsCount,
      'newPatientsCount': newPatientsCount,
      'totalPatientsCount': totalPatientsCount,
      'videoCallsCount': videoCallsCount,
      'videoCallsDuration': videoCallsDuration,
      'chatMessagesCount': chatMessagesCount,
      'averageRating': averageRating,
      'reviewsCount': reviewsCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create model from JSON
  factory DoctorAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return DoctorAnalyticsModel(
      id: json['id'],
      doctorId: json['doctorId'],
      date: DateTime.parse(json['date']),
      appointmentsCount: json['appointmentsCount'],
      completedAppointmentsCount: json['completedAppointmentsCount'],
      cancelledAppointmentsCount: json['cancelledAppointmentsCount'],
      newPatientsCount: json['newPatientsCount'],
      totalPatientsCount: json['totalPatientsCount'],
      videoCallsCount: json['videoCallsCount'],
      videoCallsDuration: json['videoCallsDuration'],
      chatMessagesCount: json['chatMessagesCount'],
      averageRating: json['averageRating'].toDouble(),
      reviewsCount: json['reviewsCount'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Create a copy of the model with updated fields
  DoctorAnalyticsModel copyWith({
    String? id,
    String? doctorId,
    DateTime? date,
    int? appointmentsCount,
    int? completedAppointmentsCount,
    int? cancelledAppointmentsCount,
    int? newPatientsCount,
    int? totalPatientsCount,
    int? videoCallsCount,
    int? videoCallsDuration,
    int? chatMessagesCount,
    double? averageRating,
    int? reviewsCount,
    DateTime? createdAt,
  }) {
    return DoctorAnalyticsModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      appointmentsCount: appointmentsCount ?? this.appointmentsCount,
      completedAppointmentsCount: completedAppointmentsCount ?? this.completedAppointmentsCount,
      cancelledAppointmentsCount: cancelledAppointmentsCount ?? this.cancelledAppointmentsCount,
      newPatientsCount: newPatientsCount ?? this.newPatientsCount,
      totalPatientsCount: totalPatientsCount ?? this.totalPatientsCount,
      videoCallsCount: videoCallsCount ?? this.videoCallsCount,
      videoCallsDuration: videoCallsDuration ?? this.videoCallsDuration,
      chatMessagesCount: chatMessagesCount ?? this.chatMessagesCount,
      averageRating: averageRating ?? this.averageRating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get formatted date
  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get formatted video call duration
  String get formattedVideoCallDuration {
    final hours = (videoCallsDuration ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((videoCallsDuration % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (videoCallsDuration % 60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }

  // Get appointment completion rate
  double get appointmentCompletionRate {
    if (appointmentsCount == 0) return 0.0;
    return completedAppointmentsCount / appointmentsCount;
  }

  // Get appointment cancellation rate
  double get appointmentCancellationRate {
    if (appointmentsCount == 0) return 0.0;
    return cancelledAppointmentsCount / appointmentsCount;
  }
}
