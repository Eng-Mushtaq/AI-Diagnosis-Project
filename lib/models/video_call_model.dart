// Video call model for storing video call information
class VideoCallModel {
  final String id;
  final String? appointmentId;
  final String callerId;
  final String receiverId;
  final String callToken;
  final String channelName;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration; // in seconds
  final String status; // 'initiated', 'connected', 'completed', 'missed', 'declined'
  final String? notes;
  final DateTime createdAt;

  VideoCallModel({
    required this.id,
    this.appointmentId,
    required this.callerId,
    required this.receiverId,
    required this.callToken,
    required this.channelName,
    required this.startTime,
    this.endTime,
    this.duration,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointmentId': appointmentId,
      'callerId': callerId,
      'receiverId': receiverId,
      'callToken': callToken,
      'channelName': channelName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create model from JSON
  factory VideoCallModel.fromJson(Map<String, dynamic> json) {
    return VideoCallModel(
      id: json['id'],
      appointmentId: json['appointmentId'],
      callerId: json['callerId'],
      receiverId: json['receiverId'],
      callToken: json['callToken'],
      channelName: json['channelName'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'],
      status: json['status'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Create a copy of the model with updated fields
  VideoCallModel copyWith({
    String? id,
    String? appointmentId,
    String? callerId,
    String? receiverId,
    String? callToken,
    String? channelName,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return VideoCallModel(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callToken: callToken ?? this.callToken,
      channelName: channelName ?? this.channelName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Get formatted duration
  String get formattedDuration {
    if (duration == null) return 'N/A';
    
    final minutes = (duration! ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration! % 60).toString().padLeft(2, '0');
    
    return '$minutes:$seconds';
  }

  // Get formatted status
  String get formattedStatus {
    return status.substring(0, 1).toUpperCase() + status.substring(1);
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case 'initiated':
        return 'blue';
      case 'connected':
        return 'green';
      case 'completed':
        return 'green';
      case 'missed':
        return 'orange';
      case 'declined':
        return 'red';
      default:
        return 'grey';
    }
  }
}
