# Admin Hierarchy System - Implementation Plan

## 🎯 Overview
Add a hierarchical role system for admins, allowing different admin roles with varying permissions. Admins can assign roles to other admins during registration and management.

## 📊 Proposed Admin Role Hierarchy

### Role Levels (from highest to lowest):
1. **Super Admin** - Full system access
   - Can manage all admins (assign/remove roles)
   - Can delete users and data
   - Can manage system settings
   - Can view all reports
   - Can bulk import/export

2. **Admin Manager** - User and role management
   - Can manage users (assign roles to admins and technicians)
   - Can manage technicians
   - Can view reports
   - Cannot delete critical data
   - Cannot manage system settings

3. **Admin** - Standard admin (current default)
   - Can manage tools
   - Can manage technicians
   - Can view reports
   - Cannot manage other admins
   - Cannot delete users

4. **Admin Assistant** - Limited admin
   - Can view all tools
   - Can view reports (read-only)
   - Can manage tool assignments
   - Cannot add/edit/delete tools
   - Cannot manage users

## 🗄️ Database Schema Changes

### 1. Update `users` table
```sql
-- Add admin_role column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS admin_role TEXT CHECK (admin_role IN ('super_admin', 'admin_manager', 'admin', 'admin_assistant'));

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_admin_role ON users(admin_role) WHERE role = 'admin';

-- Update existing admins to have 'admin' as default admin_role
UPDATE users 
SET admin_role = 'admin' 
WHERE role = 'admin' AND (admin_role IS NULL OR admin_role = '');
```

### 2. Create `admin_permissions` table (optional - for future flexibility)
```sql
CREATE TABLE IF NOT EXISTS admin_permissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_role TEXT NOT NULL UNIQUE,
  can_manage_admins BOOLEAN DEFAULT false,
  can_manage_users BOOLEAN DEFAULT false,
  can_delete_users BOOLEAN DEFAULT false,
  can_manage_tools BOOLEAN DEFAULT true,
  can_add_tools BOOLEAN DEFAULT true,
  can_edit_tools BOOLEAN DEFAULT true,
  can_delete_tools BOOLEAN DEFAULT false,
  can_manage_technicians BOOLEAN DEFAULT true,
  can_view_reports BOOLEAN DEFAULT true,
  can_export_reports BOOLEAN DEFAULT true,
  can_manage_settings BOOLEAN DEFAULT false,
  can_bulk_import BOOLEAN DEFAULT false,
  can_delete_data BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default permissions
INSERT INTO admin_permissions (admin_role, can_manage_admins, can_manage_users, can_delete_users, can_manage_tools, can_add_tools, can_edit_tools, can_delete_tools, can_manage_technicians, can_view_reports, can_export_reports, can_manage_settings, can_bulk_import, can_delete_data)
VALUES
  ('super_admin', true, true, true, true, true, true, true, true, true, true, true, true, true),
  ('admin_manager', true, true, false, true, true, true, false, true, true, true, false, false, false),
  ('admin', false, false, false, true, true, true, false, true, true, true, false, false, false),
  ('admin_assistant', false, false, false, true, false, false, false, false, true, false, false, false, false)
ON CONFLICT (admin_role) DO NOTHING;
```

## 📱 Flutter Code Changes

### 1. Update `UserRole` Model (`lib/models/user_role.dart`)
```dart
enum UserRole {
  admin,
  technician,
  pending,
}

// NEW: Admin sub-roles
enum AdminRole {
  superAdmin,      // 'super_admin'
  adminManager,    // 'admin_manager'
  admin,           // 'admin' (default)
  adminAssistant,  // 'admin_assistant'
}

extension AdminRoleExtension on AdminRole {
  String get value {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.adminManager:
        return 'admin_manager';
      case AdminRole.admin:
        return 'admin';
      case AdminRole.adminAssistant:
        return 'admin_assistant';
    }
  }

  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.adminManager:
        return 'Admin Manager';
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.adminAssistant:
        return 'Admin Assistant';
    }
  }

  static AdminRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'super_admin':
        return AdminRole.superAdmin;
      case 'admin_manager':
        return AdminRole.adminManager;
      case 'admin':
        return AdminRole.admin;
      case 'admin_assistant':
        return AdminRole.adminAssistant;
      default:
        return AdminRole.admin; // Default
    }
  }
}
```

### 2. Update Permission Checks (`lib/models/user_role.dart`)
```dart
extension UserRoleExtension on UserRole {
  // Add adminRole parameter to permission checks
  bool canManageUsers({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole == AdminRole.superAdmin || adminRole == AdminRole.adminManager;
  }

  bool canManageAdmins({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole == AdminRole.superAdmin || adminRole == AdminRole.adminManager;
  }

  bool canDeleteUsers({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole == AdminRole.superAdmin;
  }

  bool canAddTools({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole != AdminRole.adminAssistant;
  }

  bool canEditTools({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole != AdminRole.adminAssistant;
  }

  bool canDeleteTools({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole == AdminRole.superAdmin || adminRole == AdminRole.adminManager;
  }

  bool canManageSettings({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole == AdminRole.superAdmin;
  }

  bool canBulkImport({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole == AdminRole.superAdmin;
  }

  bool canDeleteData({AdminRole? adminRole}) {
    if (this != UserRole.admin) return false;
    if (adminRole == null) return false;
    return adminRole == AdminRole.superAdmin;
  }
}
```

