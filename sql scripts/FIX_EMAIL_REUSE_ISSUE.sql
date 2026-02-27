-- Fix Email Reuse Issue
-- When an email was used before and deleted, it should be reusable
-- This script ensures proper cleanup and allows email reuse

-- ===========================================
-- STEP 1: Check for orphaned auth.users records
-- ===========================================

-- Find auth.users that don't have corresponding public.users
-- These might be "pending" registrations that never completed
SELECT 
  'Orphaned auth.users (no public.users record)' as info,
  au.id,
  au.email,
  au.email_confirmed_at,
  au.created_at,
  au.raw_user_meta_data->>'role' as role
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ORDER BY au.created_at DESC;

-- ===========================================
-- STEP 2: Delete orphaned auth.users records
-- ===========================================

-- Delete auth.users that don't have public.users records
-- These are likely incomplete registrations or deleted users
-- WARNING: This will delete authentication records
-- Only delete if email is unconfirmed OR older than 7 days
DELETE FROM auth.users
WHERE id NOT IN (SELECT id FROM public.users WHERE id IS NOT NULL)
  AND (
    email_confirmed_at IS NULL 
    OR created_at < NOW() - INTERVAL '7 days'
  );

-- ===========================================
-- STEP 3: Check for unconfirmed email registrations
-- ===========================================

-- Find users with unconfirmed emails that are older than 24 hours
-- These might be blocking email reuse
SELECT 
  'Unconfirmed emails (older than 24h)' as info,
  id,
  email,
  email_confirmed_at,
  created_at,
  EXTRACT(EPOCH FROM (NOW() - created_at))/3600 as hours_old
FROM auth.users
WHERE email_confirmed_at IS NULL
  AND created_at < NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- ===========================================
-- STEP 4: Clean up old unconfirmed registrations
-- ===========================================

-- Delete unconfirmed registrations older than 24 hours
-- This allows the email to be reused
DELETE FROM auth.users
WHERE email_confirmed_at IS NULL
  AND created_at < NOW() - INTERVAL '24 hours';

-- ===========================================
-- STEP 5: Create function to properly delete a user
-- ===========================================

