import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../models/doctor_model.dart';

/// Controller for managing doctor verification
class DoctorVerificationController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // Error message
  final RxString _errorMessage = ''.obs;
  String get errorMessage => _errorMessage.value;

  // Verification documents
  final RxList<Map<String, dynamic>> _documents = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get documents => _documents;

  // Document types
  final List<String> documentTypes = [
    'Medical License',
    'Medical Degree',
    'Specialty Certificate',
    'Identity Document',
    'Other',
  ];

  /// Upload a verification document
  Future<bool> uploadVerificationDocument(
    String filePath,
    String doctorId,
    String documentType,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.uploadVerificationDocument(
        filePath,
        doctorId,
        documentType,
      );

      // Refresh documents list
      await getVerificationDocuments(doctorId);

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to upload document: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Upload a verification document from bytes
  Future<bool> uploadVerificationDocumentFromBytes(
    List<int> bytes,
    String doctorId,
    String documentType,
    String fileExtension,
  ) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.uploadVerificationDocumentFromBytes(
        bytes,
        doctorId,
        documentType,
        fileExtension,
      );

      // Refresh documents list
      await getVerificationDocuments(doctorId);

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to upload document: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get verification documents for a doctor
  Future<void> getVerificationDocuments(String doctorId) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final documents = await _supabaseService.getVerificationDocuments(
        doctorId,
      );
      _documents.assignAll(documents);
    } catch (e) {
      _errorMessage.value = 'Failed to get documents: ${e.toString()}';
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update doctor verification status
  Future<bool> updateVerificationStatus(
    String doctorId,
    String status, {
    String? rejectionReason,
    String? verifiedBy,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      await _supabaseService.updateDoctorVerificationStatus(
        doctorId,
        status,
        rejectionReason: rejectionReason,
        verifiedBy: verifiedBy,
      );

      return true;
    } catch (e) {
      _errorMessage.value =
          'Failed to update verification status: ${e.toString()}';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Check if a doctor has submitted verification documents
  Future<bool> hasSubmittedDocuments(String doctorId) async {
    try {
      await getVerificationDocuments(doctorId);
      return _documents.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get verification status for a doctor
  Future<String> getVerificationStatus(String doctorId) async {
    try {
      final doctorData =
          await _supabaseService.supabaseClient
              .from('doctors_profile')
              .select('verification_status')
              .eq('id', doctorId)
              .single();

      return doctorData['verification_status'] ?? 'pending';
    } catch (e) {
      debugPrint('Error getting verification status: $e');
      return 'pending';
    }
  }

  /// Get rejection reason for a doctor
  Future<String?> getRejectionReason(String doctorId) async {
    try {
      final doctorData =
          await _supabaseService.supabaseClient
              .from('doctors_profile')
              .select('rejection_reason')
              .eq('id', doctorId)
              .single();

      return doctorData['rejection_reason'];
    } catch (e) {
      debugPrint('Error getting rejection reason: $e');
      return null;
    }
  }
}
