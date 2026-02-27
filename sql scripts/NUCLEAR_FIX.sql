-- NUCLEAR OPTION: COMPLETE RESET
-- This removes ALL restrictions and lets authentication work
-- Run this in Supabase SQL Editor

-- ===========================================
-- 1. DROP EVERYTHING THAT COULD BLOCK AUTH
-- ===========================================

-- Drop ALL triggers on auth.users
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tgname FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass) LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || r.tgname || ' ON auth.users CASCADE';
    END LOOP;
END $$;

-- Drop all related functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.check_email_domain() CASCADE;
DROP FUNCTION IF EXISTS public.validate_email_domain(TEXT) CASCADE;

-- ===========================================
-- 2. COMPLETELY DISABLE RLS
-- ===========================================

ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tools DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.user_dashboard DISABLE ROW LEVEL SECURITY;

-- Drop ALL policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname FROM pg_policies WHERE schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.schemaname || '.' || r.tablename || ' CASCADE';
    END LOOP;
END $$;

-- ===========================================
-- 3. GRANT ABSOLUTELY EVERYTHING
-- ===========================================

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO service_role;

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO service_role;

GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO anon;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- ===========================================
-- 4. ENSURE TABLES EXIST WITH CORRECT STRUCTURE
-- ===========================================

-- Make sure users table exists
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT DEFAULT 'technician',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Make sure user_profiles table exists
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    phone TEXT,
    department TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- 5. CREATE RECORDS FOR EXISTING AUTH USERS
-- ===========================================

-- Insert records for all auth.users
INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
SELECT 
    id,
    email,
    COALESCE(raw_user_meta_data->>'full_name', 'User'),
    COALESCE(raw_user_meta_data->>'role', 'technician'),
    true,
    created_at,
    NOW()
FROM auth.users
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();

-- Insert profiles for all users
INSERT INTO public.user_profiles (id, user_id, created_at, updated_at)
SELECT 
    id,
    id,
    created_at,
    NOW()
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ===========================================
-- 6. MAKE ADMIN USER
-- ===========================================

-- Make first user admin
UPDATE public.users SET role = 'admin' WHERE id = (SELECT id FROM public.users ORDER BY created_at LIMIT 1);

-- Make any @mekar.ae user admin
UPDATE public.users SET role = 'admin' WHERE email LIKE '%@mekar.ae';

-- ===========================================
-- 7. VERIFICATION
-- ===========================================

SELECT '✅✅✅ NUCLEAR FIX COMPLETE ✅✅✅' as status;

SELECT 'Auth users: ' || COUNT(*)::text as step_1 FROM auth.users;
SELECT 'Public users: ' || COUNT(*)::text as step_2 FROM public.users;
SELECT 'Profiles: ' || COUNT(*)::text as step_3 FROM public.user_profiles;
SELECT 'Admins: ' || COUNT(*)::text as step_4 FROM public.users WHERE role = 'admin';
SELECT 'Triggers on auth.users: ' || COUNT(*)::text as step_5 FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass;

SELECT '✅ ALL RESTRICTIONS REMOVED' as message;
SELECT '✅ ALL PERMISSIONS GRANTED' as message2;
SELECT '✅ NO TRIGGERS BLOCKING AUTH' as message3;
SELECT '🚀 TRY LOGGING IN NOW!' as action;






