import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({Key? key}) : super(key: key);

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final AdminNavigationController _navigationController = Get.find<AdminNavigationController>();
  
  late TabController _tabController;
  final RxBool _isLoading = false.obs;
  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final RxList<MessageModel> _announcements = <MessageModel>[].obs;
  final RxList<MessageModel> _support = <MessageModel>[].obs;
  
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
    _isLoading.value = true;
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      final List<MessageModel> mockMessages = [
        MessageModel(
          id: 'm1',
          title: 'System Maintenance',
          content: 'The system will be down for maintenance on Saturday from 2 AM to 4 AM.',
          sender: 'System Admin',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          type: MessageType.announcement,
          isRead: true,
        ),
        MessageModel(
          id: 'm2',
          title: 'New Feature Release',
          content: 'We are excited to announce the release of our new AI diagnosis feature.',
          sender: 'Product Team',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          type: MessageType.announcement,
          isRead: false,
        ),
        MessageModel(
          id: 'm3',
          title: 'Login Issue',
          content: 'I am unable to login to my account. It says invalid credentials but I am sure my password is correct.',
          sender: 'Ahmed Ali',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          type: MessageType.support,
          isRead: false,
        ),
        MessageModel(
          id: 'm4',
          title: 'Payment Problem',
          content: 'I was charged twice for my consultation. Please help resolve this issue.',
          sender: 'Dr. Mohammed Al-Saud',
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          type: MessageType.support,
          isRead: true,
        ),
        MessageModel(
          id: 'm5',
          title: 'App Feedback',
          content: 'The new update is great but I found a bug in the appointment scheduling feature.',
          sender: 'Fatima Khan',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          type: MessageType.feedback,
          isRead: false,
        ),
      ];
      
      _messages.assignAll(mockMessages);
      
      // Filter messages by type
      _announcements.assignAll(_messages.where((msg) => msg.type == MessageType.announcement).toList());
      _support.assignAll(_messages.where((msg) => msg.type == MessageType.support).toList());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load messages: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return TabBarView(
          controller: _tabController,
          children: [
            _buildMessageList(_messages),
            _buildMessageList(_announcements),
            _buildMessageList(_support),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateMessageDialog();
        },
        child: const Icon(Icons.add),
        backgroundColor: AppColors.primaryColor,
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
  Widget _buildMessageList(List<MessageModel> messages) {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
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
                  'From: ${message.sender}',
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
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () {
              _showMessageDetails(message);
              // Mark as read
              if (!message.isRead) {
                final index = _messages.indexWhere((m) => m.id == message.id);
                if (index != -1) {
                  final updatedMessage = _messages[index].copyWith(isRead: true);
                  _messages[index] = updatedMessage;
                  
                  // Update filtered lists
                  if (message.type == MessageType.announcement) {
                    final announcementIndex = _announcements.indexWhere((m) => m.id == message.id);
                    if (announcementIndex != -1) {
                      _announcements[announcementIndex] = updatedMessage;
                    }
                  } else if (message.type == MessageType.support) {
                    final supportIndex = _support.indexWhere((m) => m.id == message.id);
                    if (supportIndex != -1) {
                      _support[supportIndex] = updatedMessage;
                    }
                  }
                }
              }
            },
          ),
        );
      },
    );
  }
  
  // Get message type color
  Color _getMessageTypeColor(MessageType type) {
    switch (type) {
      case MessageType.announcement:
        return Colors.blue;
      case MessageType.support:
        return Colors.orange;
      case MessageType.feedback:
        return Colors.green;
      default:
        return AppColors.primaryColor;
    }
  }
  
  // Get message type icon
  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.announcement:
        return Icons.campaign;
      case MessageType.support:
        return Icons.support_agent;
      case MessageType.feedback:
        return Icons.feedback;
      default:
        return Icons.message;
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
  void _showMessageDetails(MessageModel message) {
    Get.dialog(
      AlertDialog(
        title: Text(message.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('From', message.sender),
              _buildDetailRow('Type', message.type.toString().split('.').last.capitalize!),
              _buildDetailRow('Date', _formatTimestamp(message.timestamp)),
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
          if (message.type == MessageType.support)
            TextButton(
              onPressed: () {
                Get.back();
                _showReplyDialog(message);
              },
              child: const Text('Reply'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Show reply dialog
  void _showReplyDialog(MessageModel message) {
    final TextEditingController replyController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: Text('Reply to ${message.sender}'),
        content: TextField(
          controller: replyController,
          decoration: const InputDecoration(
            hintText: 'Type your reply here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (replyController.text.isNotEmpty) {
                Get.back();
                Get.snackbar(
                  'Success',
                  'Reply sent to ${message.sender}',
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
    MessageType selectedType = MessageType.announcement;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Message'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<MessageType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Message Type',
                      border: OutlineInputBorder(),
                    ),
                    items: MessageType.values.map((type) {
                      return DropdownMenuItem<MessageType>(
                        value: type,
                        child: Text(type.toString().split('.').last.capitalize!),
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
                onPressed: () {
                  if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                    // Create new message
                    final newMessage = MessageModel(
                      id: 'new${_messages.length + 1}',
                      title: titleController.text,
                      content: contentController.text,
                      sender: 'Admin',
                      timestamp: DateTime.now(),
                      type: selectedType,
                      isRead: false,
                    );
                    
                    // Add to appropriate lists
                    _messages.insert(0, newMessage);
                    if (selectedType == MessageType.announcement) {
                      _announcements.insert(0, newMessage);
                    } else if (selectedType == MessageType.support) {
                      _support.insert(0, newMessage);
                    }
                    
                    Get.back();
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
          Expanded(
            child: Text(value),
          ),
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
enum MessageType {
  announcement,
  support,
  feedback,
}
