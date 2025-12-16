-- =====================================================
-- CLEANUP DELETED USERS - Complete Email Reuse Fix
-- =====================================================
-- This script will:
-- 1. Find and delete all orphaned auth.users records
-- 2. Delete unconfirmed users that are blocking email reuse
-- 3. Create a function to check email availability
-- 4. Ensure emails can be reused after deletion
-- =====================================================

SET search_path = public;

-- ===========================================
-- STEP 1: Check current state
-- ===========================================

-- Find all auth.users that don't have public.users records
SELECT 
  'Orphaned auth.users (no public.users)' as status,
  COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- Find unconfirmed users (these block email reuse)
SELECT 
  'Unconfirmed auth.users' as status,
  COUNT(*) as count
FROM auth.users
WHERE email_confirmed_at IS NULL;

-- Find users in auth.users but not in public.users
SELECT 
  'Users in auth but not in public' as status,
  au.id,
  au.email,
  au.email_confirmed_at,
  au.created_at,
  CASE 
    WHEN au.email_confirmed_at IS NULL THEN 'Unconfirmed'
    ELSE 'Confirmed but orphaned'
  END as status
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ORDER BY au.created_at DESC;

-- ===========================================
-- STEP 2: Delete orphaned and unconfirmed users
-- ===========================================

-- Delete ALL auth.users that don't have public.users records
-- This includes:
-- - Users that were deleted from public.users
-- - Unconfirmed registrations
-- - Orphaned records
DELETE FROM auth.users
WHERE id NOT IN (
  SELECT id FROM public.users WHERE id IS NOT NULL
);

-- Also delete unconfirmed users older than 1 hour (optional - more aggressive)
-- Uncomment if you want to delete unconfirmed users after 1 hour
-- DELETE FROM auth.users
-- WHERE email_confirmed_at IS NULL 
--   AND created_at < NOW() - INTERVAL '1 hour';

-- ===========================================
-- STEP 3: Create email availability check function
-- ===========================================

-- Function to check if an email is available for registration
-- Returns true if email is available, false if already in use
CREATE OR REPLACE FUNCTION public.check_email_available(check_email TEXT)
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
  auth_user_exists BOOLEAN;
  public_user_exists BOOLEAN;
BEGIN
  -- Check if email exists in auth.users (confirmed users)
  SELECT EXISTS(
    SELECT 1 
    FROM auth.users 
    WHERE email = check_email 
      AND email_confirmed_at IS NOT NULL
  ) INTO auth_user_exists;
  
  -- Check if email exists in public.users
  SELECT EXISTS(
    SELECT 1 
    FROM public.users 
    WHERE email = check_email
  ) INTO public_user_exists;
  
  -- Email is available if it doesn't exist in either table
  RETURN NOT (auth_user_exists OR public_user_exists);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.check_email_available(TEXT) TO authenticated, anon;

-- ===========================================
-- STEP 4: Verify cleanup
-- ===========================================

-- Check remaining orphaned records (should be 0)
SELECT 
  'Remaining orphaned auth.users' as status,
  COUNT(*) as count
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL;

-- Test the email availability function
-- Replace 'test@example.com' with an email you want to check
-- SELECT public.check_email_available('test@example.com') as is_available;

-- ===========================================
-- STEP 5: Show summary
-- ===========================================

SELECT 
  'Summary' as info,
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM public.users) as total_public_users,
  (SELECT COUNT(*) FROM auth.users au 
   LEFT JOIN public.users pu ON au.id = pu.id 
   WHERE pu.id IS NULL) as orphaned_auth_users,
  (SELECT COUNT(*) FROM auth.users 
   WHERE email_confirmed_at IS NULL) as unconfirmed_users;

-- ===========================================
-- NOTES:
-- ===========================================
-- 1. After running this script, emails should be reusable
-- 2. The check_email_available() function can be called from your app
-- 3. Unconfirmed users older than 1 hour can be deleted (optional step)
-- 4. Always backup your database before running deletion scripts
-- ===========================================
