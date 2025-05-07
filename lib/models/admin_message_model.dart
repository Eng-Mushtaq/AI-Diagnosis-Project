import 'package:flutter/foundation.dart';

/// Enum for admin message types
enum AdminMessageType {
  announcement,
  support,
  feedback,
}

/// Enum for admin message status
enum AdminMessageStatus {
  active,
  archived,
  resolved,
}

/// Model class for admin messages
class AdminMessageModel {
  final String id;
  final String title;
  final String content;
  final String senderId;
  final String? senderName;
  final String? senderProfileImage;
  final String? recipientId;
  final String? recipientName;
  final AdminMessageType type;
  final AdminMessageStatus status;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminMessageAttachment>? attachments;

  AdminMessageModel({
    required this.id,
    required this.title,
    required this.content,
    required this.senderId,
    this.senderName,
    this.senderProfileImage,
    this.recipientId,
    this.recipientName,
    required this.type,
    required this.status,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.attachments,
  });

  /// Convert message type string to enum
  static AdminMessageType typeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'announcement':
        return AdminMessageType.announcement;
      case 'support':
        return AdminMessageType.support;
      case 'feedback':
        return AdminMessageType.feedback;
      default:
        return AdminMessageType.announcement;
    }
  }

  /// Convert message type enum to string
  static String typeToString(AdminMessageType type) {
    switch (type) {
      case AdminMessageType.announcement:
        return 'announcement';
      case AdminMessageType.support:
        return 'support';
      case AdminMessageType.feedback:
        return 'feedback';
    }
  }

  /// Convert message status string to enum
  static AdminMessageStatus statusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'active':
        return AdminMessageStatus.active;
      case 'archived':
        return AdminMessageStatus.archived;
      case 'resolved':
        return AdminMessageStatus.resolved;
      default:
        return AdminMessageStatus.active;
    }
  }

  /// Convert message status enum to string
  static String statusToString(AdminMessageStatus status) {
    switch (status) {
      case AdminMessageStatus.active:
        return 'active';
      case AdminMessageStatus.archived:
        return 'archived';
      case AdminMessageStatus.resolved:
        return 'resolved';
    }
  }

  /// Create model from JSON
  factory AdminMessageModel.fromJson(Map<String, dynamic> json) {
    try {
      return AdminMessageModel(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        senderId: json['sender_id'],
        senderName: json['sender_name'],
        senderProfileImage: json['sender_profile_image'],
        recipientId: json['recipient_id'],
        recipientName: json['recipient_name'],
        type: typeFromString(json['type']),
        status: statusFromString(json['status']),
        isRead: json['is_read'] ?? false,
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        attachments: json['attachments'] != null
            ? (json['attachments'] as List)
                .map((attachment) =>
                    AdminMessageAttachment.fromJson(attachment))
                .toList()
            : null,
      );
    } catch (e) {
      debugPrint('Error parsing AdminMessageModel: $e');
      rethrow;
    }
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'type': typeToString(type),
      'status': statusToString(status),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of the model with updated fields
  AdminMessageModel copyWith({
    String? id,
    String? title,
    String? content,
    String? senderId,
    String? senderName,
    String? senderProfileImage,
    String? recipientId,
    String? recipientName,
    AdminMessageType? type,
    AdminMessageStatus? status,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AdminMessageAttachment>? attachments,
  }) {
    return AdminMessageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfileImage: senderProfileImage ?? this.senderProfileImage,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      type: type ?? this.type,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
    );
  }
}

/// Model class for admin message attachments
class AdminMessageAttachment {
  final String id;
  final String messageId;
  final String attachmentUrl;
  final String attachmentType;
  final DateTime createdAt;

  AdminMessageAttachment({
    required this.id,
    required this.messageId,
    required this.attachmentUrl,
    required this.attachmentType,
    required this.createdAt,
  });

  /// Create model from JSON
  factory AdminMessageAttachment.fromJson(Map<String, dynamic> json) {
    return AdminMessageAttachment(
      id: json['id'],
      messageId: json['message_id'],
      attachmentUrl: json['attachment_url'],
      attachmentType: json['attachment_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
