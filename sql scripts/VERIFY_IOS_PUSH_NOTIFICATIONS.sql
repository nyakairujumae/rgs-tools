-- =====================================================
-- VERIFY iOS PUSH NOTIFICATIONS - Diagnostic SQL
-- =====================================================
-- Run this in Supabase SQL Editor to check iOS-specific issues

SET search_path = public;

-- ===========================================
-- STEP 1: Check iOS FCM Tokens
-- ===========================================

SELECT 
  'iOS FCM Tokens Status' as check_type,
  COUNT(*) as total_ios_tokens,
  COUNT(DISTINCT user_id) as unique_ios_users,
  MIN(created_at) as first_token_created,
  MAX(updated_at) as latest_token_updated
FROM user_fcm_tokens
WHERE platform = 'ios';

-- Show all iOS FCM tokens
SELECT 
  'All iOS FCM Tokens' as info,
  user_id,
  LEFT(fcm_token, 30) || '...' as token_preview,
  LENGTH(fcm_token) as token_length,
  created_at,
  updated_at
FROM user_fcm_tokens
WHERE platform = 'ios'
ORDER BY updated_at DESC;

-- ===========================================
-- STEP 2: Compare Android vs iOS Tokens
-- ===========================================

SELECT 
  'Platform Comparison' as info,
  platform,
  COUNT(*) as token_count,
  COUNT(DISTINCT user_id) as unique_users,
  MAX(updated_at) as latest_update
FROM user_fcm_tokens
GROUP BY platform
ORDER BY platform;

-- ===========================================
-- STEP 3: Users with iOS Tokens
-- ===========================================

SELECT 
  'Users with iOS Tokens' as info,
  u.id,
  u.email,
  u.role,
  t.fcm_token IS NOT NULL as has_ios_token,
  t.updated_at as token_updated_at
FROM users u
LEFT JOIN user_fcm_tokens t ON u.id = t.user_id AND t.platform = 'ios'
ORDER BY t.updated_at DESC NULLS LAST;

-- ===========================================
-- STEP 4: Users Missing iOS Tokens
-- ===========================================

SELECT 
  'Users Missing iOS Tokens' as info,
  u.id,
  u.email,
  u.role,
  u.created_at
FROM users u
WHERE NOT EXISTS (
  SELECT 1 FROM user_fcm_tokens t 
  WHERE t.user_id = u.id AND t.platform = 'ios'
)
ORDER BY u.created_at DESC;

-- ===========================================
-- STEP 5: Recent iOS Token Activity
-- ===========================================

SELECT 
  'Recent iOS Token Activity' as info,
  user_id,
  LEFT(fcm_token, 30) || '...' as token_preview,
  created_at,
  updated_at,
  EXTRACT(EPOCH FROM (NOW() - updated_at)) / 3600 as hours_since_update
FROM user_fcm_tokens
WHERE platform = 'ios'
ORDER BY updated_at DESC
LIMIT 10;

-- ===========================================
-- STEP 6: Test Data for iOS
-- ===========================================

-- Get a test iOS token for manual testing
SELECT 
  'Test iOS Token for Firebase Console' as info,
  u.email,
  t.fcm_token,
  t.platform,
  t.updated_at
FROM users u
INNER JOIN user_fcm_tokens t ON u.id = t.user_id
WHERE t.platform = 'ios'
ORDER BY t.updated_at DESC
LIMIT 1;

-- ===========================================
-- SUMMARY
-- ===========================================

SELECT 
  'Summary' as info,
  (SELECT COUNT(*) FROM user_fcm_tokens WHERE platform = 'ios') as ios_tokens,
  (SELECT COUNT(*) FROM user_fcm_tokens WHERE platform = 'android') as android_tokens,
  (SELECT COUNT(DISTINCT user_id) FROM user_fcm_tokens WHERE platform = 'ios') as ios_users,
  (SELECT COUNT(DISTINCT user_id) FROM user_fcm_tokens WHERE platform = 'android') as android_users,
  (SELECT COUNT(*) FROM users) as total_users;

-- ===========================================
-- NOTES:
-- ===========================================
-- 1. If ios_tokens = 0: iOS tokens are not being saved
-- 2. If ios_tokens < android_tokens: Some users don't have iOS tokens
-- 3. Check app logs for iOS token saving errors
-- 4. Verify iOS notification permissions are granted
-- 5. Most common issue: APNs not configured in Firebase Console
-- ===========================================

