class ToolHistory {
  final String? id;
  final String toolId;
  final String toolName;
  final String action; // 'Created', 'Updated', 'Assigned', 'Returned', 'Maintenance', 'Deleted'
  final String description;
  final String? oldValue;
  final String? newValue;
  final String? performedBy;
  final String? performedByRole;
  final String? timestamp;
  final String? location;
  final String? notes;
  final Map<String, dynamic>? metadata;

  ToolHistory({
    this.id,
    required this.toolId,
    required this.toolName,
    required this.action,
    required this.description,
    this.oldValue,
    this.newValue,
    this.performedBy,
    this.performedByRole,
    this.timestamp,
    this.location,
    this.notes,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tool_id': toolId,
      'tool_name': toolName,
      'action': action,
      'description': description,
      'old_value': oldValue,
      'new_value': newValue,
      'performed_by': performedBy,
      'performed_by_role': performedByRole,
      'timestamp': timestamp,
      'location': location,
      'notes': notes,
      'metadata': metadata != null ? _mapToString(metadata!) : null,
    };
  }

  factory ToolHistory.fromMap(Map<String, dynamic> map) {
    return ToolHistory(
      id: map['id']?.toString(),
      toolId: map['tool_id']?.toString() ?? '',
      toolName: map['tool_name'],
      action: map['action'],
      description: map['description'],
      oldValue: map['old_value'],
      newValue: map['new_value'],
      performedBy: map['performed_by']?.toString(),
      performedByRole: map['performed_by_role']?.toString(),
      timestamp: map['timestamp'],
      location: map['location'],
      notes: map['notes'],
      metadata: map['metadata'] != null
          ? (map['metadata'] is Map
              ? Map<String, dynamic>.from(map['metadata'] as Map)
              : _stringToMap(map['metadata']?.toString()))
          : null,
    );
  }

  static String _mapToString(Map<String, dynamic> map) {
    return map.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
  }

  static Map<String, dynamic> _stringToMap(String? str) {
    if (str == null || str.isEmpty) return {};
    final Map<String, dynamic> result = {};
    for (final entry in str.split('|')) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      }
    }
    return result;
  }

  ToolHistory copyWith({
    String? id,
    String? toolId,
    String? toolName,
    String? action,
    String? description,
    String? oldValue,
    String? newValue,
    String? performedBy,
    String? performedByRole,
    String? timestamp,
    String? location,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return ToolHistory(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      action: action ?? this.action,
      description: description ?? this.description,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      performedBy: performedBy ?? this.performedBy,
      performedByRole: performedByRole ?? this.performedByRole,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  String get actionDisplayName {
    switch (action) {
      case 'Created':
        return 'Tool Created';
      case 'Updated':
        return 'Tool Updated';
      case 'Assigned':
        return 'Tool Assigned';
      case 'Returned':
        return 'Tool Returned';
      case 'Maintenance':
        return 'Maintenance Performed';
      case 'Deleted':
        return 'Tool Deleted';
      case 'Transferred':
        return 'Tool Transferred';
      case 'Status Changed':
        return 'Status Changed';
      case 'Location Changed':
        return 'Location Changed';
      case 'Badged':
        return 'Tool Badged';
      case 'Released Badge':
        return 'Badge Released';
      case 'Released to Requester':
        return 'Released to Requester';
      default:
        return action;
    }
  }

  String get timeAgo {
    if (timestamp == null || timestamp!.isEmpty) return 'Unknown';
    final now = DateTime.now();
    final historyTime = DateTime.parse(timestamp!);
    final difference = now.difference(historyTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  bool get isRecent {
    if (timestamp == null || timestamp!.isEmpty) return false;
    final now = DateTime.now();
    final historyTime = DateTime.parse(timestamp!);
    final difference = now.difference(historyTime);
    return difference.inHours < 24;
  }
}

// Pre-defined history actions
class ToolHistoryActions {
  static const String created = 'Created';
  static const String updated = 'Updated';
  static const String assigned = 'Assigned';
  static const String returned = 'Returned';
  static const String maintenance = 'Maintenance';
  static const String deleted = 'Deleted';
  static const String transferred = 'Transferred';
  static const String statusChanged = 'Status Changed';
  static const String locationChanged = 'Location Changed';
  static const String conditionChanged = 'Condition Changed';
  static const String valueUpdated = 'Value Updated';
  static const String imageAdded = 'Image Added';
  static const String notesUpdated = 'Notes Updated';
  static const String badged = 'Badged';
  static const String releasedBadge = 'Released Badge';
  static const String releasedToRequester = 'Released to Requester';
  static const String acceptedAssignment = 'Accepted Assignment';
  static const String declinedAssignment = 'Declined Assignment';
}
