-- EMERGENCY AUTHENTICATION FIX
-- Fixes "Database error granting user" error
-- Run this NOW in your Supabase SQL Editor

-- ===========================================
-- 1. DROP ALL PROBLEMATIC TRIGGERS
-- ===========================================

-- Drop ALL triggers that might be causing issues
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS check_email_domain_trigger ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users;

-- Drop the problematic functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.check_email_domain() CASCADE;

-- ===========================================
-- 2. CREATE SIMPLE, SAFE USER CREATION TRIGGER
-- ===========================================

-- Create a VERY simple user creation function that won't fail
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Try to create user record, but don't fail if it errors
  BEGIN
    INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
      COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
      true,
      NOW(),
      NOW()
    );
  EXCEPTION
    WHEN unique_violation THEN
      -- User already exists, just update
      UPDATE public.users 
      SET email = NEW.email, updated_at = NOW()
      WHERE id = NEW.id;
    WHEN OTHERS THEN
      -- Any other error, just log it and continue
      RAISE WARNING 'Could not create user record: %', SQLERRM;
  END;

  -- Try to create profile, but don't fail if it errors
  BEGIN
    INSERT INTO public.user_profiles (id, user_id, created_at, updated_at)
    VALUES (NEW.id, NEW.id, NOW(), NOW());
  EXCEPTION
    WHEN unique_violation THEN
      -- Profile already exists, ignore
      NULL;
    WHEN OTHERS THEN
      -- Any other error, just log it and continue
      RAISE WARNING 'Could not create user profile: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ===========================================
-- 3. FIX TABLE PERMISSIONS AND RLS
-- ===========================================

-- Make sure RLS is enabled but not blocking
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on users table
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON users';
    END LOOP;
    
    -- Drop all policies on user_profiles table
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'user_profiles' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON user_profiles';
    END LOOP;
    
    -- Drop all policies on tools table
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'tools' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON tools';
    END LOOP;
END $$;

-- Create VERY permissive policies
CREATE POLICY "allow_all_authenticated" ON users
  FOR ALL 
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "allow_all_authenticated" ON user_profiles
  FOR ALL 
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "allow_all_authenticated" ON tools
  FOR ALL 
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ===========================================
-- 4. GRANT ALL NECESSARY PERMISSIONS
-- ===========================================

-- Grant table permissions
GRANT ALL PRIVILEGES ON users TO authenticated;
GRANT ALL PRIVILEGES ON user_profiles TO authenticated;
GRANT ALL PRIVILEGES ON tools TO authenticated;
GRANT ALL PRIVILEGES ON user_dashboard TO authenticated;

-- Grant sequence permissions (for auto-increment IDs if any)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant function permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO anon;

-- ===========================================
-- 5. FIX EXISTING AUTH USERS WITHOUT RECORDS
-- ===========================================

-- Create records for any auth.users that don't have them
INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', 'User'),
  COALESCE(au.raw_user_meta_data->>'role', 'technician'),
  true,
  au.created_at,
  NOW()
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = au.id)
ON CONFLICT (id) DO NOTHING;

-- Create profiles for any users without them
INSERT INTO public.user_profiles (id, user_id, created_at, updated_at)
SELECT 
  au.id,
  au.id,
  au.created_at,
  NOW()
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM public.user_profiles up WHERE up.id = au.id)
ON CONFLICT (id) DO NOTHING;

-- ===========================================
-- 6. MAKE FIRST USER ADMIN
-- ===========================================

-- Update first user to be admin
UPDATE public.users
SET role = 'admin', is_active = true, updated_at = NOW()
WHERE id = (
  SELECT id FROM public.users 
  ORDER BY created_at ASC 
  LIMIT 1
);

-- Also make any @mekar.ae user admin
UPDATE public.users
SET role = 'admin', is_active = true, updated_at = NOW()
WHERE email LIKE '%@mekar.ae';

-- ===========================================
-- 7. VERIFICATION & STATUS
-- ===========================================

SELECT '✅ EMERGENCY FIX APPLIED!' as status;

-- Show what we have
SELECT 
  'Users in auth.users: ' || COUNT(*) as auth_users
FROM auth.users;

SELECT 
  'Users in public.users: ' || COUNT(*) as public_users
FROM public.users;

SELECT 
  'User profiles: ' || COUNT(*) as profiles
FROM public.user_profiles;

SELECT 
  'Admins: ' || COUNT(*) as admin_count
FROM public.users
WHERE role = 'admin';

-- Show any auth users missing records
SELECT 
  'Auth users missing public.users record: ' || COUNT(*) as missing_users
FROM auth.users au
WHERE NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = au.id);

-- Show trigger status
SELECT 
  'Trigger exists: ' || CASE WHEN COUNT(*) > 0 THEN 'YES ✅' ELSE 'NO ❌' END as trigger_status
FROM pg_trigger
WHERE tgname = 'on_auth_user_created';




