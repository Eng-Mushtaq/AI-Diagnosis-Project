import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

// Registration screen for new users
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Doctor-specific controllers
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _hospitalController = TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // User type selection
  final Rx<UserType> _selectedUserType = UserType.patient.obs;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // Dispose doctor-specific controllers
    _specializationController.dispose();
    _hospitalController.dispose();
    _licenseNumberController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // Handle registration button press
  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // Create a map for additional user data
      Map<String, dynamic> additionalData = {};

      // Add doctor-specific data if doctor is selected
      if (_selectedUserType.value == UserType.doctor) {
        additionalData = {
          'specialization': _specializationController.text.trim(),
          'hospital': _hospitalController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
          'isAvailableForChat': false,
          'isAvailableForVideo': false,
        };
      }

      final success = await _authController.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedUserType.value,
        additionalData,
      );

      if (success) {
        // Navigate to login screen after successful registration
        Get.offAllNamed(AppRoutes.login);
      } else {
        // Show error message
        Get.snackbar(
          'Registration Failed',
          _authController.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
        );
      }
    }
  }

  // Build user type selection widget
  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Register as:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _buildUserTypeOption(
                  title: 'Patient',
                  icon: Icons.person,
                  userType: UserType.patient,
                  isSelected: _selectedUserType.value == UserType.patient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUserTypeOption(
                  title: 'Doctor',
                  icon: Icons.medical_services,
                  userType: UserType.doctor,
                  isSelected: _selectedUserType.value == UserType.doctor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build doctor-specific fields
  Widget _buildDoctorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Doctor Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Specialization field
        CustomTextField(
          label: 'Specialization',
          hint: 'e.g., Cardiologist, Neurologist',
          controller: _specializationController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
          prefixIcon: Icons.medical_information,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your specialization';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Hospital field
        CustomTextField(
          label: 'Hospital/Clinic',
          hint: 'Enter your hospital or clinic name',
          controller: _hospitalController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
          prefixIcon: Icons.local_hospital,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your hospital/clinic';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // License number field
        CustomTextField(
          label: 'License Number',
          hint: 'Enter your medical license number',
          controller: _licenseNumberController,
          keyboardType: TextInputType.text,
          prefixIcon: Icons.badge,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your license number';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        // Experience field
        CustomTextField(
          label: 'Years of Experience',
          hint: 'Enter years of professional experience',
          controller: _experienceController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.timeline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your years of experience';
            }
            if (int.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Build individual user type option
  Widget _buildUserTypeOption({
    required String title,
    required IconData icon,
    required UserType userType,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _selectedUserType.value = userType,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primaryColor.withValues(
                    alpha: 26,
                  ) // 0.1 * 255 = ~26
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primaryColor : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Welcome text
                  const Text(
                    'Join AI Diagnosist',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create an account to get started',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Name field
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Email field
                  CustomTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Password field
                  CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock,
                    suffixIcon:
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Confirm password field
                  CustomTextField(
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icons.lock,
                    suffixIcon:
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // User type selection
                  _buildUserTypeSelector(),
                  const SizedBox(height: 24),
                  // Doctor fields (conditionally displayed)
                  Obx(
                    () =>
                        _selectedUserType.value == UserType.doctor
                            ? _buildDoctorFields()
                            : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  // Register button
                  Obx(
                    () => CustomButton(
                      text: 'Register',
                      onPressed: _handleRegister,
                      isLoading: _authController.isLoading,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
