import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_text_field.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen>
    with SingleTickerProviderStateMixin {
  final AdminController _adminController = Get.find<AdminController>();
  final AdminNavigationController _navigationController =
      Get.find<AdminNavigationController>();

  late TabController _tabController;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDoctors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load doctors data
  Future<void> _loadDoctors() async {
    _isLoading.value = true;

    try {
      // Clear existing lists first to avoid any stale data
      _adminController.clearDoctorLists();

      // Add debug logging
      debugPrint('Loading doctors data...');

      // Fetch all doctor data by verification status
      // Fetch in sequence to ensure each query completes before the next one starts
      await _adminController.fetchPendingDoctors();
      debugPrint(
        'Pending doctors loaded: ${_adminController.pendingDoctors.length}',
      );

      await _adminController.fetchApprovedDoctors();
      debugPrint(
        'Approved doctors loaded: ${_adminController.approvedDoctors.length}',
      );

      await _adminController.fetchRejectedDoctors();
      debugPrint(
        'Rejected doctors loaded: ${_adminController.rejectedDoctors.length}',
      );

      // Log the verification status of each doctor for debugging
      for (final doctor in _adminController.pendingDoctors) {
        debugPrint(
          'Pending doctor: ${doctor.name} (${doctor.id}) - Status: ${doctor.verificationStatus}',
        );
      }

      for (final doctor in _adminController.approvedDoctors) {
        debugPrint(
          'Approved doctor: ${doctor.name} (${doctor.id}) - Status: ${doctor.verificationStatus}',
        );
      }

      for (final doctor in _adminController.rejectedDoctors) {
        debugPrint(
          'Rejected doctor: ${doctor.name} (${doctor.id}) - Status: ${doctor.verificationStatus}',
        );
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      Get.snackbar(
        'Error',
        'Failed to load doctors: ${e.toString()}',
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
        title: const Text('Doctor Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Approval'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDoctors),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildDoctorList(
              _adminController.pendingDoctors,
              DoctorStatus.pending,
            ),
            _buildDoctorList(
              _adminController.approvedDoctors,
              DoctorStatus.approved,
            ),
            _buildDoctorList(
              _adminController.rejectedDoctors,
              DoctorStatus.rejected,
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => AdminBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }

  // Build doctor list
  Widget _buildDoctorList(List<UserModel> doctors, DoctorStatus status) {
    if (doctors.isEmpty) {
      return Center(
        child: Text('No ${status.toString().split('.').last} doctors found'),
      );
    }

    return ListView.builder(
      itemCount: doctors.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      doctor.profileImage != null &&
                              doctor.profileImage!.isNotEmpty
                          ? NetworkImage(doctor.profileImage!)
                          : null,
                  child:
                      doctor.profileImage == null ||
                              doctor.profileImage!.isEmpty
                          ? Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey[600],
                          )
                          : null,
                ),
                title: Text(
                  doctor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Email: ${doctor.email}'),
                    if (doctor.specialization != null)
                      Text('Specialization: ${doctor.specialization}'),
                    if (doctor.hospital != null)
                      Text('Hospital: ${doctor.hospital}'),
                    if (doctor.experience != null)
                      Text('Experience: ${doctor.experience} years'),
                    Text('Status: ${doctor.verificationStatus ?? "pending"}'),
                    if (status == DoctorStatus.rejected &&
                        doctor.rejectionReason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Rejection Reason: ${doctor.rejectionReason}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing:
                    status == DoctorStatus.pending
                        ? null
                        : IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            color: AppColors.primaryColor,
                          ),
                          onPressed: () => _showDoctorDetails(doctor),
                        ),
                onTap: () => _showDoctorDetails(doctor),
              ),
              if (status == DoctorStatus.pending)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => _approveDoctor(doctor),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => _rejectDoctor(doctor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Show doctor details
  void _showDoctorDetails(UserModel doctor) {
    Get.dialog(
      AlertDialog(
        title: Text(doctor.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      doctor.profileImage != null &&
                              doctor.profileImage!.isNotEmpty
                          ? NetworkImage(doctor.profileImage!)
                          : null,
                  child:
                      doctor.profileImage == null ||
                              doctor.profileImage!.isEmpty
                          ? Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.grey[600],
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Email', doctor.email),
              _buildDetailRow('Phone', doctor.phone),
              if (doctor.specialization != null)
                _buildDetailRow('Specialization', doctor.specialization!),
              if (doctor.hospital != null)
                _buildDetailRow('Hospital', doctor.hospital!),
              if (doctor.experience != null)
                _buildDetailRow('Experience', '${doctor.experience} years'),
              _buildDetailRow(
                'Verification Status',
                doctor.verificationStatus ?? 'pending',
                textColor:
                    doctor.verificationStatus == 'rejected'
                        ? Colors.red
                        : doctor.verificationStatus == 'approved'
                        ? Colors.green
                        : null,
              ),
              if (doctor.rejectionReason != null)
                _buildDetailRow(
                  'Rejection Reason',
                  doctor.rejectionReason!,
                  textColor: Colors.red,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  // Build detail row
  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textColor != null ? TextStyle(color: textColor) : null,
            ),
          ),
        ],
      ),
    );
  }

  // Approve doctor
  void _approveDoctor(UserModel doctor) async {
    final RxBool isApproving = false.obs;

    try {
      isApproving.value = true;
      debugPrint('Approving doctor ${doctor.id}');
      final success = await _adminController.approveDoctor(doctor.id);

      if (success) {
        // Update the doctor's status in the UI immediately
        final updatedDoctor = doctor.copyWith(
          verificationStatus: 'approved',
          rejectionReason: null, // Clear any previous rejection reason
        );

        // Remove from pending list if it's there
        if (_adminController.pendingDoctors.any((d) => d.id == doctor.id)) {
          _adminController.pendingDoctors.removeWhere((d) => d.id == doctor.id);
        }

        // Add to approved list if not already there
        if (!_adminController.approvedDoctors.any((d) => d.id == doctor.id)) {
          _adminController.approvedDoctors.add(updatedDoctor);
        }

        // Show success message
        Get.snackbar(
          'Success',
          'Doctor ${doctor.name} has been approved',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Switch to the approved tab
        _tabController.animateTo(1); // Index 1 is the approved tab

        // Refresh the doctor lists in the background
        _loadDoctors();
      } else {
        Get.snackbar(
          'Error',
          'Failed to approve doctor: ${_adminController.errorMessage}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to approve doctor: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isApproving.value = false;
    }
  }

  // Reject doctor
  void _rejectDoctor(UserModel doctor) {
    final TextEditingController reasonController = TextEditingController();
    final RxBool isRejecting = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Reject Doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for rejecting ${doctor.name}:'),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Rejection Reason',
              hint: 'Enter reason for rejection',
              controller: reasonController,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(
            () => TextButton(
              onPressed:
                  isRejecting.value
                      ? null
                      : () async {
                        if (reasonController.text.trim().isEmpty) {
                          Get.snackbar(
                            'Error',
                            'Please provide a rejection reason',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        isRejecting.value = true;
                        try {
                          debugPrint(
                            'Rejecting doctor ${doctor.id} with reason: ${reasonController.text.trim()}',
                          );
                          final success = await _adminController.rejectDoctor(
                            doctor.id,
                            reasonController.text.trim(),
                          );

                          if (success) {
                            Get.back();

                            // Update the doctor's status in the UI immediately
                            final updatedDoctor = doctor.copyWith(
                              verificationStatus: 'rejected',
                              rejectionReason: reasonController.text.trim(),
                            );

                            // Remove from pending list if it's there
                            if (_adminController.pendingDoctors.any(
                              (d) => d.id == doctor.id,
                            )) {
                              _adminController.pendingDoctors.removeWhere(
                                (d) => d.id == doctor.id,
                              );
                            }

                            // Add to rejected list if not already there
                            if (!_adminController.rejectedDoctors.any(
                              (d) => d.id == doctor.id,
                            )) {
                              _adminController.rejectedDoctors.add(
                                updatedDoctor,
                              );
                            }

                            // Show success message
                            Get.snackbar(
                              'Success',
                              'Doctor ${doctor.name} has been rejected',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );

                            // Switch to the rejected tab
                            _tabController.animateTo(
                              2,
                            ); // Index 2 is the rejected tab

                            // Refresh the doctor lists in the background
                            _loadDoctors();
                          } else {
                            Get.snackbar(
                              'Error',
                              'Failed to reject doctor: ${_adminController.errorMessage}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Failed to reject doctor: ${e.toString()}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } finally {
                          isRejecting.value = false;
                        }
                      },
              child:
                  isRejecting.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
            ),
          ),
        ],
      ),
    ).then((_) {
      reasonController.dispose();
    });
  }
}

// Doctor status enum
enum DoctorStatus { pending, approved, rejected }
