-- FINAL FIX: Use SECURITY DEFINER function to bypass RLS for admin_notifications inserts
-- This is the most reliable solution for allowing technicians to create notifications
-- Run this in your Supabase SQL Editor

-- ============================================================================
-- STEP 1: Drop ALL existing policies on admin_notifications
-- ============================================================================

-- Get all policy names and drop them
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'admin_notifications' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON admin_notifications';
    END LOOP;
END $$;

-- ============================================================================
-- STEP 2: Create a SECURITY DEFINER function to insert notifications
-- ============================================================================

-- This function runs with the privileges of the function owner (postgres)
-- and can bypass RLS policies
CREATE OR REPLACE FUNCTION public.insert_admin_notification(
    p_title TEXT,
    p_message TEXT,
    p_technician_name TEXT,
    p_technician_email TEXT,
    p_type TEXT,
    p_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_notification_id UUID;
    v_user_id UUID;
BEGIN
    -- Get the current authenticated user ID
    v_user_id := auth.uid();
    
    -- Verify user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User must be authenticated to create notifications';
    END IF;
    
    -- Insert the notification (bypasses RLS because function is SECURITY DEFINER)
    INSERT INTO admin_notifications (
        title,
        message,
        technician_name,
        technician_email,
        type,
        is_read,
        timestamp,
        data
    ) VALUES (
        p_title,
        p_message,
        p_technician_name,
        p_technician_email,
        p_type,
        false,
        NOW(),
        p_data
    )
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.insert_admin_notification TO authenticated;
GRANT EXECUTE ON FUNCTION public.insert_admin_notification TO anon;

-- ============================================================================
-- STEP 3: Recreate RLS policies for SELECT, UPDATE, DELETE
-- ============================================================================

-- Only admins can read all notifications
CREATE POLICY "Admins can view all notifications" ON admin_notifications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Only admins can update notifications (mark as read, etc.)
CREATE POLICY "Admins can update notifications" ON admin_notifications
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Only admins can delete notifications
CREATE POLICY "Admins can delete notifications" ON admin_notifications
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- NOTE: We don't create an INSERT policy because inserts go through the function

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check that the function was created
SELECT 'Function created:' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'insert_admin_notification';

-- Check policies (should NOT have an INSERT policy)
SELECT 'Current policies:' as info;
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'admin_notifications' 
AND schemaname = 'public'
ORDER BY cmd, policyname;

-- Test the function (uncomment and run while logged in as a technician)
-- SELECT public.insert_admin_notification(
--     'Test Notification',
--     'This is a test',
--     'Test Technician',
--     'test@example.com',
--     'general',
--     '{"test": true}'::jsonb
-- );

