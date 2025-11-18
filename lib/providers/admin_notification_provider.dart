import 'package:flutter/foundation.dart';
import '../models/admin_notification.dart';
import '../services/supabase_service.dart';

class AdminNotificationProvider extends ChangeNotifier {
  List<AdminNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

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
  Future<void> loadNotifications() async {
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
      final notificationData = {
        'title': title ?? _getNotificationTitle(type, technicianName),
        'message': message ?? _getNotificationMessage(type, technicianName),
        'technician_name': technicianName,
        'technician_email': technicianEmail,
        'type': type.value,
        'is_read': false,
        'timestamp': DateTime.now().toIso8601String(),
        if (data != null) 'data': data,
      };

      final response = await SupabaseService.client
          .from('admin_notifications')
          .insert(notificationData)
          .select()
          .single();

      final notification = AdminNotification.fromJson(response);
      _notifications.insert(0, notification);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating notification: $e');
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

}
