import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  final AdminController _adminController = Get.find<AdminController>();
  final AdminNavigationController _navigationController =
      Get.find<AdminNavigationController>();

  late TabController _tabController;
  final RxBool _isLoading = false.obs;
  final RxBool _isCreatingAdmin = false.obs;
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

  // Load real users data from Supabase
  Future<void> _loadUsers() async {
    _isLoading.value = true;

    try {
      // Fetch all users from the admin controller
      await _adminController.refreshAllData();

      // Get users from controller
      _users.assignAll(_adminController.users);
      _patients.assignAll(_adminController.patients);
      _doctors.assignAll(_adminController.doctors);

      // Fetch admin users specifically
      final adminUsers =
          _users.where((user) => user.userType == UserType.admin).toList();
      _admins.assignAll(adminUsers);

      debugPrint(
        'Loaded ${_users.length} users: ${_patients.length} patients, ${_doctors.length} doctors, ${_admins.length} admins',
      );
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddUserDialog();
        },
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Add Admin'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
              child:
                  user.profileImage == null
                      ? Icon(_getUserIcon(user.userType), color: Colors.grey)
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
                if (user.userType == UserType.doctor &&
                    user.specialization != null)
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
    }
  }

  // Show add admin dialog
  void _showAddUserDialog() {
    // Controllers for form fields
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    // Admin role options
    final adminRoles = ['super_admin', 'content_admin', 'user_admin'];
    final selectedRole = 'content_admin'.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog title
                  const Center(
                    child: Text(
                      'Add New Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name field
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter admin name',
                    controller: nameController,
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  CustomTextField(
                    label: 'Email',
                    hint: 'Enter admin email',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  CustomTextField(
                    label: 'Password',
                    hint: 'Enter password',
                    controller: passwordController,
                    obscureText: true,
                    prefixIcon: Icons.lock,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  CustomTextField(
                    label: 'Confirm Password',
                    hint: 'Confirm password',
                    controller: confirmPasswordController,
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm the password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Admin role dropdown
                  const Text(
                    'Admin Role',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedRole.value,
                          items:
                              adminRoles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(
                                    role.replaceAll('_', ' ').capitalize!,
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              selectedRole.value = value;
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      Obx(
                        () => CustomButton(
                          text: 'Create Admin',
                          isLoading: _isCreatingAdmin.value,
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              _isCreatingAdmin.value = true;

                              try {
                                // Determine permissions based on selected role
                                Map<String, dynamic> additionalData = {
                                  'adminRole': selectedRole.value,
                                };

                                // Set permissions based on role
                                if (selectedRole.value == 'super_admin') {
                                  additionalData['permissions'] = [
                                    'manage_users',
                                    'manage_doctors',
                                    'manage_content',
                                    'view_analytics',
                                    'create_admin',
                                  ];
                                } else if (selectedRole.value ==
                                    'content_admin') {
                                  additionalData['permissions'] = [
                                    'view_users',
                                    'view_doctors',
                                    'manage_content',
                                  ];
                                } else if (selectedRole.value == 'user_admin') {
                                  additionalData['permissions'] = [
                                    'manage_users',
                                    'view_doctors',
                                  ];
                                }

                                final success = await _adminController
                                    .createAdmin(
                                      nameController.text.trim(),
                                      emailController.text.trim(),
                                      passwordController.text,
                                      additionalData,
                                    );

                                _isCreatingAdmin.value = false;

                                if (success) {
                                  Get.back();

                                  // Refresh the user lists
                                  await _loadUsers();

                                  Get.snackbar(
                                    'Success',
                                    'Admin created successfully',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green,
                                    colorText: Colors.white,
                                  );
                                } else {
                                  Get.snackbar(
                                    'Error',
                                    'Failed to create admin: ${_adminController.errorMessage}',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              } catch (e) {
                                _isCreatingAdmin.value = false;
                                Get.snackbar(
                                  'Error',
                                  'Failed to create admin: ${e.toString()}',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      // Dispose controllers when dialog is closed
      nameController.dispose();
      emailController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  // Show edit user dialog
  void _showEditUserDialog(UserModel user) {
    // Controllers for form fields
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    // Admin role options (if user is admin)
    final adminRoles = ['super_admin', 'content_admin', 'user_admin'];
    final selectedRole = (user.adminRole ?? 'content_admin').obs;

    // Loading state
    final RxBool isUpdating = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog title
                  Center(
                    child: Text(
                      'Edit ${user.userType.toString().split('.').last.capitalize!}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name field
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter name',
                    controller: nameController,
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email field (read-only)
                  CustomTextField(
                    label: 'Email',
                    hint: 'Email address',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    readOnly: true, // Email cannot be changed
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!GetUtils.isEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone field
                  CustomTextField(
                    label: 'Phone',
                    hint: 'Enter phone number',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone,
                    validator: (value) {
                      // Phone is optional
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Admin role dropdown (only for admin users)
                  if (user.userType == UserType.admin) ...[
                    const Text(
                      'Admin Role',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedRole.value,
                            items:
                                adminRoles.map((role) {
                                  return DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(
                                      role.replaceAll('_', ' ').capitalize!,
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                selectedRole.value = value;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      Obx(
                        () => CustomButton(
                          text: 'Update',
                          isLoading: isUpdating.value,
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              isUpdating.value = true;

                              try {
                                // Create updated user model
                                final updatedUser = user.copyWith(
                                  name: nameController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  adminRole:
                                      user.userType == UserType.admin
                                          ? selectedRole.value
                                          : user.adminRole,
                                );

                                // Update user in the database
                                final success = await _adminController
                                    .updateUser(updatedUser);

                                if (success) {
                                  // Refresh the user lists
                                  await _loadUsers();
                                } else {
                                  // Show error message
                                  Get.snackbar(
                                    'Error',
                                    'Failed to update user: ${_adminController.errorMessage}',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return; // Don't close dialog on error
                                }

                                Get.back();
                                Get.snackbar(
                                  'Success',
                                  'User updated successfully',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green,
                                  colorText: Colors.white,
                                );
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  'Failed to update user: ${e.toString()}',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              } finally {
                                isUpdating.value = false;
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      // Dispose controllers when dialog is closed
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
    });
  }

  // Show delete confirmation
  void _showDeleteConfirmation(UserModel user) {
    final RxBool isDeleting = false.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Delete User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${user.name}?'),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone and will remove all associated data.',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          Obx(
            () => TextButton(
              onPressed:
                  isDeleting.value
                      ? null
                      : () async {
                        isDeleting.value = true;
                        try {
                          final success = await _adminController.deleteUser(
                            user.id,
                          );

                          if (success) {
                            // Refresh the lists
                            await _loadUsers();

                            Get.back();
                            Get.snackbar(
                              'Success',
                              'User deleted successfully',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } else {
                            Get.back();
                            Get.snackbar(
                              'Error',
                              'Failed to delete user: ${_adminController.errorMessage}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        } catch (e) {
                          Get.back();
                          Get.snackbar(
                            'Error',
                            'Failed to delete user: ${e.toString()}',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        } finally {
                          isDeleting.value = false;
                        }
                      },
              child:
                  isDeleting.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
            ),
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
                  backgroundImage:
                      user.profileImage != null
                          ? NetworkImage(user.profileImage!)
                          : null,
                  child:
                      user.profileImage == null
                          ? Icon(
                            _getUserIcon(user.userType),
                            size: 50,
                            color: Colors.grey,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'User Type',
                user.userType.toString().split('.').last.capitalize!,
              ),
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Phone', user.phone),
              if (user.age != null) _buildDetailRow('Age', '${user.age} years'),
              if (user.gender != null) _buildDetailRow('Gender', user.gender!),
              if (user.specialization != null)
                _buildDetailRow('Specialization', user.specialization!),
              if (user.hospital != null)
                _buildDetailRow('Hospital', user.hospital!),
              if (user.experience != null)
                _buildDetailRow('Experience', '${user.experience} years'),
              if (user.adminRole != null)
                _buildDetailRow('Admin Role', user.adminRole!),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
