import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/message_controller.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../../widgets/empty_state.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatModel chat;
  final UserModel otherUser;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.otherUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final MessageController _messageController = Get.find<MessageController>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _messageInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load messages
  Future<void> _loadMessages() async {
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _messageController.getChatMessages(widget.chat.id);

      // Scroll to bottom after messages load
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Send message
  Future<void> _sendMessage() async {
    final content = _messageInputController.text.trim();
    if (content.isEmpty) return;

    final success = await _messageController.sendMessage(
      chatId: widget.chat.id,
      senderId: _authController.user!.id,
      receiverId: widget.otherUser.id,
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
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child:
                    widget.otherUser.profileImage != null
                        ? CachedNetworkImage(
                          imageUrl: widget.otherUser.profileImage!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) =>
                                  const CircularProgressIndicator(),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.person),
                        )
                        : const Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.grey,
                        ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    _authController.isDoctor
                        ? 'Patient'
                        : widget.otherUser.specialization ?? 'Doctor',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: Show user info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              if (_messageController.isLoading) {
                return const CustomLoadingIndicator();
              }

              if (_messageController.messages.isEmpty) {
                return const EmptyState(
                  icon: Icons.message,
                  title: 'No Messages',
                  message: 'Start a conversation by sending a message.',
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messageController.messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageItem(_messageController.messages[index]);
                },
              );
            }),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51), // 0.2 opacity
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
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
      ),
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
                    widget.otherUser.profileImage != null
                        ? CachedNetworkImage(
                          imageUrl: widget.otherUser.profileImage!,
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

                  // Attachment if any
                  if (message.attachmentUrl != null) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // TODO: Open attachment
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isCurrentUser
                                  ? Colors.white.withAlpha(51) // 0.2 opacity
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              message.attachmentType == 'image'
                                  ? Icons.image
                                  : Icons.insert_drive_file,
                              size: 16,
                              color:
                                  isCurrentUser ? Colors.white : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              message.attachmentType == 'image'
                                  ? 'Image'
                                  : 'Document',
                              style: TextStyle(
                                color:
                                    isCurrentUser ? Colors.white : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Timestamp
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat.jm().format(message.timestamp),
                        style: TextStyle(
                          color:
                              isCurrentUser
                                  ? Colors.white.withAlpha(179) // 0.7 opacity
                                  : Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isCurrentUser)
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: Colors.white.withAlpha(179), // 0.7 opacity
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isCurrentUser) const SizedBox(width: 24),
        ],
      ),
    );
  }
}
