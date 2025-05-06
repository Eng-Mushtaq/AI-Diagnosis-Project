import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/health_data_controller.dart';
import '../../../models/health_data_model.dart';
import '../../../routes/app_routes.dart';

// Widget to display health status on home screen
class HealthStatusWidget extends StatelessWidget {
  const HealthStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final HealthDataController healthDataController =
        Get.find<HealthDataController>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Health Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Get.toNamed(AppRoutes.healthData);
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (healthDataController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final latestData = healthDataController.getLatestHealthData();

              if (latestData == null) {
                return _buildNoDataView();
              }

              return _buildHealthDataView(latestData, healthDataController);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Column(
      children: [
        const Text(
          'No health data available',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            Get.toNamed(AppRoutes.addHealthData);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Health Data'),
        ),
      ],
    );
  }

  Widget _buildHealthDataView(
    HealthDataModel data,
    HealthDataController controller,
  ) {
    final bool isTemperatureNormal = controller.isTemperatureNormal(
      data.temperature,
    );
    final bool isHeartRateNormal = controller.isHeartRateNormal(data.heartRate);
    final bool isBloodPressureNormal = controller.isBloodPressureNormal(
      data.systolicBP,
      data.diastolicBP,
    );
    final bool isOxygenSaturationNormal = controller.isOxygenSaturationNormal(
      data.oxygenSaturation,
    );

    // Count abnormal values
    int abnormalCount = 0;
    if (!isTemperatureNormal) abnormalCount++;
    if (!isHeartRateNormal) abnormalCount++;
    if (!isBloodPressureNormal) abnormalCount++;
    if (!isOxygenSaturationNormal) abnormalCount++;

    // Determine overall status
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (abnormalCount == 0) {
      statusText = 'Your vital signs are normal';
      statusColor = AppColors.successColor;
      statusIcon = Icons.check_circle;
    } else if (abnormalCount == 1) {
      statusText = 'One vital sign needs attention';
      statusColor = AppColors.warningColor;
      statusIcon = Icons.warning;
    } else {
      statusText = 'Multiple vital signs need attention';
      statusColor = AppColors.errorColor;
      statusIcon = Icons.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status indicator
        Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Last updated
        Text(
          'Last updated: ${data.formattedDate} at ${data.formattedTime}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        // Vital signs grid
        Row(
          children: [
            Expanded(
              child: _buildVitalSignItem(
                'Temperature',
                data.temperature != null
                    ? '${data.temperature!.toStringAsFixed(1)}°C'
                    : 'N/A',
                Icons.thermostat,
                isTemperatureNormal,
              ),
            ),
            Expanded(
              child: _buildVitalSignItem(
                'Heart Rate',
                data.heartRate != null ? '${data.heartRate} bpm' : 'N/A',
                Icons.favorite,
                isHeartRateNormal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildVitalSignItem(
                'Blood Pressure',
                data.bloodPressure,
                Icons.speed,
                isBloodPressureNormal,
              ),
            ),
            Expanded(
              child: _buildVitalSignItem(
                'Oxygen',
                data.oxygenSaturation != null
                    ? '${data.oxygenSaturation!.toStringAsFixed(1)}%'
                    : 'N/A',
                Icons.air,
                isOxygenSaturationNormal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Add new data button
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              Get.toNamed(AppRoutes.addHealthData);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalSignItem(
    String title,
    String value,
    IconData icon,
    bool isNormal,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: isNormal ? AppColors.primaryColor : AppColors.errorColor,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isNormal ? Colors.black : AppColors.errorColor,
          ),
        ),
      ],
    );
  }
}
