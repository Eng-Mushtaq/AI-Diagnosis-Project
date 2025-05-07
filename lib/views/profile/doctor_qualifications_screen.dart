import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/doctor_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../constants/app_colors.dart';

class DoctorQualificationsScreen extends StatefulWidget {
  const DoctorQualificationsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorQualificationsScreen> createState() =>
      _DoctorQualificationsScreenState();
}

class _DoctorQualificationsScreenState
    extends State<DoctorQualificationsScreen> {
  final DoctorController _doctorController = Get.find<DoctorController>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _qualificationController =
      TextEditingController();
  final RxList<String> _qualifications = <String>[].obs;
  final RxBool _isLoading = false.obs;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize qualifications list
    if (_doctorController.selectedDoctor != null &&
        _doctorController.selectedDoctor!.qualifications != null) {
      _qualifications.assignAll(
        _doctorController.selectedDoctor!.qualifications!,
      );
    }
  }

  @override
  void dispose() {
    _qualificationController.dispose();
    super.dispose();
  }

  // Add a new qualification
  Future<void> _addQualification() async {
    if (!_formKey.currentState!.validate()) return;

    final qualification = _qualificationController.text.trim();
    if (qualification.isEmpty) return;

    if (_qualifications.contains(qualification)) {
      Get.snackbar(
        'Error',
        'This qualification already exists',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _isLoading.value = true;

    try {
      final success = await _doctorController.addDoctorQualification(
        _doctorController.selectedDoctor!.id,
        qualification,
      );

      if (success) {
        _qualifications.add(qualification);
        _qualificationController.clear();
        Get.snackbar(
          'Success',
          'Qualification added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to add qualification',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Remove a qualification
  Future<void> _removeQualification(String qualification) async {
    _isLoading.value = true;

    try {
      final success = await _doctorController.removeDoctorQualification(
        _doctorController.selectedDoctor!.id,
        qualification,
      );

      if (success) {
        _qualifications.remove(qualification);
        Get.snackbar(
          'Success',
          'Qualification removed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove qualification',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Update all qualifications
  Future<void> _updateQualifications() async {
    _isLoading.value = true;

    try {
      final success = await _doctorController.updateDoctorQualifications(
        _doctorController.selectedDoctor!.id,
        _qualifications,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Qualifications updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update qualifications',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Manage Qualifications',
        showBackButton: true,
      ),
      body: Obx(() {
        if (_doctorController.selectedDoctor == null) {
          return const Center(child: Text('No doctor selected'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add qualification form
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qualificationController,
                        decoration: InputDecoration(
                          labelText: 'Add Qualification',
                          hintText: 'e.g., MBBS, MD, MS, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a qualification';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading.value ? null : _addQualification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Qualifications list
              const Text(
                'Your Qualifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 16),

              if (_qualifications.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No qualifications added yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  itemCount: _qualifications.length,
                  itemBuilder: (context, index) {
                    final qualification = _qualifications[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(qualification),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeQualification(qualification),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Loading indicator
              if (_isLoading.value)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),

              // Update button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CustomButton(
                  text: 'Save Changes',
                  onPressed: _isLoading.value ? () {} : _updateQualifications,
                  isLoading: _isLoading.value,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
