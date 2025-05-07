import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/supabase_service.dart';

// Login screen for user authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // For future Supabase implementation
  final RxBool _isLoggingInWithSocial = false.obs;
  final RxString _socialLoginError = ''.obs;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle login button press
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Show loading indicator
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final success = await _authController.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (success) {
        // Route to different home screens based on user type
        if (_authController.isPatient) {
          Get.offAllNamed(AppRoutes.home); // Patient home
        } else if (_authController.isDoctor) {
          Get.offAllNamed(AppRoutes.doctorHome); // Doctor home
        } else if (_authController.isAdmin) {
          Get.offAllNamed(AppRoutes.adminHome); // Admin home
        } else {
          Get.offAllNamed(AppRoutes.home); // Default to patient home
        }
      } else {
        // Show error message
        Get.snackbar(
          'Login Failed',
          _authController.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
        );
      }
    }
  }

  // Handle social login with Supabase
  Future<void> _handleSocialLogin(String provider) async {
    _isLoggingInWithSocial.value = true;
    _socialLoginError.value = '';

    try {
      // Get Supabase client from service
      final supabase = SupabaseService().supabaseClient;

      // Determine provider
      if (provider == 'google') {
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo:
              kIsWeb ? null : 'io.supabase.aidiagnosist://login-callback/',
        );
      } else if (provider == 'apple') {
        await supabase.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo:
              kIsWeb ? null : 'io.supabase.aidiagnosist://login-callback/',
        );
      } else if (provider == 'facebook') {
        await supabase.auth.signInWithOAuth(
          OAuthProvider.facebook,
          redirectTo:
              kIsWeb ? null : 'io.supabase.aidiagnosist://login-callback/',
        );
      }

      // Note: The actual login completion will be handled by deep linking
      // For now, we'll just show a message
      Get.snackbar(
        'Social Login',
        'Please complete the authentication in your browser',
        snackPosition: SnackPosition.BOTTOM,
      );

      _isLoggingInWithSocial.value = false;
    } catch (e) {
      _socialLoginError.value =
          'Failed to login with $provider: ${e.toString()}';
      _isLoggingInWithSocial.value = false;
    }
  }

  // Build social login button
  Widget _buildSocialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Obx(
            () =>
                _isLoggingInWithSocial.value
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                    : Icon(icon, color: color, size: 30),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // App logo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        size: 50,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Welcome text
                  const Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue to AI Diagnosist',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
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
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        // Show dialog to enter email
                        final TextEditingController emailController =
                            TextEditingController();
                        final result = await Get.dialog<bool>(
                          AlertDialog(
                            title: const Text('Reset Password'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Enter your email to receive a password reset link',
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  label: 'Email',
                                  hint: 'Enter your email',
                                  controller: emailController,
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
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Get.back(result: true),
                                child: const Text('Send Reset Link'),
                              ),
                            ],
                          ),
                        );

                        if (result == true && emailController.text.isNotEmpty) {
                          try {
                            // Show loading indicator
                            Get.dialog(
                              const Center(child: CircularProgressIndicator()),
                              barrierDismissible: false,
                            );

                            await SupabaseService().resetPassword(
                              emailController.text.trim(),
                            );

                            // Close loading dialog
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            }

                            Get.snackbar(
                              'Password Reset',
                              'A password reset link has been sent to your email',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } catch (e) {
                            // Close loading dialog if it's still open
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            }

                            Get.snackbar(
                              'Error',
                              'Failed to send password reset link: ${e.toString()}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.errorColor,
                              colorText: Colors.white,
                            );
                          }
                        }
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Login button
                  Obx(
                    () => CustomButton(
                      text: 'Login',
                      onPressed: _handleLogin,
                      isLoading: _authController.isLoading,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Social login divider
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialLoginButton(
                        icon: Icons.g_mobiledata,
                        color: Colors.red,
                        onPressed: () => _handleSocialLogin('google'),
                      ),
                      _buildSocialLoginButton(
                        icon: Icons.apple,
                        color: Colors.black,
                        onPressed: () => _handleSocialLogin('apple'),
                      ),
                      _buildSocialLoginButton(
                        icon: Icons.facebook,
                        color: Colors.blue.shade800,
                        onPressed: () => _handleSocialLogin('facebook'),
                      ),
                    ],
                  ),
                  Obx(() {
                    if (_socialLoginError.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _socialLoginError.value,
                          style: const TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 24),
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Get.toNamed(AppRoutes.register);
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),

                  // Demo login info
                  const SizedBox(height: 32),
                  const Text(
                    'Demo Login Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Patient: patient@example.com\nDoctor: doctor@example.com\nAdmin: admin@gmail.com\n\nPassword: 123456 (for patient/doctor)\nPassword: admin123 (for admin)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
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
