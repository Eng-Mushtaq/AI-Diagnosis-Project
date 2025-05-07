import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../controllers/patient_controller.dart';
import '../../models/health_data_model.dart';
import '../../models/symptom_model.dart';
import '../../models/prediction_result_model.dart';

/// Screen to display detailed information about a patient
class PatientDetailsScreen extends StatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen>
    with SingleTickerProviderStateMixin {
  final PatientController _patientController = Get.find<PatientController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Use post-frame callback to ensure loading happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatientData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load all patient data
  Future<void> _loadPatientData() async {
    if (_patientController.selectedPatient != null) {
      await _patientController.loadAllPatientData(
        _patientController.selectedPatient!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Health'),
            Tab(text: 'Symptoms'),
            Tab(text: 'Diagnosis'),
          ],
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
        ),
      ),
      body: Obx(() {
        if (_patientController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_patientController.selectedPatient == null) {
          return const Center(
            child: Text('No patient selected', style: TextStyle(fontSize: 16)),
          );
        }

        final patient = _patientController.selectedPatient!;

        return TabBarView(
          controller: _tabController,
          children: [
            // Profile tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient profile card
                  _buildPatientProfileCard(patient),
                  const SizedBox(height: 24),

                  // Medical information
                  const Text(
                    'Medical Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMedicalInfoCard(patient),
                ],
              ),
            ),

            // Health data tab
            _buildHealthDataTab(),

            // Symptoms tab
            _buildSymptomsTab(),

            // Diagnosis tab
            _buildDiagnosisTab(),
          ],
        );
      }),
    );
  }

  // Build patient profile card
  Widget _buildPatientProfileCard(dynamic patient) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Patient avatar
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  patient.profileImage != null
                      ? NetworkImage(patient.profileImage)
                      : null,
              child:
                  patient.profileImage == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
            ),
            const SizedBox(height: 16),

            // Patient name
            Text(
              patient.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Patient basic info
            _buildInfoRow('Age', '${patient.age ?? 'N/A'}'),
            _buildInfoRow('Gender', patient.gender ?? 'N/A'),
            _buildInfoRow('Blood Group', patient.bloodGroup ?? 'N/A'),
            _buildInfoRow('Email', patient.email),
            _buildInfoRow('Phone', patient.phone),
          ],
        ),
      ),
    );
  }

  // Build medical information card
  Widget _buildMedicalInfoCard(dynamic patient) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Height',
              patient.height != null ? '${patient.height} cm' : 'N/A',
            ),
            _buildInfoRow(
              'Weight',
              patient.weight != null ? '${patient.weight} kg' : 'N/A',
            ),

            const SizedBox(height: 16),
            const Text(
              'Allergies',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTagsList(patient.allergies),

            const SizedBox(height: 16),
            const Text(
              'Chronic Conditions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTagsList(patient.chronicConditions),

            const SizedBox(height: 16),
            const Text(
              'Medications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTagsList(patient.medications),
          ],
        ),
      ),
    );
  }

  // Build health data tab
  Widget _buildHealthDataTab() {
    return Obx(() {
      if (_patientController.patientHealthData.isEmpty) {
        return const Center(
          child: Text(
            'No health data available',
            style: TextStyle(fontSize: 16),
          ),
        );
      }

      final healthData = _patientController.patientHealthData;

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: healthData.length,
        itemBuilder: (context, index) {
          return _buildHealthDataCard(healthData[index]);
        },
      );
    });
  }

  // Build symptoms tab
  Widget _buildSymptomsTab() {
    return Obx(() {
      if (_patientController.patientSymptoms.isEmpty) {
        return const Center(
          child: Text('No symptoms recorded', style: TextStyle(fontSize: 16)),
        );
      }

      final symptoms = _patientController.patientSymptoms;

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: symptoms.length,
        itemBuilder: (context, index) {
          return _buildSymptomCard(symptoms[index]);
        },
      );
    });
  }

  // Build diagnosis tab
  Widget _buildDiagnosisTab() {
    return Obx(() {
      if (_patientController.patientPredictions.isEmpty) {
        return const Center(
          child: Text(
            'No diagnosis results available',
            style: TextStyle(fontSize: 16),
          ),
        );
      }

      final predictions = _patientController.patientPredictions;

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: predictions.length,
        itemBuilder: (context, index) {
          return _buildPredictionCard(predictions[index]);
        },
      );
    });
  }

  // Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Build tags list
  Widget _buildTagsList(List<String>? tags) {
    if (tags == null || tags.isEmpty) {
      return const Text('None');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => _buildTag(tag)).toList(),
    );
  }

  // Build tag chip
  Widget _buildTag(String tag) {
    return Chip(
      label: Text(tag),
      backgroundColor: AppColors.secondaryColor.withOpacity(0.2),
      labelStyle: const TextStyle(
        color: AppColors.secondaryColor,
        fontSize: 12,
      ),
      padding: const EdgeInsets.all(4),
    );
  }

  // Build health data card
  Widget _buildHealthDataCard(HealthDataModel healthData) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                Text(
                  dateFormat.format(healthData.timestamp),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _getHealthStatusColor(healthData),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildHealthDataRow('Temperature', '${healthData.temperature}°C'),
            _buildHealthDataRow('Heart Rate', '${healthData.heartRate} bpm'),
            _buildHealthDataRow(
              'Blood Pressure',
              '${healthData.systolicBP}/${healthData.diastolicBP} mmHg',
            ),
            _buildHealthDataRow(
              'Oxygen Saturation',
              '${healthData.oxygenSaturation}%',
            ),
            if (healthData.notes != null && healthData.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${healthData.notes}',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build symptom card
  Widget _buildSymptomCard(SymptomModel symptom) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                Text(
                  dateFormat.format(symptom.timestamp),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                _buildSeverityIndicator(symptom.severity),
              ],
            ),
            const SizedBox(height: 12),
            Text(symptom.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Duration: ${symptom.duration} days',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (symptom.bodyParts != null && symptom.bodyParts!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Affected Areas:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _buildTagsList(symptom.bodyParts),
            ],
          ],
        ),
      ),
    );
  }

  // Build prediction card
  Widget _buildPredictionCard(PredictionResultModel prediction) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                Text(
                  dateFormat.format(prediction.timestamp),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                _buildUrgencyIndicator(prediction.urgencyLevel),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Possible Conditions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...prediction.diseases.map((disease) => _buildDiseaseRow(disease)),
            const SizedBox(height: 8),
            if (prediction.recommendedAction != null) ...[
              Text(
                'Recommended Action: ${prediction.recommendedAction}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build health data row
  Widget _buildHealthDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Build severity indicator
  Widget _buildSeverityIndicator(int severity) {
    Color color;
    String text;

    if (severity <= 3) {
      color = Colors.green;
      text = 'Mild';
    } else if (severity <= 6) {
      color = Colors.orange;
      text = 'Moderate';
    } else {
      color = Colors.red;
      text = 'Severe';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Build urgency indicator
  Widget _buildUrgencyIndicator(String? urgency) {
    if (urgency == null) return const SizedBox();

    Color color;

    switch (urgency.toLowerCase()) {
      case 'low':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'high':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        urgency,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Build disease row
  Widget _buildDiseaseRow(DiseaseWithProbability disease) {
    final percentage = (disease.probability * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(disease.name, style: const TextStyle(fontSize: 14)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$percentage%',
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get health status color
  Color _getHealthStatusColor(HealthDataModel healthData) {
    // Check if any vital signs are outside normal ranges
    if (healthData.temperature != null && healthData.temperature! > 37.5 ||
        healthData.temperature! < 36.0 ||
        healthData.heartRate! > 100 ||
        healthData.heartRate! < 60 ||
        healthData.systolicBP! > 140 ||
        healthData.systolicBP! < 90 ||
        healthData.diastolicBP! > 90 ||
        healthData.diastolicBP! < 60 ||
        healthData.oxygenSaturation! < 95) {
      return Colors.red;
    }

    // Check if any vital signs are borderline
    if (healthData.temperature! > 37.2 ||
        healthData.temperature! < 36.3 ||
        healthData.heartRate! > 90 ||
        healthData.heartRate! < 65 ||
        healthData.systolicBP! > 130 ||
        healthData.systolicBP! < 100 ||
        healthData.diastolicBP! > 85 ||
        healthData.diastolicBP! < 65 ||
        healthData.oxygenSaturation! < 97) {
      return Colors.orange;
    }

    // All vital signs are normal
    return Colors.green;
  }
}
