// Chat model for storing chat conversations
class ChatModel {
  final String id;
  final List<String> participantIds; // User IDs of participants
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String lastMessageContent;
  final String lastMessageSenderId;
  final bool hasUnreadMessages; // Whether there are unread messages for the current user
  final int unreadCount; // Number of unread messages for the current user

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.createdAt,
    required this.lastMessageAt,
    required this.lastMessageContent,
    required this.lastMessageSenderId,
    required this.hasUnreadMessages,
    required this.unreadCount,
  });

  // Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'lastMessageContent': lastMessageContent,
      'lastMessageSenderId': lastMessageSenderId,
      'hasUnreadMessages': hasUnreadMessages,
      'unreadCount': unreadCount,
    };
  }

  // Create model from JSON
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      participantIds: List<String>.from(json['participantIds']),
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      lastMessageContent: json['lastMessageContent'],
      lastMessageSenderId: json['lastMessageSenderId'],
      hasUnreadMessages: json['hasUnreadMessages'],
      unreadCount: json['unreadCount'],
    );
  }

  // Create a copy of the model with updated fields
  ChatModel copyWith({
    String? id,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessageContent,
    String? lastMessageSenderId,
    bool? hasUnreadMessages,
    int? unreadCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
