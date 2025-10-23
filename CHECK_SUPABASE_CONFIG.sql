-- Check Supabase Configuration and Fix JWT Issues
-- Run this in Supabase SQL Editor to diagnose and fix authentication issues

-- 1. Check current users and their roles
SELECT 
  u.id,
  u.email,
  u.full_name,
  u.role,
  u.created_at,
  u.updated_at,
  au.created_at as auth_created_at,
  au.last_sign_in_at
FROM public.users u
LEFT JOIN auth.users au ON u.id = au.id
ORDER BY u.created_at DESC;

-- 2. Check for any users with missing roles
SELECT 
  au.id,
  au.email,
  au.raw_user_meta_data,
  au.created_at
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL
ORDER BY au.created_at DESC;

-- 3. Fix any users missing from public.users table
INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', 'User'),
  COALESCE(au.raw_user_meta_data->>'role', 'technician'),
  au.created_at,
  NOW()
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE u.id IS NULL;

-- 4. Update any users with incorrect roles (if needed)
-- Uncomment and modify as needed:
-- UPDATE public.users 
-- SET role = 'admin', updated_at = NOW()
-- WHERE email = 'your-admin-email@example.com';

-- 5. Check RLS policies are working correctly
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'users';

-- 6. Verify the trigger function exists
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- 7. Check if the trigger is active
SELECT 
  trigger_name,
  event_manipulation,
  action_timing,
  action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- 8. Final verification - show all users with their roles
SELECT 
  'Current Users and Roles:' as info,
  u.email,
  u.full_name,
  u.role,
  CASE 
    WHEN u.role = 'admin' THEN '✅ Admin Access'
    WHEN u.role = 'technician' THEN '🔧 Technician Access'
    ELSE '❓ Unknown Role'
  END as access_level
FROM public.users u
ORDER BY u.role DESC, u.created_at DESC;
