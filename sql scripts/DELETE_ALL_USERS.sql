-- ⚠️ WARNING: This script will DELETE ALL USERS from the app
-- This includes:
--   - All users from public.users table
--   - All users from auth.users (Supabase Auth)
--   - All related data (pending approvals, FCM tokens, etc.)
--
-- ⚠️ THIS ACTION CANNOT BE UNDONE
-- 
-- Run this script ONLY if you want to completely reset all user data
-- Make sure you have a backup if needed

-- ===========================================
-- STEP 1: Delete from public.users (app users table)
-- This will cascade to related tables if foreign keys are set up
-- ===========================================

-- First, let's see how many users we're about to delete
SELECT 
  COUNT(*) as total_users,
  COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
  COUNT(CASE WHEN role = 'technician' THEN 1 END) as technician_count
FROM public.users;

-- Delete all users from public.users
-- Note: This will fail if there are foreign key constraints that prevent deletion
-- If it fails, you may need to delete related records first
DELETE FROM public.users;

-- ===========================================
-- STEP 2: Delete from auth.users (Supabase Auth)
-- This removes authentication records
-- ===========================================

-- First, see how many auth users exist
SELECT COUNT(*) as auth_users_count FROM auth.users;

-- Delete all users from auth.users
-- Note: This requires admin privileges and will delete all authentication data
DELETE FROM auth.users;

-- ===========================================
-- STEP 3: Clean up related tables
-- ===========================================

-- Delete all pending approvals
DELETE FROM public.pending_user_approvals;

-- Delete all FCM tokens
DELETE FROM public.user_fcm_tokens;

-- Delete all admin notifications (optional - uncomment if you want to delete these too)
-- DELETE FROM public.admin_notifications;

-- Delete all technician notifications (optional - uncomment if you want to delete these too)
-- DELETE FROM public.technician_notifications;

-- ===========================================
-- STEP 4: Verify deletion
-- ===========================================

-- Check public.users (should be 0)
SELECT COUNT(*) as remaining_public_users FROM public.users;

-- Check auth.users (should be 0)
SELECT COUNT(*) as remaining_auth_users FROM auth.users;

-- Check pending approvals (should be 0)
SELECT COUNT(*) as remaining_pending_approvals FROM public.pending_user_approvals;

-- Check FCM tokens (should be 0)
SELECT COUNT(*) as remaining_fcm_tokens FROM public.user_fcm_tokens;

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT '✅ All users and related data have been deleted successfully!' as status;


