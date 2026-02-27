-- Check current state of triggers and functions
-- Run this first to see what's currently in the database

-- ===========================================
-- Check existing triggers on auth.users
-- ===========================================

SELECT 
  'Current Triggers on auth.users' as info,
  tgname as trigger_name,
  tgenabled as enabled,
  tgtype::text as trigger_type
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
ORDER BY tgname;

-- ===========================================
-- Check existing functions
-- ===========================================

SELECT 
  'Current Functions' as info,
  proname as function_name,
  prosrc as function_source
FROM pg_proc
WHERE proname IN ('handle_new_auth_user', 'handle_email_confirmed_user', 'handle_new_user')
ORDER BY proname;

-- ===========================================
-- Check if RLS is enabled on auth.users
-- ===========================================

SELECT 
  'RLS Status' as info,
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'auth' AND tablename = 'users';

-- ===========================================
-- Check for any constraints that might block inserts
-- ===========================================

SELECT 
  'Constraints on auth.users' as info,
  conname as constraint_name,
  contype as constraint_type
FROM pg_constraint
WHERE conrelid = 'auth.users'::regclass;

