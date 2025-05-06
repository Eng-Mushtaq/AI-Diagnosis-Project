import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/health_data_model.dart';

// Health data card widget for displaying vital signs
class HealthDataCard extends StatelessWidget {
  final HealthDataModel healthData;
  final VoidCallback? onTap;

  const HealthDataCard({super.key, required this.healthData, this.onTap});

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    healthData.formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    healthData.formattedTime,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildVitalRow(
                'Temperature',
                healthData.temperature != null
                    ? '${healthData.temperature!.toStringAsFixed(1)}°C'
                    : 'N/A',
                icon: Icons.thermostat,
                isNormal: _isTemperatureNormal(healthData.temperature),
              ),
              const SizedBox(height: 12),
              _buildVitalRow(
                'Heart Rate',
                healthData.heartRate != null
                    ? '${healthData.heartRate} bpm'
                    : 'N/A',
                icon: Icons.favorite,
                isNormal: _isHeartRateNormal(healthData.heartRate),
              ),
              const SizedBox(height: 12),
              _buildVitalRow(
                'Blood Pressure',
                healthData.bloodPressure,
                icon: Icons.speed,
                isNormal: _isBloodPressureNormal(
                  healthData.systolicBP,
                  healthData.diastolicBP,
                ),
              ),
              const SizedBox(height: 12),
              _buildVitalRow(
                'Oxygen Saturation',
                healthData.oxygenSaturation != null
                    ? '${healthData.oxygenSaturation!.toStringAsFixed(1)}%'
                    : 'N/A',
                icon: Icons.air,
                isNormal: _isOxygenSaturationNormal(
                  healthData.oxygenSaturation,
                ),
              ),
              if (healthData.notes != null && healthData.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 8),
                const SizedBox(height: 8),
                Text(
                  'Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  healthData.notes!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalRow(
    String title,
    String value, {
    required IconData icon,
    required bool isNormal,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isNormal ? AppColors.primaryColor : AppColors.errorColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isNormal
                      ? AppColors.primaryLightColor.withValues(alpha: 0.2)
                      : AppColors.errorColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isNormal
                        ? AppColors.primaryDarkColor
                        : AppColors.errorColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  bool _isTemperatureNormal(double? temperature) {
    if (temperature == null) return true;
    return temperature >= 36.1 && temperature <= 37.2;
  }

  bool _isHeartRateNormal(int? heartRate) {
    if (heartRate == null) return true;
    return heartRate >= 60 && heartRate <= 100;
  }

  bool _isBloodPressureNormal(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return true;
    return systolic < 130 && diastolic < 85;
  }

  bool _isOxygenSaturationNormal(double? oxygenSaturation) {
    if (oxygenSaturation == null) return true;
    return oxygenSaturation >= 95;
  }
}
