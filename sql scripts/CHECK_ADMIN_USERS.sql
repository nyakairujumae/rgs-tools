-- =====================================================
-- CHECK ADMIN USERS - Diagnostic SQL
-- =====================================================
-- Run this in Supabase SQL Editor to check admin users

SET search_path = public;

-- ===========================================
-- STEP 1: Check All Users and Their Roles
-- ===========================================

SELECT 
  'All Users' as info,
  id,
  email,
  full_name,
  role,
  created_at,
  updated_at
FROM users
ORDER BY role, created_at DESC;

-- ===========================================
-- STEP 2: Check Admin Users Specifically
-- ===========================================

SELECT 
  'Admin Users' as info,
  id,
  email,
  full_name,
  role,
  created_at
FROM users
WHERE role = 'admin'
ORDER BY created_at DESC;

-- ===========================================
-- STEP 3: Check Role Values (Case Sensitivity)
-- ===========================================

SELECT 
  'Role Distribution' as info,
  role,
  COUNT(*) as count
FROM users
GROUP BY role
ORDER BY role;

-- ===========================================
-- STEP 4: Check for Case Variations
-- ===========================================

SELECT 
  'Potential Admin Users (Case Variations)' as info,
  id,
  email,
  full_name,
  role,
  LOWER(role) as role_lowercase
FROM users
WHERE LOWER(role) = 'admin'
ORDER BY created_at DESC;

-- ===========================================
-- STEP 5: Check RLS Policies
-- ===========================================

SELECT 
  'RLS Policies on users table' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;

-- ===========================================
-- STEP 6: Test Query as Current User
-- ===========================================

-- This will show what the current authenticated user can see
SELECT 
  'Users Visible to Current User' as info,
  id,
  email,
  full_name,
  role
FROM users
ORDER BY role, created_at DESC;

-- ===========================================
-- SUMMARY
-- ===========================================

SELECT 
  'Summary' as info,
  (SELECT COUNT(*) FROM users WHERE role = 'admin') as admin_count,
  (SELECT COUNT(*) FROM users WHERE LOWER(role) = 'admin') as admin_count_case_insensitive,
  (SELECT COUNT(*) FROM users WHERE role = 'technician') as technician_count,
  (SELECT COUNT(*) FROM users) as total_users;

-- ===========================================
-- NOTES:
-- ===========================================
-- 1. If admin_count = 0: No users have role = 'admin'
-- 2. If admin_count_case_insensitive > admin_count: Case sensitivity issue
-- 3. Check RLS policies - they might be blocking the query
-- 4. The query in PushNotificationService uses: .eq('role', 'admin')
-- 5. Make sure admin users actually have role = 'admin' (lowercase) in database
-- ===========================================

