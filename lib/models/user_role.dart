enum UserRole {
  admin,
  technician,
  pending,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.technician:
        return 'Technician';
      case UserRole.pending:
        return 'Pending Approval';
    }
  }

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.technician:
        return 'technician';
      case UserRole.pending:
        return 'pending';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'technician':
        return UserRole.technician;
      case 'pending':
        return UserRole.pending;
      default:
        return UserRole.pending; // Default to pending for new registrations
    }
  }

  // Admin permissions
  bool get canManageUsers => this == UserRole.admin;
  bool get canManageTools => this == UserRole.admin;
  bool get canManageTechnicians => this == UserRole.admin;
  bool get canViewReports => this == UserRole.admin;
  bool get canManageSettings => this == UserRole.admin;
  bool get canBulkImport => this == UserRole.admin;
  bool get canDeleteData => this == UserRole.admin;

  // Technician permissions
  bool get canCheckoutTools => true; // Both roles can checkout tools
  bool get canCheckinTools => true; // Both roles can checkin tools
  bool get canViewAssignedTools => true; // Both roles can view their assigned tools
  bool get canViewAllTools => this == UserRole.admin; // Only admin can view all tools
  bool get canViewSharedTools => true; // Both roles can view shared tools
  bool get canUpdateToolCondition => this == UserRole.admin; // Only admin can update tool condition
  bool get canAddTools => this == UserRole.admin; // Only admin can add tools
  bool get canEditTools => this == UserRole.admin; // Only admin can edit tools
}

