import 'admin_notification.dart';

class TechnicianNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  TechnicianNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory TechnicianNotification.fromJson(Map<String, dynamic> json) {
    return TechnicianNotification(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'general'),
      timestamp: _parseTimestamp(json['timestamp']),
      isRead: json['is_read'] ?? false,
      data: json['data'],
    );
  }

  /// Parse timestamp from Supabase, handling UTC correctly.
  /// Supabase stores timestamps in UTC. If the string includes timezone info
  /// (e.g. +00:00), DateTime.parse creates a UTC DateTime. If not, we treat
  /// the value as UTC since that's what Supabase uses internally.
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return DateTime.now();
    if (parsed.isUtc) {
      return parsed.toLocal();
    }
    return DateTime.utc(
      parsed.year, parsed.month, parsed.day,
      parsed.hour, parsed.minute, parsed.second,
      parsed.millisecond, parsed.microsecond,
    ).toLocal();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'data': data,
    };
  }

  TechnicianNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return TechnicianNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}




