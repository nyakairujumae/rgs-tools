-- ===========================================
-- Admin Positions System - Database Migration
-- ===========================================
-- This script creates a flexible position-based permission system
-- Run this in your Supabase SQL Editor

-- ===========================================
-- STEP 1: Create admin_positions table
-- ===========================================

CREATE TABLE IF NOT EXISTS admin_positions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index
CREATE INDEX IF NOT EXISTS idx_admin_positions_active ON admin_positions(is_active) WHERE is_active = true;

-- ===========================================
-- STEP 2: Create position_permissions table
-- ===========================================

CREATE TABLE IF NOT EXISTS position_permissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  position_id UUID REFERENCES admin_positions(id) ON DELETE CASCADE,
  permission_name TEXT NOT NULL,
  is_granted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(position_id, permission_name)
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_position_permissions_position_id ON position_permissions(position_id);
CREATE INDEX IF NOT EXISTS idx_position_permissions_name ON position_permissions(permission_name);

-- ===========================================
-- STEP 3: Add position_id to users table
-- ===========================================

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS position_id UUID REFERENCES admin_positions(id) ON DELETE SET NULL;

-- Add index
CREATE INDEX IF NOT EXISTS idx_users_position_id ON users(position_id) WHERE role = 'admin';

-- ===========================================
-- STEP 4: Enable RLS
-- ===========================================

ALTER TABLE admin_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE position_permissions ENABLE ROW LEVEL SECURITY;

-- Policies for admin_positions
CREATE POLICY "Anyone can read active positions" ON admin_positions
  FOR SELECT USING (is_active = true);

-- Policies for position_permissions
CREATE POLICY "Anyone can read position permissions" ON position_permissions
  FOR SELECT USING (true);

-- ===========================================
-- STEP 5: Insert default positions
-- ===========================================

-- Insert Super Admin position
INSERT INTO admin_positions (name, description, is_active)
VALUES 
  ('Super Admin', 'Full system access with all permissions', true),
  ('Admin', 'Standard admin with most permissions, cannot manage other admins', true),
  ('Inventory Manager', 'Can manage tools and view reports, cannot manage users', true),
  ('HR Admin', 'Can manage technicians and view reports, cannot manage tools', true),
  ('Finance Admin', 'Can view and export reports, read-only access', true),
  ('Viewer', 'Read-only access to tools and reports', true)
ON CONFLICT (name) DO NOTHING;

-- ===========================================
-- STEP 6: Insert permissions for each position
-- ===========================================

