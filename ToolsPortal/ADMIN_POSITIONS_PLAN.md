# Admin Positions System - Implementation Plan

## 🎯 Overview
Create a flexible position-based system where admins can be assigned to different positions (roles), each with specific permissions. All admins see the same UI, but their actions are restricted based on their position's permissions.

## 📊 System Design

### Core Concept
- **Positions** = Configurable roles (e.g., "Super Admin", "Inventory Manager", "HR Admin", "Finance Admin", "Viewer")
- **Permissions** = Granular abilities (e.g., "can_manage_users", "can_delete_tools", "can_view_reports")
- **Users** = Assigned to a position, inherit that position's permissions

### Example Positions
1. **Super Admin** - Full access to everything
2. **Admin Manager** - Can manage users and admins
3. **Inventory Manager** - Can manage tools, view reports, cannot manage users
4. **HR Admin** - Can manage technicians, view reports, cannot manage tools
5. **Finance Admin** - Can view reports, export data, cannot modify anything
6. **Viewer** - Read-only access to tools and reports

## 🗄️ Database Schema

### 1. Create `admin_positions` table
```sql
CREATE TABLE admin_positions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE, -- e.g., "Super Admin", "Inventory Manager"
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Create `position_permissions` table
```sql
CREATE TABLE position_permissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  position_id UUID REFERENCES admin_positions(id) ON DELETE CASCADE,
  permission_name TEXT NOT NULL, -- e.g., "can_manage_users", "can_add_tools"
  is_granted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(position_id, permission_name)
);
```

### 3. Update `users` table
```sql
-- Add position_id column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS position_id UUID REFERENCES admin_positions(id) ON DELETE SET NULL;

-- Add index
CREATE INDEX IF NOT EXISTS idx_users_position_id ON users(position_id) WHERE role = 'admin';
```

### 4. Permission Names (Standard Set)
```sql
-- These are the standard permissions we'll use
-- Can be extended later

-- User Management
'can_manage_users'           -- Assign roles, create/delete users
'can_manage_admins'          -- Assign positions to other admins
'can_delete_users'           -- Permanently delete users

-- Tool Management
'can_view_all_tools'         -- See all tools (not just assigned)
'can_add_tools'              -- Create new tools
'can_edit_tools'             -- Modify existing tools
'can_delete_tools'           -- Remove tools
'can_manage_tool_assignments' -- Assign/unassign tools
'can_update_tool_condition'   -- Change tool condition/status

-- Technician Management
'can_manage_technicians'      -- Create/edit/delete technicians
'can_approve_technicians'     -- Approve pending technician registrations

-- Reports & Data
'can_view_reports'           -- Access reports screen
'can_export_reports'         -- Export reports to PDF/Excel
'can_view_financial_data'    -- See financial summaries
'can_view_approval_workflows' -- See approval workflows

