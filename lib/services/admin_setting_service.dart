import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_setting_model.dart';
import 'supabase_service.dart';
import 'admin_service.dart';

/// Service class for handling admin setting operations
class AdminSettingService extends GetxService {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final AdminService _adminService = Get.find<AdminService>();

  // Get Supabase client
  SupabaseClient get _supabase => _supabaseService.supabaseClient;

  // Cache for settings to reduce database calls
  final Map<String, AdminSettingModel> _settingsCache = {};
  
  // Default settings
  final Map<String, dynamic> _defaultSettings = {
    SettingKey.appName: 'AI Diagnosist',
    SettingKey.appDescription: 'AI-powered healthcare diagnosis application',
    SettingKey.contactEmail: 'contact@aidiagnosist.com',
    SettingKey.supportEmail: 'support@aidiagnosist.com',
    SettingKey.passwordMinLength: 8,
    SettingKey.passwordRequireSpecialChar: true,
    SettingKey.passwordRequireNumber: true,
    SettingKey.passwordRequireUppercase: true,
    SettingKey.sessionTimeout: 60, // minutes
    SettingKey.emailNotificationsEnabled: true,
    SettingKey.pushNotificationsEnabled: true,
    SettingKey.smsNotificationsEnabled: false,
    SettingKey.primaryColor: '#2196F3',
    SettingKey.secondaryColor: '#FF9800',
    SettingKey.darkModeEnabled: false,
    SettingKey.maintenanceMode: false,
    SettingKey.maintenanceMessage: 'System is under maintenance. Please try again later.',
    SettingKey.systemVersion: '1.0.0',
    SettingKey.allowRegistration: true,
    SettingKey.allowDoctorRegistration: true,
    SettingKey.currencyCode: 'USD',
    SettingKey.taxRate: 0.0,
    SettingKey.aiDiagnosisEnabled: true,
    SettingKey.aiProvider: 'gemini',
    SettingKey.aiConfidenceThreshold: 0.7,
    SettingKey.aiMaxResults: 5,
  };

