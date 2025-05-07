import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_message_model.dart';
import '../services/admin_message_service.dart';

/// Controller for managing admin messages
class AdminMessageController extends GetxController {
  final AdminMessageService _adminMessageService =
      Get.find<AdminMessageService>();

  // Observable lists
  final RxList<AdminMessageModel> _allMessages = <AdminMessageModel>[].obs;
  final RxList<AdminMessageModel> _announcements = <AdminMessageModel>[].obs;
  final RxList<AdminMessageModel> _supportMessages = <AdminMessageModel>[].obs;
  final RxList<AdminMessageModel> _feedbackMessages = <AdminMessageModel>[].obs;

  // Loading states
  final RxBool _isLoadingMessages = false.obs;
  final RxBool _isLoadingAnnouncements = false.obs;
  final RxBool _isLoadingSupportMessages = false.obs;
  final RxBool _isLoadingFeedbackMessages = false.obs;
  final RxBool _isCreatingMessage = false.obs;
  final RxBool _isUpdatingMessage = false.obs;
  final RxBool _isDeletingMessage = false.obs;

  // Error messages
  final RxString _errorMessage = ''.obs;

  // Getters
  List<AdminMessageModel> get allMessages => _allMessages;
  List<AdminMessageModel> get announcements => _announcements;
  List<AdminMessageModel> get supportMessages => _supportMessages;
  List<AdminMessageModel> get feedbackMessages => _feedbackMessages;

