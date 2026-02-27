class Technician {
  final String? id;
  final String? userId; // auth.users id - links technician to their login account
  final String name;
  final String? employeeId;
  final String? phone;
  final String? email;
  final String? department;
  final String? hireDate;
  final String status;
  final String? profilePictureUrl;
  final String? createdAt;

  Technician({
    this.id,
    this.userId,
    required this.name,
    this.employeeId,
    this.phone,
    this.email,
    this.department,
    this.hireDate,
    this.status = 'Active',
    this.profilePictureUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'name': name,
      'employee_id': employeeId,
      'phone': phone,
      'email': email,
      'department': department,
      'hire_date': hireDate,
      'status': status,
      'profile_picture_url': profilePictureUrl,
    };
    
    // Only include id and created_at if they're not null (for updates)
    if (id != null) {
      map['id'] = id;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt;
    }
    
    return map;
  }

  factory Technician.fromMap(Map<String, dynamic> map) {
    return Technician(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      employeeId: map['employee_id'],
      phone: map['phone'],
      email: map['email'],
      department: map['department'],
      hireDate: map['hire_date'],
      status: map['status'],
      profilePictureUrl: map['profile_picture_url'],
      createdAt: map['created_at'],
    );
  }

  Technician copyWith({
    String? id,
    String? userId,
    String? name,
    String? employeeId,
    String? phone,
    String? email,
    String? department,
    String? hireDate,
    String? status,
    String? profilePictureUrl,
    String? createdAt,
  }) {
    return Technician(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      department: department ?? this.department,
      hireDate: hireDate ?? this.hireDate,
      status: status ?? this.status,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

