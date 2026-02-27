class Certification {
  final String? id;
  final String toolId;
  final String toolName;
  final String certificationType;
  final String certificationNumber;
  final String issuingAuthority;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String status; // 'Valid', 'Expired', 'Expiring Soon', 'Revoked'
  final String? notes;
  final String? documentPath;
  final String? inspectorName;
  final String? inspectorId;
  final String? location;
  final String? createdAt;
  final String? updatedAt;

  Certification({
    this.id,
    required this.toolId, // UUID string matching tools.id
    required this.toolName,
    required this.certificationType,
    required this.certificationNumber,
    required this.issuingAuthority,
    required this.issueDate,
    required this.expiryDate,
    this.status = 'Valid',
    this.notes,
    this.documentPath,
    this.inspectorName,
    this.inspectorId,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tool_id': toolId,
      'tool_name': toolName,
      'certification_type': certificationType,
      'certification_number': certificationNumber,
      'issuing_authority': issuingAuthority,
      'issue_date': issueDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'document_path': documentPath,
      'inspector_name': inspectorName,
      'inspector_id': inspectorId,
      'location': location,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Certification.fromMap(Map<String, dynamic> map) {
    return Certification(
      id: map['id']?.toString(),
      toolId: (map['tool_id'] ?? '').toString(),
      toolName: map['tool_name'],
      certificationType: map['certification_type'],
      certificationNumber: map['certification_number'],
      issuingAuthority: map['issuing_authority'],
      issueDate: DateTime.parse(map['issue_date']),
      expiryDate: DateTime.parse(map['expiry_date']),
      status: map['status'] ?? 'Valid',
      notes: map['notes'],
      documentPath: map['document_path'],
      inspectorName: map['inspector_name'],
      inspectorId: map['inspector_id'],
      location: map['location'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Certification copyWith({
    String? id,
    String? toolId,
    String? toolName,
    String? certificationType,
    String? certificationNumber,
    String? issuingAuthority,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? status,
    String? notes,
    String? documentPath,
    String? inspectorName,
    String? inspectorId,
    String? location,
    String? createdAt,
    String? updatedAt,
  }) {
    return Certification(
      id: id ?? this.id,
      toolId: toolId ?? this.toolId,
      toolName: toolName ?? this.toolName,
      certificationType: certificationType ?? this.certificationType,
      certificationNumber: certificationNumber ?? this.certificationNumber,
      issuingAuthority: issuingAuthority ?? this.issuingAuthority,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      documentPath: documentPath ?? this.documentPath,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectorId: inspectorId ?? this.inspectorId,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isExpiringSoon => !isExpired && DateTime.now().add(const Duration(days: 30)).isAfter(expiryDate);
  bool get isValid => !isExpired && status == 'Valid';

  String get statusDisplayName {
    switch (status) {
      case 'Valid':
        return 'Valid';
      case 'Expired':
        return 'Expired';
      case 'Expiring Soon':
        return 'Expiring Soon';
      case 'Revoked':
        return 'Revoked';
      default:
        return 'Unknown';
    }
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    return difference;
  }

  String get expiryStatus {
    if (isExpired) return 'Expired';
    if (isExpiringSoon) return 'Expires in ${daysUntilExpiry} days';
    return 'Valid for ${daysUntilExpiry} days';
  }
}

// Pre-defined certification types for HVAC tools
class CertificationTypes {
  static const List<String> types = [
    'Calibration Certificate',
    'Safety Inspection',
    'Electrical Safety Test',
    'Pressure Test',
    'Performance Test',
    'Compliance Certificate',
    'Quality Assurance',
    'Environmental Test',
    'EMC Test',
    'CE Marking',
    'UL Listing',
    'CSA Certification',
    'ANSI Compliance',
    'ISO 9001',
    'ISO 14001',
  ];

  static const Map<String, int> defaultValidityPeriods = {
    'Calibration Certificate': 365,
    'Safety Inspection': 180,
    'Electrical Safety Test': 365,
    'Pressure Test': 180,
    'Performance Test': 365,
    'Compliance Certificate': 1095,
    'Quality Assurance': 365,
    'Environmental Test': 365,
    'EMC Test': 365,
    'CE Marking': 1095,
    'UL Listing': 1095,
    'CSA Certification': 1095,
    'ANSI Compliance': 365,
    'ISO 9001': 1095,
    'ISO 14001': 1095,
  };

  static const Map<String, String> defaultAuthorities = {
    'Calibration Certificate': 'Dubai Municipality',
    'Safety Inspection': 'Dubai Civil Defense',
    'Electrical Safety Test': 'DEWA',
    'Pressure Test': 'Dubai Municipality',
    'Performance Test': 'Dubai Municipality',
    'Compliance Certificate': 'UAE Ministry of Industry',
    'Quality Assurance': 'Dubai Municipality',
    'Environmental Test': 'Dubai Municipality',
    'EMC Test': 'UAE Ministry of Industry',
    'CE Marking': 'European Commission',
    'UL Listing': 'Underwriters Laboratories',
    'CSA Certification': 'Canadian Standards Association',
    'ANSI Compliance': 'American National Standards Institute',
    'ISO 9001': 'International Organization for Standardization',
    'ISO 14001': 'International Organization for Standardization',
  };
}

// Mock data for certifications
class CertificationService {
  static List<Certification> getMockCertifications() {
    final now = DateTime.now();
    return [
      Certification(
        id: '1',
        toolId: 'mock-tool-1',
        toolName: 'Digital Multimeter',
        certificationType: 'Calibration Certificate',
        certificationNumber: 'CAL-2024-001',
        issuingAuthority: 'Dubai Municipality',
        issueDate: now.subtract(const Duration(days: 30)),
        expiryDate: now.add(const Duration(days: 335)),
        status: 'Valid',
        inspectorName: 'Ahmed Al-Rashid',
        inspectorId: 'INSP-001',
        location: 'Main Office',
        notes: 'Annual calibration completed successfully',
      ),
      Certification(
        id: '2',
        toolId: 'mock-tool-1',
        toolName: 'Digital Multimeter',
        certificationType: 'Electrical Safety Test',
        certificationNumber: 'EST-2024-001',
        issuingAuthority: 'DEWA',
        issueDate: now.subtract(const Duration(days: 60)),
        expiryDate: now.add(const Duration(days: 305)),
        status: 'Valid',
        inspectorName: 'Mohammed Hassan',
        inspectorId: 'INSP-002',
        location: 'Main Office',
        notes: 'Electrical safety test passed',
      ),
      Certification(
        id: '3',
        toolId: 'mock-tool-2',
        toolName: 'Refrigerant Manifold Gauge Set',
        certificationType: 'Pressure Test',
        certificationNumber: 'PT-2024-001',
        issuingAuthority: 'Dubai Municipality',
        issueDate: now.subtract(const Duration(days: 90)),
        expiryDate: now.add(const Duration(days: 90)),
        status: 'Expiring Soon',
        inspectorName: 'Omar Al-Zahra',
        inspectorId: 'INSP-003',
        location: 'Site A - Downtown',
        notes: 'Pressure test certificate expiring soon',
      ),
      Certification(
        id: '4',
        toolId: 'mock-tool-3',
        toolName: 'Vacuum Pump',
        certificationType: 'Safety Inspection',
        certificationNumber: 'SI-2024-001',
        issuingAuthority: 'Dubai Civil Defense',
        issueDate: now.subtract(const Duration(days: 120)),
        expiryDate: now.add(const Duration(days: 60)),
        status: 'Valid',
        inspectorName: 'Hassan Mohammed',
        inspectorId: 'INSP-004',
        location: 'Site B - Marina',
        notes: 'Safety inspection completed',
      ),
      Certification(
        id: '5',
        toolId: 'mock-tool-4',
        toolName: 'Cordless Drill',
        certificationType: 'CE Marking',
        certificationNumber: 'CE-2024-001',
        issuingAuthority: 'European Commission',
        issueDate: now.subtract(const Duration(days: 365)),
        expiryDate: now.add(const Duration(days: 730)),
        status: 'Valid',
        inspectorName: 'European Inspector',
        inspectorId: 'INSP-005',
        location: 'Main Office',
        notes: 'CE marking certificate valid',
      ),
      Certification(
        id: '6',
        toolId: 'mock-tool-5',
        toolName: 'Safety Harness',
        certificationType: 'Safety Inspection',
        certificationNumber: 'SI-2023-001',
        issuingAuthority: 'Dubai Civil Defense',
        issueDate: now.subtract(const Duration(days: 400)),
        expiryDate: now.subtract(const Duration(days: 40)),
        status: 'Expired',
        inspectorName: 'Ahmed Al-Rashid',
        inspectorId: 'INSP-001',
        location: 'Site A - Downtown',
        notes: 'Safety inspection certificate expired',
      ),
    ];
  }

  static List<Certification> getExpiringCertifications() {
    return getMockCertifications().where((cert) => cert.isExpiringSoon).toList();
  }

  static List<Certification> getExpiredCertifications() {
    return getMockCertifications().where((cert) => cert.isExpired).toList();
  }

  static List<Certification> getValidCertifications() {
    return getMockCertifications().where((cert) => cert.isValid).toList();
  }
}
