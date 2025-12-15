class ApprovalWorkflow {
  final String? id; // Changed from int? to String? to match UUID
  final String requestType; // 'Tool Assignment', 'Tool Purchase', 'Tool Disposal', 'Maintenance', 'Transfer'
  final String title;
  final String description;
  final String requesterId;
  final String requesterName;
  final String requesterRole;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Cancelled'
  final String priority; // 'Low', 'Medium', 'High', 'Critical'
  final DateTime requestDate;
  final DateTime? dueDate;
  final String? assignedTo;
  final String? assignedToRole;
  final String? comments;
  final String? rejectionReason;
  final DateTime? approvedDate;
  final DateTime? rejectedDate;
  final String? approvedBy;
  final String? rejectedBy;
  final Map<String, dynamic>? requestData;
  final String? location;
  final String? createdAt;
  final String? updatedAt;

  ApprovalWorkflow({
    this.id,
    required this.requestType,
    required this.title,
    required this.description,
    required this.requesterId,
    required this.requesterName,
    required this.requesterRole,
    this.status = 'Pending',
    this.priority = 'Medium',
    required this.requestDate,
    this.dueDate,
    this.assignedTo,
    this.assignedToRole,
    this.comments,
    this.rejectionReason,
    this.approvedDate,
    this.rejectedDate,
    this.approvedBy,
    this.rejectedBy,
    this.requestData,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap({bool includeId = false}) {
    final map = <String, dynamic>{
      'request_type': requestType,
      'title': title,
      'description': description,
      'requester_id': requesterId,
      'requester_name': requesterName,
      'requester_role': requesterRole,
      'status': status,
      'priority': priority,
      'request_date': requestDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'assigned_to': assignedTo,
      'assigned_to_role': assignedToRole,
      'comments': comments,
      'rejection_reason': rejectionReason,
      'approved_date': approvedDate?.toIso8601String(),
      'rejected_date': rejectedDate?.toIso8601String(),
      'approved_by': approvedBy,
      'rejected_by': rejectedBy,
      'request_data': requestData,
      'location': location,
    };

    // Only include id/created/updated when explicitly requested (e.g., updates)
    if (includeId && id != null) {
      map['id'] = id;
    }
    if (includeId) {
      if (createdAt != null) map['created_at'] = createdAt;
      if (updatedAt != null) map['updated_at'] = updatedAt;
    }

    return map;
  }

  factory ApprovalWorkflow.fromMap(Map<String, dynamic> map) {
    return ApprovalWorkflow(
      id: map['id']?.toString(), // Convert to string to handle UUID
      requestType: map['request_type'],
      title: map['title'],
      description: map['description'],
      requesterId: map['requester_id'],
      requesterName: map['requester_name'],
      requesterRole: map['requester_role'],
      status: map['status'] ?? 'Pending',
      priority: map['priority'] ?? 'Medium',
      requestDate: DateTime.parse(map['request_date']),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      assignedTo: map['assigned_to'],
      assignedToRole: map['assigned_to_role'],
      comments: map['comments'],
      rejectionReason: map['rejection_reason'],
      approvedDate: map['approved_date'] != null ? DateTime.parse(map['approved_date']) : null,
      rejectedDate: map['rejected_date'] != null ? DateTime.parse(map['rejected_date']) : null,
      approvedBy: map['approved_by'],
      rejectedBy: map['rejected_by'],
      requestData: map['request_data'] != null 
          ? (map['request_data'] is Map 
              ? Map<String, dynamic>.from(map['request_data']) 
              : _stringToMap(map['request_data'].toString())) 
          : null,
      location: map['location'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
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

  ApprovalWorkflow copyWith({
    String? id,
    String? requestType,
    String? title,
    String? description,
    String? requesterId,
    String? requesterName,
    String? requesterRole,
    String? status,
    String? priority,
    DateTime? requestDate,
    DateTime? dueDate,
    String? assignedTo,
    String? assignedToRole,
    String? comments,
    String? rejectionReason,
    DateTime? approvedDate,
    DateTime? rejectedDate,
    String? approvedBy,
    String? rejectedBy,
    Map<String, dynamic>? requestData,
    String? location,
    String? createdAt,
    String? updatedAt,
  }) {
    return ApprovalWorkflow(
      id: id ?? this.id,
      requestType: requestType ?? this.requestType,
      title: title ?? this.title,
      description: description ?? this.description,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterRole: requesterRole ?? this.requesterRole,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      requestDate: requestDate ?? this.requestDate,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToRole: assignedToRole ?? this.assignedToRole,
      comments: comments ?? this.comments,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedDate: approvedDate ?? this.approvedDate,
      rejectedDate: rejectedDate ?? this.rejectedDate,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      requestData: requestData ?? this.requestData,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isCancelled => status == 'Cancelled';

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && isPending;
  }

  String get statusDisplayName {
    switch (status) {
      case 'Pending':
        return 'Pending';
      case 'Approved':
        return 'Approved';
      case 'Rejected':
        return 'Rejected';
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
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final difference = dueDate!.difference(now).inDays;
    return difference;
  }

  String get dueStatus {
    if (isOverdue) return 'Overdue';
    if (daysUntilDue == 0) return 'Due Today';
    if (daysUntilDue == 1) return 'Due Tomorrow';
    if (daysUntilDue > 0) return 'Due in $daysUntilDue days';
    return 'No due date';
  }
}

// Pre-defined request types
class RequestTypes {
  static const String toolAssignment = 'Tool Assignment';
  static const String toolPurchase = 'Tool Purchase';
  static const String toolDisposal = 'Tool Disposal';
  static const String maintenance = 'Maintenance';
  static const String transfer = 'Transfer';
  static const String repair = 'Repair';
  static const String calibration = 'Calibration';
  static const String certification = 'Certification';

  static const List<String> allTypes = [
    toolAssignment,
    toolPurchase,
    toolDisposal,
    maintenance,
    transfer,
    repair,
    calibration,
    certification,
  ];

  static const Map<String, String> typeDescriptions = {
    toolAssignment: 'Request to assign a tool to a technician',
    toolPurchase: 'Request to purchase new tools',
    toolDisposal: 'Request to dispose of old or damaged tools',
    maintenance: 'Request for tool maintenance or repair',
    transfer: 'Request to transfer tool between locations',
    repair: 'Request for tool repair',
    calibration: 'Request for tool calibration',
    certification: 'Request for tool certification',
  };
}

// Mock data for approval workflows
class ApprovalWorkflowService {
  static List<ApprovalWorkflow> getMockWorkflows() {
    final now = DateTime.now();
    return [
      ApprovalWorkflow(
        id: '1',
        requestType: RequestTypes.toolAssignment,
        title: 'Assign Digital Multimeter to Ahmed Hassan',
        description: 'Request to assign Digital Multimeter (Serial: FL123456) to Ahmed Hassan for Site A project',
        requesterId: 'REQ-001',
        requesterName: 'Ahmed Hassan',
        requesterRole: 'Technician',
        status: 'Pending',
        priority: 'Medium',
        requestDate: now.subtract(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 3)),
        assignedTo: 'Manager',
        assignedToRole: 'Manager',
        location: 'Site A - Downtown',
        requestData: {
          'tool_id': 1,
          'tool_name': 'Digital Multimeter',
          'technician_id': 1,
          'technician_name': 'Ahmed Hassan',
          'project': 'Site A HVAC Installation',
        },
      ),
      ApprovalWorkflow(
        id: '2',
        requestType: RequestTypes.toolPurchase,
        title: 'Purchase New Refrigerant Manifold Gauge Set',
        description: 'Request to purchase 5 new Yellow Jacket manifold gauge sets for upcoming projects',
        requesterId: 'REQ-002',
        requesterName: 'Mohammed Ali',
        requesterRole: 'Supervisor',
        status: 'Approved',
        priority: 'High',
        requestDate: now.subtract(const Duration(days: 5)),
        dueDate: now.subtract(const Duration(days: 1)),
        assignedTo: 'Manager',
        assignedToRole: 'Manager',
        approvedDate: now.subtract(const Duration(days: 1)),
        approvedBy: 'Manager',
        location: 'Main Office',
        requestData: {
          'tool_name': 'Yellow Jacket Manifold Gauge Set',
          'quantity': 5,
          'unit_price': 150.0,
          'total_cost': 750.0,
          'supplier': 'HVAC Supplies Dubai',
        },
      ),
      ApprovalWorkflow(
        id: '3',
        requestType: RequestTypes.maintenance,
        title: 'Maintenance for Vacuum Pump',
        description: 'Request for annual maintenance of Vacuum Pump (Serial: VP789012)',
        requesterId: 'REQ-003',
        requesterName: 'Omar Al-Rashid',
        requesterRole: 'Technician',
        status: 'Pending',
        priority: 'Medium',
        requestDate: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 2)),
        assignedTo: 'Maintenance Team',
        assignedToRole: 'Maintenance Supervisor',
        location: 'Site B - Marina',
        requestData: {
          'tool_id': 3,
          'tool_name': 'Vacuum Pump',
          'maintenance_type': 'Annual Service',
          'estimated_cost': 200.0,
        },
      ),
      ApprovalWorkflow(
        id: '4',
        requestType: RequestTypes.toolDisposal,
        title: 'Dispose of Damaged Safety Harness',
        description: 'Request to dispose of damaged safety harness (Serial: SH345678) due to wear and tear',
        requesterId: 'REQ-004',
        requesterName: 'Hassan Mohammed',
        requesterRole: 'Safety Officer',
        status: 'Rejected',
        priority: 'Low',
        requestDate: now.subtract(const Duration(days: 3)),
        dueDate: now.subtract(const Duration(days: 1)),
        assignedTo: 'Manager',
        assignedToRole: 'Manager',
        rejectedDate: now.subtract(const Duration(days: 1)),
        rejectedBy: 'Manager',
        rejectionReason: 'Safety harness can be repaired instead of disposed',
        location: 'Main Office',
        requestData: {
          'tool_id': 5,
          'tool_name': 'Safety Harness',
          'disposal_reason': 'Wear and tear',
          'condition': 'Poor',
        },
      ),
      ApprovalWorkflow(
        id: '5',
        requestType: RequestTypes.transfer,
        title: 'Transfer Cordless Drill to Site A',
        description: 'Request to transfer Cordless Drill (Serial: CD901234) from Main Office to Site A',
        requesterId: 'REQ-005',
        requesterName: 'Ahmed Hassan',
        requesterRole: 'Technician',
        status: 'Pending',
        priority: 'Low',
        requestDate: now.subtract(const Duration(hours: 6)),
        dueDate: now.add(const Duration(days: 1)),
        assignedTo: 'Manager',
        assignedToRole: 'Manager',
        location: 'Site A - Downtown',
        requestData: {
          'tool_id': 4,
          'tool_name': 'Cordless Drill',
          'from_location': 'Main Office',
          'to_location': 'Site A - Downtown',
          'reason': 'Project requirement',
        },
      ),
    ];
  }

  static List<ApprovalWorkflow> getPendingWorkflows() {
    return getMockWorkflows().where((w) => w.isPending).toList();
  }

  static List<ApprovalWorkflow> getOverdueWorkflows() {
    return getMockWorkflows().where((w) => w.isOverdue).toList();
  }

  static List<ApprovalWorkflow> getWorkflowsByType(String type) {
    return getMockWorkflows().where((w) => w.requestType == type).toList();
  }
}
