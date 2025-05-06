import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/health_data_controller.dart';
import '../../models/health_data_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

// Screen to add new health data
class AddHealthDataScreen extends StatefulWidget {
  const AddHealthDataScreen({super.key});

  @override
  State<AddHealthDataScreen> createState() => _AddHealthDataScreenState();
}

class _AddHealthDataScreenState extends State<AddHealthDataScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final HealthDataController _healthDataController =
      Get.find<HealthDataController>();

  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _systolicBPController = TextEditingController();
  final TextEditingController _diastolicBPController = TextEditingController();
  final TextEditingController _respiratoryRateController =
      TextEditingController();
  final TextEditingController _oxygenSaturationController =
      TextEditingController();
  final TextEditingController _bloodGlucoseController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _temperatureController.dispose();
    _heartRateController.dispose();
    _systolicBPController.dispose();
    _diastolicBPController.dispose();
    _respiratoryRateController.dispose();
    _oxygenSaturationController.dispose();
    _bloodGlucoseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Handle save button press
  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final userId = _authController.user!.id;

      // Parse values
      final temperature =
          _temperatureController.text.isNotEmpty
              ? double.tryParse(_temperatureController.text)
              : null;
      final heartRate =
          _heartRateController.text.isNotEmpty
              ? int.tryParse(_heartRateController.text)
              : null;
      final systolicBP =
          _systolicBPController.text.isNotEmpty
              ? int.tryParse(_systolicBPController.text)
              : null;
      final diastolicBP =
          _diastolicBPController.text.isNotEmpty
              ? int.tryParse(_diastolicBPController.text)
              : null;
      final respiratoryRate =
          _respiratoryRateController.text.isNotEmpty
              ? int.tryParse(_respiratoryRateController.text)
              : null;
      final oxygenSaturation =
          _oxygenSaturationController.text.isNotEmpty
              ? double.tryParse(_oxygenSaturationController.text)
              : null;
      final bloodGlucose =
          _bloodGlucoseController.text.isNotEmpty
              ? double.tryParse(_bloodGlucoseController.text)
              : null;
      final notes = _notesController.text.trim();

      // Create health data model
      final healthData = HealthDataModel(
        id: '',
        userId: userId,
        timestamp: DateTime.now(),
        temperature: temperature,
        heartRate: heartRate,
        systolicBP: systolicBP,
        diastolicBP: diastolicBP,
        respiratoryRate: respiratoryRate,
        oxygenSaturation: oxygenSaturation,
        bloodGlucose: bloodGlucose,
        notes: notes.isNotEmpty ? notes : null,
      );

      // Save health data
      final success = await _healthDataController.addHealthData(healthData);

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'Health data saved successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.successColor,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          _healthDataController.errorMessage,
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
      appBar: AppBar(title: const Text('Add Health Data')),
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
                            'Enter your vital signs to track your health. '
                            'You can leave fields blank if you don\'t have the measurements.',
                            style: TextStyle(color: AppColors.primaryDarkColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Temperature
                CustomTextField(
                  label: 'Temperature (°C)',
                  hint: 'e.g., 37.0',
                  controller: _temperatureController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,1}'),
                    ),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final temp = double.tryParse(value);
                      if (temp == null) {
                        return 'Please enter a valid number';
                      }
                      if (temp < AppConstants.minTemperature ||
                          temp > AppConstants.maxTemperature) {
                        return 'Temperature should be between ${AppConstants.minTemperature} and ${AppConstants.maxTemperature}°C';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Heart rate
                CustomTextField(
                  label: 'Heart Rate (bpm)',
                  hint: 'e.g., 75',
                  controller: _heartRateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final rate = int.tryParse(value);
                      if (rate == null) {
                        return 'Please enter a valid number';
                      }
                      if (rate < AppConstants.minHeartRate ||
                          rate > AppConstants.maxHeartRate) {
                        return 'Heart rate should be between ${AppConstants.minHeartRate} and ${AppConstants.maxHeartRate} bpm';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Blood pressure
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Systolic BP (mmHg)',
                        hint: 'e.g., 120',
                        controller: _systolicBPController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final systolic = int.tryParse(value);
                            if (systolic == null) {
                              return 'Invalid number';
                            }
                            if (systolic < AppConstants.minSystolicBP ||
                                systolic > AppConstants.maxSystolicBP) {
                              return 'Invalid range';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Diastolic BP (mmHg)',
                        hint: 'e.g., 80',
                        controller: _diastolicBPController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final diastolic = int.tryParse(value);
                            if (diastolic == null) {
                              return 'Invalid number';
                            }
                            if (diastolic < AppConstants.minDiastolicBP ||
                                diastolic > AppConstants.maxDiastolicBP) {
                              return 'Invalid range';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Respiratory rate
                CustomTextField(
                  label: 'Respiratory Rate (breaths/min)',
                  hint: 'e.g., 16',
                  controller: _respiratoryRateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final rate = int.tryParse(value);
                      if (rate == null) {
                        return 'Please enter a valid number';
                      }
                      if (rate < 8 || rate > 30) {
                        return 'Respiratory rate should be between 8 and 30 breaths/min';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Oxygen saturation
                CustomTextField(
                  label: 'Oxygen Saturation (%)',
                  hint: 'e.g., 98',
                  controller: _oxygenSaturationController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,1}'),
                    ),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final saturation = double.tryParse(value);
                      if (saturation == null) {
                        return 'Please enter a valid number';
                      }
                      if (saturation < 80 || saturation > 100) {
                        return 'Oxygen saturation should be between 80% and 100%';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Blood glucose
                CustomTextField(
                  label: 'Blood Glucose (mg/dL)',
                  hint: 'e.g., 95',
                  controller: _bloodGlucoseController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,1}'),
                    ),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final glucose = double.tryParse(value);
                      if (glucose == null) {
                        return 'Please enter a valid number';
                      }
                      if (glucose < 50 || glucose > 400) {
                        return 'Blood glucose should be between 50 and 400 mg/dL';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Notes
                CustomTextField(
                  label: 'Notes (Optional)',
                  hint: 'Any additional information...',
                  controller: _notesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 32),

                // Save button
                Obx(
                  () => CustomButton(
                    text: 'Save Health Data',
                    onPressed: _handleSave,
                    isLoading: _healthDataController.isLoading,
                    width: double.infinity,
                    height: 56,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
