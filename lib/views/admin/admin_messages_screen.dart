import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/admin_message_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../models/admin_message_model.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen>
    with SingleTickerProviderStateMixin {
  final AdminMessageController _messageController =
      Get.find<AdminMessageController>();
  final AdminNavigationController _navigationController =
      Get.find<AdminNavigationController>();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load messages data
  Future<void> _loadMessages() async {
    await _messageController.refreshAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages & Announcements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Messages'),
            Tab(text: 'Announcements'),
            Tab(text: 'Support'),
          ],
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages),
        ],
      ),
      body: Obx(() {
        if (_messageController.isLoadingMessages) {
          return const Center(child: CircularProgressIndicator());
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildMessageList(_messageController.allMessages),
            _buildMessageList(_messageController.announcements),
            _buildMessageList(_messageController.supportMessages),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () {
          _showCreateMessageDialog();
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Obx(
        () => AdminBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }

  // Build message list
  Widget _buildMessageList(List<AdminMessageModel> messages) {
    if (messages.isEmpty) {
      return const Center(child: Text('No messages found'));
    }

    return ListView.builder(
      itemCount: messages.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final message = messages[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getMessageTypeColor(message.type),
              child: Icon(
                _getMessageTypeIcon(message.type),
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    message.title,
                    style: TextStyle(
                      fontWeight:
                          message.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (!message.isRead)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'From: ${message.senderName ?? "Admin"}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(message.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            onTap: () {
              _showMessageDetails(message);
              // Mark as read
              if (!message.isRead) {
                _messageController.markMessageAsRead(message.id);
              }
            },
          ),
        );
      },
    );
  }

  // Get message type color
  Color _getMessageTypeColor(AdminMessageType type) {
    switch (type) {
      case AdminMessageType.announcement:
        return Colors.blue;
      case AdminMessageType.support:
        return Colors.orange;
      case AdminMessageType.feedback:
        return Colors.green;
    }
  }

  // Get message type icon
  IconData _getMessageTypeIcon(AdminMessageType type) {
    switch (type) {
      case AdminMessageType.announcement:
        return Icons.campaign;
      case AdminMessageType.support:
        return Icons.support_agent;
      case AdminMessageType.feedback:
        return Icons.feedback;
    }
  }

  // Format timestamp
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Show message details
  void _showMessageDetails(AdminMessageModel message) {
    Get.dialog(
      AlertDialog(
        title: Text(message.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('From', message.senderName ?? "Admin"),
              _buildDetailRow(
                'Type',
                message.type.toString().split('.').last.capitalize!,
              ),
              _buildDetailRow('Date', _formatTimestamp(message.createdAt)),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(message.content),
            ],
          ),
        ),
        actions: [
          if (message.type == AdminMessageType.support)
            TextButton(
              onPressed: () {
                Get.back();
                _showReplyDialog(message);
              },
              child: const Text('Reply'),
            ),
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  // Show reply dialog
  void _showReplyDialog(AdminMessageModel message) {
    final TextEditingController replyController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Reply to ${message.senderName ?? "User"}'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            hintText: 'Type your reply here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (replyController.text.isNotEmpty) {
                Get.back();
                Get.snackbar(
                  'Success',
                  'Reply sent to ${message.senderName ?? "User"}',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    ).then((_) => replyController.dispose());
  }

  // Show create message dialog
  void _showCreateMessageDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    AdminMessageType selectedType = AdminMessageType.announcement;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Message'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<AdminMessageType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Message Type',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        AdminMessageType.values.map((type) {
                          return DropdownMenuItem<AdminMessageType>(
                            value: type,
                            child: Text(
                              type.toString().split('.').last.capitalize!,
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty &&
                      contentController.text.isNotEmpty) {
                    // Create new message using the controller
                    final success = await _messageController.createAdminMessage(
                      title: titleController.text,
                      content: contentController.text,
                      type: selectedType,
                    );

                    Get.back();

                    if (success) {
                      Get.snackbar(
                        'Success',
                        'Message created successfully',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    } else {
                      Get.snackbar(
                        'Error',
                        'Failed to create message: ${_messageController.errorMessage}',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  } else {
                    Get.snackbar(
                      'Error',
                      'Please fill in all fields',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      titleController.dispose();
      contentController.dispose();
    });
  }

  // Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// Message model
class MessageModel {
  final String id;
  final String title;
  final String content;
  final String sender;
  final DateTime timestamp;
  final MessageType type;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.title,
    required this.content,
    required this.sender,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });

  MessageModel copyWith({
    String? id,
    String? title,
    String? content,
    String? sender,
    DateTime? timestamp,
    MessageType? type,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Message type enum
enum MessageType { announcement, support, feedback }
