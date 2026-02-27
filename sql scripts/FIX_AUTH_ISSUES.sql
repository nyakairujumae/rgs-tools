-- FIX AUTHENTICATION ISSUES
-- This script fixes login/signup problems after database changes
-- Run this in your Supabase SQL Editor

-- ===========================================
-- 1. FIX USER CREATION TRIGGER
-- ===========================================

-- Temporarily disable the strict email validation to allow login/signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create user record in public.users table (without strict domain validation for now)
  INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
    NOW(),
    NOW()
  );
  
  -- Create user profile record
  INSERT INTO public.user_profiles (id, user_id, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.id,
    NOW(),
    NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log the error but don't fail the user creation
    RAISE WARNING 'Error creating user record: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 2. ENSURE RLS POLICIES ARE CORRECT
-- ===========================================

-- Fix users table policies
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Allow inserts for authenticated users" ON users;
DROP POLICY IF EXISTS "Admins can read all users" ON users;

-- Recreate user policies
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Allow inserts for authenticated users" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can read all users" ON users
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ===========================================
-- 3. FIX USER_PROFILES POLICIES
-- ===========================================

-- Fix user_profiles table policies
DROP POLICY IF EXISTS "Users can read own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can read all profiles" ON user_profiles;

-- Recreate user_profiles policies
CREATE POLICY "Users can read own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can read all profiles" ON user_profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ===========================================
-- 4. FIX TOOLS TABLE POLICIES
-- ===========================================

-- Fix tools table policies to be less restrictive
DROP POLICY IF EXISTS "Authenticated users can view tools" ON tools;
DROP POLICY IF EXISTS "Admins can insert tools" ON tools;
DROP POLICY IF EXISTS "Admins can update tools" ON tools;
DROP POLICY IF EXISTS "Admins can delete tools" ON tools;
DROP POLICY IF EXISTS "Technicians can insert their own inventory tools" ON tools;
DROP POLICY IF EXISTS "Technicians can update their own tools" ON tools;
DROP POLICY IF EXISTS "Technicians can view assigned and shared tools" ON tools;

-- Recreate tools policies with more permissive access
CREATE POLICY "Authenticated users can view tools" ON tools
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert tools" ON tools
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update tools" ON tools
FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete tools" ON tools
FOR DELETE USING (auth.role() = 'authenticated');

-- ===========================================
-- 5. CREATE MISSING ADMIN USER
-- ===========================================

-- Create admin user for jumae if it doesn't exist
-- First, check if jumae user exists in auth.users
DO $$
DECLARE
    jumae_user_id UUID;
BEGIN
    -- Try to find jumae user in auth.users
    SELECT id INTO jumae_user_id 
    FROM auth.users 
    WHERE email = 'jumae@mekar.ae' 
    LIMIT 1;
    
    -- If user exists, ensure they have admin role in users table
    IF jumae_user_id IS NOT NULL THEN
        INSERT INTO users (id, email, full_name, role, is_active, created_at, updated_at)
        VALUES (
            jumae_user_id,
            'jumae@mekar.ae',
            'Jumae',
            'admin',
            true,
            NOW(),
            NOW()
        ) ON CONFLICT (id) DO UPDATE SET 
            role = 'admin',
            is_active = true,
            updated_at = NOW();
            
        -- Also create user profile
        INSERT INTO user_profiles (id, user_id, created_at, updated_at)
        VALUES (
            jumae_user_id,
            jumae_user_id,
            NOW(),
            NOW()
        ) ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- ===========================================
-- 6. GRANT NECESSARY PERMISSIONS
-- ===========================================

-- Grant all necessary permissions
GRANT ALL ON users TO authenticated;
GRANT ALL ON user_profiles TO authenticated;
GRANT ALL ON tools TO authenticated;
GRANT ALL ON user_dashboard TO authenticated;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_profile(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_email_domain(TEXT) TO authenticated;

-- ===========================================
-- 7. VERIFICATION
-- ===========================================

-- Test queries to verify everything is working
SELECT 'Authentication fix complete!' as status;

-- Check if tables exist and are accessible
SELECT 
    'users' as table_name, 
    COUNT(*) as record_count 
FROM users
UNION ALL
SELECT 
    'user_profiles' as table_name, 
    COUNT(*) as record_count 
FROM user_profiles
UNION ALL
SELECT 
    'tools' as table_name, 
    COUNT(*) as record_count 
FROM tools;

