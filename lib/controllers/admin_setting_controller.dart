import 'package:get/get.dart';
import '../models/admin_setting_model.dart';
import '../services/admin_setting_service.dart';

/// Controller for managing admin settings
class AdminSettingController extends GetxController {
  final AdminSettingService _settingService = Get.find<AdminSettingService>();

  // Observable lists
  final RxList<AdminSettingModel> _allSettings = <AdminSettingModel>[].obs;
  final RxMap<String, RxList<AdminSettingModel>> _settingsByCategory = <String, RxList<AdminSettingModel>>{}.obs;

  // Loading states
  final RxBool _isLoadingSettings = false.obs;
  final RxBool _isLoadingCategorySettings = false.obs;
  final RxBool _isSavingSetting = false.obs;
  final RxBool _isDeletingSetting = false.obs;
  final RxBool _isInitializingDefaults = false.obs;

  // Error messages
  final RxString _errorMessage = ''.obs;

  // Getters
  List<AdminSettingModel> get allSettings => _allSettings;
  Map<String, List<AdminSettingModel>> get settingsByCategory => 
      _settingsByCategory.map((key, value) => MapEntry(key, value.toList()));
  
  List<AdminSettingModel> getSettingsForCategory(String category) {
    return _settingsByCategory[category]?.toList() ?? [];
  }

  bool get isLoadingSettings => _isLoadingSettings.value;
  bool get isLoadingCategorySettings => _isLoadingCategorySettings.value;
  bool get isSavingSetting => _isSavingSetting.value;
  bool get isDeletingSetting => _isDeletingSetting.value;
  bool get isInitializingDefaults => _isInitializingDefaults.value;

  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    // Load data when controller is initialized
    fetchAllSettings();
  }

  // Fetch all settings
  Future<void> fetchAllSettings() async {
    _isLoadingSettings.value = true;
    _errorMessage.value = '';

    try {
      final settings = await _settingService.getAllSettings();
      _allSettings.assignAll(settings);
      
      // Group settings by category
      final Map<String, List<AdminSettingModel>> grouped = {};
      for (var setting in settings) {
        if (!grouped.containsKey(setting.category)) {
          grouped[setting.category] = [];
        }
        grouped[setting.category]!.add(setting);
      }
      
      // Update observable map
      _settingsByCategory.clear();
      for (var entry in grouped.entries) {
        _settingsByCategory[entry.key] = entry.value.obs;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch settings: ${e.toString()}';
    } finally {
      _isLoadingSettings.value = false;
    }
  }

  // Fetch settings by category
  Future<void> fetchSettingsByCategory(String category) async {
    _isLoadingCategorySettings.value = true;
    _errorMessage.value = '';

    try {
      final settings = await _settingService.getSettingsByCategory(category);
      
      // Update category in map
      _settingsByCategory[category] = settings.obs;
      
      // Update all settings list
      final existingKeys = _allSettings.map((s) => s.key).toSet();
      for (var setting in settings) {
        if (existingKeys.contains(setting.key)) {
          // Replace existing setting
          final index = _allSettings.indexWhere((s) => s.key == setting.key);
          if (index != -1) {
            _allSettings[index] = setting;
          }
        } else {
          // Add new setting
          _allSettings.add(setting);
        }
      }
    } catch (e) {
      _errorMessage.value = 'Failed to fetch settings for category $category: ${e.toString()}';
    } finally {
      _isLoadingCategorySettings.value = false;
    }
  }

  // Get setting value
  Future<dynamic> getSettingValue(String key) async {
    try {
      // Check if we already have the setting in our list
      final existingSetting = _allSettings.firstWhereOrNull((s) => s.key == key);
      if (existingSetting != null) {
        return existingSetting.value;
      }
      
      // Otherwise fetch from service
      return await _settingService.getSettingValue(key);
    } catch (e) {
      _errorMessage.value = 'Failed to get setting value: ${e.toString()}';
      return null;
    }
  }

  // Save setting
  Future<bool> saveSetting({
    required String key,
    required dynamic value,
    String? description,
    required String category,
    bool isPublic = false,
  }) async {
    _isSavingSetting.value = true;
    _errorMessage.value = '';

    try {
      final setting = await _settingService.saveSetting(
        key: key,
        value: value,
        description: description,
        category: category,
        isPublic: isPublic,
      );
      
      if (setting != null) {
        // Update in all settings list
        final index = _allSettings.indexWhere((s) => s.key == key);
        if (index != -1) {
          _allSettings[index] = setting;
        } else {
          _allSettings.add(setting);
        }
        
        // Update in category map
        if (_settingsByCategory.containsKey(category)) {
          final categoryIndex = _settingsByCategory[category]!.indexWhere((s) => s.key == key);
          if (categoryIndex != -1) {
            _settingsByCategory[category]![categoryIndex] = setting;
          } else {
            _settingsByCategory[category]!.add(setting);
          }
        } else {
          _settingsByCategory[category] = [setting].obs;
        }
        
        return true;
      } else {
        _errorMessage.value = 'Failed to save setting. Only admins can save settings.';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to save setting: ${e.toString()}';
      return false;
    } finally {
      _isSavingSetting.value = false;
    }
  }

  // Delete setting
  Future<bool> deleteSetting(String key) async {
    _isDeletingSetting.value = true;
    _errorMessage.value = '';

    try {
      final success = await _settingService.deleteSetting(key);
      
      if (success) {
        // Find the setting to get its category
        final setting = _allSettings.firstWhereOrNull((s) => s.key == key);
        final category = setting?.category;
        
        // Remove from all settings list
        _allSettings.removeWhere((s) => s.key == key);
        
        // Remove from category map if category is known
        if (category != null && _settingsByCategory.containsKey(category)) {
          _settingsByCategory[category]!.removeWhere((s) => s.key == key);
        }
        
        return true;
      } else {
        _errorMessage.value = 'Failed to delete setting. Only admins can delete settings.';
        return false;
      }
    } catch (e) {
      _errorMessage.value = 'Failed to delete setting: ${e.toString()}';
      return false;
    } finally {
      _isDeletingSetting.value = false;
    }
  }

  // Initialize default settings
  Future<void> initializeDefaultSettings() async {
    _isInitializingDefaults.value = true;
    _errorMessage.value = '';

    try {
      await _settingService.initializeDefaultSettings();
      await fetchAllSettings();
    } catch (e) {
      _errorMessage.value = 'Failed to initialize default settings: ${e.toString()}';
    } finally {
      _isInitializingDefaults.value = false;
    }
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await fetchAllSettings();
  }
}
