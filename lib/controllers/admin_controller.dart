import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import '../services/doctor_verification_service.dart';

/// Controller for managing admin-specific operations and state
class AdminController extends GetxController {
  final AdminService _adminService = Get.find<AdminService>();
  final DoctorVerificationService _doctorVerificationService =
      Get.find<DoctorVerificationService>();

  // Observable lists
  final RxList<UserModel> _users = <UserModel>[].obs;
  final RxList<UserModel> _patients = <UserModel>[].obs;
  final RxList<UserModel> _doctors = <UserModel>[].obs;
  final RxList<UserModel> _pendingDoctors = <UserModel>[].obs;
  final RxList<UserModel> _approvedDoctors = <UserModel>[].obs;
  final RxList<UserModel> _rejectedDoctors = <UserModel>[].obs;

  // Dashboard statistics
  final RxInt _totalUsers = 0.obs;
  final RxInt _totalDoctors = 0.obs;
  final RxInt _totalPatients = 0.obs;
  final RxInt _pendingApprovals = 0.obs;

  // Loading states
  final RxBool _isLoadingUsers = false.obs;
  final RxBool _isLoadingPatients = false.obs;
  final RxBool _isLoadingDoctors = false.obs;
  final RxBool _isLoadingPendingDoctors = false.obs;
  final RxBool _isLoadingApprovedDoctors = false.obs;
  final RxBool _isLoadingRejectedDoctors = false.obs;
  final RxBool _isLoadingDashboardStats = false.obs;
  final RxBool _isCreatingAdmin = false.obs;
  final RxBool _isDeletingUser = false.obs;
  final RxBool _isApprovingDoctor = false.obs;
  final RxBool _isRejectingDoctor = false.obs;

  // Error messages
  final RxString _errorMessage = ''.obs;

  // Getters
  List<UserModel> get users => _users;
  List<UserModel> get patients => _patients;
  List<UserModel> get doctors => _doctors;
  List<UserModel> get pendingDoctors => _pendingDoctors;
  List<UserModel> get approvedDoctors => _approvedDoctors;
  List<UserModel> get rejectedDoctors => _rejectedDoctors;

  // Dashboard statistics getters
  int get totalUsers => _totalUsers.value;
  int get totalDoctors => _totalDoctors.value;
  int get totalPatients => _totalPatients.value;
  int get pendingApprovals => _pendingApprovals.value;

