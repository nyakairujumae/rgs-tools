-- Fix Payo's admin role in the database
-- Run this in Supabase SQL Editor to ensure Payo is properly set as admin

-- First, let's check if Payo exists in the users table
SELECT id, email, full_name, role, created_at 
FROM public.users 
WHERE email ILIKE '%payo%' OR full_name ILIKE '%payo%';

-- If Payo exists, update their role to admin
UPDATE public.users 
SET role = 'admin', updated_at = NOW()
WHERE email ILIKE '%payo%' OR full_name ILIKE '%payo%';

-- If Payo doesn't exist, we need to find their user ID from auth.users
-- and create a record in the users table
INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', 'Payo'),
  'admin',
  NOW(),
  NOW()
FROM auth.users au
WHERE au.email ILIKE '%payo%'
AND NOT EXISTS (
  SELECT 1 FROM public.users u WHERE u.id = au.id
);

-- Verify the update
SELECT id, email, full_name, role, created_at, updated_at 
FROM public.users 
WHERE email ILIKE '%payo%' OR full_name ILIKE '%payo%';

-- Also check auth.users to see if the user exists there
SELECT id, email, raw_user_meta_data, created_at
FROM auth.users 
WHERE email ILIKE '%payo%';
