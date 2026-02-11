-- Fix Function Search Path Security Warnings
-- Run this in Supabase SQL Editor to fix the security warnings
-- This adds SET search_path = public to all functions to prevent search path injection

-- Fix approval workflow functions
CREATE OR REPLACE FUNCTION public.approve_workflow(workflow_id UUID, approver_comments TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.approval_workflows
  SET 
    status = 'Approved',
    approved_date = NOW(),
    approved_by = auth.uid(),
    comments = COALESCE(approver_comments, comments),
    updated_at = NOW()
  WHERE id = workflow_id AND status = 'Pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval workflow not found or already processed.';
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.reject_workflow(workflow_id UUID, rejection_reason TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.approval_workflows
  SET 
    status = 'Rejected',
    rejected_date = NOW(),
    rejected_by = auth.uid(),
    rejection_reason = rejection_reason,
    updated_at = NOW()
  WHERE id = workflow_id AND status = 'Pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval workflow not found or already processed.';
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION update_approval_workflows_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Fix create_approval_workflow function (already has SET search_path, but ensure it's correct)
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

-- Verify functions are fixed
SELECT 
    proname as function_name,
    CASE 
        WHEN proconfig IS NULL THEN '❌ Missing search_path'
        WHEN array_to_string(proconfig, ', ') LIKE '%search_path%' THEN '✅ Has search_path'
        ELSE '⚠️ Check manually'
    END as search_path_status
FROM pg_proc
WHERE proname IN ('approve_workflow', 'reject_workflow', 'update_approval_workflows_updated_at', 'create_approval_workflow')
AND pronamespace = 'public'::regnamespace;

SELECT '✅ Approval workflow functions fixed with SET search_path = public' as status;
