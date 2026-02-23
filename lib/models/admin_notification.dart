class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String technicianName;
  final String technicianEmail;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.technicianName,
    required this.technicianEmail,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      technicianName: json['technician_name'] ?? '',
      technicianEmail: json['technician_email'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'access_request'),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'technician_name': technicianName,
      'technician_email': technicianEmail,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'data': data,
    };
  }

  AdminNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? technicianName,
    String? technicianEmail,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AdminNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      technicianName: technicianName ?? this.technicianName,
      technicianEmail: technicianEmail ?? this.technicianEmail,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

enum NotificationType {
  accessRequest('access_request', 'Access Request'),
  toolRequest('tool_request', 'Tool Request'),
  toolAssignment('tool_assignment', 'Tool Assignment'),
  maintenanceRequest('maintenance_request', 'Maintenance Request'),
  issueReport('issue_report', 'Issue Report'),
  userApproved('user_approved', 'User Approved'),
  general('general', 'General');

  const NotificationType(this.value, this.displayName);
  
  final String value;
  final String displayName;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'access_request':
        return NotificationType.accessRequest;
      case 'tool_request':
        return NotificationType.toolRequest;
      case 'tool_assignment':
      case 'tool_assigned':
        return NotificationType.toolAssignment;
      case 'maintenance_request':
        return NotificationType.maintenanceRequest;
      case 'issue_report':
        return NotificationType.issueReport;
      case 'user_approved':
        return NotificationType.userApproved;
      case 'general':
        return NotificationType.general;
      default:
        return NotificationType.general;
    }
  }

  @override
  String toString() => value;
}
