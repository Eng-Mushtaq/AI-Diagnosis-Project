import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/doctor_review_model.dart';
import '../services/supabase_service.dart';
import '../services/mock_data_service.dart';

/// Controller for managing doctor reviews
class DoctorReviewController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final MockDataService _mockDataService = MockDataService();
  
  // Observable reviews list
  final RxList<DoctorReviewModel> _reviews = <DoctorReviewModel>[].obs;
  List<DoctorReviewModel> get reviews => _reviews;
  
  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  
  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;
  
  // Get doctor reviews
  Future<void> getDoctorReviews(String doctorId) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to get reviews from Supabase
      try {
        final reviewsData = await _supabaseService.getDoctorReviews(doctorId);
        
        List<DoctorReviewModel> doctorReviews = [];
        for (final reviewData in reviewsData) {
          doctorReviews.add(DoctorReviewModel(
            id: reviewData['id'],
            doctorId: reviewData['doctorId'],
            patientId: reviewData['patientId'],
            appointmentId: reviewData['appointmentId'],
            rating: reviewData['rating'],
            review: reviewData['review'],
            isAnonymous: reviewData['isAnonymous'],
            isVerified: reviewData['isVerified'],
            createdAt: DateTime.parse(reviewData['createdAt']),
            patientName: reviewData['patientName'],
            patientImage: reviewData['patientImage'],
            appointmentDate: reviewData['appointmentDate'] != null
                ? DateTime.parse(reviewData['appointmentDate'])
                : null,
          ));
        }
        
        _reviews.assignAll(doctorReviews);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }
      
      // Fallback to mock data (empty list for now)
      _reviews.clear();
    } catch (e) {
      _errorMessage.value = 'Failed to get doctor reviews: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Get patient reviews
  Future<void> getPatientReviews(String patientId) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to get reviews from Supabase
      try {
        final reviewsData = await _supabaseService.getPatientReviews(patientId);
        
        List<DoctorReviewModel> patientReviews = [];
        for (final reviewData in reviewsData) {
          patientReviews.add(DoctorReviewModel(
            id: reviewData['id'],
            doctorId: reviewData['doctorId'],
            patientId: reviewData['patientId'],
            appointmentId: reviewData['appointmentId'],
            rating: reviewData['rating'],
            review: reviewData['review'],
            isAnonymous: reviewData['isAnonymous'],
            isVerified: reviewData['isVerified'],
            createdAt: DateTime.parse(reviewData['createdAt']),
            patientName: reviewData['doctorName'], // Using doctorName for display
            patientImage: reviewData['doctorImage'], // Using doctorImage for display
            appointmentDate: reviewData['appointmentDate'] != null
                ? DateTime.parse(reviewData['appointmentDate'])
                : null,
          ));
        }
        
        _reviews.assignAll(patientReviews);
        return;
      } catch (supabaseError) {
        // If Supabase fails, log the error and fall back to mock data
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}. Using mock data.';
      }
      
      // Fallback to mock data (empty list for now)
      _reviews.clear();
    } catch (e) {
      _errorMessage.value = 'Failed to get patient reviews: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Add a review for a doctor
  Future<bool> addDoctorReview({
    required String doctorId,
    required String patientId,
    String? appointmentId,
    required int rating,
    String? review,
    bool isAnonymous = false,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Check if patient has already reviewed this doctor
      final hasReviewed = await _supabaseService.hasPatientReviewedDoctor(
        patientId: patientId,
        doctorId: doctorId,
        appointmentId: appointmentId,
      );
      
      if (hasReviewed) {
        _errorMessage.value = 'You have already reviewed this doctor';
        return false;
      }
      
      // Try to add review to Supabase
      try {
        final reviewData = await _supabaseService.addDoctorReview(
          doctorId: doctorId,
          patientId: patientId,
          appointmentId: appointmentId,
          rating: rating,
          review: review,
          isAnonymous: isAnonymous,
        );
        
        // Add the new review to the list
        final newReview = DoctorReviewModel(
          id: reviewData['id'],
          doctorId: reviewData['doctorId'],
          patientId: reviewData['patientId'],
          appointmentId: reviewData['appointmentId'],
          rating: reviewData['rating'],
          review: reviewData['review'],
          isAnonymous: reviewData['isAnonymous'],
          isVerified: reviewData['isVerified'],
          createdAt: DateTime.parse(reviewData['createdAt']),
        );
        
        _reviews.insert(0, newReview);
        return true;
      } catch (supabaseError) {
        // If Supabase fails, log the error
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to add review: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Update a doctor review
  Future<bool> updateDoctorReview({
    required String reviewId,
    required int rating,
    String? review,
    bool? isAnonymous,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';
    
    try {
      // Try to update review in Supabase
      try {
        await _supabaseService.updateDoctorReview(
          reviewId: reviewId,
          rating: rating,
          review: review,
          isAnonymous: isAnonymous,
        );
        
        // Update the review in the list
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          _reviews[index] = _reviews[index].copyWith(
            rating: rating,
            review: review,
            isAnonymous: isAnonymous,
          );
        }
        
        return true;
      } catch (supabaseError) {
        // If Supabase fails, log the error
        _errorMessage.value = 'Supabase error: ${supabaseError.toString()}';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to update review: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  // Calculate average rating
  double get averageRating {
    if (_reviews.isEmpty) return 0.0;
    
    final sum = _reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return sum / _reviews.length;
  }
  
  // Get rating distribution
  Map<int, int> get ratingDistribution {
    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    
    for (final review in _reviews) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }
    
    return distribution;
  }
}
