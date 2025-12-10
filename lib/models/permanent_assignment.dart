class PermanentAssignment {
  final int? id;
  final int toolId;
  final int technicianId;
  final int? locationId;
  final String assignedDate;
  final String? assignedBy;
  final String? notes;
  final String status; // 'Active', 'On Leave', 'Transferred', 'Returned'
  final String? leaveStartDate;
  final String? leaveEndDate;
  final String? leaveReason;
  final int? transferredToTechnicianId;
  final String? transferDate;
  final String? transferReason;
  final String? returnedDate;
  final String? returnReason;
  final String? createdAt;
  final String? updatedAt;

  PermanentAssignment({
    this.id,
    required this.toolId,
    required this.technicianId,
    this.locationId,
    required this.assignedDate,
    this.assignedBy,
    this.notes,
    this.status = 'Active',
    this.leaveStartDate,
    this.leaveEndDate,
    this.leaveReason,
    this.transferredToTechnicianId,
    this.transferDate,
    this.transferReason,
    this.returnedDate,
    this.returnReason,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tool_id': toolId,
      'technician_id': technicianId,
      'location_id': locationId,
      'assigned_date': assignedDate,
      'assigned_by': assignedBy,
      'notes': notes,
      'status': status,
      'leave_start_date': leaveStartDate,
      'leave_end_date': leaveEndDate,
      'leave_reason': leaveReason,
      'transferred_to_technician_id': transferredToTechnicianId,
      'transfer_date': transferDate,
      'transfer_reason': transferReason,
      'returned_date': returnedDate,
      'return_reason': returnReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PermanentAssignment.fromMap(Map<String, dynamic> map) {
    return PermanentAssignment(
      id: map['id'],
      toolId: map['tool_id'],
      technicianId: map['technician_id'],
      locationId: map['location_id'],
      assignedDate: map['assigned_date'],
      assignedBy: map['assigned_by'],
      notes: map['notes'],
      status: map['status'] ?? 'Active',
      leaveStartDate: map['leave_start_date'],
      leaveEndDate: map['leave_end_date'],
      leaveReason: map['leave_reason'],
      transferredToTechnicianId: map['transferred_to_technician_id'],
      transferDate: map['transfer_date'],
      transferReason: map['transfer_reason'],
      returnedDate: map['returned_date'],
      returnReason: map['return_reason'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  PermanentAssignment copyWith({
    int? id,
    int? toolId,
    int? technicianId,
    int? locationId,
    String? assignedDate,
    String? assignedBy,
    String? notes,
    String? status,
    String? leaveStartDate,
    String? leaveEndDate,
    String? leaveReason,
    int? transferredToTechnicianId,
    String? transferDate,
    String? transferReason,
    String? returnedDate,
    String? returnReason,
    String? createdAt,
    String? updatedAt,
  }) {
    return PermanentAssignment(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      technicianId: technicianId ?? this.technicianId,
      locationId: locationId ?? this.locationId,
      assignedDate: assignedDate ?? this.assignedDate,
      assignedBy: assignedBy ?? this.assignedBy,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      leaveStartDate: leaveStartDate ?? this.leaveStartDate,
      leaveEndDate: leaveEndDate ?? this.leaveEndDate,
      leaveReason: leaveReason ?? this.leaveReason,
      transferredToTechnicianId: transferredToTechnicianId ?? this.transferredToTechnicianId,
      transferDate: transferDate ?? this.transferDate,
      transferReason: transferReason ?? this.transferReason,
      returnedDate: returnedDate ?? this.returnedDate,
      returnReason: returnReason ?? this.returnReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == 'Active';
  bool get isOnLeave => status == 'On Leave';
  bool get isTransferred => status == 'Transferred';
  bool get isReturned => status == 'Returned';

  String get statusDisplayName {
    switch (status) {
      case 'Active':
        return 'Active';
      case 'On Leave':
        return 'On Leave';
      case 'Transferred':
        return 'Transferred';
      case 'Returned':
        return 'Returned';
      default:
        return 'Unknown';
    }
  }
}
