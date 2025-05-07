import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/doctor_analytics_model.dart';
import '../services/supabase_service.dart';
import '../services/mock_data_service.dart';

/// Controller for managing doctor dashboard analytics
class DoctorAnalyticsController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final MockDataService _mockDataService = MockDataService();
  
  // Observable analytics list
  final RxList<DoctorAnalyticsModel> _analytics = <DoctorAnalyticsModel>[].obs;
  List<DoctorAnalyticsModel> get analytics => _analytics;
  
  // Analytics summary
  final Rx<Map<String, dynamic>> _analyticsSummary = Rx<Map<String, dynamic>>({});
  Map<String, dynamic> get analyticsSummary => _analyticsSummary.value;
  
  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  
  // Get doctor analytics for a date range
  Future<void> getDoctorAnalytics(
    String doctorId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to get analytics from Supabase
      try {
        final analyticsData = await _supabaseService.getDoctorAnalytics(
          doctorId,
          startDate: startDate,
          endDate: endDate,
        );
        
        List<DoctorAnalyticsModel> doctorAnalytics = [];
        for (final data in analyticsData) {
          doctorAnalytics.add(DoctorAnalyticsModel(
            id: data['id'],
            doctorId: data['doctorId'],
            date: DateTime.parse(data['date']),
            appointmentsCount: data['appointmentsCount'],
            completedAppointmentsCount: data['completedAppointmentsCount'],
            cancelledAppointmentsCount: data['cancelledAppointmentsCount'],
            newPatientsCount: data['newPatientsCount'],
            totalPatientsCount: data['totalPatientsCount'],
            videoCallsCount: data['videoCallsCount'],
            videoCallsDuration: data['videoCallsDuration'],
            chatMessagesCount: data['chatMessagesCount'],
            averageRating: data['averageRating'],
            reviewsCount: data['reviewsCount'],
            createdAt: DateTime.parse(data['createdAt']),
          ));
        }
        
        _analytics.assignAll(doctorAnalytics);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }
      
      // Fallback to mock data (empty list for now)
      _analytics.clear();
    } catch (e) {
      _errorMessage.value = 'Failed to get doctor analytics: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get doctor analytics summary
  Future<void> getDoctorAnalyticsSummary(String doctorId) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to get analytics summary from Supabase
      try {
        final summary = await _supabaseService.getDoctorAnalyticsSummary(doctorId);
        _analyticsSummary.value = summary;
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }
      
      // Fallback to mock data
      _analyticsSummary.value = {
        'totalAppointments': 0,
        'completedAppointments': 0,
        'cancelledAppointments': 0,
        'totalPatients': 0,
        'newPatients': 0,
        'totalVideoCalls': 0,
        'totalVideoCallDuration': 0,
        'totalChatMessages': 0,
        'averageRating': 0.0,
        'totalReviews': 0,
      };
    } catch (e) {
      _errorMessage.value = 'Failed to get doctor analytics summary: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Update doctor analytics
  Future<void> updateDoctorAnalytics(String doctorId) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to update analytics in Supabase
      try {
        await _supabaseService.updateDoctorAnalytics(doctorId);
        
        // Refresh analytics data
        final endDate = DateTime.now();
        final startDate = endDate.subtract(const Duration(days: 30));
        
        await getDoctorAnalytics(
          doctorId,
          startDate: startDate,
          endDate: endDate,
        );
        
        await getDoctorAnalyticsSummary(doctorId);
        
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}';
      }
    } catch (e) {
      _errorMessage.value = 'Failed to update doctor analytics: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get appointment completion rate
  double get appointmentCompletionRate {
    if (analyticsSummary.isEmpty) return 0.0;
    
    final totalAppointments = analyticsSummary['totalAppointments'] as int;
    final completedAppointments = analyticsSummary['completedAppointments'] as int;
    
    if (totalAppointments == 0) return 0.0;
    return completedAppointments / totalAppointments;
  }
  
  // Get appointment cancellation rate
  double get appointmentCancellationRate {
    if (analyticsSummary.isEmpty) return 0.0;
    
    final totalAppointments = analyticsSummary['totalAppointments'] as int;
    final cancelledAppointments = analyticsSummary['cancelledAppointments'] as int;
    
    if (totalAppointments == 0) return 0.0;
    return cancelledAppointments / totalAppointments;
  }
  
  // Get formatted video call duration
  String get formattedVideoCallDuration {
    if (analyticsSummary.isEmpty) return '00:00:00';
    
    final duration = analyticsSummary['totalVideoCallDuration'] as int;
    final hours = (duration ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((duration % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    
    return '$hours:$minutes:$seconds';
  }
}
