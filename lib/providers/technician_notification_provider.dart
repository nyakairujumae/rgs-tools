import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/technician_notification.dart';
import '../services/supabase_service.dart';
import '../services/badge_service.dart';

class TechnicianNotificationProvider extends ChangeNotifier {
  List<TechnicianNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription? _realtimeSubscription;

  List<TechnicianNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  int get totalCount => _notifications.length;

  List<TechnicianNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  /// Load notifications from Supabase
  Future<void> loadNotifications({bool skipIfLoading = true}) async {
    // Prevent concurrent loads
    if (_isLoading && skipIfLoading) {
      debugPrint('⚠️ [TechnicianNotifications] Already loading, skipping duplicate call');
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

      final userId = session.user.id;

      // Load notifications from technician_notifications table
      final response = await SupabaseService.client
          .from('technician_notifications')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(100);

      _notifications = (response as List)
          .map((json) => TechnicianNotification.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
      
      // Sync badge with database after loading notifications
      try {
        final unreadCount = _notifications.where((n) => !n.isRead).length;
        final currentBadge = await BadgeService.getBadgeCount();
        if (unreadCount != currentBadge) {
          await BadgeService.updateBadge(unreadCount);
          debugPrint('✅ [TechnicianNotifications] Badge synced: $unreadCount unread');
        }
      } catch (e) {
        debugPrint('⚠️ [TechnicianNotifications] Error syncing badge: $e');
      }
      
      // Set up realtime subscription for real-time updates
      _setupRealtimeSubscription(userId);
    } catch (e) {
      debugPrint('Error loading technician notifications: $e');
      if (e.toString().contains('JWT expired') || e.toString().contains('PGRST303')) {
        _error = 'Session expired. Please log in again';
      } else if (e.toString().contains('PGRST204') || e.toString().contains('relation "technician_notifications" does not exist')) {
        _error = 'Notifications table not found. Please run the SQL script to create it.';
      } else {
        _error = 'Failed to load notifications: $e';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new notification
  void addNotification(TechnicianNotification notification) {
    _notifications.insert(0, notification); // Add to beginning
    notifyListeners();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('technician_notifications')
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
          debugPrint('✅ [TechnicianNotifications] Badge updated after marking as read: $unreadCount unread');
        } catch (e) {
          debugPrint('⚠️ [TechnicianNotifications] Error syncing badge: $e');
        }
      }
    } catch (e) {
      debugPrint('Error marking technician notification as read: $e');
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
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseService.client
          .from('technician_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
      
      // Sync badge with database after marking all as read
      try {
        await BadgeService.clearBadge();
        debugPrint('✅ [TechnicianNotifications] Badge cleared after marking all as read');
      } catch (e) {
        debugPrint('⚠️ [TechnicianNotifications] Error clearing badge: $e');
      }
    } catch (e) {
      debugPrint('Error marking all technician notifications as read: $e');
      // Still update locally even if API call fails
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    }
  }

  /// Remove a notification
  Future<void> removeNotification(String notificationId) async {
    try {
      await SupabaseService.client
          .from('technician_notifications')
          .delete()
          .eq('id', notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing technician notification: $e');
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

  /// Set up realtime subscription for real-time notification updates
  void _setupRealtimeSubscription(String userId) {
    // Clean up existing subscription
    _realtimeChannel?.unsubscribe();
    _realtimeSubscription?.cancel();
    
    try {
      debugPrint('📡 [TechnicianNotifications] Setting up realtime subscription for user: $userId');
      
      final channel = SupabaseService.client.channel('technician_notifications_realtime_$userId');
      
      // Listen for new notifications (INSERT) - only for this user
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'technician_notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) async {
          debugPrint('📡 [TechnicianNotifications] New notification received via realtime');
          try {
            final newNotification = TechnicianNotification.fromJson(payload.newRecord);
            _notifications.insert(0, newNotification);
            notifyListeners();
            
            // Update badge in real-time
            final unreadCount = _notifications.where((n) => !n.isRead).length;
            await BadgeService.updateBadge(unreadCount);
            debugPrint('✅ [TechnicianNotifications] Badge updated in real-time: $unreadCount unread');
          } catch (e) {
            debugPrint('⚠️ [TechnicianNotifications] Error processing new notification: $e');
            // Reload notifications if parsing fails
            loadNotifications(skipIfLoading: false);
          }
        },
      );
      
      // Listen for notification updates (UPDATE - when marked as read)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'technician_notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) async {
          debugPrint('📡 [TechnicianNotifications] Notification updated via realtime');
          try {
            final updatedNotification = TechnicianNotification.fromJson(payload.newRecord);
            final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
            if (index != -1) {
              _notifications[index] = updatedNotification;
              notifyListeners();
              
              // Update badge in real-time
              final unreadCount = _notifications.where((n) => !n.isRead).length;
              await BadgeService.updateBadge(unreadCount);
              debugPrint('✅ [TechnicianNotifications] Badge updated in real-time: $unreadCount unread');
            } else {
              // Notification not in local list, reload
              loadNotifications(skipIfLoading: false);
            }
          } catch (e) {
            debugPrint('⚠️ [TechnicianNotifications] Error processing notification update: $e');
            loadNotifications(skipIfLoading: false);
          }
        },
      );
      
      // Listen for notification deletions (DELETE)
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: 'technician_notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) async {
          debugPrint('📡 [TechnicianNotifications] Notification deleted via realtime');
          try {
            final deletedId = payload.oldRecord['id'] as String;
            _notifications.removeWhere((n) => n.id == deletedId);
            notifyListeners();
            
            // Update badge in real-time
            final unreadCount = _notifications.where((n) => !n.isRead).length;
            await BadgeService.updateBadge(unreadCount);
            debugPrint('✅ [TechnicianNotifications] Badge updated in real-time: $unreadCount unread');
          } catch (e) {
            debugPrint('⚠️ [TechnicianNotifications] Error processing notification deletion: $e');
            loadNotifications(skipIfLoading: false);
          }
        },
      );
      
      channel.subscribe();
      _realtimeChannel = channel;
      debugPrint('✅ [TechnicianNotifications] Realtime subscription active');
    } catch (e) {
      debugPrint('⚠️ [TechnicianNotifications] Error setting up realtime subscription: $e');
      debugPrint('⚠️ [TechnicianNotifications] Notifications will still work, but updates may be delayed');
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}




