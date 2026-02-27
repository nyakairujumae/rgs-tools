-- ⚠️ WARNING: This script will DELETE ALL USERS from the app
-- This is a SAFER version that handles foreign key constraints
--
-- ⚠️ THIS ACTION CANNOT BE UNDONE
-- 
-- Run this script ONLY if you want to completely reset all user data

-- ===========================================
-- STEP 1: Show what will be deleted (for verification)
-- ===========================================

SELECT 
  'Users to be deleted:' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
  COUNT(CASE WHEN role = 'technician' THEN 1 END) as technician_count
FROM public.users;

-- ===========================================
-- STEP 2: Delete related data first (to avoid foreign key errors)
-- ===========================================

-- Delete FCM tokens (references user_id)
DELETE FROM public.user_fcm_tokens;

-- Delete pending approvals (references user_id)
DELETE FROM public.pending_user_approvals;

-- Delete admin notifications (if they reference user_id)
-- Uncomment if you want to delete these too:
-- DELETE FROM public.admin_notifications WHERE technician_id IN (SELECT id FROM public.users);
-- DELETE FROM public.admin_notifications WHERE user_id IN (SELECT id FROM public.users);

-- Delete technician notifications (if they reference user_id)
-- Uncomment if you want to delete these too:
-- DELETE FROM public.technician_notifications WHERE user_id IN (SELECT id FROM public.users);

-- Delete tool issues (if they reference user_id)
-- Uncomment if you want to delete these too:
-- DELETE FROM public.tool_issues WHERE reported_by_id IN (SELECT id FROM public.users);

-- Delete tool requests (if they reference user_id)
-- Uncomment if you want to delete these too:
-- DELETE FROM public.tool_requests WHERE requested_by_id IN (SELECT id FROM public.users);

-- ===========================================
-- STEP 3: Delete from public.users
-- ===========================================

DELETE FROM public.users;

-- ===========================================
-- STEP 4: Delete from auth.users
-- Note: This may require admin privileges
-- If this fails, use Supabase Dashboard → Authentication → Users → Delete
-- ===========================================

-- Try to delete from auth.users
-- If this fails with a permission error, you'll need to delete via Dashboard
-- Note: Direct deletion from auth.users may not be allowed
-- You may need to delete via Supabase Dashboard → Authentication → Users
DELETE FROM auth.users;

-- ===========================================
-- STEP 5: Verify deletion
-- ===========================================

SELECT 
  'Verification:' as info,
  (SELECT COUNT(*) FROM public.users) as remaining_public_users,
  (SELECT COUNT(*) FROM auth.users) as remaining_auth_users,
  (SELECT COUNT(*) FROM public.pending_user_approvals) as remaining_pending_approvals,
  (SELECT COUNT(*) FROM public.user_fcm_tokens) as remaining_fcm_tokens;

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT 
  CASE 
    WHEN (SELECT COUNT(*) FROM public.users) = 0 
      AND (SELECT COUNT(*) FROM auth.users) = 0 
    THEN '✅ All users deleted successfully!'
    WHEN (SELECT COUNT(*) FROM public.users) = 0 
      AND (SELECT COUNT(*) FROM auth.users) > 0 
    THEN '⚠️ Public users deleted, but auth.users still has records. Delete them via Dashboard.'
    ELSE '❌ Some users may still exist. Check the verification above.'
  END as status;