  bool get isLoadingUsers => _isLoadingUsers.value;
  bool get isLoadingPatients => _isLoadingPatients.value;
  bool get isLoadingDoctors => _isLoadingDoctors.value;
  bool get isLoadingPendingDoctors => _isLoadingPendingDoctors.value;
  bool get isLoadingApprovedDoctors => _isLoadingApprovedDoctors.value;
  bool get isLoadingRejectedDoctors => _isLoadingRejectedDoctors.value;
  bool get isLoadingDashboardStats => _isLoadingDashboardStats.value;
  bool get isCreatingAdmin => _isCreatingAdmin.value;
  bool get isDeletingUser => _isDeletingUser.value;
  bool get isApprovingDoctor => _isApprovingDoctor.value;
  bool get isRejectingDoctor => _isRejectingDoctor.value;

  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    // Load data when controller is initialized
    fetchAllUsers();
    fetchAllPatients();
    fetchAllDoctors();
    fetchPendingDoctors();
    fetchApprovedDoctors();
    fetchRejectedDoctors();
    fetchDashboardStats();
  }

  // Fetch dashboard statistics
  Future<void> fetchDashboardStats() async {
    _isLoadingDashboardStats.value = true;
    _errorMessage.value = '';

    try {
      final stats = await _adminService.getDashboardStats();
      _totalUsers.value = stats['totalUsers'] ?? 0;
      _totalDoctors.value = stats['totalDoctors'] ?? 0;
      _totalPatients.value = stats['totalPatients'] ?? 0;
      _pendingApprovals.value = stats['pendingApprovals'] ?? 0;
    } catch (e) {
      _errorMessage.value =
          'Failed to fetch dashboard statistics: ${e.toString()}';
    } finally {
      _isLoadingDashboardStats.value = false;
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    return await _adminService.isCurrentUserAdmin();
  }

  // Fetch all users
  Future<void> fetchAllUsers() async {
    _isLoadingUsers.value = true;
    _errorMessage.value = '';

    try {
      final users = await _adminService.getAllUsers();
      _users.assignAll(users);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch users: ${e.toString()}';
    } finally {
      _isLoadingUsers.value = false;
    }
  }

  // Fetch all patients
  Future<void> fetchAllPatients() async {
    _isLoadingPatients.value = true;
    _errorMessage.value = '';

    try {
      final patients = await _adminService.getAllPatients();
      _patients.assignAll(patients);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch patients: ${e.toString()}';
    } finally {
      _isLoadingPatients.value = false;
    }
  }

  // Fetch all doctors
  Future<void> fetchAllDoctors() async {
    _isLoadingDoctors.value = true;
    _errorMessage.value = '';

    try {
      final doctors = await _adminService.getAllDoctors();
      _doctors.assignAll(doctors);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch doctors: ${e.toString()}';
    } finally {
      _isLoadingDoctors.value = false;
    }
  }

  // Create a new admin
  Future<bool> createAdmin(
    String name,
    String email,
    String password, [
    Map<String, dynamic>? additionalData,
  ]) async {
    _isCreatingAdmin.value = true;
    _errorMessage.value = '';

    try {
      final success = await _adminService.createAdmin(
        name,
        email,
        password,
        additionalData,
      );

      if (success) {
        await fetchAllUsers();
      } else {
        _errorMessage.value =
            'Failed to create admin. Only admins can create other admins.';
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Failed to create admin: ${e.toString()}';
      return false;
    } finally {
      _isCreatingAdmin.value = false;
    }
  }

  // Create the first admin (no admin check required)
  Future<bool> createFirstAdmin(
    String name,
    String email,
    String password,
  ) async {
    _isCreatingAdmin.value = true;
    _errorMessage.value = '';

    try {
      final success = await _adminService.createFirstAdmin(
        name,
        email,
        password,
      );
      if (success) {
        await fetchAllUsers();
      } else {
        _errorMessage.value =
            'Failed to create first admin. Admin users might already exist.';
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Failed to create first admin: ${e.toString()}';
      return false;
    } finally {
      _isCreatingAdmin.value = false;
    }
  }

  // Update a user
  Future<bool> updateUser(UserModel user) async {
    final RxBool isUpdatingUser = true.obs;
    _errorMessage.value = '';

    try {
      final success = await _adminService.updateUser(user);
      if (success) {
        // Refresh all lists
        await fetchAllUsers();
        await fetchAllPatients();
        await fetchAllDoctors();
      } else {
        _errorMessage.value =
            'Failed to update user. Only admins can update users.';
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Failed to update user: ${e.toString()}';
      return false;
    } finally {
      isUpdatingUser.value = false;
    }
  }

  // Delete a user
  Future<bool> deleteUser(String userId) async {
    _isDeletingUser.value = true;
    _errorMessage.value = '';

    try {
      final success = await _adminService.deleteUser(userId);
      if (success) {
        // Refresh all lists
        await fetchAllUsers();
        await fetchAllPatients();
        await fetchAllDoctors();
      } else {
        _errorMessage.value =
            'Failed to delete user. Only admins can delete users.';
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Failed to delete user: ${e.toString()}';
      return false;
    } finally {
      _isDeletingUser.value = false;
    }
  }

  // Clear doctor lists
  void clearDoctorLists() {
    _pendingDoctors.clear();
    _approvedDoctors.clear();
    _rejectedDoctors.clear();
    debugPrint('Cleared all doctor lists');
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    clearDoctorLists();
    await fetchAllUsers();
    await fetchAllPatients();
    await fetchAllDoctors();
    await fetchPendingDoctors();
    await fetchApprovedDoctors();
    await fetchRejectedDoctors();
    await fetchDashboardStats();
  }

  // Fetch doctors by verification status
  Future<void> fetchDoctorsByStatus(String status) async {
    switch (status) {
      case 'pending':
        await fetchPendingDoctors();
        break;
      case 'approved':
        await fetchApprovedDoctors();
        break;
      case 'rejected':
        await fetchRejectedDoctors();
        break;
    }
  }

  // Fetch pending doctors
  Future<void> fetchPendingDoctors() async {
    _isLoadingPendingDoctors.value = true;
    _errorMessage.value = '';

    try {
      final doctors = await _doctorVerificationService
          .fetchDoctorsByVerificationStatus('pending');
      _pendingDoctors.assignAll(doctors);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch pending doctors: ${e.toString()}';
    } finally {
      _isLoadingPendingDoctors.value = false;
    }
  }

  // Fetch approved doctors
  Future<void> fetchApprovedDoctors() async {
    _isLoadingApprovedDoctors.value = true;
    _errorMessage.value = '';

    try {
      final doctors = await _doctorVerificationService
          .fetchDoctorsByVerificationStatus('approved');
      _approvedDoctors.assignAll(doctors);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch approved doctors: ${e.toString()}';
    } finally {
      _isLoadingApprovedDoctors.value = false;
    }
  }

  // Fetch rejected doctors
  Future<void> fetchRejectedDoctors() async {
    _isLoadingRejectedDoctors.value = true;
    _errorMessage.value = '';

    try {
      final doctors = await _doctorVerificationService
          .fetchDoctorsByVerificationStatus('rejected');
      _rejectedDoctors.assignAll(doctors);
    } catch (e) {
      _errorMessage.value = 'Failed to fetch rejected doctors: ${e.toString()}';
    } finally {
      _isLoadingRejectedDoctors.value = false;
    }
  }

  // Approve a doctor
  Future<bool> approveDoctor(String doctorId) async {
    _isApprovingDoctor.value = true;
    _errorMessage.value = '';

    try {
      debugPrint('AdminController: Approving doctor with ID: $doctorId');
      final success = await _doctorVerificationService.approveDoctor(doctorId);

      if (success) {
        debugPrint(
          'AdminController: Doctor approved successfully, updating UI',
        );

        // Find the doctor in the pending list
        final doctorToMove = _pendingDoctors.firstWhere(
          (doctor) => doctor.id == doctorId,
          orElse:
              () => _doctors.firstWhere(
                (doctor) => doctor.id == doctorId,
                orElse:
                    () => UserModel(
                      id: doctorId,
                      name: 'Unknown Doctor',
                      email: 'unknown@example.com',
                      phone: '',
                      userType: UserType.doctor,
                      verificationStatus: 'approved',
                    ),
              ),
        );

        // Create an updated doctor model with approved status
        final updatedDoctor = doctorToMove.copyWith(
          verificationStatus: 'approved',
          rejectionReason: null,
        );

        // Remove from pending list
        _pendingDoctors.removeWhere((doctor) => doctor.id == doctorId);

        // Add to approved list if not already there
        if (!_approvedDoctors.any((doctor) => doctor.id == doctorId)) {
          _approvedDoctors.add(updatedDoctor);
        }

        // Remove from rejected list if it's there
        _rejectedDoctors.removeWhere((doctor) => doctor.id == doctorId);

        // Log the counts after UI update
        debugPrint(
          'AdminController: After UI update - Pending: ${_pendingDoctors.length}, Approved: ${_approvedDoctors.length}, Rejected: ${_rejectedDoctors.length}',
        );

        // Refresh doctor lists in the background
        fetchPendingDoctors();
        fetchApprovedDoctors();
        fetchRejectedDoctors();
        fetchAllDoctors();
      } else {
        _errorMessage.value =
            'Failed to approve doctor. Only admins can approve doctors.';
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Failed to approve doctor: ${e.toString()}';
      debugPrint('AdminController: Error approving doctor: $e');
      return false;
    } finally {
      _isApprovingDoctor.value = false;
    }
  }

  // Reject a doctor
  Future<bool> rejectDoctor(String doctorId, String rejectionReason) async {
    _isRejectingDoctor.value = true;
    _errorMessage.value = '';

    try {
      debugPrint('AdminController: Rejecting doctor with ID: $doctorId');
      debugPrint('AdminController: Rejection reason: $rejectionReason');

      final success = await _doctorVerificationService.rejectDoctor(
        doctorId,
        rejectionReason,
      );

      if (success) {
        debugPrint(
          'AdminController: Doctor rejected successfully, updating UI',
        );

        // Find the doctor in the pending list
        final doctorToMove = _pendingDoctors.firstWhere(
          (doctor) => doctor.id == doctorId,
          orElse:
              () => _doctors.firstWhere(
                (doctor) => doctor.id == doctorId,
                orElse:
                    () => UserModel(
                      id: doctorId,
                      name: 'Unknown Doctor',
                      email: 'unknown@example.com',
                      phone: '',
                      userType: UserType.doctor,
                      verificationStatus: 'rejected',
                      rejectionReason: rejectionReason,
                    ),
              ),
        );

        // Create an updated doctor model with rejected status
        final updatedDoctor = doctorToMove.copyWith(
          verificationStatus: 'rejected',
          rejectionReason: rejectionReason,
        );

        // Remove from pending list
        _pendingDoctors.removeWhere((doctor) => doctor.id == doctorId);

        // Remove from approved list if it's there
        _approvedDoctors.removeWhere((doctor) => doctor.id == doctorId);

        // Add to rejected list if not already there
        if (!_rejectedDoctors.any((doctor) => doctor.id == doctorId)) {
          _rejectedDoctors.add(updatedDoctor);
        }

        // Log the counts after UI update
        debugPrint(
          'AdminController: After UI update - Pending: ${_pendingDoctors.length}, Approved: ${_approvedDoctors.length}, Rejected: ${_rejectedDoctors.length}',
        );

        // Refresh doctor lists in the background
        fetchPendingDoctors();
        fetchApprovedDoctors();
        fetchRejectedDoctors();
        fetchAllDoctors();
      } else {
        _errorMessage.value =
            'Failed to reject doctor. Only admins can reject doctors.';
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Failed to reject doctor: ${e.toString()}';
      debugPrint('AdminController: Error rejecting doctor: $e');
      return false;
    } finally {
      _isRejectingDoctor.value = false;
    }
  }

  // Get doctor verification documents
  Future<List<Map<String, dynamic>>> getDoctorVerificationDocuments(
    String doctorId,
  ) async {
    try {
      return await _doctorVerificationService.getDoctorVerificationDocuments(
        doctorId,
      );
    } catch (e) {
      _errorMessage.value =
          'Failed to get doctor verification documents: ${e.toString()}';
      return [];
    }
  }
}
