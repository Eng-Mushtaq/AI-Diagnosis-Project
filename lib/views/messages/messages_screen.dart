import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/message_controller.dart';
import '../../controllers/doctor_controller.dart';
import '../../controllers/patient_controller.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_loading_indicator.dart';
import '../../widgets/empty_state.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final MessageController _messageController = Get.find<MessageController>();
  final AuthController _authController = Get.find<AuthController>();
  final DoctorController _doctorController = Get.find<DoctorController>();
  final PatientController _patientController = Get.find<PatientController>();

  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load initial data
  Future<void> _loadData() async {
    if (_authController.user != null) {
      await _messageController.getUserChats(_authController.user!.id);

      // Load users based on user type
      if (_authController.isDoctor) {
        await _patientController.getDoctorPatients(_authController.user!.id);
      } else {
        await _doctorController.getAllDoctors();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () =>
              _isSearching.value ? _buildSearchField() : const Text('Messages'),
        ),
        actions: [
          IconButton(
            icon: Obx(
              () =>
                  _isSearching.value
                      ? const Icon(Icons.close)
                      : const Icon(Icons.search),
            ),
            onPressed: () {
              _isSearching.value = !_isSearching.value;
              if (!_isSearching.value) {
                _searchController.clear();
                _searchQuery.value = '';
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showNewChatDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Obx(() {
          if (_messageController.isLoading) {
            return const CustomLoadingIndicator();
          }

          if (_messageController.chats.isEmpty) {
            return const EmptyState(
              icon: Icons.message,
              title: 'No Messages',
              message:
                  'You don\'t have any messages yet. Start a conversation with a doctor or patient.',
            );
          }

          final filteredChats =
              _searchQuery.value.isEmpty
                  ? _messageController.chats
                  : _messageController.searchChatsByName(
                    _searchQuery.value,
                    _authController.isDoctor
                        ? _patientController.patients.cast<UserModel>()
                        : _doctorController.doctors.cast<UserModel>(),
                  );

          if (filteredChats.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'No Results',
              message: 'No chats match your search query.',
            );
          }

          return ListView.builder(
            itemCount: filteredChats.length,
            itemBuilder: (context, index) {
              return _buildChatItem(filteredChats[index]);
            },
          );
        }),
      ),
    );
  }

  // Build search field
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search chats...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        _searchQuery.value = value;
      },
    );
  }

  // Build chat item
  Widget _buildChatItem(ChatModel chat) {
    // Get the other participant ID
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != _authController.user!.id,
      orElse: () => '',
    );

    // Get user info based on user type
    UserModel? otherUser;
    if (_authController.isDoctor) {
      otherUser = _patientController.patients.firstWhereOrNull(
        (patient) => patient.id == otherParticipantId,
      );
    } else {
      otherUser = _doctorController.doctors
          .map((doctor) => doctor as UserModel)
          .cast<UserModel>()
          .firstWhere((doctor) => doctor.id == otherParticipantId);
    }

    if (otherUser == null) {
      return const SizedBox.shrink();
    }

    final isCurrentUserLastSender =
        chat.lastMessageSenderId == _authController.user!.id;

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child:
              otherUser.profileImage != null
                  ? CachedNetworkImage(
                    imageUrl: otherUser.profileImage!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) => const CircularProgressIndicator(),
                    errorWidget:
                        (context, url, error) => const Icon(Icons.person),
                  )
                  : const Icon(Icons.person, size: 30, color: Colors.grey),
        ),
      ),
      title: Text(
        otherUser.name,
        style: TextStyle(
          fontWeight:
              chat.hasUnreadMessages && !isCurrentUserLastSender
                  ? FontWeight.bold
                  : FontWeight.normal,
        ),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              isCurrentUserLastSender
                  ? 'You: ${chat.lastMessageContent}'
                  : chat.lastMessageContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight:
                    chat.hasUnreadMessages && !isCurrentUserLastSender
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDateTime(chat.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color:
                  chat.hasUnreadMessages && !isCurrentUserLastSender
                      ? AppColors.primaryColor
                      : Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          if (chat.hasUnreadMessages && !isCurrentUserLastSender)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Use post-frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _messageController.setSelectedChat(chat);
          Get.to(() => ChatDetailScreen(chat: chat, otherUser: otherUser!));
        });
      },
    );
  }

  // Format date time
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat.jm().format(dateTime); // Today: 3:30 PM
    } else if (messageDate == yesterday) {
      return 'Yesterday'; // Yesterday
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat.E().format(dateTime); // Day of week: Mon, Tue, etc.
    } else {
      return DateFormat.yMd().format(dateTime); // Date: 1/1/2021
    }
  }

  // Show new chat dialog
  void _showNewChatDialog() {
    final List<UserModel> users =
        _authController.isDoctor
            ? _patientController.patients.cast<UserModel>()
            : _doctorController.doctors.cast<UserModel>();

    Get.dialog(
      AlertDialog(
        title: const Text('New Chat'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // TODO: Implement search
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: ClipOval(
                          child:
                              user.profileImage != null
                                  ? CachedNetworkImage(
                                    imageUrl: user.profileImage!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) =>
                                            const CircularProgressIndicator(),
                                    errorWidget:
                                        (context, url, error) =>
                                            const Icon(Icons.person),
                                  )
                                  : const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text(
                        _authController.isDoctor
                            ? 'Patient'
                            : user.specialization ?? 'Doctor',
                      ),
                      onTap: () async {
                        Get.back();
                        _startNewChat(user);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ],
      ),
    );
  }

  // Start new chat
  Future<void> _startNewChat(UserModel otherUser) async {
    final currentUser = _authController.user!;

    final chatId = await _messageController.createChat(
      currentUserId: currentUser.id,
      otherUserId: otherUser.id,
    );

    if (chatId != null) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chat = _messageController.selectedChat;
        if (chat != null) {
          Get.to(() => ChatDetailScreen(chat: chat, otherUser: otherUser));
        }
      });
    } else {
      Get.snackbar(
        'Error',
        'Failed to create chat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