-- Get position IDs (we'll use a function to make this dynamic)
DO $$
DECLARE
  super_admin_id UUID;
  admin_id UUID;
  inventory_manager_id UUID;
  hr_admin_id UUID;
  finance_admin_id UUID;
  viewer_id UUID;
BEGIN
  -- Get position IDs
  SELECT id INTO super_admin_id FROM admin_positions WHERE name = 'Super Admin';
  SELECT id INTO admin_id FROM admin_positions WHERE name = 'Admin';
  SELECT id INTO inventory_manager_id FROM admin_positions WHERE name = 'Inventory Manager';
  SELECT id INTO hr_admin_id FROM admin_positions WHERE name = 'HR Admin';
  SELECT id INTO finance_admin_id FROM admin_positions WHERE name = 'Finance Admin';
  SELECT id INTO viewer_id FROM admin_positions WHERE name = 'Viewer';

  -- Super Admin - All permissions
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (super_admin_id, 'can_manage_users', true),
    (super_admin_id, 'can_manage_admins', true),
    (super_admin_id, 'can_delete_users', true),
    (super_admin_id, 'can_view_all_tools', true),
    (super_admin_id, 'can_add_tools', true),
    (super_admin_id, 'can_edit_tools', true),
    (super_admin_id, 'can_delete_tools', true),
    (super_admin_id, 'can_manage_tool_assignments', true),
    (super_admin_id, 'can_update_tool_condition', true),
    (super_admin_id, 'can_manage_technicians', true),
    (super_admin_id, 'can_approve_technicians', true),
    (super_admin_id, 'can_view_reports', true),
    (super_admin_id, 'can_export_reports', true),
    (super_admin_id, 'can_view_financial_data', true),
    (super_admin_id, 'can_view_approval_workflows', true),
    (super_admin_id, 'can_manage_settings', true),
    (super_admin_id, 'can_bulk_import', true),
    (super_admin_id, 'can_delete_data', true),
    (super_admin_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Admin - Most permissions except managing admins
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (admin_id, 'can_manage_users', false),
    (admin_id, 'can_manage_admins', false),
    (admin_id, 'can_delete_users', false),
    (admin_id, 'can_view_all_tools', true),
    (admin_id, 'can_add_tools', true),
    (admin_id, 'can_edit_tools', true),
    (admin_id, 'can_delete_tools', false),
    (admin_id, 'can_manage_tool_assignments', true),
    (admin_id, 'can_update_tool_condition', true),
    (admin_id, 'can_manage_technicians', true),
    (admin_id, 'can_approve_technicians', true),
    (admin_id, 'can_view_reports', true),
    (admin_id, 'can_export_reports', true),
    (admin_id, 'can_view_financial_data', true),
    (admin_id, 'can_view_approval_workflows', true),
    (admin_id, 'can_manage_settings', false),
    (admin_id, 'can_bulk_import', false),
    (admin_id, 'can_delete_data', false),
    (admin_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Inventory Manager - Tool management and reports
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (inventory_manager_id, 'can_manage_users', false),
    (inventory_manager_id, 'can_manage_admins', false),
    (inventory_manager_id, 'can_delete_users', false),
    (inventory_manager_id, 'can_view_all_tools', true),
    (inventory_manager_id, 'can_add_tools', true),
    (inventory_manager_id, 'can_edit_tools', true),
    (inventory_manager_id, 'can_delete_tools', false),
    (inventory_manager_id, 'can_manage_tool_assignments', true),
    (inventory_manager_id, 'can_update_tool_condition', true),
    (inventory_manager_id, 'can_manage_technicians', false),
    (inventory_manager_id, 'can_approve_technicians', false),
    (inventory_manager_id, 'can_view_reports', true),
    (inventory_manager_id, 'can_export_reports', true),
    (inventory_manager_id, 'can_view_financial_data', false),
    (inventory_manager_id, 'can_view_approval_workflows', false),
    (inventory_manager_id, 'can_manage_settings', false),
    (inventory_manager_id, 'can_bulk_import', false),
    (inventory_manager_id, 'can_delete_data', false),
    (inventory_manager_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- HR Admin - Technician management and reports
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (hr_admin_id, 'can_manage_users', false),
    (hr_admin_id, 'can_manage_admins', false),
    (hr_admin_id, 'can_delete_users', false),
    (hr_admin_id, 'can_view_all_tools', false),
    (hr_admin_id, 'can_add_tools', false),
    (hr_admin_id, 'can_edit_tools', false),
    (hr_admin_id, 'can_delete_tools', false),
    (hr_admin_id, 'can_manage_tool_assignments', false),
    (hr_admin_id, 'can_update_tool_condition', false),
    (hr_admin_id, 'can_manage_technicians', true),
    (hr_admin_id, 'can_approve_technicians', true),
    (hr_admin_id, 'can_view_reports', true),
    (hr_admin_id, 'can_export_reports', true),
    (hr_admin_id, 'can_view_financial_data', false),
    (hr_admin_id, 'can_view_approval_workflows', true),
    (hr_admin_id, 'can_manage_settings', false),
    (hr_admin_id, 'can_bulk_import', false),
    (hr_admin_id, 'can_delete_data', false),
    (hr_admin_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Finance Admin - Reports and exports only
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (finance_admin_id, 'can_manage_users', false),
    (finance_admin_id, 'can_manage_admins', false),
    (finance_admin_id, 'can_delete_users', false),
    (finance_admin_id, 'can_view_all_tools', false),
    (finance_admin_id, 'can_add_tools', false),
    (finance_admin_id, 'can_edit_tools', false),
    (finance_admin_id, 'can_delete_tools', false),
    (finance_admin_id, 'can_manage_tool_assignments', false),
    (finance_admin_id, 'can_update_tool_condition', false),
    (finance_admin_id, 'can_manage_technicians', false),
    (finance_admin_id, 'can_approve_technicians', false),
    (finance_admin_id, 'can_view_reports', true),
    (finance_admin_id, 'can_export_reports', true),
    (finance_admin_id, 'can_view_financial_data', true),
    (finance_admin_id, 'can_view_approval_workflows', false),
    (finance_admin_id, 'can_manage_settings', false),
    (finance_admin_id, 'can_bulk_import', false),
    (finance_admin_id, 'can_delete_data', false),
    (finance_admin_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Viewer - Read-only
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (viewer_id, 'can_manage_users', false),
    (viewer_id, 'can_manage_admins', false),
    (viewer_id, 'can_delete_users', false),
    (viewer_id, 'can_view_all_tools', true),
    (viewer_id, 'can_add_tools', false),
    (viewer_id, 'can_edit_tools', false),
    (viewer_id, 'can_delete_tools', false),
    (viewer_id, 'can_manage_tool_assignments', false),
    (viewer_id, 'can_update_tool_condition', false),
    (viewer_id, 'can_manage_technicians', false),
    (viewer_id, 'can_approve_technicians', false),
    (viewer_id, 'can_view_reports', true),
    (viewer_id, 'can_export_reports', false),
    (viewer_id, 'can_view_financial_data', false),
    (viewer_id, 'can_view_approval_workflows', false),
    (viewer_id, 'can_manage_settings', false),
    (viewer_id, 'can_bulk_import', false),
    (viewer_id, 'can_delete_data', false),
    (viewer_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;
END $$;

-- ===========================================
-- STEP 7: Assign default position to existing admins
-- ===========================================

-- Assign "Admin" position to all existing admins
UPDATE users
SET position_id = (
  SELECT id FROM admin_positions WHERE name = 'Admin' LIMIT 1
)
WHERE role = 'admin' AND position_id IS NULL;

-- ===========================================
-- STEP 8: Create helper function to check permissions
-- ===========================================

CREATE OR REPLACE FUNCTION user_has_permission(
  user_id_param UUID,
  permission_name_param TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
  user_position_id UUID;
  has_permission BOOLEAN;
BEGIN
  -- Get user's role
  SELECT role INTO user_role FROM users WHERE id = user_id_param;
  
  -- If not admin, return false
    IF user_role != 'admin' THEN
    RETURN false;
    END IF;
    
  -- Get user's position_id
  SELECT position_id INTO user_position_id FROM users WHERE id = user_id_param;
  
  -- If no position assigned, return false
  IF user_position_id IS NULL THEN
    RETURN false;
  END IF;
  
  -- Check if position has the permission
  SELECT is_granted INTO has_permission
  FROM position_permissions
  WHERE position_id = user_position_id
    AND permission_name = permission_name_param;
  
  -- Return permission status (default to false if not found)
  RETURN COALESCE(has_permission, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 9: Verification Queries
-- ===========================================

-- Check positions were created
SELECT name, description, is_active 
FROM admin_positions 
ORDER BY name;

-- Check permissions for each position
SELECT 
  ap.name as position_name,
  pp.permission_name,
  pp.is_granted
FROM admin_positions ap
LEFT JOIN position_permissions pp ON ap.id = pp.position_id
ORDER BY ap.name, pp.permission_name;

-- Check existing admins have positions assigned
SELECT 
  u.email,
  u.role,
  ap.name as position_name
FROM users u
LEFT JOIN admin_positions ap ON u.position_id = ap.id
WHERE u.role = 'admin'
ORDER BY u.created_at DESC;

-- ===========================================
-- ROLLBACK SCRIPT (if needed)
-- ===========================================

-- To rollback:
-- ALTER TABLE users DROP COLUMN IF EXISTS position_id;
-- DROP TABLE IF EXISTS position_permissions CASCADE;
-- DROP TABLE IF EXISTS admin_positions CASCADE;
-- DROP FUNCTION IF EXISTS user_has_permission(UUID, TEXT);
