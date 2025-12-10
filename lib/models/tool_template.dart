class ToolTemplate {
  final int? id;
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final String? description;
  final double? estimatedValue;
  final String? imagePath;
  final List<String> requiredFields;
  final Map<String, dynamic> defaultValues;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  ToolTemplate({
    this.id,
    required this.name,
    required this.category,
    this.brand,
    this.model,
    this.description,
    this.estimatedValue,
    this.imagePath,
    this.requiredFields = const [],
    this.defaultValues = const {},
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'model': model,
      'description': description,
      'estimated_value': estimatedValue,
      'image_path': imagePath,
      'required_fields': requiredFields.join(','),
      'default_values': _mapToString(defaultValues),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ToolTemplate.fromMap(Map<String, dynamic> map) {
    return ToolTemplate(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      brand: map['brand'],
      model: map['model'],
      description: map['description'],
      estimatedValue: map['estimated_value'],
      imagePath: map['image_path'],
      requiredFields: map['required_fields']?.split(',') ?? [],
      defaultValues: _stringToMap(map['default_values']),
      isActive: map['is_active'] == 1,
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

  ToolTemplate copyWith({
    int? id,
    String? name,
    String? category,
    String? brand,
    String? model,
    String? description,
    double? estimatedValue,
    String? imagePath,
    List<String>? requiredFields,
    Map<String, dynamic>? defaultValues,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return ToolTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      description: description ?? this.description,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      imagePath: imagePath ?? this.imagePath,
      requiredFields: requiredFields ?? this.requiredFields,
      defaultValues: defaultValues ?? this.defaultValues,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Pre-defined tool templates for HVAC industry
class ToolTemplates {
  static List<ToolTemplate> get defaultTemplates => [
    // Electrical Tools
    ToolTemplate(
      name: 'Digital Multimeter',
      category: 'Testing Equipment',
      brand: 'Fluke',
      model: '87V',
      description: 'Professional digital multimeter for electrical measurements',
      estimatedValue: 400.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'Testing Equipment',
      },
    ),
    
    ToolTemplate(
      name: 'Clamp Meter',
      category: 'Testing Equipment',
      brand: 'Fluke',
      model: '325',
      description: 'AC/DC clamp meter for current measurements',
      estimatedValue: 200.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'Testing Equipment',
      },
    ),

    // HVAC Tools
    ToolTemplate(
      name: 'Refrigerant Manifold Gauge Set',
      category: 'HVAC Tools',
      brand: 'Yellow Jacket',
      model: '41040',
      description: '4-valve manifold gauge set for refrigerant work',
      estimatedValue: 150.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'HVAC Tools',
      },
    ),

    ToolTemplate(
      name: 'Vacuum Pump',
      category: 'HVAC Tools',
      brand: 'Robinair',
      model: '15500',
      description: '5 CFM vacuum pump for system evacuation',
      estimatedValue: 300.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'HVAC Tools',
      },
    ),

    // Power Tools
    ToolTemplate(
      name: 'Cordless Drill',
      category: 'Power Tools',
      brand: 'DeWalt',
      model: 'DCD791D2',
      description: '20V MAX XR cordless drill driver kit',
      estimatedValue: 180.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'Power Tools',
      },
    ),

    ToolTemplate(
      name: 'Reciprocating Saw',
      category: 'Power Tools',
      brand: 'Milwaukee',
      model: 'M18 FUEL',
      description: '18V cordless reciprocating saw',
      estimatedValue: 220.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'Power Tools',
      },
    ),

    // Safety Equipment
    ToolTemplate(
      name: 'Safety Harness',
      category: 'Safety Equipment',
      brand: '3M',
      model: 'DBI-SALA',
      description: 'Full body safety harness for fall protection',
      estimatedValue: 120.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'Safety Equipment',
      },
    ),

    ToolTemplate(
      name: 'Hard Hat',
      category: 'Safety Equipment',
      brand: 'Honeywell',
      model: 'H7',
      description: 'ANSI Type I Class C hard hat',
      estimatedValue: 25.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'Safety Equipment',
      },
    ),

    // Measuring Tools
    ToolTemplate(
      name: 'Laser Distance Meter',
      category: 'Measuring Tools',
      brand: 'Bosch',
      model: 'GLM 50 C',
      description: '50m laser distance meter with Bluetooth',
      estimatedValue: 100.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'Measuring Tools',
      },
    ),

    ToolTemplate(
      name: 'Tape Measure',
      category: 'Measuring Tools',
      brand: 'Stanley',
      model: 'PowerLock',
      description: '25ft tape measure with magnetic tip',
      estimatedValue: 15.0,
      requiredFields: ['serialNumber', 'purchaseDate', 'purchasePrice'],
      defaultValues: {
        'condition': 'Good',
        'status': 'Available',
        'category': 'Measuring Tools',
      },
    ),
  ];
}
