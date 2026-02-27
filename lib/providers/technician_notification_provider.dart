import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../models/technician_notification.dart';
import '../services/supabase_service.dart';
import '../services/badge_service.dart';
import '../utils/logger.dart';

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
      Logger.debug('⚠️ [TechnicianNotifications] Already loading, skipping duplicate call');
      return;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    final isOnline = _connectivity.isOnline;

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

      if (isOnline) {
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

        // Cache for offline use
        await _cache.cacheTechnicianNotifications(userId, _notifications);

        // Sync badge with database after loading notifications
        try {
          final unreadCount = _notifications.where((n) => !n.isRead).length;
          final currentBadge = await BadgeService.getBadgeCount();
          if (unreadCount != currentBadge) {
            await BadgeService.updateBadge(unreadCount);
            Logger.debug(
                '✅ [TechnicianNotifications] Badge synced: $unreadCount unread');
          }
        } catch (e) {
          Logger.debug('⚠️ [TechnicianNotifications] Error syncing badge: $e');
        }

        // Set up realtime subscription for real-time updates
        _setupRealtimeSubscription(userId);
      } else {
        Logger.debug(
            '📡 [TechnicianNotifications] Offline – loading notifications from cache');
        _notifications =
            await _cache.getCachedTechnicianNotifications(userId);
        if (_notifications.isEmpty) {
          _error =
              'You are offline and no notifications are cached yet. Connect once to sync them.';
        }
      }
    } catch (e) {
      Logger.debug('Error loading technician notifications: $e');
      if (e.toString().contains('JWT expired') ||
          e.toString().contains('PGRST303')) {
        _error = 'Session expired. Please log in again';
      } else if (e.toString().contains('PGRST204') ||
          e
              .toString()
              .contains('relation "technician_notifications" does not exist')) {
        _error =
            'Notifications table not found. Please run the SQL script to create it.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('network')) {
        final session = SupabaseService.client.auth.currentSession;
        final userId = session?.user.id;
        if (userId != null) {
          final cached =
              await _cache.getCachedTechnicianNotifications(userId);
          if (cached.isNotEmpty) {
            _notifications = cached;
            _error = null;
          } else {
            _error =
                'Cannot reach the server. You are offline and no notifications are cached yet.';
          }
        } else {
          _error =
              'Cannot reach the server. You are offline and no notifications are cached yet.';
        }
      } else {
        _error = 'Failed to load notifications. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new notification to local state
  void addNotification(TechnicianNotification notification) {
    _notifications.insert(0, notification); // Add to beginning
    notifyListeners();
  }

  /// Send a tool assignment notification to a technician
  Future<void> sendToolAssignmentNotification({
    required String technicianUserId,
    required String toolId,
    required String toolName,
    required String assignedByName,
    required String assignmentType,
  }) async {
    try {
      await SupabaseService.client.from('technician_notifications').insert({
        'user_id': technicianUserId,
        'title': 'Tool Assigned to You',
        'message': '$assignedByName assigned "$toolName" to you. Please accept or decline.',
        'type': 'tool_assigned',
        'is_read': false,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'tool_id': toolId,
          'tool_name': toolName,
          'assigned_by_name': assignedByName,
          'assignment_type': assignmentType,
        },
      });
      Logger.debug('✅ [TechnicianNotifications] Tool assignment notification sent to $technicianUserId');
    } catch (e) {
      Logger.debug('❌ [TechnicianNotifications] Error sending assignment notification: $e');
      rethrow;
    }
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
          Logger.debug('✅ [TechnicianNotifications] Badge updated after marking as read: $unreadCount unread');
        } catch (e) {
          Logger.debug('⚠️ [TechnicianNotifications] Error syncing badge: $e');
        }
      }
    } catch (e) {
      Logger.debug('Error marking technician notification as read: $e');
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
        Logger.debug('✅ [TechnicianNotifications] Badge cleared after marking all as read');
      } catch (e) {
        Logger.debug('⚠️ [TechnicianNotifications] Error clearing badge: $e');
      }
    } catch (e) {
      Logger.debug('Error marking all technician notifications as read: $e');
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
      Logger.debug('Error removing technician notification: $e');
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
      Logger.debug('📡 [TechnicianNotifications] Setting up realtime subscription for user: $userId');
      
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
          Logger.debug('📡 [TechnicianNotifications] New notification received via realtime');
          try {
            final newNotification = TechnicianNotification.fromJson(payload.newRecord);
            _notifications.insert(0, newNotification);
            notifyListeners();
            
            // Update badge in real-time
            final unreadCount = _notifications.where((n) => !n.isRead).length;
            await BadgeService.updateBadge(unreadCount);
            Logger.debug('✅ [TechnicianNotifications] Badge updated in real-time: $unreadCount unread');
          } catch (e) {
            Logger.debug('⚠️ [TechnicianNotifications] Error processing new notification: $e');
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
          Logger.debug('📡 [TechnicianNotifications] Notification updated via realtime');
          try {
            final updatedNotification = TechnicianNotification.fromJson(payload.newRecord);
            final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
            if (index != -1) {
              _notifications[index] = updatedNotification;
              notifyListeners();
              
              // Update badge in real-time
              final unreadCount = _notifications.where((n) => !n.isRead).length;
              await BadgeService.updateBadge(unreadCount);
              Logger.debug('✅ [TechnicianNotifications] Badge updated in real-time: $unreadCount unread');
            } else {
              // Notification not in local list, reload
              loadNotifications(skipIfLoading: false);
            }
          } catch (e) {
            Logger.debug('⚠️ [TechnicianNotifications] Error processing notification update: $e');
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
          Logger.debug('📡 [TechnicianNotifications] Notification deleted via realtime');
          try {
            final deletedId = payload.oldRecord['id'] as String;
            _notifications.removeWhere((n) => n.id == deletedId);
            notifyListeners();
            
            // Update badge in real-time
            final unreadCount = _notifications.where((n) => !n.isRead).length;
            await BadgeService.updateBadge(unreadCount);
            Logger.debug('✅ [TechnicianNotifications] Badge updated in real-time: $unreadCount unread');
          } catch (e) {
            Logger.debug('⚠️ [TechnicianNotifications] Error processing notification deletion: $e');
            loadNotifications(skipIfLoading: false);
          }
        },
      );
      
      channel.subscribe();
      _realtimeChannel = channel;
      Logger.debug('✅ [TechnicianNotifications] Realtime subscription active');
    } catch (e) {
      Logger.debug('⚠️ [TechnicianNotifications] Error setting up realtime subscription: $e');
      Logger.debug('⚠️ [TechnicianNotifications] Notifications will still work, but updates may be delayed');
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}




