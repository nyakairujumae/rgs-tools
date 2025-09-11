class ToolHistory {
  final int? id;
  final int toolId;
  final String toolName;
  final String action; // 'Created', 'Updated', 'Assigned', 'Returned', 'Maintenance', 'Deleted'
  final String description;
  final String? oldValue;
  final String? newValue;
  final String? performedBy;
  final String? performedByRole;
  final String timestamp;
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
    required this.timestamp,
    this.location,
    this.notes,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
      id: map['id'],
      toolId: map['tool_id'],
      toolName: map['tool_name'],
      action: map['action'],
      description: map['description'],
      oldValue: map['old_value'],
      newValue: map['new_value'],
      performedBy: map['performed_by'],
      performedByRole: map['performed_by_role'],
      timestamp: map['timestamp'],
      location: map['location'],
      notes: map['notes'],
      metadata: map['metadata'] != null ? _stringToMap(map['metadata']) : null,
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
    int? id,
    int? toolId,
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
      default:
        return action;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final historyTime = DateTime.parse(timestamp);
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
    final now = DateTime.now();
    final historyTime = DateTime.parse(timestamp);
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
}

// History service for creating history entries
class ToolHistoryService {
  static ToolHistory createHistory({
    required int toolId,
    required String toolName,
    required String action,
    required String description,
    String? oldValue,
    String? newValue,
    String? performedBy,
    String? performedByRole,
    String? location,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return ToolHistory(
      toolId: toolId,
      toolName: toolName,
      action: action,
      description: description,
      oldValue: oldValue,
      newValue: newValue,
      performedBy: performedBy,
      performedByRole: performedByRole,
      timestamp: DateTime.now().toIso8601String(),
      location: location,
      notes: notes,
      metadata: metadata,
    );
  }

  static List<ToolHistory> getMockHistory() {
    final now = DateTime.now();
    return [
      ToolHistory(
        id: 1,
        toolId: 1,
        toolName: 'Digital Multimeter',
        action: ToolHistoryActions.created,
        description: 'Tool added to inventory',
        performedBy: 'Admin User',
        performedByRole: 'Administrator',
        timestamp: now.subtract(const Duration(days: 30)).toIso8601String(),
        location: 'Main Office',
      ),
      ToolHistory(
        id: 2,
        toolId: 1,
        toolName: 'Digital Multimeter',
        action: ToolHistoryActions.assigned,
        description: 'Assigned to Ahmed Hassan',
        oldValue: 'Available',
        newValue: 'In Use',
        performedBy: 'Manager',
        performedByRole: 'Manager',
        timestamp: now.subtract(const Duration(days: 25)).toIso8601String(),
        location: 'Main Office',
      ),
      ToolHistory(
        id: 3,
        toolId: 1,
        toolName: 'Digital Multimeter',
        action: ToolHistoryActions.maintenance,
        description: 'Annual calibration performed',
        performedBy: 'Maintenance Team',
        performedByRole: 'Technician',
        timestamp: now.subtract(const Duration(days: 20)).toIso8601String(),
        location: 'Main Office',
        notes: 'Calibration passed, accuracy within ±0.1%',
      ),
      ToolHistory(
        id: 4,
        toolId: 1,
        toolName: 'Digital Multimeter',
        action: ToolHistoryActions.locationChanged,
        description: 'Moved to Site A - Downtown',
        oldValue: 'Main Office',
        newValue: 'Site A - Downtown',
        performedBy: 'Ahmed Hassan',
        performedByRole: 'Technician',
        timestamp: now.subtract(const Duration(days: 15)).toIso8601String(),
        location: 'Site A - Downtown',
      ),
      ToolHistory(
        id: 5,
        toolId: 1,
        toolName: 'Digital Multimeter',
        action: ToolHistoryActions.updated,
        description: 'Current value updated',
        oldValue: '400.00',
        newValue: '380.00',
        performedBy: 'Admin User',
        performedByRole: 'Administrator',
        timestamp: now.subtract(const Duration(days: 10)).toIso8601String(),
        location: 'Site A - Downtown',
        notes: 'Depreciation calculation applied',
      ),
      ToolHistory(
        id: 6,
        toolId: 1,
        toolName: 'Digital Multimeter',
        action: ToolHistoryActions.imageAdded,
        description: 'Tool image updated',
        performedBy: 'Ahmed Hassan',
        performedByRole: 'Technician',
        timestamp: now.subtract(const Duration(days: 5)).toIso8601String(),
        location: 'Site A - Downtown',
      ),
      ToolHistory(
        id: 7,
        toolId: 1,
        toolName: 'Digital Multimeter',
        action: ToolHistoryActions.notesUpdated,
        description: 'Notes updated',
        oldValue: 'Standard multimeter for electrical work',
        newValue: 'Standard multimeter for electrical work. Recently calibrated.',
        performedBy: 'Ahmed Hassan',
        performedByRole: 'Technician',
        timestamp: now.subtract(const Duration(days: 2)).toIso8601String(),
        location: 'Site A - Downtown',
      ),
    ];
  }
}
