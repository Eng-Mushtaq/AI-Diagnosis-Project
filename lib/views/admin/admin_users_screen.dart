import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final AdminNavigationController _navigationController = Get.find<AdminNavigationController>();
  
  late TabController _tabController;
  final RxBool _isLoading = false.obs;
  final RxList<UserModel> _users = <UserModel>[].obs;
  final RxList<UserModel> _doctors = <UserModel>[].obs;
  final RxList<UserModel> _patients = <UserModel>[].obs;
  final RxList<UserModel> _admins = <UserModel>[].obs;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Load mock users data
  Future<void> _loadUsers() async {
    _isLoading.value = true;
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data
      final List<UserModel> mockUsers = [
        UserModel(
          id: 'p1',
          name: 'Ahmed Ali',
          email: 'ahmed@example.com',
          phone: '+966501234567',
          userType: UserType.patient,
          profileImage: 'https://randomuser.me/api/portraits/men/1.jpg',
          age: 35,
          gender: 'Male',
        ),
        UserModel(
          id: 'p2',
          name: 'Fatima Khan',
          email: 'fatima@example.com',
          phone: '+966512345678',
          userType: UserType.patient,
          profileImage: 'https://randomuser.me/api/portraits/women/2.jpg',
          age: 28,
          gender: 'Female',
        ),
        UserModel(
          id: 'd1',
          name: 'Dr. Mohammed Al-Saud',
          email: 'dr.mohammed@example.com',
          phone: '+966523456789',
          userType: UserType.doctor,
          profileImage: 'https://randomuser.me/api/portraits/men/3.jpg',
          specialization: 'Cardiology',
          hospital: 'King Faisal Hospital',
          experience: 10,
        ),
        UserModel(
          id: 'd2',
          name: 'Dr. Sara Ahmed',
          email: 'dr.sara@example.com',
          phone: '+966534567890',
          userType: UserType.doctor,
          profileImage: 'https://randomuser.me/api/portraits/women/4.jpg',
          specialization: 'Neurology',
          hospital: 'Saudi German Hospital',
          experience: 8,
        ),
        UserModel(
          id: 'a1',
          name: 'Admin User',
          email: 'admin@example.com',
          phone: '+966545678901',
          userType: UserType.admin,
          adminRole: 'super_admin',
        ),
      ];
      
      _users.assignAll(mockUsers);
      
      // Filter users by type
      _patients.assignAll(_users.where((user) => user.userType == UserType.patient).toList());
      _doctors.assignAll(_users.where((user) => user.userType == UserType.doctor).toList());
      _admins.assignAll(_users.where((user) => user.userType == UserType.admin).toList());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load users: ${e.toString()}',
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
        title: const Text('User Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Patients'),
            Tab(text: 'Doctors'),
            Tab(text: 'Admins'),
          ],
          labelColor: AppColors.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
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
            _buildUserList(_patients),
            _buildUserList(_doctors),
            _buildUserList(_admins),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUserDialog();
        },
        child: const Icon(Icons.add),
        backgroundColor: AppColors.primaryColor,
      ),
      bottomNavigationBar: Obx(
        () => AdminBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }
  
  // Build user list
  Widget _buildUserList(List<UserModel> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No users found'));
    }
    
    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage: user.profileImage != null
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: user.profileImage == null
                  ? Icon(
                      _getUserIcon(user.userType),
                      color: Colors.grey,
                    )
                  : null,
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Email: ${user.email}'),
                Text('Phone: ${user.phone}'),
                if (user.userType == UserType.doctor && user.specialization != null)
                  Text('Specialization: ${user.specialization}'),
                if (user.userType == UserType.admin && user.adminRole != null)
                  Text('Role: ${user.adminRole}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryColor),
                  onPressed: () => _showEditUserDialog(user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteConfirmation(user),
                ),
              ],
            ),
            onTap: () {
              // View user details
              _showUserDetails(user);
            },
          ),
        );
      },
    );
  }
  
  // Get icon based on user type
  IconData _getUserIcon(UserType userType) {
    switch (userType) {
      case UserType.patient:
        return Icons.person;
      case UserType.doctor:
        return Icons.medical_services;
      case UserType.admin:
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
  
  // Show add user dialog
  void _showAddUserDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Add New User'),
        content: const Text('This feature is not implemented yet.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Show edit user dialog
  void _showEditUserDialog(UserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Edit User'),
        content: const Text('This feature is not implemented yet.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Show delete confirmation
  void _showDeleteConfirmation(UserModel user) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove user from lists
              _users.remove(user);
              _patients.remove(user);
              _doctors.remove(user);
              _admins.remove(user);
              Get.back();
              Get.snackbar(
                'Success',
                'User deleted successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  // Show user details
  void _showUserDetails(UserModel user) {
    Get.dialog(
      AlertDialog(
        title: Text(user.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user.profileImage == null
                      ? Icon(
                          _getUserIcon(user.userType),
                          size: 50,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('User Type', user.userType.toString().split('.').last.capitalize!),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phone),
              if (user.age != null) _buildDetailRow('Age', '${user.age} years'),
              if (user.gender != null) _buildDetailRow('Gender', user.gender!),
              if (user.specialization != null) _buildDetailRow('Specialization', user.specialization!),
              if (user.hospital != null) _buildDetailRow('Hospital', user.hospital!),
              if (user.experience != null) _buildDetailRow('Experience', '${user.experience} years'),
              if (user.adminRole != null) _buildDetailRow('Admin Role', user.adminRole!),
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
}
