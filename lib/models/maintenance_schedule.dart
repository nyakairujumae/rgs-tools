class MaintenanceSchedule {
  final int? id;
  final String toolId; // UUID string matching tools.id
  final String toolName;
  final String maintenanceType;
  final String description;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final String status; // 'Scheduled', 'In Progress', 'Completed', 'Overdue', 'Cancelled'
  final String priority; // 'Low', 'Medium', 'High', 'Critical'
  final String? assignedTo;
  final String? notes;
  final double? estimatedCost;
  final double? actualCost;
  final String? partsUsed;
  final String? nextMaintenanceDate;
  final int? intervalDays;
  final String? createdAt;
  final String? updatedAt;

  MaintenanceSchedule({
    this.id,
    required this.toolId,
    required this.toolName,
    required this.maintenanceType,
    required this.description,
    required this.scheduledDate,
    this.completedDate,
    this.status = 'Scheduled',
    this.priority = 'Medium',
    this.assignedTo,
    this.notes,
    this.estimatedCost,
    this.actualCost,
    this.partsUsed,
    this.nextMaintenanceDate,
    this.intervalDays,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tool_id': toolId,
      'tool_name': toolName,
      'maintenance_type': maintenanceType,
      'description': description,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'status': status,
      'priority': priority,
      'assigned_to': assignedTo,
      'notes': notes,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'parts_used': partsUsed,
      'next_maintenance_date': nextMaintenanceDate,
      'interval_days': intervalDays,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory MaintenanceSchedule.fromMap(Map<String, dynamic> map) {
    return MaintenanceSchedule(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? ''),
      toolId: (map['tool_id'] ?? '').toString(),
      toolName: map['tool_name'],
      maintenanceType: map['maintenance_type'],
      description: map['description'],
      scheduledDate: DateTime.parse(map['scheduled_date']),
      completedDate: map['completed_date'] != null 
          ? DateTime.parse(map['completed_date']) 
          : null,
      status: map['status'] ?? 'Scheduled',
      priority: map['priority'] ?? 'Medium',
      assignedTo: map['assigned_to'],
      notes: map['notes'],
      estimatedCost: map['estimated_cost'],
      actualCost: map['actual_cost'],
      partsUsed: map['parts_used'],
      nextMaintenanceDate: map['next_maintenance_date'],
      intervalDays: map['interval_days'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  MaintenanceSchedule copyWith({
    int? id,
    String? toolId,
    String? toolName,
    String? maintenanceType,
    String? description,
    DateTime? scheduledDate,
    DateTime? completedDate,
    String? status,
    String? priority,
    String? assignedTo,
    String? notes,
    double? estimatedCost,
    double? actualCost,
    String? partsUsed,
    String? nextMaintenanceDate,
    int? intervalDays,
    String? createdAt,
    String? updatedAt,
  }) {
    return MaintenanceSchedule(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      partsUsed: partsUsed ?? this.partsUsed,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      intervalDays: intervalDays ?? this.intervalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue {
    return status != 'Completed' && 
           status != 'Cancelled' && 
           scheduledDate.isBefore(DateTime.now());
  }

  bool get isCompleted => status == 'Completed';
  bool get isScheduled => status == 'Scheduled';
  bool get isInProgress => status == 'In Progress';

  String get statusDisplayName {
    switch (status) {
      case 'Scheduled':
        return 'Scheduled';
      case 'In Progress':
        return 'In Progress';
      case 'Completed':
        return 'Completed';
      case 'Overdue':
        return 'Overdue';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'Low':
        return 'Low';
      case 'Medium':
        return 'Medium';
      case 'High':
        return 'High';
      case 'Critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final difference = scheduledDate.difference(now).inDays;
    return difference;
  }

  String get dueStatus {
    if (isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';
    if (daysUntilDue == 0) return 'Due Today';
    if (daysUntilDue == 1) return 'Due Tomorrow';
    if (daysUntilDue > 0) return 'Due in $daysUntilDue days';
    return 'Overdue';
  }
}

// Pre-defined maintenance types for HVAC tools
class MaintenanceTypes {
  static const List<String> types = [
    'Routine Inspection',
    'Calibration',
    'Cleaning',
    'Lubrication',
    'Battery Replacement',
    'Filter Replacement',
    'Safety Check',
    'Performance Test',
    'Repair',
    'Replacement',
    'Recertification',
    'Software Update',
  ];

  static const Map<String, int> defaultIntervals = {
    'Routine Inspection': 30,
    'Calibration': 90,
    'Cleaning': 14,
    'Lubrication': 60,
    'Battery Replacement': 180,
    'Filter Replacement': 30,
    'Safety Check': 90,
    'Performance Test': 180,
    'Repair': 0,
    'Replacement': 0,
    'Recertification': 365,
    'Software Update': 90,
  };

  static const Map<String, String> defaultPriorities = {
    'Routine Inspection': 'Medium',
    'Calibration': 'High',
    'Cleaning': 'Low',
    'Lubrication': 'Low',
    'Battery Replacement': 'Medium',
    'Filter Replacement': 'Medium',
    'Safety Check': 'High',
    'Performance Test': 'High',
    'Repair': 'Critical',
    'Replacement': 'Critical',
    'Recertification': 'High',
    'Software Update': 'Medium',
  };
}
