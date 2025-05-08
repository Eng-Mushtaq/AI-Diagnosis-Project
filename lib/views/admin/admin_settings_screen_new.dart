import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_setting_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../../models/admin_setting_model.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final AdminSettingController _settingController =
      Get.find<AdminSettingController>();
  final AdminNavigationController _navigationController =
      Get.find<AdminNavigationController>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load settings
  Future<void> _loadSettings() async {
    await _settingController.refreshAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Settings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSettings),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authController.logout();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_settingController.isLoadingSettings) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin profile card
              _buildAdminProfileCard(),
              const SizedBox(height: 24),

              // Settings by category
              ...SettingCategory.all.map((category) {
                final settings = _settingController.getSettingsForCategory(
                  category,
                );
                if (settings.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(_formatCategoryName(category)),
                    _buildSettingsCard(settings),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),

              // Initialize default settings button
              Center(
                child: ElevatedButton.icon(
                  onPressed:
                      _settingController.isInitializingDefaults
                          ? null
                          : () => _initializeDefaultSettings(),
                  icon:
                      _settingController.isInitializingDefaults
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.settings_backup_restore),
                  label: const Text('Initialize Default Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSettingDialog(),
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Obx(
        () => AdminBottomNavBar(
          currentIndex: _navigationController.currentIndex,
          onTap: _navigationController.changePage,
        ),
      ),
    );
  }

  // Format category name
  String _formatCategoryName(String category) {
    return category.split('_').map((word) => word.capitalize).join(' ');
  }

  // Build admin profile card
  Widget _buildAdminProfileCard() {
    final user = _authController.user;
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
              child:
                  user.profileImage == null
                      ? const Icon(Icons.admin_panel_settings, size: 40)
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.adminRole ?? 'Administrator',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryColor),
              onPressed: () {
                Get.snackbar(
                  'Coming Soon',
                  'Edit profile feature is not implemented yet',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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

  // Build settings card
  Widget _buildSettingsCard(List<AdminSettingModel> settings) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: settings.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final setting = settings[index];
          return _buildSettingTile(setting);
        },
      ),
    );
  }

  // Build setting tile
  Widget _buildSettingTile(AdminSettingModel setting) {
    Widget? trailing;

    // Determine the type of setting value and create appropriate widget
    if (setting.value is bool) {
      trailing = Switch(
        value: setting.value as bool,
        onChanged: (value) => _updateSetting(setting, value),
        activeColor: AppColors.primaryColor,
      );
    } else {
      trailing = const Icon(Icons.edit, color: AppColors.primaryColor);
    }

    return ListTile(
      title: Text(
        _formatSettingKey(setting.key),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (setting.description != null) ...[
            const SizedBox(height: 4),
            Text(setting.description!),
          ],
          const SizedBox(height: 4),
          Text(
            'Value: ${_formatSettingValue(setting.value)}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
      trailing: trailing,
      onTap:
          setting.value is bool ? null : () => _showEditSettingDialog(setting),
    );
  }

  // Format setting key
  String _formatSettingKey(String key) {
    return key.split('_').map((word) => word.capitalize).join(' ');
  }

  // Format setting value
  String _formatSettingValue(dynamic value) {
    if (value == null) return 'Not set';
    if (value is bool) return value ? 'Enabled' : 'Disabled';
    if (value is Map || value is List) return 'Complex value';
    return value.toString();
  }

  // Update setting
  Future<void> _updateSetting(
    AdminSettingModel setting,
    dynamic newValue,
  ) async {
    final success = await _settingController.saveSetting(
      key: setting.key,
      value: newValue,
      description: setting.description,
      category: setting.category,
      isPublic: setting.isPublic,
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Setting updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update setting: ${_settingController.errorMessage}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Show edit setting dialog
  void _showEditSettingDialog(AdminSettingModel setting) {
    final TextEditingController valueController = TextEditingController(
      text: setting.value?.toString() ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: setting.description ?? '',
    );
    bool isPublic = setting.isPublic;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit ${_formatSettingKey(setting.key)}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Public Setting'),
                    subtitle: const Text(
                      'If enabled, this setting will be visible to all users',
                    ),
                    value: isPublic,
                    onChanged: (value) {
                      setState(() {
                        isPublic = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (valueController.text.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Value cannot be empty',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  // Parse value based on original type
                  dynamic newValue = valueController.text;
                  if (setting.value is int) {
                    newValue = int.tryParse(valueController.text) ?? 0;
                  } else if (setting.value is double) {
                    newValue = double.tryParse(valueController.text) ?? 0.0;
                  } else if (setting.value is bool) {
                    newValue = valueController.text.toLowerCase() == 'true';
                  }

                  final success = await _settingController.saveSetting(
                    key: setting.key,
                    value: newValue,
                    description: descriptionController.text,
                    category: setting.category,
                    isPublic: isPublic,
                  );

                  Get.back();

                  if (success) {
                    Get.snackbar(
                      'Success',
                      'Setting updated successfully',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Failed to update setting: ${_settingController.errorMessage}',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      valueController.dispose();
      descriptionController.dispose();
    });
  }

  // Show add setting dialog
  void _showAddSettingDialog() {
    final TextEditingController keyController = TextEditingController();
    final TextEditingController valueController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedCategory = SettingCategory.general;
    bool isPublic = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Setting'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: 'Key',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. app_name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        SettingCategory.all.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(_formatCategoryName(category)),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Public Setting'),
                    subtitle: const Text(
                      'If enabled, this setting will be visible to all users',
                    ),
                    value: isPublic,
                    onChanged: (value) {
                      setState(() {
                        isPublic = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (keyController.text.isEmpty ||
                      valueController.text.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Key and value cannot be empty',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  final success = await _settingController.saveSetting(
                    key: keyController.text,
                    value: valueController.text,
                    description: descriptionController.text,
                    category: selectedCategory,
                    isPublic: isPublic,
                  );

                  Get.back();

                  if (success) {
                    Get.snackbar(
                      'Success',
                      'Setting created successfully',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    Get.snackbar(
                      'Error',
                      'Failed to create setting: ${_settingController.errorMessage}',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      keyController.dispose();
      valueController.dispose();
      descriptionController.dispose();
    });
  }

  // Initialize default settings
  Future<void> _initializeDefaultSettings() async {
    // Show loading dialog
    Get.dialog(
      const AlertDialog(
        title: Text('Initializing Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Creating database tables and initializing default settings...',
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await _settingController.initializeDefaultSettings();

      // Close loading dialog
      Get.back();

      Get.snackbar(
        'Success',
        'Default settings initialized successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      // Close loading dialog
      Get.back();

      Get.snackbar(
        'Error',
        'Failed to initialize settings: ${_settingController.errorMessage}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
