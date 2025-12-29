class Tool {
  final String? id;
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final String condition;
  final String? location;
  final String? assignedTo;
  final String status;
  final String toolType; // 'inventory', 'shared', 'assigned'
  final String? imagePath;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Tool({
    this.id,
    required this.name,
    required this.category,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    required this.condition,
    this.location,
    this.assignedTo,
    this.status = 'Available',
    this.toolType = 'inventory', // Default to inventory when adding new tools
    this.imagePath,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'name': name,
      'category': category,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'purchase_date': purchaseDate,
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'condition': condition,
      'location': location,
      'status': status,
      'tool_type': toolType,
      'image_path': imagePath,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
    
    // Only include id if it's not null (for updates)
    if (id != null) {
      map['id'] = id;
    }
    
    // Always include assigned_to to allow clearing it (setting to null)
    map['assigned_to'] = assignedTo;
    
    return map;
  }

  factory Tool.fromMap(Map<String, dynamic> map) {
    return Tool(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      brand: map['brand'],
      model: map['model'],
      serialNumber: map['serial_number'],
      purchaseDate: map['purchase_date'],
      purchasePrice: map['purchase_price'],
      currentValue: map['current_value'],
      condition: map['condition'],
      location: map['location'],
      assignedTo: map['assigned_to'],
      status: map['status'],
      toolType: map['tool_type'] ?? 'inventory', // Default to inventory if null
      imagePath: map['image_path'],
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Tool copyWith({
    String? id,
    String? name,
    String? category,
    String? brand,
    String? model,
    String? serialNumber,
    String? purchaseDate,
    double? purchasePrice,
    double? currentValue,
    String? condition,
    String? location,
    String? assignedTo,
    String? status,
    String? toolType,
    String? imagePath,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return Tool(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentValue: currentValue ?? this.currentValue,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      toolType: toolType ?? this.toolType,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

