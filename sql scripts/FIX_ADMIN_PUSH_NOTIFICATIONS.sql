-- =====================================================
-- FIX ADMIN PUSH NOTIFICATIONS - RLS Bypass
-- =====================================================
-- This creates an RPC function to get admin user IDs
-- Bypassing RLS so push notifications can find admins

SET search_path = public;

-- ===========================================
-- Create RPC Function to Get Admin User IDs
-- ===========================================

CREATE OR REPLACE FUNCTION public.get_admin_user_ids()
RETURNS TABLE(id UUID, email TEXT, role TEXT)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.email, u.role
  FROM users u
  WHERE u.role = 'admin';
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_admin_user_ids() TO authenticated, anon;

-- ===========================================
-- Verify Function Works
-- ===========================================

-- Test the function
SELECT * FROM public.get_admin_user_ids();

-- ===========================================
-- NOTES:
-- ===========================================
-- 1. This function uses SECURITY DEFINER to bypass RLS
-- 2. It returns admin user IDs that can be used for push notifications
-- 3. Update PushNotificationService.sendToAdmins() to use this function
-- ===========================================