  bool get isLoadingMessages => _isLoadingMessages.value;
  bool get isLoadingAnnouncements => _isLoadingAnnouncements.value;
  bool get isLoadingSupportMessages => _isLoadingSupportMessages.value;
  bool get isLoadingFeedbackMessages => _isLoadingFeedbackMessages.value;
  bool get isCreatingMessage => _isCreatingMessage.value;
  bool get isUpdatingMessage => _isUpdatingMessage.value;
  bool get isDeletingMessage => _isDeletingMessage.value;

  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    // Load data when controller is initialized
    fetchAllMessages();
    fetchAnnouncementMessages();
    fetchSupportMessages();
    fetchFeedbackMessages();
  }

  // Fetch all admin messages
  Future<void> fetchAllMessages() async {
    _isLoadingMessages.value = true;
    _errorMessage.value = '';

    try {
      final messages = await _adminMessageService.getAllAdminMessages();
      _allMessages.assignAll(messages);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch messages: ${e.toString()}';
    } finally {
      _isLoadingMessages.value = false;
    }
  }

  // Fetch announcement messages
  Future<void> fetchAnnouncementMessages() async {
    _isLoadingAnnouncements.value = true;
    _errorMessage.value = '';

    try {
      final messages = await _adminMessageService.getAdminMessagesByType(
        AdminMessageType.announcement,
      );
      _announcements.assignAll(messages);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch announcements: ${e.toString()}';
    } finally {
      _isLoadingAnnouncements.value = false;
    }
  }

  // Fetch support messages
  Future<void> fetchSupportMessages() async {
    _isLoadingSupportMessages.value = true;
    _errorMessage.value = '';

    try {
      final messages = await _adminMessageService.getAdminMessagesByType(
        AdminMessageType.support,
      );
      _supportMessages.assignAll(messages);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch support messages: ${e.toString()}';
    } finally {
      _isLoadingSupportMessages.value = false;
    }
  }

  // Fetch feedback messages
  Future<void> fetchFeedbackMessages() async {
    _isLoadingFeedbackMessages.value = true;
    _errorMessage.value = '';

    try {
      final messages = await _adminMessageService.getAdminMessagesByType(
        AdminMessageType.feedback,
      );
      _feedbackMessages.assignAll(messages);
    } catch (e) {
      _errorMessage.value =
          'Failed to fetch feedback messages: ${e.toString()}';
    } finally {
      _isLoadingFeedbackMessages.value = false;
    }
  }

  // Create a new admin message
  Future<bool> createAdminMessage({
    required String title,
    required String content,
    String? recipientId,
    required AdminMessageType type,
    AdminMessageStatus status = AdminMessageStatus.active,
  }) async {
    _isCreatingMessage.value = true;
    _errorMessage.value = '';

    try {
      final message = await _adminMessageService.createAdminMessage(
        title: title,
        content: content,
        recipientId: recipientId,
        type: type,
        status: status,
      );

      if (message != null) {
        // Add to appropriate lists
        _allMessages.insert(0, message);

        switch (type) {
          case AdminMessageType.announcement:
            _announcements.insert(0, message);
            break;
          case AdminMessageType.support:
            _supportMessages.insert(0, message);
            break;
          case AdminMessageType.feedback:
            _feedbackMessages.insert(0, message);
            break;
        }

        return true;
      } else {
        _errorMessage.value =
            'Failed to create message. Only admins can create messages.';
        return false;
      }
    } catch (e) {
      // Check if it's a PostgrestException with a 404 error
      if (e.toString().contains('PostgrestException') &&
          e.toString().contains('code: 404')) {
        _errorMessage.value =
            'The admin_messages table does not exist in the database. Please run the database setup script.';
        debugPrint('Database table not found: ${e.toString()}');
      } else {
        _errorMessage.value = 'Failed to create message: ${e.toString()}';
        debugPrint('Error creating admin message: ${e.toString()}');
      }
      return false;
    } finally {
      _isCreatingMessage.value = false;
    }
  }

  // Update an admin message
  Future<bool> updateAdminMessage(AdminMessageModel message) async {
    _isUpdatingMessage.value = true;
    _errorMessage.value = '';

    try {
      final success = await _adminMessageService.updateAdminMessage(message);

      if (success) {
        // Update in all lists
        await fetchAllMessages();
        await fetchAnnouncementMessages();
        await fetchSupportMessages();
        await fetchFeedbackMessages();
        return true;
      } else {
        _errorMessage.value =
            'Failed to update message. Only admins can update messages.';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to update message: ${e.toString()}';
      return false;
    } finally {
      _isUpdatingMessage.value = false;
    }
  }

  // Delete an admin message
  Future<bool> deleteAdminMessage(String messageId) async {
    _isDeletingMessage.value = true;
    _errorMessage.value = '';

    try {
      final success = await _adminMessageService.deleteAdminMessage(messageId);

      if (success) {
        // Remove from all lists
        _allMessages.removeWhere((message) => message.id == messageId);
        _announcements.removeWhere((message) => message.id == messageId);
        _supportMessages.removeWhere((message) => message.id == messageId);
        _feedbackMessages.removeWhere((message) => message.id == messageId);
        return true;
      } else {
        _errorMessage.value =
            'Failed to delete message. Only admins can delete messages.';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to delete message: ${e.toString()}';
      return false;
    } finally {
      _isDeletingMessage.value = false;
    }
  }

  // Mark an admin message as read
  Future<bool> markMessageAsRead(String messageId) async {
    try {
      final success = await _adminMessageService.markAdminMessageAsRead(
        messageId,
      );

      if (success) {
        // Update message in lists
        final index = _allMessages.indexWhere(
          (message) => message.id == messageId,
        );
        if (index != -1) {
          final updatedMessage = _allMessages[index].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _allMessages[index] = updatedMessage;
        }

        // Update in type-specific lists
        final announcementIndex = _announcements.indexWhere(
          (message) => message.id == messageId,
        );
        if (announcementIndex != -1) {
          final updatedMessage = _announcements[announcementIndex].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _announcements[announcementIndex] = updatedMessage;
        }

        final supportIndex = _supportMessages.indexWhere(
          (message) => message.id == messageId,
        );
        if (supportIndex != -1) {
          final updatedMessage = _supportMessages[supportIndex].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _supportMessages[supportIndex] = updatedMessage;
        }

        final feedbackIndex = _feedbackMessages.indexWhere(
          (message) => message.id == messageId,
        );
        if (feedbackIndex != -1) {
          final updatedMessage = _feedbackMessages[feedbackIndex].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          _feedbackMessages[feedbackIndex] = updatedMessage;
        }

        return true;
      }
      return false;
    } catch (e) {
      _errorMessage.value = 'Failed to mark message as read: ${e.toString()}';
      return false;
    }
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await fetchAllMessages();
    await fetchAnnouncementMessages();
    await fetchSupportMessages();
    await fetchFeedbackMessages();
  }
}
