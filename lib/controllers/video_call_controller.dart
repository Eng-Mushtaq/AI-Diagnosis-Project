import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/video_call_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../services/mock_data_service.dart';

/// Controller for managing video calls
class VideoCallController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final MockDataService _mockDataService = MockDataService();
  
  // Observable video calls list
  final RxList<VideoCallModel> _videoCalls = <VideoCallModel>[].obs;
  List<VideoCallModel> get videoCalls => _videoCalls;
  
  // Active call
  final Rx<VideoCallModel?> _activeCall = Rx<VideoCallModel?>(null);
  VideoCallModel? get activeCall => _activeCall.value;
  
  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  
  // Get user video calls
  Future<void> getUserVideoCalls(String userId) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to get video calls from Supabase
      try {
        final callsData = await _supabaseService.getUserVideoCalls(userId);
        
        List<VideoCallModel> calls = [];
        for (final callData in callsData) {
          calls.add(VideoCallModel(
            id: callData['id'],
            appointmentId: callData['appointmentId'],
            callerId: callData['callerId'],
            receiverId: callData['receiverId'],
            callToken: callData['callToken'],
            channelName: callData['channelName'],
            startTime: DateTime.parse(callData['startTime']),
            endTime: callData['endTime'] != null 
                ? DateTime.parse(callData['endTime']) 
                : null,
            duration: callData['duration'],
            status: callData['status'],
            notes: callData['notes'],
            createdAt: DateTime.parse(callData['createdAt']),
          ));
        }
        
        _videoCalls.assignAll(calls);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }
      
      // Fallback to mock data (empty list for now)
      _videoCalls.clear();
    } catch (e) {
      _errorMessage.value = 'Failed to get video calls: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Create a new video call
  Future<Map<String, dynamic>?> createVideoCall({
    required String callerId,
    required String receiverId,
    String? appointmentId,
    String? notes,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to create video call in Supabase
      try {
        final callData = await _supabaseService.createVideoCall(
          callerId: callerId,
          receiverId: receiverId,
          appointmentId: appointmentId,
          notes: notes,
        );
        
        // Set active call
        _activeCall.value = VideoCallModel(
          id: callData['id'],
          callerId: callerId,
          receiverId: receiverId,
          appointmentId: appointmentId,
          callToken: callData['callToken'],
          channelName: callData['channelName'],
          startTime: DateTime.now(),
          status: 'initiated',
          createdAt: DateTime.now(),
        );
        
        return callData;
      } catch (supabaseError) {
        // If Supabase fails, log the error
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}';
        return null;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to create video call: ${e.toString()}';
      return null;
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Update video call status
  Future<void> updateVideoCallStatus({
    required String callId,
    required String status,
    DateTime? endTime,
    int? duration,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to update video call status in Supabase
      try {
        await _supabaseService.updateVideoCallStatus(
          callId: callId,
          status: status,
          endTime: endTime,
          duration: duration,
        );
        
        // Update active call if it's the same call
        if (_activeCall.value != null && _activeCall.value!.id == callId) {
          _activeCall.value = _activeCall.value!.copyWith(
            status: status,
            endTime: endTime,
            duration: duration,
          );
        }
        
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}';
      }
    } catch (e) {
      _errorMessage.value = 'Failed to update video call status: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // End active call
  Future<void> endActiveCall() async {
    if (_activeCall.value == null) return;
    
    final endTime = DateTime.now();
    final duration = endTime.difference(_activeCall.value!.startTime).inSeconds;
    
    await updateVideoCallStatus(
      callId: _activeCall.value!.id,
      status: 'completed',
      endTime: endTime,
      duration: duration,
    );
    
    _activeCall.value = null;
  }
  
  // Clear active call
  void clearActiveCall() {
    _activeCall.value = null;
  }
  
  // Get call participant details
  Future<UserModel?> getCallParticipant(String userId) async {
    try {
      final user = await _supabaseService.getUserProfile(userId);
      return user;
    } catch (e) {
      _errorMessage.value = 'Failed to get call participant: ${e.toString()}';
      return null;
    }
  }
}