-- System
'can_manage_settings'        -- Access system settings
'can_bulk_import'            -- Import data in bulk
'can_delete_data'            -- Delete critical data
'can_manage_notifications'   -- Configure notifications
```

## 📱 Flutter Implementation

### 1. Create Position Model (`lib/models/admin_position.dart`)
```dart
class AdminPosition {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final List<PositionPermission> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminPosition({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminPosition.fromJson(Map<String, dynamic> json) {
    return AdminPosition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((p) => PositionPermission.fromJson(p))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Check if position has a specific permission
  bool hasPermission(String permissionName) {
    return permissions.any((p) => 
      p.permissionName == permissionName && p.isGranted
    );
  }
}

class PositionPermission {
  final String id;
  final String positionId;
  final String permissionName;
  final bool isGranted;

  PositionPermission({
    required this.id,
    required this.positionId,
    required this.permissionName,
    required this.isGranted,
  });

  factory PositionPermission.fromJson(Map<String, dynamic> json) {
    return PositionPermission(
      id: json['id'] as String,
      positionId: json['position_id'] as String,
      permissionName: json['permission_name'] as String,
      isGranted: json['is_granted'] as bool,
    );
  }
}
```

### 2. Create Position Service (`lib/services/admin_position_service.dart`)
```dart
class AdminPositionService {
  // Get all positions
  static Future<List<AdminPosition>> getAllPositions() async {
    final positionsResponse = await SupabaseService.client
          .from('admin_positions')
        .select('*, position_permissions(*)')
          .eq('is_active', true)
        .order('name');

    return (positionsResponse as List)
          .map((json) => AdminPosition.fromJson(json))
          .toList();
  }

  // Get position by ID
  static Future<AdminPosition?> getPositionById(String positionId) async {
    final response = await SupabaseService.client
        .from('admin_positions')
        .select('*, position_permissions(*)')
        .eq('id', positionId)
        .maybeSingle();

    if (response == null) return null;
    return AdminPosition.fromJson(response);
  }

  // Get user's position
  static Future<AdminPosition?> getUserPosition(String userId) async {
      final userResponse = await SupabaseService.client
          .from('users')
        .select('position_id')
          .eq('id', userId)
          .maybeSingle();

    if (userResponse == null || userResponse['position_id'] == null) {
      return null;
    }

    return getPositionById(userResponse['position_id'] as String);
  }

  // Check if user has permission
  static Future<bool> userHasPermission(
    String userId,
    String permissionName,
  ) async {
    final position = await getUserPosition(userId);
    if (position == null) return false;
    return position.hasPermission(permissionName);
  }
}
```

### 3. Update AuthProvider (`lib/providers/auth_provider.dart`)
```dart
class AuthProvider with ChangeNotifier {
  // ... existing code ...
  
  AdminPosition? _adminPosition;
  AdminPosition? get adminPosition => _adminPosition;
  
  // Load admin position
  Future<void> _loadAdminPosition() async {
    if (_user == null || _userRole != UserRole.admin) {
      _adminPosition = null;
      return;
    }
    
    try {
      _adminPosition = await AdminPositionService.getUserPosition(_user!.id);
    } catch (e) {
      debugPrint('⚠️ Error loading admin position: $e');
      _adminPosition = null;
    }
  }
  
  // Permission check helper
  bool hasPermission(String permissionName) {
    if (_userRole != UserRole.admin) return false;
    if (_adminPosition == null) return false;
    return _adminPosition!.hasPermission(permissionName);
  }
  
  // Convenience getters
  bool get canManageUsers => hasPermission('can_manage_users');
  bool get canManageAdmins => hasPermission('can_manage_admins');
  bool get canAddTools => hasPermission('can_add_tools');
  bool get canEditTools => hasPermission('can_edit_tools');
  bool get canDeleteTools => hasPermission('can_delete_tools');
  // ... etc for all permissions
}
```

### 4. Update Permission Checks Throughout App
Replace hardcoded `authProvider.isAdmin` checks with:
```dart
// Old way
if (authProvider.isAdmin) { ... }

// New way
if (authProvider.hasPermission('can_add_tools')) { ... }
```

### 5. Update Registration Screen
- Show position dropdown when registering as admin
- Load positions from database
- Default to a basic "Admin" position if none selected

### 6. Create Position Management Screen
- List all positions
- Create/edit positions
- Assign permissions to positions
- Assign positions to users
- View which users have which positions

## 🎨 UI Changes

### 1. Admin Registration
- Add "Position" dropdown (loads from `admin_positions` table)
- Show position description
- Default to first available position

### 2. Position Management Screen (New)
- List of all positions
- Create new position button
- Edit position permissions
- Assign position to users
- Visual permission matrix

### 3. All Admin Screens
- Same UI for all admins
- Buttons/actions hidden based on permissions
- Show "Access Denied" message if trying to perform unauthorized action

## 📋 Implementation Steps

### Phase 1: Database Setup
1. ✅ Create `admin_positions` table
2. ✅ Create `position_permissions` table
3. ✅ Add `position_id` to `users` table
4. ✅ Insert default positions with permissions
5. ✅ Test database structure

### Phase 2: Core Models & Services
1. ✅ Create `AdminPosition` model
2. ✅ Create `AdminPositionService`
3. ✅ Update `AuthProvider` to load position
4. ✅ Add permission check methods
5. ✅ Test position loading

### Phase 3: Registration & Assignment
1. ✅ Update admin registration to select position
2. ✅ Create position management screen
3. ✅ Add position assignment functionality
4. ✅ Test registration and assignment

### Phase 4: Permission Enforcement
1. ✅ Replace all `isAdmin` checks with permission checks
2. ✅ Hide/show UI elements based on permissions
3. ✅ Add server-side permission validation
4. ✅ Test all permission scenarios

### Phase 5: Position Management UI
1. ✅ Create position CRUD screen
2. ✅ Permission assignment UI
3. ✅ User position assignment UI
4. ✅ Test position management

### Phase 6: Testing & Polish
1. ✅ Test all positions
2. ✅ Test permission enforcement
3. ✅ UI/UX polish
4. ✅ Documentation

## 🔒 Security Considerations

1. **Server-Side Validation**
   - Always validate permissions on the server (RLS policies)
   - Never trust client-side checks alone

2. **Default Position**
   - New admins should get a default "Viewer" or "Admin" position
   - Only users with `can_manage_admins` can assign positions

3. **Position Changes**
   - Log all position changes
   - Require confirmation for position changes
   - Prevent self-demotion if it removes critical permissions

## 📝 Default Positions Setup

We'll create these default positions:

1. **Super Admin** - All permissions enabled
2. **Admin** - Most permissions, except managing other admins
3. **Inventory Manager** - Tool management, reports, no user management
4. **Viewer** - Read-only access

You can add more positions as needed through the UI!

## 🚀 Next Steps

1. Review this plan
2. Run database migration
3. Start implementation
4. Test with different positions
