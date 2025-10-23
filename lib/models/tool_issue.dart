class ToolIssue {
  final String? id;
  final String toolId;
  final String toolName;
  final String reportedBy; // Technician name and ID
  final String? reportedByUserId; // User ID of the reporter
  final String issueType; // 'Faulty', 'Lost', 'Damaged', 'Missing Parts', 'Other'
  final String description;
  final String priority; // 'Low', 'Medium', 'High', 'Critical'
  final String status; // 'Open', 'In Progress', 'Resolved', 'Closed'
  final String? assignedTo; // Admin or technician handling the issue
  final String? assignedToUserId; // User ID of the assigned person
  final String? resolution;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final List<String>? attachments; // Image URLs or file paths
  final String? location; // Where the issue occurred
  final double? estimatedCost; // Cost to fix/replace

  ToolIssue({
    this.id,
    required this.toolId,
    required this.toolName,
    required this.reportedBy,
    this.reportedByUserId,
    required this.issueType,
    required this.description,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.assignedToUserId,
    this.resolution,
    required this.reportedAt,
    this.resolvedAt,
    this.attachments,
    this.location,
    this.estimatedCost,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'tool_id': toolId,
      'tool_name': toolName,
      'reported_by': reportedBy,
      'reported_by_user_id': reportedByUserId,
      'issue_type': issueType,
      'description': description,
      'priority': priority,
      'status': status,
      'assigned_to': assignedTo,
      'assigned_to_user_id': assignedToUserId,
      'resolution': resolution,
      'reported_at': reportedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'attachments': attachments,
      'location': location,
      'estimated_cost': estimatedCost,
    };

    // Only include id if it's not null (for updates)
    if (id != null) {
      json['id'] = id;
    }

    return json;
  }

  factory ToolIssue.fromJson(Map<String, dynamic> json) {
    return ToolIssue(
      id: json['id'],
      toolId: json['tool_id'],
      toolName: json['tool_name'],
      reportedBy: json['reported_by'],
      reportedByUserId: json['reported_by_user_id'],
      issueType: json['issue_type'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      assignedTo: json['assigned_to'],
      assignedToUserId: json['assigned_to_user_id'],
      resolution: json['resolution'],
      reportedAt: DateTime.parse(json['reported_at']),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      attachments: json['attachments']?.cast<String>(),
      location: json['location'],
      estimatedCost: json['estimated_cost']?.toDouble(),
    );
  }

  ToolIssue copyWith({
    String? id,
    String? toolId,
    String? toolName,
    String? reportedBy,
    String? reportedByUserId,
    String? issueType,
    String? description,
    String? priority,
    String? status,
    String? assignedTo,
    String? assignedToUserId,
    String? resolution,
    DateTime? reportedAt,
    DateTime? resolvedAt,
    List<String>? attachments,
    String? location,
    double? estimatedCost,
  }) {
    return ToolIssue(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByUserId: reportedByUserId ?? this.reportedByUserId,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      resolution: resolution ?? this.resolution,
      reportedAt: reportedAt ?? this.reportedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      attachments: attachments ?? this.attachments,
      location: location ?? this.location,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  // Helper methods
  bool get isOpen => status == 'Open';
  bool get isInProgress => status == 'In Progress';
  bool get isResolved => status == 'Resolved';
  bool get isClosed => status == 'Closed';
  
  bool get isHighPriority => priority == 'High' || priority == 'Critical';
  bool get isCritical => priority == 'Critical';

  Duration get age => DateTime.now().difference(reportedAt);
  String get ageText {
    final days = age.inDays;
    if (days == 0) return 'Today';
    if (days == 1) return '1 day ago';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${(days / 7).floor()} weeks ago';
    return '${(days / 30).floor()} months ago';
  }
}

