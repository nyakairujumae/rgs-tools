-- ===========================================
-- Admin Hierarchy System - Database Migration
-- ===========================================
-- This script adds admin role hierarchy support to the users table
-- Run this in your Supabase SQL Editor

-- ===========================================
-- STEP 1: Add admin_role column to users table
-- ===========================================

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS admin_role TEXT CHECK (admin_role IN ('super_admin', 'admin_manager', 'admin', 'admin_assistant'));

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_users_admin_role ON users(admin_role) WHERE role = 'admin';

-- ===========================================
-- STEP 2: Set default admin_role for existing admins
-- ===========================================

-- Update existing admins to have 'admin' as default admin_role
UPDATE users 
SET admin_role = 'admin' 
WHERE role = 'admin' AND (admin_role IS NULL OR admin_role = '');

-- ===========================================
-- STEP 3: Create admin_permissions table (optional - for future flexibility)
-- ===========================================

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

-- Insert default permissions for each admin role
INSERT INTO admin_permissions (admin_role, can_manage_admins, can_manage_users, can_delete_users, can_manage_tools, can_add_tools, can_edit_tools, can_delete_tools, can_manage_technicians, can_view_reports, can_export_reports, can_manage_settings, can_bulk_import, can_delete_data)
VALUES
  ('super_admin', true, true, true, true, true, true, true, true, true, true, true, true, true),
  ('admin_manager', true, true, false, true, true, true, false, true, true, true, false, false, false),
  ('admin', false, false, false, true, true, true, false, true, true, true, false, false, false),
  ('admin_assistant', false, false, false, true, false, false, false, false, true, false, false, false, false)
ON CONFLICT (admin_role) DO UPDATE SET
  can_manage_admins = EXCLUDED.can_manage_admins,
  can_manage_users = EXCLUDED.can_manage_users,
  can_delete_users = EXCLUDED.can_delete_users,
  can_manage_tools = EXCLUDED.can_manage_tools,
  can_add_tools = EXCLUDED.can_add_tools,
  can_edit_tools = EXCLUDED.can_edit_tools,
  can_delete_tools = EXCLUDED.can_delete_tools,
  can_manage_technicians = EXCLUDED.can_manage_technicians,
  can_view_reports = EXCLUDED.can_view_reports,
  can_export_reports = EXCLUDED.can_export_reports,
  can_manage_settings = EXCLUDED.can_manage_settings,
  can_bulk_import = EXCLUDED.can_bulk_import,
  can_delete_data = EXCLUDED.can_delete_data,
  updated_at = NOW();

-- ===========================================
-- STEP 4: Enable RLS on admin_permissions table
-- ===========================================

ALTER TABLE admin_permissions ENABLE ROW LEVEL SECURITY;

-- Policy: All authenticated users can read permissions (needed for UI)
CREATE POLICY "Anyone can read admin permissions" ON admin_permissions
  FOR SELECT USING (true);

-- Only admins can modify permissions (this would need to be enforced in application code)
-- For now, we'll rely on application-level checks

-- ===========================================
-- STEP 5: Create function to get admin permissions
-- ===========================================

CREATE OR REPLACE FUNCTION get_admin_permissions(user_admin_role TEXT)
RETURNS TABLE (
  can_manage_admins BOOLEAN,
  can_manage_users BOOLEAN,
  can_delete_users BOOLEAN,
  can_manage_tools BOOLEAN,
  can_add_tools BOOLEAN,
  can_edit_tools BOOLEAN,
  can_delete_tools BOOLEAN,
  can_manage_technicians BOOLEAN,
  can_view_reports BOOLEAN,
  can_export_reports BOOLEAN,
  can_manage_settings BOOLEAN,
  can_bulk_import BOOLEAN,
  can_delete_data BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ap.can_manage_admins,
    ap.can_manage_users,
    ap.can_delete_users,
    ap.can_manage_tools,
    ap.can_add_tools,
    ap.can_edit_tools,
    ap.can_delete_tools,
    ap.can_manage_technicians,
    ap.can_view_reports,
    ap.can_export_reports,
    ap.can_manage_settings,
    ap.can_bulk_import,
    ap.can_delete_data
  FROM admin_permissions ap
  WHERE ap.admin_role = user_admin_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 6: Update trigger to set default admin_role
-- ===========================================

-- Update the email confirmation trigger to set default admin_role
CREATE OR REPLACE FUNCTION public.handle_email_confirmed_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_admin_role TEXT;
BEGIN
  -- Only create user record if email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    -- Email was just confirmed - now create the user record
    user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'technician');
    user_admin_role := COALESCE(NEW.raw_user_meta_data->>'admin_role', 'admin');
    
    -- If role is not admin, admin_role should be NULL
    IF user_role != 'admin' THEN
      user_admin_role := NULL;
    END IF;
    
    -- Create user record in public.users table
    INSERT INTO public.users (id, email, full_name, role, admin_role, created_at, updated_at)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      user_role,
      user_admin_role,
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      role = EXCLUDED.role,
      admin_role = EXCLUDED.admin_role,
      updated_at = NOW();
    
    -- For technicians, create pending approval
    IF user_role = 'technician' THEN
      -- Create pending approval record
      INSERT INTO public.pending_user_approvals (
        user_id,
        email,
        full_name,
        status,
        submitted_at
      )
      VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        'pending',
        NOW()
      )
      ON CONFLICT (user_id) DO NOTHING;
      
      RAISE NOTICE 'Created user and pending approval for technician: %', NEW.email;
    ELSE
      RAISE NOTICE 'Created user record for admin with role %: %', user_admin_role, NEW.email;
    END IF;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the trigger
    RAISE WARNING 'Error in handle_email_confirmed_user for %: %', NEW.email, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 7: Create audit log for role changes (optional)
-- ===========================================

CREATE TABLE IF NOT EXISTS admin_role_changes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  old_admin_role TEXT,
  new_admin_role TEXT,
  changed_by UUID REFERENCES users(id),
  changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_admin_role_changes_user_id ON admin_role_changes(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_role_changes_changed_at ON admin_role_changes(changed_at);

ALTER TABLE admin_role_changes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own role change history
CREATE POLICY "Users can view own role changes" ON admin_role_changes
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Admins can view all role changes (enforced in application)
-- This would need application-level checks

-- ===========================================
-- STEP 8: Verification Queries
-- ===========================================

-- Check that admin_role column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'admin_role';

-- Check existing admins have admin_role set
SELECT id, email, role, admin_role
FROM users
WHERE role = 'admin'
ORDER BY created_at DESC
LIMIT 10;

-- Check admin_permissions table
SELECT * FROM admin_permissions ORDER BY 
  CASE admin_role
    WHEN 'super_admin' THEN 1
    WHEN 'admin_manager' THEN 2
    WHEN 'admin' THEN 3
    WHEN 'admin_assistant' THEN 4
  END;

-- ===========================================
-- ROLLBACK SCRIPT (if needed)
-- ===========================================

-- To rollback, run:
-- ALTER TABLE users DROP COLUMN IF EXISTS admin_role;
-- DROP TABLE IF EXISTS admin_permissions CASCADE;
-- DROP TABLE IF EXISTS admin_role_changes CASCADE;
-- DROP FUNCTION IF EXISTS get_admin_permissions(TEXT);
-- Then restore the original handle_email_confirmed_user() function



