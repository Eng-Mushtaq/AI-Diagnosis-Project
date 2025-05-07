import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final ProfileController _profileController = Get.find<ProfileController>();
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  // Dropdown values
  String? _selectedGender;
  String? _selectedBloodGroup;

  // List controllers
  final RxList<String> _allergies = <String>[].obs;
  final RxList<String> _chronicConditions = <String>[].obs;
  final RxList<String> _medications = <String>[].obs;

  // Text controllers for adding new items
  final TextEditingController _newAllergyController = TextEditingController();
  final TextEditingController _newConditionController = TextEditingController();
  final TextEditingController _newMedicationController =
      TextEditingController();

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
    _ageController = TextEditingController(text: user.age?.toString() ?? '');
    _heightController = TextEditingController(
      text: user.height?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: user.weight?.toString() ?? '',
    );

    _selectedGender = user.gender;
    _selectedBloodGroup = user.bloodGroup;

    if (user.allergies != null) _allergies.assignAll(user.allergies!);
    if (user.chronicConditions != null) {
      _chronicConditions.assignAll(user.chronicConditions!);
    }
    if (user.medications != null) _medications.assignAll(user.medications!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _newAllergyController.dispose();
    _newConditionController.dispose();
    _newMedicationController.dispose();
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
      age:
          _ageController.text.isNotEmpty
              ? int.parse(_ageController.text)
              : null,
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      height:
          _heightController.text.isNotEmpty
              ? double.parse(_heightController.text)
              : null,
      weight:
          _weightController.text.isNotEmpty
              ? double.parse(_weightController.text)
              : null,
      allergies: _allergies.isNotEmpty ? _allergies.toList() : null,
      chronicConditions:
          _chronicConditions.isNotEmpty ? _chronicConditions.toList() : null,
      medications: _medications.isNotEmpty ? _medications.toList() : null,
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
      appBar: AppBar(title: const Text('Edit Profile')),
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
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Age',
                  controller: _ageController,
                  prefixIcon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),

                // Gender dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textLightColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          hint: const Text('Select Gender'),
                          isExpanded: true,
                          items:
                              ['Male', 'Female', 'Other']
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(gender),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Health Information Section
                _buildSectionHeader('Health Information'),
                const SizedBox(height: 8),

                // Blood Group dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Group',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textLightColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBloodGroup,
                          hint: const Text('Select Blood Group'),
                          isExpanded: true,
                          items:
                              ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                  .map(
                                    (group) => DropdownMenuItem(
                                      value: group,
                                      child: Text(group),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBloodGroup = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Height (cm)',
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Weight (kg)',
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Allergies
                _buildListSection(
                  'Allergies',
                  _allergies,
                  _newAllergyController,
                  'Add allergy',
                ),
                const SizedBox(height: 16),

                // Chronic Conditions
                _buildListSection(
                  'Chronic Conditions',
                  _chronicConditions,
                  _newConditionController,
                  'Add condition',
                ),
                const SizedBox(height: 16),

                // Medications
                _buildListSection(
                  'Medications',
                  _medications,
                  _newMedicationController,
                  'Add medication',
                ),
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

  // Build list section (for allergies, conditions, medications)
  Widget _buildListSection(
    String title,
    RxList<String> items,
    TextEditingController controller,
    String addButtonText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...items.map(
                (item) => Chip(
                  label: Text(item),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => items.remove(item),
                  backgroundColor: Colors.grey[200],
                ),
              ),
              ActionChip(
                label: Text(addButtonText),
                avatar: const Icon(Icons.add, size: 18),
                onPressed: () => _showAddItemDialog(title, controller, items),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show dialog to add a new item to a list
  void _showAddItemDialog(
    String title,
    TextEditingController controller,
    RxList<String> items,
  ) {
    controller.clear();
    Get.dialog(
      AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Enter $title'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                items.add(controller.text);
                Get.back();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
