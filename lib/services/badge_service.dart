import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';
import 'package:flutter/material.dart';

/// Service to manage app badge count synchronized with database notifications
class BadgeService {
  static const String _badgeCountKey = 'badge_count';
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  /// Get current badge count from SharedPreferences
  static Future<int> getBadgeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_badgeCountKey) ?? 0;
    } catch (e) {
      debugPrint('❌ [Badge] Error getting badge count: $e');
      return 0;
    }
  }

  /// Update badge count (increment by 1)
  static Future<void> incrementBadge() async {
    try {
      final currentCount = await getBadgeCount();
      await updateBadge(currentCount + 1);
      debugPrint('✅ [Badge] Incremented to: ${currentCount + 1}');
    } catch (e) {
      debugPrint('❌ [Badge] Error incrementing badge: $e');
    }
  }

  /// Update badge count to specific value
  static Future<void> updateBadge(int count) async {
    try {
      // Ensure count is non-negative
      final badgeCount = count < 0 ? 0 : count;
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_badgeCountKey, badgeCount);
      
      // Update app badge
      if (badgeCount > 0) {
        await FlutterAppBadger.updateBadgeCount(badgeCount);
      } else {
        await FlutterAppBadger.removeBadge();
      }
      
      // Note: Android notification badge is handled via notification payload (number field)
      // The FlutterAppBadger handles the app icon badge for both iOS and Android
      
      debugPrint('✅ [Badge] Updated to: $badgeCount');
    } catch (e) {
      debugPrint('❌ [Badge] Error updating badge: $e');
    }
  }

  /// Clear badge (set to 0)
  static Future<void> clearBadge() async {
    try {
      await updateBadge(0);
      debugPrint('✅ [Badge] Cleared');
    } catch (e) {
      debugPrint('❌ [Badge] Error clearing badge: $e');
    }
  }

  /// Sync badge count with database unread notifications
  /// This should be called on app start and when notifications are read
  static Future<void> syncBadgeWithDatabase(BuildContext? context) async {
    try {
      // Get unread count from database
      final unreadCount = await _getUnreadNotificationCount(context);
      
      // Update badge to match database count
      await updateBadge(unreadCount);
      
      debugPrint('✅ [Badge] Synced with database: $unreadCount unread notifications');
    } catch (e) {
      debugPrint('❌ [Badge] Error syncing with database: $e');
    }
  }

  /// Get unread notification count from database
  static Future<int> _getUnreadNotificationCount(BuildContext? context) async {
    try {
      final authUser = SupabaseService.client.auth.currentUser;
      if (authUser == null) {
        return 0;
      }

      int unreadCount = 0;

      // Get user role to determine which notifications to count
      String? userRole;
      String? userEmail;
      
      try {
        final userRecord = await SupabaseService.client
            .from('users')
            .select('role, email')
            .eq('id', authUser.id)
            .maybeSingle();
        
        if (userRecord != null) {
          userRole = userRecord['role'] as String?;
          userEmail = userRecord['email'] as String?;
        }
      } catch (e) {
        debugPrint('⚠️ [Badge] Could not fetch user role: $e');
      }

      // Count admin notifications (for admins)
      if (userRole == 'admin') {
        try {
          final adminNotifications = await SupabaseService.client
              .from('admin_notifications')
              .select('is_read')
              .eq('is_read', false)
              .limit(1000); // Reasonable limit
          
          unreadCount += (adminNotifications as List)
              .where((n) => (n['is_read'] as bool?) != true)
              .length;
        } catch (e) {
          debugPrint('⚠️ [Badge] Error counting admin notifications: $e');
        }
      }

      // Count technician notifications (for all users)
      try {
        final technicianNotifications = await SupabaseService.client
            .from('technician_notifications')
            .select('is_read')
            .eq('user_id', authUser.id)
            .eq('is_read', false)
            .limit(1000); // Reasonable limit
        
        unreadCount += (technicianNotifications as List)
            .where((n) => (n['is_read'] as bool?) != true)
            .length;
      } catch (e) {
        debugPrint('⚠️ [Badge] Error counting technician notifications: $e');
      }

      // Also count admin_notifications where technician_email matches (for technicians)
      if (userRole == 'technician' && userEmail != null) {
        try {
          final adminNotificationsForTech = await SupabaseService.client
              .from('admin_notifications')
              .select('is_read')
              .eq('technician_email', userEmail)
              .eq('is_read', false)
              .limit(1000);
          
          unreadCount += (adminNotificationsForTech as List)
              .where((n) => (n['is_read'] as bool?) != true)
              .length;
        } catch (e) {
          debugPrint('⚠️ [Badge] Error counting admin notifications for technician: $e');
        }
      }

      return unreadCount;
    } catch (e) {
      debugPrint('❌ [Badge] Error getting unread count: $e');
      return 0;
    }
  }

  /// Initialize badge on app start
  static Future<void> initializeBadge(BuildContext? context) async {
    try {
      // Sync with database to get accurate count
      await syncBadgeWithDatabase(context);
      debugPrint('✅ [Badge] Initialized');
    } catch (e) {
      debugPrint('❌ [Badge] Error initializing badge: $e');
    }
  }

  /// Refresh badge count (useful for manual refresh)
  static Future<void> refreshBadge(BuildContext? context) async {
    await syncBadgeWithDatabase(context);
  }
}

