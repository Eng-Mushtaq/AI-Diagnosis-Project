import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

import '../models/prediction_result_model.dart';

// Disease prediction card widget for displaying disease predictions
class DiseasePredictionCard extends StatelessWidget {
  final DiseaseWithProbability disease;
  final int index;
  final VoidCallback? onTap;

  const DiseasePredictionCard({
    super.key,
    required this.disease,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getProbabilityColor().withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getProbabilityColor(),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      disease.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getProbabilityColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      disease.probabilityPercentage,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getProbabilityColor(),
                      ),
                    ),
                  ),
                ],
              ),
              if (disease.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  disease.description!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (disease.symptoms != null && disease.symptoms!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Common Symptoms:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      disease.symptoms!
                          .take(3)
                          .map((symptom) => _buildSymptomChip(symptom))
                          .toList(),
                ),
              ],
              if (disease.specialistType != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services,
                      size: 16,
                      color: AppColors.secondaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Consult: ${disease.specialistType}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomChip(String symptom) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLightColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        symptom,
        style: const TextStyle(fontSize: 12, color: AppColors.primaryDarkColor),
      ),
    );
  }

  Color _getProbabilityColor() {
    if (disease.probability < 0.3) return AppColors.successColor;
    if (disease.probability < 0.7) return AppColors.warningColor;
    return AppColors.errorColor;
  }
}
