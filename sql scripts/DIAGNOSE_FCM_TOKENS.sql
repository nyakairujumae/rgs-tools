-- Diagnostic script to check FCM token saving issues
-- Run this in Supabase SQL Editor to diagnose why tokens aren't being saved

-- ===========================================
-- 1. Check table structure
-- ===========================================
SELECT 
  'Table Structure' as check_type,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'user_fcm_tokens'
ORDER BY ordinal_position;

-- ===========================================
-- 2. Check unique constraints
-- ===========================================
SELECT 
  'Unique Constraints' as check_type,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public' 
  AND table_name = 'user_fcm_tokens'
  AND constraint_type = 'UNIQUE';

-- ===========================================
-- 3. Check RLS policies
-- ===========================================
SELECT 
  'RLS Policies' as check_type,
  policyname,
  cmd as operation,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'user_fcm_tokens';

-- ===========================================
-- 4. Check if RLS is enabled
-- ===========================================
SELECT 
  'RLS Status' as check_type,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' 
  AND tablename = 'user_fcm_tokens';

-- ===========================================
-- 5. Count existing tokens
-- ===========================================
SELECT 
  'Token Count' as check_type,
  COUNT(*) as total_tokens,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(CASE WHEN platform = 'android' THEN 1 END) as android_tokens,
  COUNT(CASE WHEN platform = 'ios' THEN 1 END) as ios_tokens
FROM public.user_fcm_tokens;

-- ===========================================
-- 6. Show sample tokens (if any)
-- ===========================================
SELECT 
  'Sample Tokens' as check_type,
  user_id,
  platform,
  LEFT(fcm_token, 30) || '...' as token_preview,
  updated_at
FROM public.user_fcm_tokens
ORDER BY updated_at DESC
LIMIT 10;

-- ===========================================
-- 7. Check for admin users and their tokens
-- ===========================================
SELECT 
  'Admin Users & Tokens' as check_type,
  u.id as user_id,
  u.email,
  u.role,
  t.platform,
  CASE WHEN t.fcm_token IS NOT NULL THEN 'Has Token' ELSE 'No Token' END as token_status,
  LEFT(t.fcm_token, 20) || '...' as token_preview
FROM public.users u
LEFT JOIN public.user_fcm_tokens t ON u.id = t.user_id
WHERE u.role = 'admin'
ORDER BY u.email;

-- ===========================================
-- 8. Verify table has correct unique constraint
-- ===========================================
-- This should show: user_fcm_tokens_user_id_platform_key
SELECT 
  'Expected Constraint' as check_type,
  'user_fcm_tokens_user_id_platform_key' as expected_constraint_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_constraint 
      WHERE conname = 'user_fcm_tokens_user_id_platform_key'
      AND conrelid = 'public.user_fcm_tokens'::regclass
    ) THEN '✅ EXISTS' 
    ELSE '❌ MISSING - Run FIX_FCM_TOKENS_TABLE.sql' 
  END as status;

