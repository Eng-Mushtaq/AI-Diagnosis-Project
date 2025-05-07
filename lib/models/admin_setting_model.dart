import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Model class for admin settings
class AdminSettingModel {
  final String id;
  final String key;
  final dynamic value;
  final String? description;
  final String category;
  final bool isPublic;
  final String? createdBy;
  final DateTime createdAt;
  final String? updatedBy;
  final DateTime updatedAt;

  AdminSettingModel({
    required this.id,
    required this.key,
    required this.value,
    this.description,
    required this.category,
    required this.isPublic,
    this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
  });

  /// Create model from JSON
  factory AdminSettingModel.fromJson(Map<String, dynamic> json) {
    try {
      dynamic settingValue;
      if (json['setting_value'] is String) {
        try {
          // Try to parse as JSON if it's a string
          settingValue = jsonDecode(json['setting_value']);
        } catch (e) {
          // If not valid JSON, use as is
          settingValue = json['setting_value'];
        }
      } else {
        // Use as is if not a string
        settingValue = json['setting_value'];
      }

      return AdminSettingModel(
        id: json['id'],
        key: json['setting_key'],
        value: settingValue,
        description: json['description'],
        category: json['category'],
        isPublic: json['is_public'] ?? false,
        createdBy: json['created_by'],
        createdAt: DateTime.parse(json['created_at']),
        updatedBy: json['updated_by'],
        updatedAt: DateTime.parse(json['updated_at']),
      );
    } catch (e) {
      debugPrint('Error parsing AdminSettingModel: $e');
      rethrow;
    }
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setting_key': key,
      'setting_value': value is String || value is num || value is bool
          ? value
          : jsonEncode(value),
      'description': description,
      'category': category,
      'is_public': isPublic,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of the model with updated fields
  AdminSettingModel copyWith({
    String? id,
    String? key,
    dynamic value,
    String? description,
    String? category,
    bool? isPublic,
    String? createdBy,
    DateTime? createdAt,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return AdminSettingModel(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Predefined setting categories
class SettingCategory {
  static const String general = 'general';
  static const String security = 'security';
  static const String notification = 'notification';
  static const String appearance = 'appearance';
  static const String system = 'system';
  static const String payment = 'payment';
  static const String integration = 'integration';
  static const String ai = 'ai';
  
  static List<String> get all => [
    general,
    security,
    notification,
    appearance,
    system,
    payment,
    integration,
    ai,
  ];
}

/// Predefined setting keys
class SettingKey {
  // General settings
  static const String appName = 'app_name';
  static const String appLogo = 'app_logo';
  static const String appDescription = 'app_description';
  static const String contactEmail = 'contact_email';
  static const String contactPhone = 'contact_phone';
  static const String supportEmail = 'support_email';
  
  // Security settings
  static const String passwordMinLength = 'password_min_length';
  static const String passwordRequireSpecialChar = 'password_require_special_char';
  static const String passwordRequireNumber = 'password_require_number';
  static const String passwordRequireUppercase = 'password_require_uppercase';
  static const String sessionTimeout = 'session_timeout';
  
  // Notification settings
  static const String emailNotificationsEnabled = 'email_notifications_enabled';
  static const String pushNotificationsEnabled = 'push_notifications_enabled';
  static const String smsNotificationsEnabled = 'sms_notifications_enabled';
  
  // Appearance settings
  static const String primaryColor = 'primary_color';
  static const String secondaryColor = 'secondary_color';
  static const String darkModeEnabled = 'dark_mode_enabled';
  
  // System settings
  static const String maintenanceMode = 'maintenance_mode';
  static const String maintenanceMessage = 'maintenance_message';
  static const String systemVersion = 'system_version';
  static const String allowRegistration = 'allow_registration';
  static const String allowDoctorRegistration = 'allow_doctor_registration';
  
  // Payment settings
  static const String currencyCode = 'currency_code';
  static const String paymentGateway = 'payment_gateway';
  static const String taxRate = 'tax_rate';
  
  // Integration settings
  static const String googleApiKey = 'google_api_key';
  static const String geminiApiKey = 'gemini_api_key';
  static const String deepSeekApiKey = 'deepseek_api_key';
  static const String rapidApiKey = 'rapid_api_key';
  
  // AI settings
  static const String aiDiagnosisEnabled = 'ai_diagnosis_enabled';
  static const String aiProvider = 'ai_provider';
  static const String aiConfidenceThreshold = 'ai_confidence_threshold';
  static const String aiMaxResults = 'ai_max_results';
}