  // Get all admin settings
  Future<List<AdminSettingModel>> getAllSettings() async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can get all settings');
        return [];
      }

      // Get all settings
      final response = await _supabase
          .from('admin_settings')
          .select()
          .order('category', ascending: true)
          .order('setting_key', ascending: true);

      // Parse the response into AdminSettingModel objects
      List<AdminSettingModel> settings = [];
      for (var setting in response) {
        try {
          final model = AdminSettingModel.fromJson(setting);
          settings.add(model);
          
          // Update cache
          _settingsCache[model.key] = model;
        } catch (e) {
          debugPrint('Error parsing admin setting: $e');
        }
      }

      return settings;
    } catch (e) {
      debugPrint('Error getting all admin settings: $e');
      return [];
    }
  }

  // Get settings by category
  Future<List<AdminSettingModel>> getSettingsByCategory(String category) async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can get settings by category');
        return [];
      }

      // Get settings by category
      final response = await _supabase
          .from('admin_settings')
          .select()
          .eq('category', category)
          .order('setting_key', ascending: true);

      // Parse the response into AdminSettingModel objects
      List<AdminSettingModel> settings = [];
      for (var setting in response) {
        try {
          final model = AdminSettingModel.fromJson(setting);
          settings.add(model);
          
          // Update cache
          _settingsCache[model.key] = model;
        } catch (e) {
          debugPrint('Error parsing admin setting: $e');
        }
      }

      return settings;
    } catch (e) {
      debugPrint('Error getting settings by category: $e');
      return [];
    }
  }

  // Get a single setting by key
  Future<AdminSettingModel?> getSetting(String key) async {
    try {
      // Check cache first
      if (_settingsCache.containsKey(key)) {
        return _settingsCache[key];
      }

      // Get setting from database
      final response = await _supabase
          .from('admin_settings')
          .select()
          .eq('setting_key', key)
          .maybeSingle();

      if (response != null) {
        final model = AdminSettingModel.fromJson(response);
        
        // Update cache
        _settingsCache[key] = model;
        
        return model;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting setting: $e');
      return null;
    }
  }

  // Get setting value by key
  Future<dynamic> getSettingValue(String key) async {
    try {
      // Check cache first
      if (_settingsCache.containsKey(key)) {
        return _settingsCache[key]!.value;
      }

      // Get setting from database
      final setting = await getSetting(key);
      if (setting != null) {
        return setting.value;
      }
      
      // Return default value if available
      if (_defaultSettings.containsKey(key)) {
        return _defaultSettings[key];
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting setting value: $e');
      
      // Return default value if available
      if (_defaultSettings.containsKey(key)) {
        return _defaultSettings[key];
      }
      
      return null;
    }
  }

  // Create or update a setting
  Future<AdminSettingModel?> saveSetting({
    required String key,
    required dynamic value,
    String? description,
    required String category,
    bool isPublic = false,
  }) async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can save settings');
        return null;
      }

      // Get current user ID
      final currentUser = _supabaseService.getCurrentAuthUser();
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return null;
      }

      // Check if setting already exists
      final existingSetting = await _supabase
          .from('admin_settings')
          .select()
          .eq('setting_key', key)
          .maybeSingle();

      if (existingSetting != null) {
        // Update existing setting
        final response = await _supabase
            .from('admin_settings')
            .update({
              'setting_value': value,
              'description': description,
              'category': category,
              'is_public': isPublic,
              'updated_by': currentUser.id,
            })
            .eq('setting_key', key)
            .select()
            .single();

        final model = AdminSettingModel.fromJson(response);
        
        // Update cache
        _settingsCache[key] = model;
        
        return model;
      } else {
        // Create new setting
        final response = await _supabase
            .from('admin_settings')
            .insert({
              'setting_key': key,
              'setting_value': value,
              'description': description,
              'category': category,
              'is_public': isPublic,
              'created_by': currentUser.id,
              'updated_by': currentUser.id,
            })
            .select()
            .single();

        final model = AdminSettingModel.fromJson(response);
        
        // Update cache
        _settingsCache[key] = model;
        
        return model;
      }
    } catch (e) {
      debugPrint('Error saving setting: $e');
      return null;
    }
  }

  // Delete a setting
  Future<bool> deleteSetting(String key) async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can delete settings');
        return false;
      }

      // Delete setting
      await _supabase.from('admin_settings').delete().eq('setting_key', key);
      
      // Remove from cache
      _settingsCache.remove(key);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting setting: $e');
      return false;
    }
  }

  // Clear settings cache
  void clearCache() {
    _settingsCache.clear();
  }
  
  // Initialize default settings if they don't exist
  Future<void> initializeDefaultSettings() async {
    try {
      // First check if current user is admin
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (!isAdmin) {
        debugPrint('Only admins can initialize default settings');
        return;
      }
      
      // Get current user ID
      final currentUser = _supabaseService.getCurrentAuthUser();
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return;
      }
      
      // Get all existing settings
      final existingSettings = await getAllSettings();
      final existingKeys = existingSettings.map((s) => s.key).toSet();
      
      // Create default settings that don't exist
      for (var entry in _defaultSettings.entries) {
        if (!existingKeys.contains(entry.key)) {
          // Determine category based on key
          String category = SettingCategory.general;
          if (entry.key.startsWith('password') || entry.key.startsWith('session')) {
            category = SettingCategory.security;
          } else if (entry.key.endsWith('Notifications') || entry.key.contains('notification')) {
            category = SettingCategory.notification;
          } else if (entry.key.contains('Color') || entry.key.contains('Mode')) {
            category = SettingCategory.appearance;
          } else if (entry.key.startsWith('maintenance') || entry.key.startsWith('system') || entry.key.startsWith('allow')) {
            category = SettingCategory.system;
          } else if (entry.key.contains('currency') || entry.key.contains('payment') || entry.key.contains('tax')) {
            category = SettingCategory.payment;
          } else if (entry.key.endsWith('ApiKey')) {
            category = SettingCategory.integration;
          } else if (entry.key.startsWith('ai')) {
            category = SettingCategory.ai;
          }
          
          // Create setting
          await saveSetting(
            key: entry.key,
            value: entry.value,
            category: category,
            isPublic: category == SettingCategory.appearance,
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing default settings: $e');
    }
  }
}
