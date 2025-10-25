import 'package:flutter/foundation.dart';

/// Application configuration management
/// Handles environment-specific settings and feature flags
class AppConfig {
  static const String _defaultEnvironment = 'development';
  
  // Environment detection
  static String get environment {
    if (kDebugMode) {
      return 'development';
    } else if (kProfileMode) {
      return 'staging';
    } else {
      return 'production';
    }
  }
  
  // Database configuration
  static String get databaseName {
    switch (environment) {
      case 'development':
        return 'rgs_tools_dev.db';
      case 'staging':
        return 'rgs_tools_staging.db';
      case 'production':
        return 'rgs_tools_prod.db';
      default:
        return 'rgs_tools.db';
    }
  }
  
  static int get databaseVersion => 1;
  
  // API configuration
  static String get baseUrl {
    switch (environment) {
      case 'development':
        return 'http://localhost:3000/api';
      case 'staging':
        return 'https://api-staging.rgstools.com';
      case 'production':
        return 'https://api.rgstools.com';
      default:
        return 'http://localhost:3000/api';
    }
  }
  
  // Feature flags
  static bool get enableBarcodeScanning => true;
  static bool get enableImageCapture => true;
  static bool get enableOfflineMode => true;
  static bool get enablePushNotifications => environment != 'development';
  static bool get enableAnalytics => environment == 'production';
  static bool get enableCrashReporting => environment == 'production';
  
  // UI configuration
  static bool get enableAnimations => true;
  static Duration get animationDuration => const Duration(milliseconds: 300);
  static int get maxImageSize => 5 * 1024 * 1024; // 5MB
  static List<String> get supportedImageFormats => ['jpg', 'jpeg', 'png', 'webp'];
  
  // Business rules
  static int get maxToolsPerTechnician => 10;
  static Duration get maintenanceReminderDays => const Duration(days: 30);
  static Duration get toolCheckoutMaxDuration => const Duration(days: 30);
  static double get toolDepreciationRate => 0.1; // 10% per year
  
  // Logging configuration
  static bool get enableDebugLogging => environment == 'development';
  static bool get enableInfoLogging => environment != 'production';
  static bool get enableWarningLogging => true;
  static bool get enableErrorLogging => true;
  
  // Security configuration
  static bool get enableBiometricAuth => environment != 'development';
  static Duration get sessionTimeout => const Duration(hours: 8);
  static int get maxLoginAttempts => 5;
  
  // Performance configuration
  static int get maxCacheSize => 100; // MB
  static Duration get cacheExpiration => const Duration(hours: 24);
  static int get maxConcurrentRequests => 5;
  
  // Validation rules
  static int get minPasswordLength => 8;
  static int get maxNameLength => 100;
  static int get maxDescriptionLength => 500;
  static RegExp get emailRegex => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static RegExp get phoneRegex => RegExp(r'^\+?[\d\s\-\(\)]+$');
  
  // Allow all email domains - no restrictions
  static List<String> get allowedEmailDomains => [];
  
  // Check if email domain is allowed - always return true for any domain
  static bool isEmailDomainAllowed(String email) {
    // Allow any email domain - no restrictions
    return true;
  }
  
  // Export configuration
  static List<String> get supportedExportFormats => ['csv', 'pdf', 'excel'];
  static int get maxExportRecords => 10000;
  
  // Backup configuration
  static bool get enableAutoBackup => environment == 'production';
  static Duration get backupInterval => const Duration(days: 7);
  static int get maxBackupFiles => 10;
  
  /// Get configuration value by key
  static T getValue<T>(String key, T defaultValue) {
    switch (key) {
      case 'environment':
        return environment as T;
      case 'databaseName':
        return databaseName as T;
      case 'baseUrl':
        return baseUrl as T;
      case 'enableBarcodeScanning':
        return enableBarcodeScanning as T;
      case 'enableImageCapture':
        return enableImageCapture as T;
      case 'enableOfflineMode':
        return enableOfflineMode as T;
      case 'enablePushNotifications':
        return enablePushNotifications as T;
      case 'enableAnalytics':
        return enableAnalytics as T;
      case 'enableCrashReporting':
        return enableCrashReporting as T;
      case 'enableAnimations':
        return enableAnimations as T;
      case 'animationDuration':
        return animationDuration as T;
      case 'maxImageSize':
        return maxImageSize as T;
      case 'supportedImageFormats':
        return supportedImageFormats as T;
      case 'maxToolsPerTechnician':
        return maxToolsPerTechnician as T;
      case 'maintenanceReminderDays':
        return maintenanceReminderDays as T;
      case 'toolCheckoutMaxDuration':
        return toolCheckoutMaxDuration as T;
      case 'toolDepreciationRate':
        return toolDepreciationRate as T;
      case 'enableDebugLogging':
        return enableDebugLogging as T;
      case 'enableInfoLogging':
        return enableInfoLogging as T;
      case 'enableWarningLogging':
        return enableWarningLogging as T;
      case 'enableErrorLogging':
        return enableErrorLogging as T;
      case 'enableBiometricAuth':
        return enableBiometricAuth as T;
      case 'sessionTimeout':
        return sessionTimeout as T;
      case 'maxLoginAttempts':
        return maxLoginAttempts as T;
      case 'maxCacheSize':
        return maxCacheSize as T;
      case 'cacheExpiration':
        return cacheExpiration as T;
      case 'maxConcurrentRequests':
        return maxConcurrentRequests as T;
      case 'minPasswordLength':
        return minPasswordLength as T;
      case 'maxNameLength':
        return maxNameLength as T;
      case 'maxDescriptionLength':
        return maxDescriptionLength as T;
      case 'emailRegex':
        return emailRegex as T;
      case 'phoneRegex':
        return phoneRegex as T;
      case 'supportedExportFormats':
        return supportedExportFormats as T;
      case 'maxExportRecords':
        return maxExportRecords as T;
      case 'enableAutoBackup':
        return enableAutoBackup as T;
      case 'backupInterval':
        return backupInterval as T;
      case 'maxBackupFiles':
        return maxBackupFiles as T;
      default:
        return defaultValue;
    }
  }
  
  /// Check if feature is enabled
  static bool isFeatureEnabled(String feature) {
    switch (feature) {
      case 'barcode_scanning':
        return enableBarcodeScanning;
      case 'image_capture':
        return enableImageCapture;
      case 'offline_mode':
        return enableOfflineMode;
      case 'push_notifications':
        return enablePushNotifications;
      case 'analytics':
        return enableAnalytics;
      case 'crash_reporting':
        return enableCrashReporting;
      case 'biometric_auth':
        return enableBiometricAuth;
      case 'auto_backup':
        return enableAutoBackup;
      default:
        return false;
    }
  }
  
  /// Get environment-specific configuration
  static Map<String, dynamic> getEnvironmentConfig() {
    return {
      'environment': environment,
      'databaseName': databaseName,
      'baseUrl': baseUrl,
      'enableDebugLogging': enableDebugLogging,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
    };
  }
}

