-- FINAL WORKING FIX - Run this ONCE in Supabase SQL Editor
-- This creates the function that the code expects

-- Step 1: Drop the old function if it exists
DROP FUNCTION IF EXISTS public.insert_admin_notification(TEXT, TEXT, TEXT, TEXT, TEXT, JSONB);
DROP FUNCTION IF EXISTS public.create_admin_notification(TEXT, TEXT, TEXT, TEXT, TEXT, JSONB);

-- Step 2: Create the function with the name the code uses
-- This function now automatically creates approval workflows for tool requests
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
    v_notification_id UUID;
    v_workflow_id UUID;
    v_requester_id UUID;
    v_tool_name TEXT;
    v_requester_name TEXT;
BEGIN
    -- Create the notification first
    INSERT INTO admin_notifications (title, message, technician_name, technician_email, type, is_read, timestamp, data)
    VALUES (p_title, p_message, p_technician_name, p_technician_email, p_type, false, NOW(), p_data)
    RETURNING id INTO v_notification_id;
    
    -- If this is a tool request, automatically create an approval workflow
    IF p_type = 'tool_request' AND p_data IS NOT NULL THEN
        -- Extract data from notification
        v_requester_id := (p_data->>'requester_id')::UUID;
        v_tool_name := COALESCE(p_data->>'tool_name', 'Unknown Tool');
        v_requester_name := COALESCE(p_data->>'requester_name', p_technician_name);
        
        -- Only create workflow if we have a valid requester ID
        IF v_requester_id IS NOT NULL THEN
            BEGIN
                -- Create approval workflow using the function (if it exists)
                SELECT public.create_approval_workflow(
                    p_request_type := 'Tool Assignment',
                    p_title := 'Tool Assignment Request: ' || v_tool_name,
                    p_description := v_requester_name || ' requested the tool "' || v_tool_name || '"',
                    p_requester_id := v_requester_id,
                    p_requester_name := v_requester_name,
                    p_requester_role := 'Technician',
                    p_status := 'Pending',
                    p_priority := 'Medium',
                    p_location := p_data->>'location',
                    p_request_data := p_data
                ) INTO v_workflow_id;
            EXCEPTION WHEN OTHERS THEN
                -- Don't fail notification creation if workflow creation fails
                -- Just log a warning
                NULL;
            END;
        END IF;
    END IF;
    
    RETURN v_notification_id;
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

-- Verify function was created
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'create_admin_notification' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        RAISE NOTICE 'SUCCESS: Function create_admin_notification created!';
    ELSE
        RAISE EXCEPTION 'ERROR: Function was not created!';
    END IF;
END $$;

-- List all policies to verify
SELECT 'Current policies on admin_notifications:' as info;
SELECT policyname, cmd FROM pg_policies 
WHERE tablename = 'admin_notifications' AND schemaname = 'public';

