import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/doctor_controller.dart';
import '../../models/doctor_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({Key? key}) : super(key: key);

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final DoctorController _doctorController = Get.find<DoctorController>();
  final AdminNavigationController _navigationController = Get.find<AdminNavigationController>();
  
  late TabController _tabController;
  final RxBool _isLoading = false.obs;
  final RxList<DoctorModel> _pendingDoctors = <DoctorModel>[].obs;
  final RxList<DoctorModel> _approvedDoctors = <DoctorModel>[].obs;
  final RxList<DoctorModel> _rejectedDoctors = <DoctorModel>[].obs;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDoctors();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Load doctors data
  Future<void> _loadDoctors() async {
    _isLoading.value = true;
    
    try {
      // Get all doctors
      await _doctorController.getAllDoctors();
      
      // Create mock pending and rejected doctors
      final List<DoctorModel> allDoctors = _doctorController.doctors;
      
      // For demo purposes, we'll create mock pending and rejected doctors
      final List<DoctorModel> pendingDoctors = [
        DoctorModel(
          id: 'pending1',
          name: 'Dr. Abdullah Al-Qahtani',
          specialization: 'Dermatology',
          hospital: 'King Fahd Medical City',
          city: 'Riyadh',
          profileImage: 'https://randomuser.me/api/portraits/men/32.jpg',
          rating: 0.0,
          experience: 5,
          consultationFee: 300,
          isAvailableForVideo: true,
          isAvailableForChat: true,
        ),
        DoctorModel(
          id: 'pending2',
          name: 'Dr. Layla Al-Otaibi',
          specialization: 'Pediatrics',
          hospital: 'King Khalid University Hospital',
          city: 'Riyadh',
          profileImage: 'https://randomuser.me/api/portraits/women/33.jpg',
          rating: 0.0,
          experience: 3,
          consultationFee: 250,
          isAvailableForVideo: true,
          isAvailableForChat: false,
        ),
      ];
      
      final List<DoctorModel> rejectedDoctors = [
        DoctorModel(
          id: 'rejected1',
          name: 'Dr. Khalid Al-Harbi',
          specialization: 'General Practice',
          hospital: 'Saudi German Hospital',
          city: 'Jeddah',
          profileImage: 'https://randomuser.me/api/portraits/men/34.jpg',
          rating: 0.0,
          experience: 2,
          consultationFee: 200,
          isAvailableForVideo: false,
          isAvailableForChat: true,
        ),
      ];
      
      _pendingDoctors.assignAll(pendingDoctors);
      _approvedDoctors.assignAll(allDoctors);
      _rejectedDoctors.assignAll(rejectedDoctors);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load doctors: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending Approval'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDoctors,
          ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return TabBarView(
          controller: _tabController,
          children: [
            _buildDoctorList(_pendingDoctors, DoctorStatus.pending),
            _buildDoctorList(_approvedDoctors, DoctorStatus.approved),
            _buildDoctorList(_rejectedDoctors, DoctorStatus.rejected),
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => AdminBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }
  
  // Build doctor list
  Widget _buildDoctorList(List<DoctorModel> doctors, DoctorStatus status) {
    if (doctors.isEmpty) {
      return Center(
        child: Text('No ${status.toString().split('.').last} doctors found'),
      );
    }
    
    return ListView.builder(
      itemCount: doctors.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: NetworkImage(doctor.profileImage),
                ),
                title: Text(
                  doctor.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Specialization: ${doctor.specialization}'),
                    Text('Hospital: ${doctor.hospital}'),
                    Text('Experience: ${doctor.experience} years'),
                    Text('City: ${doctor.city}'),
                  ],
                ),
                trailing: status == DoctorStatus.pending
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.info_outline, color: AppColors.primaryColor),
                        onPressed: () => _showDoctorDetails(doctor),
                      ),
                onTap: () => _showDoctorDetails(doctor),
              ),
              if (status == DoctorStatus.pending)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => _approveDoctor(doctor),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => _rejectDoctor(doctor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  // Show doctor details
  void _showDoctorDetails(DoctorModel doctor) {
    Get.dialog(
      AlertDialog(
        title: Text(doctor.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: NetworkImage(doctor.profileImage),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Specialization', doctor.specialization),
              _buildDetailRow('Hospital', doctor.hospital),
              _buildDetailRow('City', doctor.city),
              _buildDetailRow('Experience', '${doctor.experience} years'),
              _buildDetailRow('Consultation Fee', '${doctor.consultationFee} SAR'),
              _buildDetailRow('Rating', doctor.rating.toString()),
              _buildDetailRow('Video Consultation', doctor.isAvailableForVideo ? 'Available' : 'Not Available'),
              _buildDetailRow('Chat Consultation', doctor.isAvailableForChat ? 'Available' : 'Not Available'),
              if (doctor.about != null) _buildDetailRow('About', doctor.about!),
              if (doctor.qualifications != null && doctor.qualifications!.isNotEmpty)
                _buildListDetailRow('Qualifications', doctor.qualifications!),
              if (doctor.languages != null && doctor.languages!.isNotEmpty)
                _buildListDetailRow('Languages', doctor.languages!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Build detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  // Build list detail row
  Widget _buildListDetailRow(String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          ...values.map((value) => Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(value)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
  
  // Approve doctor
  void _approveDoctor(DoctorModel doctor) {
    _pendingDoctors.remove(doctor);
    _approvedDoctors.add(doctor);
    Get.snackbar(
      'Success',
      'Doctor ${doctor.name} has been approved',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
  
  // Reject doctor
  void _rejectDoctor(DoctorModel doctor) {
    _pendingDoctors.remove(doctor);
    _rejectedDoctors.add(doctor);
    Get.snackbar(
      'Success',
      'Doctor ${doctor.name} has been rejected',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// Doctor status enum
enum DoctorStatus {
  pending,
  approved,
  rejected,
}
