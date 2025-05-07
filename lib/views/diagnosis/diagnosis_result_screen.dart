import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/disease_controller.dart';
import '../../controllers/doctor_controller.dart';
import '../../models/prediction_result_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/disease_prediction_card.dart';

// Diagnosis result screen to display AI analysis results
class DiagnosisResultScreen extends StatefulWidget {
  const DiagnosisResultScreen({super.key});

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  final DiseaseController _diseaseController = Get.find<DiseaseController>();
  final DoctorController _doctorController = Get.find<DoctorController>();

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure loading happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctors();
    });
  }

  // Load doctors based on recommended specialists
  Future<void> _loadDoctors() async {
    if (_diseaseController.currentPrediction != null) {
      final specialists = _getRecommendedSpecialists();
      if (specialists.isNotEmpty) {
        await _doctorController.getDoctorsBySpecialization(specialists.first);
      } else {
        await _doctorController.getAllDoctors();
      }
    }
  }

  // Get recommended specialists from prediction
  List<String> _getRecommendedSpecialists() {
    final prediction = _diseaseController.currentPrediction;
    if (prediction == null) return [];

    final specialists = <String>[];
    for (final disease in prediction.diseases) {
      if (disease.specialistType != null &&
          !specialists.contains(disease.specialistType)) {
        specialists.add(disease.specialistType!);
      }
    }

    return specialists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Results')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            final prediction = _diseaseController.currentPrediction;

            if (_diseaseController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (prediction == null) {
              return const Center(
                child: Text('No prediction results available'),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result summary card
                _buildResultSummaryCard(prediction),
                const SizedBox(height: 24),

                // Possible conditions
                const Text(
                  'Possible Conditions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Disease list
                ...prediction.diseases.asMap().entries.map((entry) {
                  final index = entry.key;
                  final disease = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DiseasePredictionCard(
                      disease: disease,
                      index: index,
                      onTap: () {
                        _showDiseaseDetails(disease);
                      },
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Recommended action
                if (prediction.recommendedAction != null) ...[
                  Card(
                    color: _getUrgencyColor(
                      prediction.urgencyLevel,
                    ).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services,
                                color: _getUrgencyColor(
                                  prediction.urgencyLevel,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recommended Action',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getUrgencyColor(
                                    prediction.urgencyLevel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prediction.recommendedAction!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Recommended specialists
                if (_getRecommendedSpecialists().isNotEmpty) ...[
                  const Text(
                    'Recommended Specialists',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _getRecommendedSpecialists()
                            .map(
                              (specialist) => ActionChip(
                                label: Text(specialist),
                                avatar: const Icon(Icons.person, size: 16),
                                onPressed: () {
                                  _doctorController.getDoctorsBySpecialization(
                                    specialist,
                                  );
                                  Get.toNamed(AppRoutes.doctors);
                                },
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Find Doctors',
                        icon: Icons.people,
                        onPressed: () {
                          Get.toNamed(AppRoutes.doctors);
                        },
                        backgroundColor: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'New Analysis',
                        icon: Icons.refresh,
                        onPressed: () {
                          Get.offNamed(AppRoutes.diagnosis);
                        },
                        isOutlined: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Disclaimer
                const Text(
                  'Disclaimer: This analysis is based on the symptoms you provided and is not a medical diagnosis. Always consult a healthcare professional for medical advice.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
        ),
      ),
    );
  }

  // Build result summary card
  Widget _buildResultSummaryCard(PredictionResultModel prediction) {
    final topDisease = prediction.diseases.first;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(
                      prediction.urgencyLevel,
                    ).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getUrgencyIcon(prediction.urgencyLevel),
                    color: _getUrgencyColor(prediction.urgencyLevel),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analysis Complete',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _getUrgencyColor(prediction.urgencyLevel),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on your symptoms',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Match',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topDisease.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getProbabilityColor(
                      topDisease.probability,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    topDisease.probabilityPercentage,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getProbabilityColor(topDisease.probability),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Urgency Level',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prediction.urgencyLevel ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getUrgencyColor(prediction.urgencyLevel),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analyzed',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${prediction.diseases.length} conditions',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Get color based on urgency level
  Color _getUrgencyColor(String? urgencyLevel) {
    switch (urgencyLevel) {
      case 'Low':
        return AppColors.successColor;
      case 'Medium':
        return AppColors.warningColor;
      case 'High':
        return AppColors.errorColor;
      default:
        return Colors.grey;
    }
  }

  // Get icon based on urgency level
  IconData _getUrgencyIcon(String? urgencyLevel) {
    switch (urgencyLevel) {
      case 'Low':
        return Icons.check_circle;
      case 'Medium':
        return Icons.warning;
      case 'High':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  // Get color based on probability
  Color _getProbabilityColor(double probability) {
    if (probability < 0.3) return AppColors.successColor;
    if (probability < 0.7) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  // Show detailed information about a disease
  void _showDiseaseDetails(DiseaseWithProbability disease) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Disease name and probability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            disease.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getProbabilityColor(
                              disease.probability,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            disease.probabilityPercentage,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getProbabilityColor(disease.probability),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Disease description
                    if (disease.description != null) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        disease.description!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Common symptoms
                    if (disease.symptoms != null &&
                        disease.symptoms!.isNotEmpty) ...[
                      const Text(
                        'Common Symptoms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...disease.symptoms!.map(
                        (symptom) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 8,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  symptom,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Recommended specialist
                    if (disease.specialistType != null) ...[
                      const Text(
                        'Recommended Specialist',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            disease.specialistType!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Find ${disease.specialistType ?? 'Doctor'}',
                            icon: Icons.search,
                            onPressed: () {
                              Navigator.pop(context);
                              if (disease.specialistType != null) {
                                _doctorController.getDoctorsBySpecialization(
                                  disease.specialistType!,
                                );
                              }
                              Get.toNamed(AppRoutes.doctors);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Disclaimer
                    const Text(
                      'Disclaimer: This information is for educational purposes only and is not a substitute for professional medical advice.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
