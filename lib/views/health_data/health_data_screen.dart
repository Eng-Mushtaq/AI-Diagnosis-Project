import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/health_data_controller.dart';
import '../../models/health_data_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/health_data_card.dart';

// Health data screen to display user's health data history
class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final HealthDataController _healthDataController =
      Get.find<HealthDataController>();

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure loading happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHealthData();
    });
  }

  // Load health data for current user
  Future<void> _loadHealthData() async {
    if (_authController.user != null) {
      await _healthDataController.getHealthData(_authController.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Get.toNamed(AppRoutes.addHealthData);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHealthData,
        child: Obx(() {
          if (_healthDataController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_healthDataController.healthDataList.isEmpty) {
            return _buildEmptyState();
          }

          // Sort by timestamp (newest first)
          final sortedData = List<HealthDataModel>.from(
            _healthDataController.healthDataList,
          )..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final healthData = sortedData[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: HealthDataCard(
                  healthData: healthData,
                  onTap: () {
                    // TODO: Show health data details
                    _showHealthDataDetails(healthData);
                  },
                ),
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.addHealthData);
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'No Health Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Start tracking your vital signs to monitor your health over time.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed(AppRoutes.addHealthData);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Health Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show health data details in a bottom sheet
  void _showHealthDataDetails(HealthDataModel healthData) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Health Data Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildDetailRow('Date', healthData.formattedDate),
                    _buildDetailRow('Time', healthData.formattedTime),
                    if (healthData.temperature != null)
                      _buildDetailRow(
                        'Temperature',
                        '${healthData.temperature!.toStringAsFixed(1)}°C',
                      ),
                    if (healthData.heartRate != null)
                      _buildDetailRow(
                        'Heart Rate',
                        '${healthData.heartRate} bpm',
                      ),
                    if (healthData.systolicBP != null &&
                        healthData.diastolicBP != null)
                      _buildDetailRow(
                        'Blood Pressure',
                        healthData.bloodPressure,
                      ),
                    if (healthData.respiratoryRate != null)
                      _buildDetailRow(
                        'Respiratory Rate',
                        '${healthData.respiratoryRate} breaths/min',
                      ),
                    if (healthData.oxygenSaturation != null)
                      _buildDetailRow(
                        'Oxygen Saturation',
                        '${healthData.oxygenSaturation!.toStringAsFixed(1)}%',
                      ),
                    if (healthData.bloodGlucose != null)
                      _buildDetailRow(
                        'Blood Glucose',
                        '${healthData.bloodGlucose!.toStringAsFixed(1)} mg/dL',
                      ),
                    if (healthData.notes != null &&
                        healthData.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          healthData.notes!,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16), // Add bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build detail row for bottom sheet
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
