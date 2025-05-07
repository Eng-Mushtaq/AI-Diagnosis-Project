import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/patient_controller.dart';
import '../../controllers/message_controller.dart';
import '../../controllers/video_call_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../models/health_data_model.dart';
import '../../models/symptom_model.dart';
import '../../models/prediction_result_model.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_tab_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../widgets/empty_state.dart';

import 'video_call_screen.dart';
import '../../views/messages/chat_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({Key? key, required this.patientId})
    : super(key: key);

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  final PatientController _patientController = Get.find<PatientController>();
  final MessageController _messageController = Get.find<MessageController>();
  final VideoCallController _videoCallController =
      Get.find<VideoCallController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    await _patientController.getPatientById(widget.patientId);
    if (_patientController.selectedPatient != null) {
      await Future.wait([
        _patientController.getPatientAppointments(widget.patientId),
        _patientController.getPatientHealthData(widget.patientId),
        _patientController.getPatientSymptoms(widget.patientId),
        _patientController.getPatientPredictions(widget.patientId),
      ]);
    }
  }

  void _startChat() async {
    final patient = _patientController.selectedPatient;
    if (patient == null) return;

    // Create or get existing chat
    final chatId = await _messageController.createOrGetChat(
      receiverId: patient.id,
      receiverName: patient.name,
      receiverImage: patient.profileImage,
    );

    if (chatId != null) {
      Get.to(() => ChatScreen(chatId: chatId));
    }
  }

  void _startVideoCall() async {
    final patient = _patientController.selectedPatient;
    if (patient == null) return;

    // Create video call
    final callData = await _videoCallController.createVideoCall(
      callerId: Get.find<AuthController>().user!.id,
      receiverId: patient.id,
    );

    if (callData != null) {
      Get.to(
        () => VideoCallScreen(
          callId: callData['id'],
          callToken: callData['callToken'],
          channelName: callData['channelName'],
          isInitiator: true,
          patientId: patient.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Patient Details',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientData,
          ),
        ],
      ),
      body: Obx(() {
        if (_patientController.isLoading) {
          return const LoadingIndicator();
        }

        if (_patientController.errorMessage.isNotEmpty) {
          return ErrorMessage(
            message: _patientController.errorMessage,
            onRetry: _loadPatientData,
          );
        }

        final patient = _patientController.selectedPatient;
        if (patient == null) {
          return const EmptyState(
            icon: Icons.person_off,
            title: 'Patient Not Found',
            message: 'The requested patient could not be found.',
          );
        }

        return Column(
          children: [
            _buildPatientHeader(patient),
            CustomTabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Appointments'),
                Tab(text: 'Health Data'),
                Tab(text: 'Diagnoses'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(patient),
                  _buildAppointmentsTab(),
                  _buildHealthDataTab(),
                  _buildDiagnosesTab(),
                ],
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final patient = _patientController.selectedPatient;
        if (patient == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startChat,
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _startVideoCall,
                  icon: const Icon(Icons.video_call),
                  label: const Text('Video Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPatientHeader(UserModel patient) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryColor.withOpacity(0.2),
            backgroundImage:
                patient.profileImage != null && patient.profileImage!.isNotEmpty
                    ? NetworkImage(patient.profileImage!)
                    : null,
            child:
                patient.profileImage == null || patient.profileImage!.isEmpty
                    ? Text(
                      patient.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (patient.relationshipType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRelationshipColor(patient.relationshipType!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      patient.relationshipType!.capitalize!,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  patient.email,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  patient.phone ?? 'No phone number',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(UserModel patient) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Personal Information'),
          _buildInfoCard([
            if (patient.gender != null)
              _buildInfoRow('Gender', patient.gender!),
            if (patient.age != null)
              _buildInfoRow('Age', '${patient.age} years'),
            if (patient.bloodGroup != null)
              _buildInfoRow('Blood Group', patient.bloodGroup!),
            if (patient.height != null)
              _buildInfoRow('Height', '${patient.height} cm'),
            if (patient.weight != null)
              _buildInfoRow('Weight', '${patient.weight} kg'),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Medical Information'),
          _buildInfoCard([
            if (patient.allergies != null && patient.allergies!.isNotEmpty)
              _buildInfoRow('Allergies', patient.allergies!.join(', ')),
            if (patient.chronicConditions != null &&
                patient.chronicConditions!.isNotEmpty)
              _buildInfoRow(
                'Chronic Conditions',
                patient.chronicConditions!.join(', '),
              ),
            if (patient.medications != null && patient.medications!.isNotEmpty)
              _buildInfoRow('Medications', patient.medications!.join(', ')),
          ]),
          const SizedBox(height: 16),
          if (patient.relationshipNotes != null &&
              patient.relationshipNotes!.isNotEmpty) ...[
            _buildSectionTitle('Doctor Notes'),
            _buildInfoCard([
              _buildInfoRow('Notes', patient.relationshipNotes!),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return Obx(() {
      final appointments = _patientController.patientAppointments;

      if (appointments.isEmpty) {
        return const EmptyState(
          icon: Icons.calendar_today,
          title: 'No Appointments',
          message: 'This patient has no appointments yet.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return _buildAppointmentCard(appointment);
        },
      );
    });
  }

  Widget _buildHealthDataTab() {
    return Obx(() {
      final healthData = _patientController.patientHealthData;

      if (healthData.isEmpty) {
        return const EmptyState(
          icon: Icons.favorite,
          title: 'No Health Data',
          message: 'This patient has no health data yet.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: healthData.length,
        itemBuilder: (context, index) {
          final data = healthData[index];
          return _buildHealthDataCard(data);
        },
      );
    });
  }

  Widget _buildDiagnosesTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: AppColors.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primaryColor,
              tabs: const [Tab(text: 'Symptoms'), Tab(text: 'AI Diagnoses')],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [_buildSymptomsSubtab(), _buildDiagnosesSubtab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsSubtab() {
    return Obx(() {
      final symptoms = _patientController.patientSymptoms;

      if (symptoms.isEmpty) {
        return const EmptyState(
          icon: Icons.sick,
          title: 'No Symptoms',
          message: 'This patient has not reported any symptoms yet.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: symptoms.length,
        itemBuilder: (context, index) {
          final symptom = symptoms[index];
          return _buildSymptomCard(symptom);
        },
      );
    });
  }

  Widget _buildDiagnosesSubtab() {
    return Obx(() {
      final predictions = _patientController.patientPredictions;

      if (predictions.isEmpty) {
        return const EmptyState(
          icon: Icons.medical_services,
          title: 'No Diagnoses',
          message: 'This patient has no AI diagnoses yet.',
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: predictions.length,
        itemBuilder: (context, index) {
          final prediction = predictions[index];
          return _buildPredictionCard(prediction);
        },
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
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
                  appointment.formattedDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.capitalize!,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${appointment.formattedTime}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Type: ${appointment.type.capitalize}',
              style: const TextStyle(fontSize: 14),
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(appointment.notes!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthDataCard(HealthDataModel data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
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
                  _getHealthDataTypeText(data),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  data.formattedDate,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getHealthDataValueText(data),
              style: const TextStyle(fontSize: 14),
            ),
            if (data.notes != null && data.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(data.notes!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomCard(SymptomModel symptom) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
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
                  'Symptom',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(symptom.timestamp),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Severity: ${symptom.severity}/10',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Duration: ${symptom.duration}',
              style: const TextStyle(fontSize: 14),
            ),
            if (symptom.description != null &&
                symptom.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(symptom.description!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(PredictionResultModel prediction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
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
                  'AI Diagnosis',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(prediction.timestamp),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Possible Conditions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            ...prediction.diseases.map(
              (disease) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        disease.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getProbabilityColor(disease.probability),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(disease.probability * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (prediction.recommendedAction != null &&
                prediction.recommendedAction!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Recommendation:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                prediction.recommendedAction!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRelationshipColor(String relationshipType) {
    switch (relationshipType.toLowerCase()) {
      case 'primary':
        return Colors.green;
      case 'specialist':
        return Colors.blue;
      case 'consultant':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getProbabilityColor(double probability) {
    if (probability >= 0.7) {
      return Colors.red;
    } else if (probability >= 0.4) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  String _getHealthDataTypeText(HealthDataModel data) {
    if (data.temperature != null) return 'Temperature';
    if (data.heartRate != null) return 'Heart Rate';
    if (data.systolicBP != null && data.diastolicBP != null)
      return 'Blood Pressure';
    if (data.respiratoryRate != null) return 'Respiratory Rate';
    if (data.oxygenSaturation != null) return 'Oxygen Saturation';
    if (data.bloodGlucose != null) return 'Blood Glucose';
    return 'Health Data';
  }

  String _getHealthDataValueText(HealthDataModel data) {
    if (data.temperature != null) return '${data.temperature}°C';
    if (data.heartRate != null) return '${data.heartRate} bpm';
    if (data.systolicBP != null && data.diastolicBP != null)
      return '${data.systolicBP}/${data.diastolicBP} mmHg';
    if (data.respiratoryRate != null)
      return '${data.respiratoryRate} breaths/min';
    if (data.oxygenSaturation != null) return '${data.oxygenSaturation}%';
    if (data.bloodGlucose != null) return '${data.bloodGlucose} mg/dL';
    return 'No value';
  }
}
