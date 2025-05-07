import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/mock_data_service.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import 'dart:async';

// Message controller for managing chat and message data
class MessageController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final MockDataService _mockDataService =
      MockDataService(); // Keep for fallback

  // Observable chat list
  final RxList<ChatModel> _chats = <ChatModel>[].obs;
  List<ChatModel> get chats => _chats;

  // Observable messages for current chat
  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  List<MessageModel> get messages => _messages;

  // Selected chat
  final Rx<ChatModel?> _selectedChat = Rx<ChatModel?>(null);
  ChatModel? get selectedChat => _selectedChat.value;

  // Selected user for new chat
  final Rx<UserModel?> _selectedUser = Rx<UserModel?>(null);
  UserModel? get selectedUser => _selectedUser.value;

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // Get all chats for current user
  Future<void> getUserChats(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Use Supabase service to get chats
      final userChats = await _supabaseService.getUserChats(userId);
      _chats.assignAll(userChats);
    } catch (e) {
      _errorMessage.value = 'Failed to get chats: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        final mockChats = await _mockDataService.getUserChats(userId);
        _chats.assignAll(mockChats);
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get chats: ${e.toString()}. Mock data error: ${mockError.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Get messages for a specific chat
  Future<void> getChatMessages(String chatId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      // Use Supabase service to get chat messages
      final chatMessages = await _supabaseService.getChatMessages(chatId);

      // Use Future.microtask to avoid setState during build
      await Future.microtask(() {
        _messages.assignAll(chatMessages);
      });

      // Mark messages as read
      final currentUser = Get.find<AuthController>().user;
      if (currentUser != null) {
        await markMessagesAsRead(chatId, currentUser.id);
      }
    } catch (e) {
      _errorMessage.value = 'Failed to get messages: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        final mockMessages = await _mockDataService.getChatMessages(chatId);
        await Future.microtask(() {
          _messages.assignAll(mockMessages);
        });
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get messages: ${e.toString()}. Mock data error: ${mockError.toString()}';
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Poll for new messages
  Timer? _messagePollingTimer;
  DateTime _lastMessageTimestamp = DateTime.now();

  void startMessagePolling(String chatId, {int intervalSeconds = 3}) {
    // Stop any existing polling
    stopMessagePolling();

    // Set the last message timestamp to now
    _lastMessageTimestamp = DateTime.now();

    // Start polling for new messages
    _messagePollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _pollForNewMessages(chatId),
    );
  }

  void stopMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = null;
  }

  Future<void> _pollForNewMessages(String chatId) async {
    try {
      // Get new messages since the last check
      final newMessages = await _supabaseService.getNewMessages(
        chatId,
        _lastMessageTimestamp,
      );

      if (newMessages.isNotEmpty) {
        // Update the last message timestamp
        _lastMessageTimestamp = newMessages.last.timestamp;

        // Add new messages to the list
        _messages.addAll(newMessages);

        // Mark messages as read
        final currentUser = Get.find<AuthController>().user;
        if (currentUser != null) {
          await markMessagesAsRead(chatId, currentUser.id);
        }

        // Update the chat with the last message
        await _updateChatWithNewMessage(chatId, newMessages.last);
      }
    } catch (e) {
      debugPrint('Error polling for new messages: $e');
    }
  }

  // Send a new message
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
    String? attachmentUrl,
    String? attachmentType,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final message = MessageModel(
        id: '', // Will be generated by the service
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
      );

      // Use Supabase service to send message
      final newMessage = await _supabaseService.sendMessage(message);
      _messages.add(newMessage);

      // Update the chat with the new message
      await _updateChatWithNewMessage(chatId, newMessage);

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to send message: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        final message = MessageModel(
          id: '', // Will be generated by the service
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          content: content,
          timestamp: DateTime.now(),
          isRead: false,
          attachmentUrl: attachmentUrl,
          attachmentType: attachmentType,
        );

        final mockMessage = await _mockDataService.sendMessage(message);
        _messages.add(mockMessage);
        await _updateChatWithNewMessage(chatId, mockMessage);
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
        return true;
      } catch (mockError) {
        _errorMessage.value =
            'Failed to send message: ${e.toString()}. Mock data error: ${mockError.toString()}';
        return false;
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Create a new chat
  Future<String?> createChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Check if chat already exists
      final existingChat = _chats.firstWhereOrNull(
        (chat) =>
            chat.participantIds.contains(currentUserId) &&
            chat.participantIds.contains(otherUserId),
      );

      if (existingChat != null) {
        _selectedChat.value = existingChat;
        return existingChat.id;
      }

      // Use Supabase service to create chat
      final newChat = await _supabaseService.createChatSession(
        currentUserId,
        otherUserId,
      );

      _chats.add(newChat);
      _selectedChat.value = newChat;
      return newChat.id;
    } catch (e) {
      _errorMessage.value = 'Failed to create chat: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        final mockChat = await _mockDataService.createChat(
          currentUserId,
          otherUserId,
        );
        _chats.add(mockChat);
        _selectedChat.value = mockChat;
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
        return mockChat.id;
      } catch (mockError) {
        _errorMessage.value =
            'Failed to create chat: ${e.toString()}. Mock data error: ${mockError.toString()}';
        return null;
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      // Use Supabase service to mark messages as read
      await _supabaseService.markMessagesAsRead(chatId, userId);

      // Use Future.microtask to avoid setState during build
      await Future.microtask(() {
        // Update local messages
        for (int i = 0; i < _messages.length; i++) {
          if (!_messages[i].isRead) {
            _messages[i] = _messages[i].copyWith(isRead: true);
          }
        }

        // Update chat unread status
        final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
        if (chatIndex != -1) {
          _chats[chatIndex] = _chats[chatIndex].copyWith(
            hasUnreadMessages: false,
            unreadCount: 0,
          );
        }
      });
    } catch (e) {
      debugPrint('Failed to mark messages as read: ${e.toString()}');
      _errorMessage.value = 'Failed to mark messages as read: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        await _mockDataService.markMessagesAsRead(chatId);
      } catch (mockError) {
        debugPrint(
          'Failed to mark messages as read with mock data: ${mockError.toString()}',
        );
      }
    }
  }

  // Set selected chat
  void setSelectedChat(ChatModel chat) {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      _selectedChat.value = chat;
    });
  }

  // Set selected user for new chat
  void setSelectedUser(UserModel user) {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      _selectedUser.value = user;
    });
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Use Supabase service to get user
      final user = await _supabaseService.getUserProfile(userId);
      _selectedUser.value = user;
      return user;
    } catch (e) {
      _errorMessage.value = 'Failed to get user: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        final mockUser = await _mockDataService.getUserById(userId);
        _selectedUser.value = mockUser;
        _errorMessage.value =
            'Using mock data (Supabase error: ${e.toString()})';
        return mockUser;
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get user: ${e.toString()}. Mock data error: ${mockError.toString()}';
        return null;
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // Check if chat exists in local list
      final existingChat = _chats.firstWhereOrNull((chat) => chat.id == chatId);
      if (existingChat != null) {
        _selectedChat.value = existingChat;
        return existingChat;
      }

      // Use Supabase service to get chat
      final chat = await _supabaseService.getChatById(chatId);
      if (chat != null) {
        _selectedChat.value = chat;
        // Add to local list if not already there
        if (!_chats.any((c) => c.id == chat.id)) {
          _chats.add(chat);
        }
      }
      return chat;
    } catch (e) {
      _errorMessage.value = 'Failed to get chat: ${e.toString()}';

      // Fallback to mock data if Supabase fails
      try {
        final mockChat = await _mockDataService.getChatById(chatId);
        if (mockChat != null) {
          _selectedChat.value = mockChat;
          if (!_chats.any((c) => c.id == mockChat.id)) {
            _chats.add(mockChat);
          }
          _errorMessage.value =
              'Using mock data (Supabase error: ${e.toString()})';
          return mockChat;
        }
        return null;
      } catch (mockError) {
        _errorMessage.value =
            'Failed to get chat: ${e.toString()}. Mock data error: ${mockError.toString()}';
        return null;
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Create or get existing chat
  Future<String?> createOrGetChat({
    required String receiverId,
    required String receiverName,
    String? receiverImage,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final currentUser = Get.find<AuthController>().user;
      if (currentUser == null) {
        _errorMessage.value = 'User not authenticated';
        return null;
      }

      // Check if chat already exists
      final existingChat = _chats.firstWhereOrNull(
        (chat) =>
            chat.participantIds.contains(currentUser.id) &&
            chat.participantIds.contains(receiverId),
      );

      if (existingChat != null) {
        _selectedChat.value = existingChat;
        return existingChat.id;
      }

      // Create new chat
      return await createChat(
        currentUserId: currentUser.id,
        otherUserId: receiverId,
      );
    } catch (e) {
      _errorMessage.value = 'Failed to create or get chat: ${e.toString()}';
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Update chat with new message
  Future<void> _updateChatWithNewMessage(
    String chatId,
    MessageModel message,
  ) async {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessageAt: message.timestamp,
        lastMessageContent: message.content,
        lastMessageSenderId: message.senderId,
      );
    }
  }

  // Search chats by user name
  List<ChatModel> searchChatsByName(String query, List<UserModel> allUsers) {
    if (query.isEmpty) return chats;

    return chats.where((chat) {
      // Find the other participant in the chat
      final otherParticipantId = chat.participantIds.firstWhere(
        (id) => id != Get.find<AuthController>().user?.id,
        orElse: () => '',
      );

      if (otherParticipantId.isEmpty) return false;

      // Find the user by ID
      final otherUser = allUsers.firstWhereOrNull(
        (user) => user.id == otherParticipantId,
      );

      if (otherUser == null) return false;

      // Check if the user name contains the query
      return otherUser.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Dispose resources
  @override
  void onClose() {
    stopMessagePolling();
    super.onClose();
  }
}
