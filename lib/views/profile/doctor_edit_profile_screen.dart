import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  const DoctorEditProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorEditProfileScreen> createState() => _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ProfileController _profileController = Get.find<ProfileController>();
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specializationController;
  late TextEditingController _hospitalController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _experienceController;

  // Availability toggles
  late bool _isAvailableForChat;
  late bool _isAvailableForVideo;

  // List controllers
  final RxList<String> _qualifications = <String>[].obs;

  // Text controller for adding new qualification
  final TextEditingController _newQualificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = _authController.user;
    if (user == null) return;

    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone);
    _specializationController = TextEditingController(text: user.specialization ?? '');
    _hospitalController = TextEditingController(text: user.hospital ?? '');
    _licenseNumberController = TextEditingController(text: user.licenseNumber ?? '');
    _experienceController = TextEditingController(text: user.experience?.toString() ?? '');

    _isAvailableForChat = user.isAvailableForChat ?? false;
    _isAvailableForVideo = user.isAvailableForVideo ?? false;

    if (user.qualifications != null) _qualifications.assignAll(user.qualifications!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    _licenseNumberController.dispose();
    _experienceController.dispose();
    _newQualificationController.dispose();
    super.dispose();
  }

  // Save profile changes
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authController.user;
    if (currentUser == null) return;

    // Create updated user model
    final updatedUser = currentUser.copyWith(
      name: _nameController.text,
      phone: _phoneController.text,
      specialization: _specializationController.text.isNotEmpty ? _specializationController.text : null,
      hospital: _hospitalController.text.isNotEmpty ? _hospitalController.text : null,
      licenseNumber: _licenseNumberController.text.isNotEmpty ? _licenseNumberController.text : null,
      experience: _experienceController.text.isNotEmpty ? int.parse(_experienceController.text) : null,
      qualifications: _qualifications.isNotEmpty ? _qualifications.toList() : null,
      isAvailableForChat: _isAvailableForChat,
      isAvailableForVideo: _isAvailableForVideo,
    );

    final success = await _profileController.updateProfile(updatedUser);
    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Doctor Profile')),
      body: Obx(() {
        final user = _authController.user;
        if (user == null) {
          return const Center(child: Text('User not found'));
        }

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            user.profileImage != null
                                ? NetworkImage(user.profileImage!)
                                : null,
                        child:
                            user.profileImage == null
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppColors.primaryColor,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              // TODO: Implement image upload
                              Get.snackbar(
                                'Coming Soon',
                                'Image upload feature is not implemented yet',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Information Section
                _buildSectionHeader('Personal Information'),
                const SizedBox(height: 8),

                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  prefixIcon: Icons.email,
                  enabled: false, // Email cannot be changed
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Professional Information Section
                _buildSectionHeader('Professional Information'),
                const SizedBox(height: 8),

                CustomTextField(
                  label: 'Specialization',
                  controller: _specializationController,
                  prefixIcon: Icons.medical_services,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your specialization';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Hospital/Clinic',
                  controller: _hospitalController,
                  prefixIcon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your hospital or clinic';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'License Number',
                  controller: _licenseNumberController,
                  prefixIcon: Icons.card_membership,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your license number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Experience (years)',
                  controller: _experienceController,
                  prefixIcon: Icons.work,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your years of experience';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Qualifications Section
                _buildSectionHeader('Qualifications'),
                const SizedBox(height: 8),
                _buildQualificationsList(),
                const SizedBox(height: 24),

                // Availability Section
                _buildSectionHeader('Availability'),
                const SizedBox(height: 8),
                _buildAvailabilityToggles(),
                const SizedBox(height: 32),

                // Save Button
                Obx(
                  () => CustomButton(
                    text: 'Save Changes',
                    onPressed: _saveProfile,
                    isLoading: _profileController.isLoading,
                    width: double.infinity,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryColor,
      ),
    );
  }

  // Build qualifications list
  Widget _buildQualificationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._qualifications.map(
                (qualification) => Chip(
                  label: Text(qualification),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _qualifications.remove(qualification),
                  backgroundColor: Colors.grey[200],
                ),
              ),
              ActionChip(
                label: const Text('Add Qualification'),
                avatar: const Icon(Icons.add, size: 18),
                onPressed: () => _showAddQualificationDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show dialog to add a new qualification
  void _showAddQualificationDialog() {
    _newQualificationController.clear();
    Get.dialog(
      AlertDialog(
        title: const Text('Add Qualification'),
        content: TextField(
          controller: _newQualificationController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter qualification or certification',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_newQualificationController.text.isNotEmpty) {
                _qualifications.add(_newQualificationController.text);
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Build availability toggles
  Widget _buildAvailabilityToggles() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Available for Video Consultation'),
              subtitle: const Text('Allow patients to book video consultations with you'),
              value: _isAvailableForVideo,
              onChanged: (value) {
                setState(() {
                  _isAvailableForVideo = value;
                });
              },
              secondary: const Icon(Icons.videocam, color: AppColors.primaryColor),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Available for Chat Consultation'),
              subtitle: const Text('Allow patients to chat with you'),
              value: _isAvailableForChat,
              onChanged: (value) {
                setState(() {
                  _isAvailableForChat = value;
                });
              },
              secondary: const Icon(Icons.chat, color: AppColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
