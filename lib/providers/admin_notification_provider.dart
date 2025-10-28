import 'package:flutter/foundation.dart';
import '../models/admin_notification.dart';

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

  /// Load notifications from local storage or API
  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For now, we'll use mock data. Later this can be replaced with API calls
      await Future.delayed(Duration(milliseconds: 500)); // Simulate API delay
      
      _notifications = _getMockNotifications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
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
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Remove a notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Create a mock notification for testing
  void createMockNotification({
    required String technicianName,
    required String technicianEmail,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) {
    final notification = AdminNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _getNotificationTitle(type, technicianName),
      message: _getNotificationMessage(type, technicianName),
      technicianName: technicianName,
      technicianEmail: technicianEmail,
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    addNotification(notification);
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
      case NotificationType.general:
        return 'New notification from $technicianName';
    }
  }

  /// Mock data for testing
  List<AdminNotification> _getMockNotifications() {
    return [
      AdminNotification(
        id: '1',
        title: 'Access Request',
        message: 'Technician John Smith needs to access the RGS app',
        technicianName: 'John Smith',
        technicianEmail: 'john.smith@company.com',
        type: NotificationType.accessRequest,
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        isRead: false,
      ),
      AdminNotification(
        id: '2',
        title: 'Tool Request',
        message: 'Technician Mike Johnson requested a tool',
        technicianName: 'Mike Johnson',
        technicianEmail: 'mike.johnson@company.com',
        type: NotificationType.toolRequest,
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
        isRead: false,
      ),
      AdminNotification(
        id: '3',
        title: 'Issue Report',
        message: 'Technician Sarah Wilson reported an issue',
        technicianName: 'Sarah Wilson',
        technicianEmail: 'sarah.wilson@company.com',
        type: NotificationType.issueReport,
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        isRead: true,
      ),
      AdminNotification(
        id: '4',
        title: 'Maintenance Request',
        message: 'Technician David Brown requested maintenance for a tool',
        technicianName: 'David Brown',
        technicianEmail: 'david.brown@company.com',
        type: NotificationType.maintenanceRequest,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        isRead: true,
      ),
      AdminNotification(
        id: '5',
        title: 'Access Request',
        message: 'Technician Lisa Davis needs to access the RGS app',
        technicianName: 'Lisa Davis',
        technicianEmail: 'lisa.davis@company.com',
        type: NotificationType.accessRequest,
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
        isRead: true,
      ),
    ];
  }
}
