-- CREATE APPROVAL WORKFLOWS FUNCTION - Run this in Supabase SQL Editor
-- This creates a function similar to create_admin_notification that automatically creates approval workflows
-- for tool requests, just like notifications work

-- ============================================================================
-- STEP 1: Create the function to create approval workflows (bypasses RLS)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_approval_workflow(
    p_request_type TEXT,
    p_title TEXT,
    p_description TEXT,
    p_requester_id UUID,
    p_requester_name TEXT,
    p_requester_role TEXT DEFAULT 'Technician',
    p_status TEXT DEFAULT 'Pending',
    p_priority TEXT DEFAULT 'Medium',
    p_location TEXT DEFAULT NULL,
    p_request_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO approval_workflows (
        request_type,
        title,
        description,
        requester_id,
        requester_name,
        requester_role,
        status,
        priority,
        request_date,
        location,
        request_data
    )
    VALUES (
        p_request_type,
        p_title,
        p_description,
        p_requester_id,
        p_requester_name,
        p_requester_role,
        p_status,
        p_priority,
        NOW(),
        p_location,
        p_request_data
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.create_approval_workflow TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_approval_workflow TO anon;

-- ============================================================================
-- STEP 2: Update create_admin_notification to automatically create approval workflows
-- ============================================================================

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
    INSERT INTO admin_notifications (
        title,
        message,
        technician_name,
        technician_email,
        type,
        is_read,
        timestamp,
        data
    )
    VALUES (
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
    
    -- If this is a tool request, automatically create an approval workflow
    IF p_type = 'tool_request' AND p_data IS NOT NULL THEN
        -- Extract data from notification
        v_requester_id := (p_data->>'requester_id')::UUID;
        v_tool_name := COALESCE(p_data->>'tool_name', 'Unknown Tool');
        v_requester_name := COALESCE(p_data->>'requester_name', p_technician_name);
        
        -- Only create workflow if we have a valid requester ID
        IF v_requester_id IS NOT NULL THEN
            BEGIN
                -- Create approval workflow using the function
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
                
                -- Log success (can be removed in production)
                RAISE NOTICE 'Created approval workflow % for tool request notification %', v_workflow_id, v_notification_id;
            EXCEPTION WHEN OTHERS THEN
                -- Don't fail notification creation if workflow creation fails
                RAISE WARNING 'Failed to create approval workflow for notification %: %', v_notification_id, SQLERRM;
            END;
        END IF;
    END IF;
    
    RETURN v_notification_id;
END;
$$;

-- Verify functions exist
SELECT 'Functions created successfully!' as status;

-- Test query to verify
SELECT 
    proname as function_name,
    proargnames as parameters
FROM pg_proc
WHERE proname IN ('create_admin_notification', 'create_approval_workflow')
AND pronamespace = 'public'::regnamespace;