CREATE OR REPLACE FUNCTION public.delete_user_completely(user_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_id UUID;
BEGIN
  -- Find the user by email
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = user_email;
  
  IF user_id IS NULL THEN
    RAISE NOTICE 'User with email % not found', user_email;
    RETURN FALSE;
  END IF;
  
  -- STEP 1: Handle foreign key constraints in pending_user_approvals
  -- The reviewed_by column references public.users(id), so we need to set it to NULL
  -- before deleting from public.users
  -- Use a more robust approach that handles NULL and type casting
  BEGIN
    -- Try updating with UUID comparison
    UPDATE public.pending_user_approvals
    SET reviewed_by = NULL
    WHERE reviewed_by IS NOT NULL
      AND (
        reviewed_by::UUID = user_id
        OR reviewed_by::TEXT = user_id::TEXT
      );
    
    -- Log how many rows were updated
    GET DIAGNOSTICS user_id = ROW_COUNT;
    RAISE NOTICE 'Updated % pending_user_approvals records', user_id;
  EXCEPTION WHEN OTHERS THEN
    -- If UUID cast fails, try TEXT comparison
    UPDATE public.pending_user_approvals
    SET reviewed_by = NULL
    WHERE reviewed_by IS NOT NULL
      AND reviewed_by::TEXT = user_id::TEXT;
  END;
  
  -- STEP 2: Delete pending approvals where this user is the requester
  DELETE FROM public.pending_user_approvals WHERE user_id = user_id;
  
  -- STEP 3: Handle other foreign key references to public.users
  -- Update tools assigned_to to NULL if this user is assigned
  UPDATE public.tools SET assigned_to = NULL WHERE assigned_to = user_id;
  
  -- Update approval_workflows if this user is referenced
  UPDATE public.approval_workflows 
  SET assigned_to = NULL 
  WHERE assigned_to = user_id;
  
  UPDATE public.approval_workflows 
  SET approved_by = NULL 
  WHERE approved_by = user_id;
  
  UPDATE public.approval_workflows 
  SET rejected_by = NULL 
  WHERE rejected_by = user_id;
  
  -- Update tool_issues if this user is referenced
  UPDATE public.tool_issues 
  SET reported_by_user_id = NULL 
  WHERE reported_by_user_id = user_id;
  
  UPDATE public.tool_issues 
  SET assigned_to_user_id = NULL 
  WHERE assigned_to_user_id = user_id;
  
  -- STEP 4: Delete related data (no foreign key constraints)
  DELETE FROM public.user_fcm_tokens WHERE user_id = user_id;
  
  -- STEP 5: Verify no pending_user_approvals still reference this user
  -- Double-check that reviewed_by is NULL for this user
  DO $$
  DECLARE
    remaining_refs INTEGER;
  BEGIN
    SELECT COUNT(*) INTO remaining_refs
    FROM public.pending_user_approvals
    WHERE reviewed_by IS NOT NULL
      AND (
        reviewed_by::UUID = user_id
        OR reviewed_by::TEXT = user_id::TEXT
      );
    
    IF remaining_refs > 0 THEN
      -- Force set to NULL one more time
      UPDATE public.pending_user_approvals
      SET reviewed_by = NULL
      WHERE reviewed_by IS NOT NULL
        AND (
          reviewed_by::UUID = user_id
          OR reviewed_by::TEXT = user_id::TEXT
        );
      RAISE NOTICE 'Force-cleared % remaining reviewed_by references', remaining_refs;
    END IF;
  END $$;
  
  -- STEP 6: Delete from public.users (should work now that foreign keys are handled)
  DELETE FROM public.users WHERE id = user_id;
  
  -- STEP 7: Delete from auth.users (this is the critical part for email reuse)
  DELETE FROM auth.users WHERE id = user_id;
  
  RAISE NOTICE 'User % completely deleted', user_email;
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error deleting user %: %', user_email, SQLERRM;
    RETURN FALSE;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.delete_user_completely TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_user_completely TO service_role;

-- ===========================================
-- STEP 6: Create function to check if email can be reused
-- ===========================================

CREATE OR REPLACE FUNCTION public.can_reuse_email(check_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_exists BOOLEAN;
  is_confirmed BOOLEAN;
  is_old BOOLEAN;
BEGIN
  -- Check if email exists in auth.users
  SELECT EXISTS(
    SELECT 1 FROM auth.users WHERE email = check_email
  ) INTO user_exists;
  
  IF NOT user_exists THEN
    RETURN TRUE; -- Email doesn't exist, can be reused
  END IF;
  
  -- Check if email is confirmed
  SELECT EXISTS(
    SELECT 1 FROM auth.users 
    WHERE email = check_email 
    AND email_confirmed_at IS NOT NULL
  ) INTO is_confirmed;
  
  IF is_confirmed THEN
    RETURN FALSE; -- Email is confirmed and in use, cannot reuse
  END IF;
  
  -- Check if unconfirmed registration is old (more than 24 hours)
  SELECT EXISTS(
    SELECT 1 FROM auth.users 
    WHERE email = check_email 
    AND email_confirmed_at IS NULL
    AND created_at < NOW() - INTERVAL '24 hours'
  ) INTO is_old;
  
  IF is_old THEN
    RETURN TRUE; -- Old unconfirmed registration, can be reused
  END IF;
  
  RETURN FALSE; -- Recent unconfirmed registration, cannot reuse yet
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.can_reuse_email TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_reuse_email TO anon;

-- ===========================================
-- STEP 7: Verify cleanup
-- ===========================================

SELECT 
  'Cleanup verification' as info,
  (SELECT COUNT(*) FROM auth.users WHERE email_confirmed_at IS NULL AND created_at < NOW() - INTERVAL '24 hours') as old_unconfirmed,
  (SELECT COUNT(*) FROM auth.users au LEFT JOIN public.users pu ON au.id = pu.id WHERE pu.id IS NULL) as orphaned_auth_users;

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT '✅ Email reuse fix applied!' as status;
SELECT 'You can now use delete_user_completely(email) to properly delete users' as usage;
SELECT 'You can use can_reuse_email(email) to check if an email can be reused' as usage2;
