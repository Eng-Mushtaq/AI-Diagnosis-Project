import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

// Onboarding screen with feature introduction
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final RxInt _currentPage = 0.obs;

  // Onboarding data with icons (not images)
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'AI-Powered Diagnosis',
      'description':
          'Get instant health insights with our advanced AI diagnosis system based on your symptoms.',
      'icon': Icons.medical_services,
      'color': AppColors.primaryColor,
    },
    {
      'title': 'Connect with Doctors',
      'description':
          'Consult with qualified healthcare professionals through video calls and chat.',
      'icon': Icons.people,
      'color': AppColors.secondaryColor,
    },
    {
      'title': 'Track Your Health',
      'description':
          'Monitor your vital signs and health metrics to stay informed about your wellbeing.',
      'icon': Icons.favorite,
      'color': Colors.red,
    },
    {
      'title': 'Secure & Private',
      'description':
          'Your health data is encrypted and protected with the highest security standards.',
      'icon': Icons.shield,
      'color': Colors.green,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Navigate to login screen
  void _navigateToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }

  // Navigate to next page or login screen if on last page
  void _nextPage() {
    if (_currentPage.value < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _navigateToLogin,
                child: const Text('Skip'),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (index) => _currentPage.value = index,
                itemBuilder: (context, index) {
                  final item = _onboardingData[index];
                  return _buildOnboardingPage(
                    title: item['title'],
                    description: item['description'],
                    icon: item['icon'],
                    color: item['color'],
                  );
                },
              ),
            ),

            // Page indicator and buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page indicator
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                        (index) =>
                            _buildPageIndicator(index == _currentPage.value),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next/Get Started button
                  Obx(
                    () => CustomButton(
                      text:
                          _currentPage.value == _onboardingData.length - 1
                              ? 'Get Started'
                              : 'Next',
                      onPressed: _nextPage,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build individual onboarding page
  Widget _buildOnboardingPage({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 26), // 10% opacity
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build page indicator dot
  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryColor : AppColors.textLightColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
