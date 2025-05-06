import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/disease_controller.dart';
import '../../controllers/symptom_controller.dart';
import '../../routes/app_routes.dart';
import '../../models/symptom_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

// Diagnosis screen for symptom input and analysis
class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final DiseaseController _diseaseController = Get.find<DiseaseController>();
  final SymptomController _symptomController = Get.find<SymptomController>();

  final TextEditingController _symptomTextController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final RxInt _severity = 5.obs;
  final RxInt _duration = 1.obs;
  final RxList<String> _selectedBodyParts = <String>[].obs;
  final RxList<String> _selectedFactors = <String>[].obs;

  @override
  void dispose() {
    _symptomTextController.dispose();
    super.dispose();
  }

  // Handle diagnosis button press
  Future<void> _handleDiagnosis() async {
    if (_formKey.currentState!.validate()) {
      final userId = _authController.user!.id;
      final symptomDescription = _symptomTextController.text.trim();

      // Create prediction
      final success = await _diseaseController.createPrediction(
        userId,
        symptomDescription,
      );

      if (success) {
        // Save symptom data
        await _symptomController.addSymptom(
          SymptomModel(
            id: '',
            userId: userId,
            timestamp: DateTime.now(),
            description: symptomDescription,
            severity: _severity.value,
            duration: _duration.value,
            bodyParts:
                _selectedBodyParts.isNotEmpty
                    ? _selectedBodyParts.toList()
                    : null,
            associatedFactors:
                _selectedFactors.isNotEmpty ? _selectedFactors.toList() : null,
            images: null,
          ),
        );

        // Navigate to result screen
        Get.toNamed(AppRoutes.diagnosisResult);
      } else {
        // Show error message
        Get.snackbar(
          'Error',
          _diseaseController.errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptom Analysis')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                Card(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: AppColors.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Describe your symptoms in detail for better analysis. '
                            'This is not a medical diagnosis.',
                            style: TextStyle(color: AppColors.primaryDarkColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Symptom description
                CustomTextField(
                  label: 'Describe Your Symptoms',
                  hint:
                      'E.g., I have a headache with pressure behind my eyes for the past 3 days...',
                  controller: _symptomTextController,
                  maxLines: 5,
                  maxLength: AppConstants.maxSymptomLength,
                  textCapitalization: TextCapitalization.sentences,
                  validator: _symptomController.validateSymptomDescription,
                ),
                const SizedBox(height: 24),

                // Severity slider
                const Text(
                  'Severity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Column(
                    children: [
                      Slider(
                        value: _severity.value.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: _severity.value.toString(),
                        activeColor: _getSeverityColor(_severity.value),
                        onChanged: (value) {
                          _severity.value = value.round();
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mild'),
                          Text(
                            '${_severity.value}/10',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getSeverityColor(_severity.value),
                            ),
                          ),
                          const Text('Severe'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Duration slider
                const Text(
                  'Duration (days)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Column(
                    children: [
                      Slider(
                        value: _duration.value.toDouble(),
                        min: 1,
                        max: 30,
                        divisions: 29,
                        label: _duration.value.toString(),
                        activeColor: AppColors.primaryColor,
                        onChanged: (value) {
                          _duration.value = value.round();
                        },
                      ),
                      Text(
                        '${_duration.value} ${_duration.value == 1 ? 'day' : 'days'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Body parts
                const Text(
                  'Affected Body Parts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _symptomController
                            .getCommonBodyParts()
                            .map(
                              (part) => ChoiceChip(
                                label: Text(part),
                                selected: _selectedBodyParts.contains(part),
                                onSelected: (selected) {
                                  if (selected) {
                                    _selectedBodyParts.add(part);
                                  } else {
                                    _selectedBodyParts.remove(part);
                                  }
                                },
                                selectedColor: AppColors.primaryLightColor,
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Associated factors
                const Text(
                  'Associated Factors',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _symptomController
                            .getCommonAssociatedFactors()
                            .map(
                              (factor) => ChoiceChip(
                                label: Text(factor),
                                selected: _selectedFactors.contains(factor),
                                onSelected: (selected) {
                                  if (selected) {
                                    _selectedFactors.add(factor);
                                  } else {
                                    _selectedFactors.remove(factor);
                                  }
                                },
                                selectedColor: AppColors.secondaryLightColor,
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Analyze button
                Obx(
                  () => CustomButton(
                    text: 'Analyze Symptoms',
                    onPressed: _handleDiagnosis,
                    isLoading: _diseaseController.isLoading,
                    icon: Icons.search,
                    width: double.infinity,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 24),

                // Disclaimer
                const Text(
                  'Disclaimer: This is not a medical diagnosis. Always consult a healthcare professional for medical advice.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get color based on severity
  Color _getSeverityColor(int severity) {
    if (severity <= 3) return AppColors.successColor;
    if (severity <= 6) return AppColors.warningColor;
    return AppColors.errorColor;
  }
}
