import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/patient_controller.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../controllers/navigation_controller.dart';

/// Screen to display a list of patients for doctors
class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final PatientController _patientController = Get.find<PatientController>();
  final DoctorNavigationController _navigationController = Get.find<DoctorNavigationController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure loading happens after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load patients for the doctor
  Future<void> _loadPatients() async {
    if (_authController.user != null) {
      await _patientController.getDoctorPatients(_authController.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                _searchQuery.value = value;
              },
            ),
          ),

          // Patients list
          Expanded(
            child: Obx(() {
              if (_patientController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_patientController.patients.isEmpty) {
                return const Center(
                  child: Text(
                    'No patients found',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final filteredPatients = _patientController.searchPatientsByName(_searchQuery.value);

              return RefreshIndicator(
                onRefresh: _loadPatients,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = filteredPatients[index];
                    return _buildPatientCard(patient);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => DoctorBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }

  // Build patient card widget
  Widget _buildPatientCard(UserModel patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _patientController.setSelectedPatient(patient);
          Get.toNamed(AppRoutes.patientDetails);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Patient avatar
              CircleAvatar(
                radius: 30,
                backgroundImage: patient.profileImage != null
                    ? NetworkImage(patient.profileImage!)
                    : null,
                child: patient.profileImage == null
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Patient info
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
                    Text(
                      'Age: ${patient.age ?? 'N/A'} | Gender: ${patient.gender ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Blood Group: ${patient.bloodGroup ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
