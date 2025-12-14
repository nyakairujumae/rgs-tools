import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to track if this is the first launch of the app
class FirstLaunchService {
  static const String _firstLaunchKey = 'has_completed_first_launch';

  /// Check if this is the first launch (before first login)
  /// Returns true if the user has never completed the splash screen
  static Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      return !(prefs.getBool(_firstLaunchKey) ?? false);
    } catch (e) {
      // If we can't check, assume it's not first launch to avoid blocking
      print('⚠️ Error checking first launch status: $e');
      return false;
    }
  }

  /// Mark that the first launch has been completed
  /// This should be called after the splash screen is shown and user proceeds
  static Future<void> markFirstLaunchComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      await prefs.setBool(_firstLaunchKey, true);
      print('✅ First launch marked as complete');
    } catch (e) {
      print('⚠️ Error marking first launch complete: $e');
      // Don't throw - this is not critical
    }
  }

  /// Reset first launch status (useful for testing)
  static Future<void> resetFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('SharedPreferences timeout');
        },
      );
      await prefs.remove(_firstLaunchKey);
      print('✅ First launch status reset');
    } catch (e) {
      print('⚠️ Error resetting first launch status: $e');
    }
  }
}