### 3. Update `AuthProvider` (`lib/providers/auth_provider.dart`)
```dart
class AuthProvider with ChangeNotifier {
  // ... existing code ...
  
  AdminRole? _adminRole;
  
  AdminRole? get adminRole => _adminRole;
  
  bool get isSuperAdmin => _userRole == UserRole.admin && _adminRole == AdminRole.superAdmin;
  bool get isAdminManager => _userRole == UserRole.admin && _adminRole == AdminRole.adminManager;
  bool get isAdminAssistant => _userRole == UserRole.admin && _adminRole == AdminRole.adminAssistant;
  
  // Load admin role from database
  Future<void> _loadAdminRole() async {
    if (_user == null || _userRole != UserRole.admin) {
      _adminRole = null;
      return;
    }
    
    try {
      final response = await SupabaseService.client
          .from('users')
          .select('admin_role')
          .eq('id', _user!.id)
          .maybeSingle();
      
      if (response != null && response['admin_role'] != null) {
        _adminRole = AdminRoleExtension.fromString(response['admin_role']);
      } else {
        // Default to 'admin' if not set
        _adminRole = AdminRole.admin;
      }
    } catch (e) {
      debugPrint('⚠️ Error loading admin role: $e');
      _adminRole = AdminRole.admin; // Default fallback
    }
  }
  
  // Call _loadAdminRole() in initialize() after loading user role
}
```

### 4. Update Registration Screens

#### `lib/screens/admin_registration_screen.dart`
- Add dropdown for admin role selection
- Only show if current user is Super Admin or Admin Manager
- Default to 'admin' if not specified

#### `lib/screens/role_selection_screen.dart`
- If user selects "Register as Admin", check if they need to select admin role
- For new registrations, default to 'admin' role
- Only Super Admin/Admin Manager can assign higher roles during registration

### 5. Update Admin Role Management Screen
- Show admin_role column
- Allow Super Admin/Admin Manager to change admin roles
- Display role hierarchy visually
- Show permissions for each role

### 6. Update All Permission Checks
- Update all screens that check `authProvider.isAdmin` to also check `adminRole`
- Use new permission methods: `canManageUsers(adminRole: authProvider.adminRole)`
- Update UI to hide/show features based on admin role

## 🎨 UI/UX Changes

### 1. Admin Registration Screen
- Add "Admin Role" dropdown (if registering as admin)
- Show role descriptions
- Default to "Admin" for new registrations

### 2. Admin Role Management Screen
- Add "Admin Role" column
- Show role badges with colors:
  - Super Admin: Red/Gold
  - Admin Manager: Blue
  - Admin: Green
  - Admin Assistant: Gray
- Add filter by admin role
- Allow role changes (with confirmation)

### 3. Admin Home Screen
- Show current admin role badge
- Hide features based on permissions
- Show "Manage Admin Roles" menu item (only for Super Admin/Admin Manager)

## 📋 Implementation Steps

### Phase 1: Database Setup
1. ✅ Run SQL migration to add `admin_role` column
2. ✅ Create `admin_permissions` table (optional)
3. ✅ Set default admin_role for existing admins
4. ✅ Test database changes

### Phase 2: Core Models & Providers
1. ✅ Create `AdminRole` enum
2. ✅ Update `AuthProvider` to load admin role
3. ✅ Update permission checks
4. ✅ Test role loading

### Phase 3: Registration Flow
1. ✅ Update admin registration screen
2. ✅ Add admin role selection dropdown
3. ✅ Update registration logic to save admin_role
4. ✅ Test registration with different roles

### Phase 4: Management UI
1. ✅ Update admin role management screen
2. ✅ Add role assignment functionality
3. ✅ Add role filtering
4. ✅ Test role changes

### Phase 5: Permission Enforcement
1. ✅ Update all screens to check admin role
2. ✅ Hide/show features based on permissions
3. ✅ Add permission checks to API calls
4. ✅ Test all permission scenarios

### Phase 6: Testing & Refinement
1. ✅ Test all admin roles
2. ✅ Test role assignment
3. ✅ Test permission enforcement
4. ✅ UI/UX polish

## 🔒 Security Considerations

1. **Role Assignment Protection**
   - Only Super Admin and Admin Manager can assign admin roles
   - Prevent self-demotion (Super Admin can't remove their own role)
   - Log all role changes

2. **Permission Checks**
   - Always check permissions server-side (RLS policies)
   - Never trust client-side permission checks alone
   - Add RLS policies for admin_role-based access

3. **Default Roles**
   - New admin registrations default to 'admin' (lowest full admin)
   - Only existing Super Admin/Admin Manager can promote

## 📝 SQL Migration Script

See `ADMIN_HIERARCHY_MIGRATION.sql` (to be created)

## 🚀 Next Steps

1. Review and approve this plan
2. Create SQL migration script
3. Start with Phase 1 (Database Setup)
4. Implement incrementally, testing each phase



