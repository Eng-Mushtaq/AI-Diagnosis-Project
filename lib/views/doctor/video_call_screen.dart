import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../controllers/video_call_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';
import '../../widgets/loading_indicator.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final String callToken;
  final String channelName;
  final bool isInitiator;
  final String patientId;

  const VideoCallScreen({
    Key? key,
    required this.callId,
    required this.callToken,
    required this.channelName,
    required this.isInitiator,
    required this.patientId,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final VideoCallController _videoCallController = Get.find<VideoCallController>();
  final AuthController _authController = Get.find<AuthController>();
  
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _callTimer;
  int _callDuration = 0;
  UserModel? _participant;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  @override
  void dispose() {
    _endCall();
    _callTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeCall() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get participant details
      final participant = await _videoCallController.getCallParticipant(widget.patientId);
      
      setState(() {
        _participant = participant;
        _isLoading = false;
      });
      
      // In a real implementation, we would initialize the video call SDK here
      // For this demo, we'll simulate a connection after a short delay
      if (widget.isInitiator) {
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _isConnected = true;
          });
          _startCallTimer();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize call: ${e.toString()}';
      });
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // In a real implementation, we would mute/unmute the audio here
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    // In a real implementation, we would turn on/off the camera here
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    // In a real implementation, we would toggle the speaker here
  }

  void _endCall() async {
    _callTimer?.cancel();
    
    // Update call status in Supabase
    if (_isConnected) {
      await _videoCallController.updateVideoCallStatus(
        callId: widget.callId,
        status: 'completed',
        endTime: DateTime.now(),
        duration: _callDuration,
      );
    } else {
      await _videoCallController.updateVideoCallStatus(
        callId: widget.callId,
        status: widget.isInitiator ? 'missed' : 'declined',
      );
    }
    
    _videoCallController.clearActiveCall();
    Get.back();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const LoadingIndicator(color: Colors.white)
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildCallView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallView() {
    return Stack(
      children: [
        // This would be the remote video view in a real implementation
        Container(
          color: Colors.grey[900],
          child: Center(
            child: _isConnected
                ? const Icon(
                    Icons.person,
                    color: Colors.white54,
                    size: 120,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                        backgroundImage: _participant?.profileImage != null &&
                                _participant!.profileImage!.isNotEmpty
                            ? NetworkImage(_participant!.profileImage!)
                            : null,
                        child: _participant?.profileImage == null ||
                                _participant!.profileImage!.isEmpty
                            ? Text(
                                _participant?.name.substring(0, 1).toUpperCase() ?? 'P',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _participant?.name ?? 'Patient',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isInitiator ? 'Calling...' : 'Incoming call...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        
        // This would be the local video view in a real implementation
        if (_isConnected)
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: _isCameraOff
                  ? const Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white54,
                        size: 32,
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.person,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
            ),
          ),
        
        // Call info and controls
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Call controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_isConnected)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      onPressed: _toggleMute,
                    ),
                    const SizedBox(width: 24),
                    _buildControlButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      label: _isCameraOff ? 'Camera On' : 'Camera Off',
                      onPressed: _toggleCamera,
                    ),
                    const SizedBox(width: 24),
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      label: _isSpeakerOn ? 'Speaker Off' : 'Speaker On',
                      onPressed: _toggleSpeaker,
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              _buildEndCallButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'End Call',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
