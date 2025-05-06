import 'package:intl/intl.dart';

// Appointment model for storing consultation appointments
class AppointmentModel {
  final String id;
  final String userId;
  final String doctorId;
  final DateTime appointmentDate;
  final String timeSlot;
  final String type; // 'video', 'chat', 'in-person'
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String? reason;
  final List<String>? attachments; // URLs to attached files
  final String? notes;
  final double fee;
  final String? prescriptionUrl;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.type,
    required this.status,
    this.reason,
    this.attachments,
    this.notes,
    required this.fee,
    this.prescriptionUrl,
    required this.createdAt,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'doctorId': doctorId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'type': type,
      'status': status,
      'reason': reason,
      'attachments': attachments,
      'notes': notes,
      'fee': fee,
      'prescriptionUrl': prescriptionUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create model from JSON
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      userId: json['userId'],
      doctorId: json['doctorId'],
      appointmentDate: DateTime.parse(json['appointmentDate']),
      timeSlot: json['timeSlot'],
      type: json['type'],
      status: json['status'],
      reason: json['reason'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      notes: json['notes'],
      fee: json['fee'].toDouble(),
      prescriptionUrl: json['prescriptionUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Get formatted appointment date
  String get formattedDate {
    return DateFormat('EEEE, MMM dd, yyyy').format(appointmentDate);
  }

  // Get formatted fee
  String get formattedFee {
    return 'SAR ${fee.toStringAsFixed(2)}';
  }

  // Get appointment type icon
  String get typeIcon {
    switch (type) {
      case 'video':
        return 'video_call';
      case 'chat':
        return 'chat';
      case 'in-person':
        return 'person';
      default:
        return 'calendar_today';
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case 'scheduled':
        return 'blue';
      case 'completed':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Create a copy of the model with updated fields
  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? doctorId,
    DateTime? appointmentDate,
    String? timeSlot,
    String? type,
    String? status,
    String? reason,
    List<String>? attachments,
    String? notes,
    double? fee,
    String? prescriptionUrl,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      doctorId: doctorId ?? this.doctorId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      fee: fee ?? this.fee,
      prescriptionUrl: prescriptionUrl ?? this.prescriptionUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
