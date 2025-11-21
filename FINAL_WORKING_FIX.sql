-- FINAL WORKING FIX - Run this ONCE in Supabase SQL Editor
-- This creates the function that the code expects

-- Step 1: Drop the old function if it exists
DROP FUNCTION IF EXISTS public.insert_admin_notification(TEXT, TEXT, TEXT, TEXT, TEXT, JSONB);
DROP FUNCTION IF EXISTS public.create_admin_notification(TEXT, TEXT, TEXT, TEXT, TEXT, JSONB);

-- Step 2: Create the function with the name the code uses
CREATE OR REPLACE FUNCTION public.create_admin_notification(
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
    v_id UUID;
BEGIN
    INSERT INTO admin_notifications (title, message, technician_name, technician_email, type, is_read, timestamp, data)
    VALUES (p_title, p_message, p_technician_name, p_technician_email, p_type, false, NOW(), p_data)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$;

-- Step 3: Grant permissions
GRANT EXECUTE ON FUNCTION public.create_admin_notification TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_admin_notification TO anon;

-- Step 4: Fix RLS policies - drop all INSERT policies
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'admin_notifications' AND schemaname = 'public' AND cmd = 'INSERT') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON admin_notifications';
    END LOOP;
END $$;

-- Step 5: Ensure admin policies exist
DROP POLICY IF EXISTS "Admins can view all notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Admins can update notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Admins can delete notifications" ON admin_notifications;

CREATE POLICY "Admins can view all notifications" ON admin_notifications
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
  );

CREATE POLICY "Admins can update notifications" ON admin_notifications
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
  );

CREATE POLICY "Admins can delete notifications" ON admin_notifications
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin')
  );

-- Verify
SELECT 'SUCCESS: Function create_admin_notification created!' as status;

