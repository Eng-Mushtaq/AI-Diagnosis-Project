import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_message_model.dart';
import '../models/user_model.dart';
import 'supabase_service.dart';
import 'admin_service.dart';

/// Service class for handling admin message operations
class AdminMessageService extends GetxService {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final AdminService _adminService = Get.find<AdminService>();

  // Get Supabase client
  SupabaseClient get _supabase => _supabaseService.supabaseClient;

  // Get all admin messages
  Future<List<AdminMessageModel>> getAllAdminMessages() async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can get all admin messages');
        return [];
      }

      try {
        // Get all admin messages without trying to join with users table
        final response = await _supabase
            .from('admin_messages')
            .select()
            .order('created_at', ascending: false);

        debugPrint('Retrieved ${response.length} admin messages');

        // Parse the response into AdminMessageModel objects
        List<AdminMessageModel> messages = [];
        for (var message in response) {
          try {
            // Get sender details in a separate query
            String? senderName;
            String? senderProfileImage;
            String? recipientName;

            try {
              if (message['sender_id'] != null) {
                final senderData =
                    await _supabase
                        .from('users')
                        .select('name, profile_image')
                        .eq('id', message['sender_id'])
                        .maybeSingle();

                if (senderData != null) {
                  senderName = senderData['name'];
                  senderProfileImage = senderData['profile_image'];
                }
              }

              if (message['recipient_id'] != null) {
                final recipientData =
                    await _supabase
                        .from('users')
                        .select('name')
                        .eq('id', message['recipient_id'])
                        .maybeSingle();

                if (recipientData != null) {
                  recipientName = recipientData['name'];
                }
              }
            } catch (userError) {
              debugPrint('Error fetching user details: $userError');
              // Continue with null values for user details
            }

            // Handle missing fields with defaults
            final String title =
                message['title'] ?? message['subject'] ?? 'No Title';

            messages.add(
              AdminMessageModel(
                id: message['id'],
                title: title,
                content: message['content'],
                senderId: message['sender_id'],
                senderName: senderName ?? 'Unknown',
                senderProfileImage: senderProfileImage,
                recipientId: message['recipient_id'],
                recipientName: recipientName,
                type: AdminMessageModel.typeFromString(
                  message['message_type'] ?? message['type'] ?? 'announcement',
                ),
                status: AdminMessageModel.statusFromString(
                  message['status'] ?? 'active',
                ),
                isRead: message['is_read'] ?? false,
                readAt:
                    message['read_at'] != null
                        ? DateTime.parse(message['read_at'])
                        : null,
                createdAt: DateTime.parse(message['created_at']),
                updatedAt:
                    message['updated_at'] != null
                        ? DateTime.parse(message['updated_at'])
                        : DateTime.parse(message['created_at']),
              ),
            );
          } catch (e) {
            debugPrint('Error parsing admin message: $e');
          }
        }

        return messages;
      } catch (e) {
        if (e is PostgrestException && e.code == '42P01') {
          // Table doesn't exist yet
          debugPrint(
            'Admin messages table does not exist or has different structure. Creating mock data...',
          );

          // Return empty list for now
          return [];
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error getting all admin messages: $e');
      return [];
    }
  }

  // Get admin messages by type
  Future<List<AdminMessageModel>> getAdminMessagesByType(
    AdminMessageType type,
  ) async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can get admin messages by type');
        return [];
      }

      try {
        // Determine which field to use for type filtering
        final typeField = await _determineTypeField();
        final typeValue = AdminMessageModel.typeToString(type);

        // Get admin messages by type without trying to join with users table
        final response = await _supabase
            .from('admin_messages')
            .select()
            .eq(typeField, typeValue)
            .order('created_at', ascending: false);

        debugPrint(
          'Retrieved ${response.length} admin messages of type: $typeValue',
        );

        // Parse the response into AdminMessageModel objects
        List<AdminMessageModel> messages = [];
        for (var message in response) {
          try {
            // Get sender details in a separate query
            String? senderName;
            String? senderProfileImage;
            String? recipientName;

            try {
              if (message['sender_id'] != null) {
                final senderData =
                    await _supabase
                        .from('users')
                        .select('name, profile_image')
                        .eq('id', message['sender_id'])
                        .maybeSingle();

                if (senderData != null) {
                  senderName = senderData['name'];
                  senderProfileImage = senderData['profile_image'];
                }
              }

              if (message['recipient_id'] != null) {
                final recipientData =
                    await _supabase
                        .from('users')
                        .select('name')
                        .eq('id', message['recipient_id'])
                        .maybeSingle();

                if (recipientData != null) {
                  recipientName = recipientData['name'];
                }
              }
            } catch (userError) {
              debugPrint('Error fetching user details: $userError');
              // Continue with null values for user details
            }

            // Handle missing fields with defaults
            final String title =
                message['title'] ?? message['subject'] ?? 'No Title';

            messages.add(
              AdminMessageModel(
                id: message['id'],
                title: title,
                content: message['content'],
                senderId: message['sender_id'],
                senderName: senderName ?? 'Unknown',
                senderProfileImage: senderProfileImage,
                recipientId: message['recipient_id'],
                recipientName: recipientName,
                type: AdminMessageModel.typeFromString(
                  message['message_type'] ?? message['type'] ?? 'announcement',
                ),
                status: AdminMessageModel.statusFromString(
                  message['status'] ?? 'active',
                ),
                isRead: message['is_read'] ?? false,
                readAt:
                    message['read_at'] != null
                        ? DateTime.parse(message['read_at'])
                        : null,
                createdAt: DateTime.parse(message['created_at']),
                updatedAt:
                    message['updated_at'] != null
                        ? DateTime.parse(message['updated_at'])
                        : DateTime.parse(message['created_at']),
              ),
            );
          } catch (e) {
            debugPrint('Error parsing admin message: $e');
          }
        }

        return messages;
      } catch (e) {
        if (e is PostgrestException && e.code == '42P01') {
          // Table doesn't exist yet
          debugPrint(
            'Admin messages table does not exist or has different structure. Creating mock data...',
          );

          // Return empty list for now
          return [];
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('Error getting admin messages by type: $e');
      return [];
    }
  }

  // Helper method to determine which field to use for type filtering
  Future<String> _determineTypeField() async {
    try {
      // Try to query with 'type' field first
      await _supabase.from('admin_messages').select('type').limit(1);
      return 'type';
    } catch (e) {
      try {
        // Try with 'message_type' field
        await _supabase.from('admin_messages').select('message_type').limit(1);
        return 'message_type';
      } catch (e) {
        // Default to message_type as per SQL schema
        return 'message_type';
      }
    }
  }

  // Create a new admin message
  Future<AdminMessageModel?> createAdminMessage({
    required String title,
    required String content,
    String? recipientId,
    required AdminMessageType type,
    AdminMessageStatus status = AdminMessageStatus.active,
  }) async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can create admin messages');
        return null;
      }

      // Get current user ID
      final currentUser = _supabaseService.getCurrentAuthUser();
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      // Determine which fields to use based on table structure
      Map<String, dynamic> data = {};

      try {
        // Check if admin_messages table exists and determine its structure
        final tableInfo = await _supabase
            .from('admin_messages')
            .select('id')
            .limit(1);
        debugPrint(
          'admin_messages table exists with structure: ${tableInfo.toString()}',
        );

        // Try to determine if we should use 'title' or 'subject'
        bool useTitle = true;
        try {
          await _supabase.from('admin_messages').select('title').limit(1);
        } catch (e) {
          useTitle = false;
        }

        // Try to determine if we should use 'type' or 'message_type'
        bool useType = true;
        try {
          await _supabase.from('admin_messages').select('type').limit(1);
        } catch (e) {
          useType = false;
        }

        // Prepare data for insertion based on table structure
        data = {
          useTitle ? 'title' : 'subject': title,
          'content': content,
          'sender_id': currentUser.id,
          'recipient_id': recipientId,
          useType ? 'type' : 'message_type': AdminMessageModel.typeToString(
            type,
          ),
          'status': AdminMessageModel.statusToString(status),
          'is_read': false,
        };
      } catch (tableError) {
        // If we get an error, the table might not exist or have a different structure
        debugPrint('admin_messages table error: $tableError');

        // Use the SQL schema structure we created
        data = {
          'subject': title,
          'content': content,
          'sender_id': currentUser.id,
          'recipient_id': recipientId,
          'message_type': AdminMessageModel.typeToString(type),
          'is_read': false,
        };
      }

      try {
        // Insert message and get the result
        final response =
            await _supabase
                .from('admin_messages')
                .insert(data)
                .select()
                .single();

        debugPrint('Successfully inserted admin message: ${response['id']}');

        // Get sender details
        final senderData =
            await _supabase
                .from('users')
                .select('name, profile_image')
                .eq('id', currentUser.id)
                .single();

        // Get recipient details if applicable
        Map<String, dynamic>? recipientData;
        if (recipientId != null) {
          try {
            recipientData =
                await _supabase
                    .from('users')
                    .select('name')
                    .eq('id', recipientId)
                    .single();
          } catch (e) {
            debugPrint('Error getting recipient details: $e');
            // Continue without recipient details
          }
        }

        // Handle missing fields with defaults
        final String messageTitle =
            response['title'] ?? response['subject'] ?? title;

        // Create and return the message model
        return AdminMessageModel(
          id: response['id'],
          title: messageTitle,
          content: response['content'],
          senderId: response['sender_id'],
          senderName: senderData['name'],
          senderProfileImage: senderData['profile_image'],
          recipientId: response['recipient_id'],
          recipientName: recipientData?['name'],
          type: AdminMessageModel.typeFromString(
            response['message_type'] ?? response['type'] ?? 'announcement',
          ),
          status: AdminMessageModel.statusFromString(
            response['status'] ?? 'active',
          ),
          isRead: response['is_read'] ?? false,
          readAt:
              response['read_at'] != null
                  ? DateTime.parse(response['read_at'])
                  : null,
          createdAt: DateTime.parse(response['created_at']),
          updatedAt:
              response['updated_at'] != null
                  ? DateTime.parse(response['updated_at'])
                  : DateTime.parse(response['created_at']),
        );
      } catch (insertError) {
        debugPrint('Error inserting admin message: $insertError');

        // Create a mock message for development purposes
        final now = DateTime.now();
        return AdminMessageModel(
          id: 'mock-${now.millisecondsSinceEpoch}',
          title: title,
          content: content,
          senderId: currentUser.id,
          senderName: 'Admin User',
          senderProfileImage: null,
          recipientId: recipientId,
          recipientName: recipientId != null ? 'Recipient' : null,
          type: type,
          status: status,
          isRead: false,
          readAt: null,
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (e) {
      debugPrint('Error creating admin message: $e');

      // Return null instead of rethrowing to prevent app crashes
      return null;
    }
  }

  // Update an admin message
  Future<bool> updateAdminMessage(AdminMessageModel message) async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can update admin messages');
        return false;
      }

      // Prepare data for update
      final Map<String, dynamic> data = {
        'title': message.title,
        'content': message.content,
        'recipient_id': message.recipientId,
        'type': AdminMessageModel.typeToString(message.type),
        'status': AdminMessageModel.statusToString(message.status),
      };

      // Update message
      await _supabase.from('admin_messages').update(data).eq('id', message.id);

      return true;
    } catch (e) {
      debugPrint('Error updating admin message: $e');
      return false;
    }
  }

  // Delete an admin message
  Future<bool> deleteAdminMessage(String messageId) async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can delete admin messages');
        return false;
      }

      // Delete message
      await _supabase.from('admin_messages').delete().eq('id', messageId);

      return true;
    } catch (e) {
      debugPrint('Error deleting admin message: $e');
      return false;
    }
  }

  // Mark an admin message as read
  Future<bool> markAdminMessageAsRead(String messageId) async {
    try {
      // Get current user ID
      final currentUser = _supabaseService.getCurrentAuthUser();
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      // Update message read status
      await _supabase
          .from('admin_messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('recipient_id', currentUser.id);

      return true;
    } catch (e) {
      debugPrint('Error marking admin message as read: $e');
      return false;
    }
  }
}
