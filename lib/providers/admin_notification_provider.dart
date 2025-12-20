import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/admin_notification.dart';
import '../services/supabase_service.dart';
import '../services/push_notification_service.dart';
import '../services/badge_service.dart';

class AdminNotificationProvider extends ChangeNotifier {
  List<AdminNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription? _realtimeSubscription;

  List<AdminNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get totalCount => _notifications.length;

  List<AdminNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  List<AdminNotification> getNotificationsByType(NotificationType type) =>
      _notifications.where((n) => n.type == type).toList();

  /// Load notifications from Supabase
  Future<void> loadNotifications({bool skipIfLoading = true}) async {
    // Prevent concurrent loads
    if (_isLoading && skipIfLoading) {
      debugPrint('⚠️ [AdminNotifications] Already loading, skipping duplicate call');
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if user is authenticated
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        _error = 'Please log in to view notifications';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Load notifications from Supabase
      final response = await SupabaseService.client
          .from('admin_notifications')
          .select()
          .order('timestamp', ascending: false)
          .limit(100);

      _notifications = (response as List)
          .map((json) => AdminNotification.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
      
      // Sync badge with database after loading notifications
      // Use the unreadCount from the loaded notifications
      // Only update if count changed to prevent unnecessary updates
      try {
        final unreadCount = _notifications.where((n) => !n.isRead).length;
        final currentBadge = await BadgeService.getBadgeCount();
        if (unreadCount != currentBadge) {
          await BadgeService.updateBadge(unreadCount);
          debugPrint('✅ [AdminNotifications] Badge synced: $unreadCount unread');
        }
      } catch (e) {
        debugPrint('⚠️ [AdminNotifications] Error syncing badge: $e');
      }
      
      // Set up realtime subscription for real-time updates
      _setupRealtimeSubscription();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (e.toString().contains('JWT expired') || e.toString().contains('PGRST303')) {
        _error = 'Session expired. Please log in again';
      } else if (e.toString().contains('PGRST204') || e.toString().contains('relation "admin_notifications" does not exist')) {
        _error = 'Notifications table not found. Please run the SQL script to create it.';
      } else {
        _error = 'Failed to load notifications: $e';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new notification
  void addNotification(AdminNotification notification) {
    _notifications.insert(0, notification); // Add to beginning
    notifyListeners();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
        
        // Sync badge with database after marking as read
        try {
          final unreadCount = _notifications.where((n) => !n.isRead).length;
          await BadgeService.updateBadge(unreadCount);
          debugPrint('✅ [AdminNotifications] Badge updated after marking as read: $unreadCount unread');
        } catch (e) {
          debugPrint('⚠️ [AdminNotifications] Error syncing badge: $e');
        }
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      // Still update locally even if API call fails
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await SupabaseService.client
          .from('admin_notifications')
          .update({'is_read': true})
          .eq('is_read', false);

      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
      
      // Sync badge with database after marking all as read
      try {
        await BadgeService.clearBadge();
        debugPrint('✅ [AdminNotifications] Badge cleared after marking all as read');
      } catch (e) {
        debugPrint('⚠️ [AdminNotifications] Error clearing badge: $e');
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      // Still update locally even if API call fails
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    }
  }

  /// Remove a notification
  Future<void> removeNotification(String notificationId) async {
    try {
      await SupabaseService.client
          .from('admin_notifications')
          .delete()
          .eq('id', notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing notification: $e');
      // Still remove locally even if API call fails
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    }
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Create a notification (saves to Supabase)
  Future<void> createNotification({
    required String technicianName,
    required String technicianEmail,
    required NotificationType type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Use function to bypass RLS
      final result = await SupabaseService.client.rpc(
        'create_admin_notification',
        params: {
          'p_title': title ?? _getNotificationTitle(type, technicianName),
          'p_message': message ?? _getNotificationMessage(type, technicianName),
          'p_technician_name': technicianName,
          'p_technician_email': technicianEmail,
          'p_type': type.value,
          if (data != null) 'p_data': data,
        },
      );

      if (result == null) {
        throw Exception('Function returned null - notification was not created');
      }

      final notificationId = result.toString();
      debugPrint('✅ Notification created with ID: $notificationId');
      // Note: Approval workflows are now automatically created by the database function
      // when tool_request notifications are created - no client-side code needed!

      // Send push notification to admins (non-blocking)
      debugPrint('📤 [Push] Attempting to send push notification to admins...');
      PushNotificationService.sendToAdmins(
        title: title ?? _getNotificationTitle(type, technicianName),
        body: message ?? _getNotificationMessage(type, technicianName),
        data: {
          'type': type.value,
          'notification_id': notificationId,
          if (data != null) ...data,
        },
      ).then((count) {
        debugPrint('✅ [Push] Push notification sent to $count admin(s)');
        if (count == 0) {
          debugPrint('⚠️ [Push] WARNING: No admins received the notification!');
          debugPrint('⚠️ [Push] This might mean:');
          debugPrint('⚠️ [Push] 1. No admin users found in database');
          debugPrint('⚠️ [Push] 2. Admin users have no FCM tokens');
          debugPrint('⚠️ [Push] 3. RLS policies blocking token queries');
        }
      }).catchError((e, stackTrace) {
        debugPrint('❌ [Push] ERROR sending push notification: $e');
        debugPrint('❌ [Push] Stack trace: $stackTrace');
      });

      // Create notification object from the data we already have
      // (We can't fetch it because technicians don't have SELECT permission on admin_notifications)
      final notification = AdminNotification(
        id: notificationId,
        title: title ?? _getNotificationTitle(type, technicianName),
        message: message ?? _getNotificationMessage(type, technicianName),
        technicianName: technicianName,
        technicianEmail: technicianEmail,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        data: data,
      );

      // Only add to local list if user is admin (technicians don't need to see admin notifications)
      // The notification is successfully created in the database, which is what matters
      try {
        final currentUser = SupabaseService.client.auth.currentUser;
        if (currentUser != null) {
          // Try to check if user is admin - if we can't check, just skip adding to list
          final userRecord = await SupabaseService.client
              .from('users')
              .select('role')
              .eq('id', currentUser.id)
              .maybeSingle();
          
          if (userRecord != null && userRecord['role'] == 'admin') {
            _notifications.insert(0, notification);
            notifyListeners();
          }
        }
      } catch (e) {
        // If we can't check role or add to list, that's okay
        // The notification was successfully created in the database
        debugPrint('Note: Could not add notification to local list (user may not be admin): $e');
      }
    } catch (e) {
      debugPrint('❌ Error creating notification: $e');
      if (e.toString().contains('Could not find the function')) {
        throw Exception('Database function not found. Please run FINAL_WORKING_FIX.sql in Supabase SQL Editor.');
      }
      rethrow;
    }
  }

  /// Create a mock notification for testing (legacy method, now uses createNotification)
  Future<void> createMockNotification({
    required String technicianName,
    required String technicianEmail,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    // Use the new createNotification method
    await createNotification(
      technicianName: technicianName,
      technicianEmail: technicianEmail,
      type: type,
      data: data,
    );
  }

  String _getNotificationTitle(NotificationType type, String technicianName) {
    switch (type) {
      case NotificationType.accessRequest:
        return 'Access Request';
      case NotificationType.toolRequest:
        return 'Tool Request';
      case NotificationType.maintenanceRequest:
        return 'Maintenance Request';
      case NotificationType.issueReport:
        return 'Issue Report';
      case NotificationType.userApproved:
        return 'User Approved';
      case NotificationType.general:
        return 'General Notification';
    }
  }

  String _getNotificationMessage(NotificationType type, String technicianName) {
    switch (type) {
      case NotificationType.accessRequest:
        return 'Technician $technicianName needs to access the RGS app';
      case NotificationType.toolRequest:
        return 'Technician $technicianName requested a tool';
      case NotificationType.maintenanceRequest:
        return 'Technician $technicianName requested maintenance for a tool';
      case NotificationType.issueReport:
        return 'Technician $technicianName reported an issue';
      case NotificationType.userApproved:
        return 'User $technicianName has been approved and can now access the app';
      case NotificationType.general:
        return 'New notification from $technicianName';
    }
  }

  /// Set up realtime subscription for real-time notification updates
  void _setupRealtimeSubscription() {
    // Clean up existing subscription
    _realtimeChannel?.unsubscribe();
    _realtimeSubscription?.cancel();
    
    try {
      debugPrint('📡 [AdminNotifications] Setting up realtime subscription...');
      
      final channel = SupabaseService.client.channel('admin_notifications_realtime');
      
      // Listen for new notifications (INSERT)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'admin_notifications',
        callback: (payload) async {
          debugPrint('📡 [AdminNotifications] New notification received via realtime');
          try {
            final newNotification = AdminNotification.fromJson(payload.newRecord);
            _notifications.insert(0, newNotification);
            notifyListeners();
            
            // Update badge in real-time
            final unreadCount = _notifications.where((n) => !n.isRead).length;
            await BadgeService.updateBadge(unreadCount);
            debugPrint('✅ [AdminNotifications] Badge updated in real-time: $unreadCount unread');
          } catch (e) {
            debugPrint('⚠️ [AdminNotifications] Error processing new notification: $e');
            // Reload notifications if parsing fails
            loadNotifications(skipIfLoading: false);
          }
        },
      );
      
      // Listen for notification updates (UPDATE - when marked as read)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'admin_notifications',
        callback: (payload) async {
          debugPrint('📡 [AdminNotifications] Notification updated via realtime');
          try {
            final updatedNotification = AdminNotification.fromJson(payload.newRecord);
            final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
            if (index != -1) {
              _notifications[index] = updatedNotification;
              notifyListeners();
              
              // Update badge in real-time
              final unreadCount = _notifications.where((n) => !n.isRead).length;
              await BadgeService.updateBadge(unreadCount);
              debugPrint('✅ [AdminNotifications] Badge updated in real-time: $unreadCount unread');
            } else {
              // Notification not in local list, reload
              loadNotifications(skipIfLoading: false);
            }
          } catch (e) {
            debugPrint('⚠️ [AdminNotifications] Error processing notification update: $e');
            loadNotifications(skipIfLoading: false);
          }
        },
      );
      
      // Listen for notification deletions (DELETE)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'admin_notifications',
        callback: (payload) async {
          debugPrint('📡 [AdminNotifications] Notification deleted via realtime');
          try {
            final deletedId = payload.oldRecord['id'] as String;
            _notifications.removeWhere((n) => n.id == deletedId);
            notifyListeners();
            
            // Update badge in real-time
            final unreadCount = _notifications.where((n) => !n.isRead).length;
            await BadgeService.updateBadge(unreadCount);
            debugPrint('✅ [AdminNotifications] Badge updated in real-time: $unreadCount unread');
          } catch (e) {
            debugPrint('⚠️ [AdminNotifications] Error processing notification deletion: $e');
            loadNotifications(skipIfLoading: false);
          }
        },
      );
      
      channel.subscribe();
      _realtimeChannel = channel;
      debugPrint('✅ [AdminNotifications] Realtime subscription active');
    } catch (e) {
      debugPrint('⚠️ [AdminNotifications] Error setting up realtime subscription: $e');
      debugPrint('⚠️ [AdminNotifications] Notifications will still work, but updates may be delayed');
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

}
