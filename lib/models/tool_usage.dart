class ToolUsage {
  final int? id;
  final int toolId;
  final int technicianId;
  final String checkOutDate;
  final String? checkInDate;
  final String? notes;
  final String? conditionOnReturn;

  ToolUsage({
    this.id,
    required this.toolId,
    required this.technicianId,
    required this.checkOutDate,
    this.checkInDate,
    this.notes,
    this.conditionOnReturn,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tool_id': toolId,
      'technician_id': technicianId,
      'check_out_date': checkOutDate,
      'check_in_date': checkInDate,
      'notes': notes,
      'condition_on_return': conditionOnReturn,
    };
  }

  factory ToolUsage.fromMap(Map<String, dynamic> map) {
    return ToolUsage(
      id: map['id'],
      toolId: map['tool_id'],
      technicianId: map['technician_id'],
      checkOutDate: map['check_out_date'],
      checkInDate: map['check_in_date'],
      notes: map['notes'],
      conditionOnReturn: map['condition_on_return'],
    );
  }

  ToolUsage copyWith({
    int? id,
    int? toolId,
    int? technicianId,
    String? checkOutDate,
    String? checkInDate,
    String? notes,
    String? conditionOnReturn,
  }) {
    return ToolUsage(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      technicianId: technicianId ?? this.technicianId,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      checkInDate: checkInDate ?? this.checkInDate,
      notes: notes ?? this.notes,
      conditionOnReturn: conditionOnReturn ?? this.conditionOnReturn,
    );
  }

  bool get isCheckedOut => checkInDate == null;
  
  Duration get duration {
    final checkOut = DateTime.parse(checkOutDate);
    final checkIn = checkInDate != null ? DateTime.parse(checkInDate!) : DateTime.now();
    return checkIn.difference(checkOut);
  }
}
