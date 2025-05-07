import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/patient_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import '../../widgets/empty_state.dart';
import 'patient_detail_screen.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final PatientController _patientController = Get.find<PatientController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  final RxList<UserModel> _filteredPatients = <UserModel>[].obs;
  final RxBool _isSearching = false.obs;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPatients);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final currentUser = _authController.currentUser.value;
    if (currentUser != null) {
      await _patientController.getDoctorPatients(currentUser.id);
      _filteredPatients.assignAll(_patientController.patients);
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredPatients.assignAll(_patientController.patients);
      _isSearching.value = false;
    } else {
      _isSearching.value = true;
      _filteredPatients.assignAll(_patientController.patients.where((patient) {
        return patient.name.toLowerCase().contains(query) ||
            (patient.email?.toLowerCase().contains(query) ?? false) ||
            (patient.phone?.toLowerCase().contains(query) ?? false);
      }).toList());
    }
  }

  void _viewPatientDetails(UserModel patient) {
    Get.to(() => PatientDetailScreen(patientId: patient.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Patients',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search patients...',
              onTap: () {
                _searchController.clear();
                _filterPatients();
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_patientController.isLoading) {
                return const LoadingIndicator();
              }

              if (_patientController.errorMessage.isNotEmpty) {
                return ErrorMessage(
                  message: _patientController.errorMessage,
                  onRetry: _loadPatients,
                );
              }

              final patients = _isSearching.value
                  ? _filteredPatients
                  : _patientController.patients;

              if (patients.isEmpty) {
                return const EmptyState(
                  icon: Icons.people,
                  title: 'No Patients Found',
                  message: 'You don\'t have any patients yet.',
                );
              }

              return RefreshIndicator(
                onRefresh: _loadPatients,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    return _buildPatientCard(patient);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(UserModel patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _viewPatientDetails(patient),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                backgroundImage: patient.profileImage != null &&
                        patient.profileImage!.isNotEmpty
                    ? NetworkImage(patient.profileImage!)
                    : null,
                child: patient.profileImage == null ||
                        patient.profileImage!.isEmpty
                    ? Text(
                        patient.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (patient.relationshipType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRelationshipColor(patient.relationshipType!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          patient.relationshipType!.capitalize!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (patient.gender != null)
                      Text(
                        'Gender: ${patient.gender}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (patient.age != null)
                      Text(
                        'Age: ${patient.age} years',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ],
          ),
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
}
