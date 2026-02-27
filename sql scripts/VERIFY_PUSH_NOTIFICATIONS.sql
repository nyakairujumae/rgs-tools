-- =====================================================
-- VERIFY PUSH NOTIFICATIONS - Complete Diagnostic
-- =====================================================
-- This script helps diagnose why push notifications aren't working
-- Run this in Supabase SQL Editor to check all components

SET search_path = public;

-- ===========================================
-- STEP 1: Check FCM Tokens in Database
-- ===========================================

SELECT 
  'FCM Tokens Status' as check_type,
  COUNT(*) as total_tokens,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(CASE WHEN platform = 'android' THEN 1 END) as android_tokens,
  COUNT(CASE WHEN platform = 'ios' THEN 1 END) as ios_tokens
FROM user_fcm_tokens;

-- Show all FCM tokens
SELECT 
  'All FCM Tokens' as info,
  user_id,
  platform,
  LEFT(fcm_token, 30) || '...' as token_preview,
  created_at,
  updated_at
FROM user_fcm_tokens
ORDER BY updated_at DESC;

-- ===========================================
-- STEP 2: Check Edge Function Deployment
-- ===========================================

-- Check if Edge Function exists (requires admin access)
SELECT 
  'Edge Function Check' as info,
  proname as function_name,
  pronargs as arg_count,
  prorettype::regtype as return_type
FROM pg_proc
WHERE proname = 'send-push-notification'
   OR proname LIKE '%push%notification%';

-- Note: Edge Functions are stored separately, this query may not find them
-- Check Supabase Dashboard → Edge Functions → send-push-notification

-- ===========================================
-- STEP 3: Check Notification Triggers
-- ===========================================

-- Check if notifications are being created
SELECT 
  'Recent Admin Notifications' as info,
  COUNT(*) as total_notifications,
  COUNT(CASE WHEN is_read = false THEN 1 END) as unread_notifications,
  MAX(timestamp) as latest_notification
FROM admin_notifications;

-- Check recent notifications
SELECT 
  'Recent Notifications' as info,
  id,
  title,
  type,
  is_read,
  timestamp,
  technician_email
FROM admin_notifications
ORDER BY timestamp DESC
LIMIT 10;

-- ===========================================
-- STEP 4: Check User Roles and IDs
-- ===========================================

-- Check users with FCM tokens
SELECT 
  'Users with FCM Tokens' as info,
  u.id,
  u.email,
  u.role,
  COUNT(t.fcm_token) as token_count,
  STRING_AGG(DISTINCT t.platform, ', ') as platforms
FROM users u
INNER JOIN user_fcm_tokens t ON u.id = t.user_id
GROUP BY u.id, u.email, u.role
ORDER BY token_count DESC;

-- ===========================================
-- STEP 5: Check for Missing Tokens
-- ===========================================

-- Find users without FCM tokens
SELECT 
  'Users without FCM Tokens' as info,
  u.id,
  u.email,
  u.role
FROM users u
LEFT JOIN user_fcm_tokens t ON u.id = t.user_id
WHERE t.user_id IS NULL
ORDER BY u.created_at DESC;

-- ===========================================
-- STEP 6: Check Token Validity
-- ===========================================

-- Check for duplicate or invalid tokens
SELECT 
  'Token Issues' as info,
  user_id,
  platform,
  COUNT(*) as duplicate_count,
  MIN(created_at) as first_created,
  MAX(updated_at) as last_updated
FROM user_fcm_tokens
GROUP BY user_id, platform
HAVING COUNT(*) > 1;

-- ===========================================
-- STEP 7: Test Data for Push Notification
-- ===========================================

-- Get a test user with FCM token (for manual testing)
SELECT 
  'Test User for Push Notification' as info,
  u.id as user_id,
  u.email,
  u.role,
  t.fcm_token,
  t.platform,
  LEFT(t.fcm_token, 30) || '...' as token_preview
FROM users u
INNER JOIN user_fcm_tokens t ON u.id = t.user_id
WHERE u.role = 'admin' OR u.role = 'technician'
ORDER BY t.updated_at DESC
LIMIT 5;

-- ===========================================
-- SUMMARY
-- ===========================================

SELECT 
  'Summary' as info,
  (SELECT COUNT(*) FROM user_fcm_tokens) as total_fcm_tokens,
  (SELECT COUNT(DISTINCT user_id) FROM user_fcm_tokens) as users_with_tokens,
  (SELECT COUNT(*) FROM users) as total_users,
  (SELECT COUNT(*) FROM admin_notifications WHERE timestamp > NOW() - INTERVAL '24 hours') as notifications_last_24h,
  (SELECT COUNT(*) FROM admin_notifications WHERE is_read = false) as unread_notifications;

-- ===========================================
-- NOTES:
-- ===========================================
-- 1. If total_fcm_tokens = 0: FCM tokens are not being saved
-- 2. If users_with_tokens < total_users: Some users don't have tokens
-- 3. Check Edge Function in Supabase Dashboard → Edge Functions
-- 4. Check Edge Function logs for errors
-- 5. Verify secrets are set: GOOGLE_PROJECT_ID, GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY
-- ===========================================

