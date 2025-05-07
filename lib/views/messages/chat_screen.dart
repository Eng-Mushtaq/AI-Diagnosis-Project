import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/message_controller.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../../widgets/empty_state.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageController _messageController = Get.find<MessageController>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _messageInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load chat and messages
  Future<void> _loadChat() async {
    await _messageController.getChatById(widget.chatId);

    if (_messageController.selectedChat != null) {
      // Get the other user
      final chat = _messageController.selectedChat!;
      final otherUserId = chat.participantIds.firstWhere(
        (id) => id != _authController.user!.id,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty) {
        await _messageController.getUserById(otherUserId);
        _otherUser = _messageController.selectedUser;
      }

      // Load messages
      await _messageController.getChatMessages(widget.chatId);

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // Send message
  Future<void> _sendMessage() async {
    if (_otherUser == null) return;

    final content = _messageInputController.text.trim();
    if (content.isEmpty) return;

    final success = await _messageController.sendMessage(
      chatId: widget.chatId,
      senderId: _authController.user!.id,
      receiverId: _otherUser!.id,
      content: content,
    );

    if (success) {
      _messageInputController.clear();

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      Get.snackbar(
        'Error',
        'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Chat', showBackButton: true),
      body: Obx(() {
        if (_messageController.isLoading) {
          return const CustomLoadingIndicator();
        }

        if (_otherUser == null) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'Error',
            message: 'Could not load chat details',
          );
        }

        return Column(
          children: [
            // Messages list
            Expanded(
              child:
                  _messageController.messages.isEmpty
                      ? const EmptyState(
                        icon: Icons.message,
                        title: 'No Messages',
                        message: 'Start a conversation by sending a message.',
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messageController.messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageItem(
                            _messageController.messages[index],
                          );
                        },
                      ),
            ),

            // Message input
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // TODO: Implement attachment
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageInputController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primaryColor),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // Build message item
  Widget _buildMessageItem(MessageModel message) {
    final isCurrentUser = message.senderId == _authController.user!.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child:
                    _otherUser?.profileImage != null
                        ? CachedNetworkImage(
                          imageUrl: _otherUser!.profileImage!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  const CircularProgressIndicator(),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.person),
                        )
                        : const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey,
                        ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isCurrentUser ? AppColors.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black,
                    ),
                  ),

                  // Message timestamp
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUser ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // Format timestamp
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
