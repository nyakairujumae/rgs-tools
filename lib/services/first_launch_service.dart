import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Service to track if splash screen has been shown
/// Uses a single persistent boolean flag in local storage
/// Flag is saved immediately when splash is first shown
class FirstLaunchService {
  static const String _splashShownKey = 'splash_screen_shown';
  static bool? _cachedValue;

  /// Check if splash screen has been shown before
  /// Returns false if splash has been shown (should NOT show again)
  /// Returns true if splash has NOT been shown (should show on first install)
  static Future<bool> isFirstLaunch() async {
    // Return cached value if available (synchronous check)
    if (_cachedValue != null) {
      return _cachedValue!;
    }

    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          Logger.debug('⚠️ SharedPreferences timeout, assuming splash was shown');
          return SharedPreferences.getInstance();
        },
      );
      
      final splashShown = prefs.getBool(_splashShownKey) ?? false;
      _cachedValue = !splashShown; // Cache the inverse (isFirstLaunch)
      
      Logger.debug('🔍 Splash screen check: ${splashShown ? "ALREADY SHOWN" : "NOT SHOWN YET"}');
      return !splashShown;
    } catch (e) {
      // If we can't check, assume splash was shown (don't show again)
      Logger.debug('⚠️ Error checking splash status: $e - assuming splash was shown');
      _cachedValue = false;
      return false;
    }
  }

  /// Mark that the splash screen has been shown
  /// This should be called IMMEDIATELY when splash is first shown
  /// This flag persists forever - splash will never show again
  static Future<void> markSplashShown() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          Logger.debug('⚠️ SharedPreferences timeout while saving splash flag');
          return SharedPreferences.getInstance();
        },
      );
      
      await prefs.setBool(_splashShownKey, true);
      _cachedValue = false; // Update cache
      
      Logger.debug('✅ Splash screen flag saved - will NEVER show again');
    } catch (e) {
      Logger.debug('⚠️ Error saving splash flag: $e');
      // Still update cache even if save fails
      _cachedValue = false;
    }
  }

  /// Reset splash flag (useful for testing only)
  static Future<void> resetSplashFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      await prefs.remove(_splashShownKey);
      _cachedValue = null; // Clear cache
      Logger.debug('✅ Splash flag reset (testing only)');
    } catch (e) {
      Logger.debug('⚠️ Error resetting splash flag: $e');
    }
  }
}

