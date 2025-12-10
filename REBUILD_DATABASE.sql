-- =====================================================
-- COMPLETE DATABASE REBUILD
-- =====================================================
-- This script will:
-- 1. Drop ALL existing tables, triggers, functions
-- 2. Recreate everything from scratch
-- 3. Set up proper authentication
-- =====================================================

-- STEP 1: Drop EVERYTHING
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.tools CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.tool_assignments CASCADE;
DROP TABLE IF EXISTS public.tool_checkouts CASCADE;

-- Drop all functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.create_user_profile() CASCADE;
DROP FUNCTION IF EXISTS public.validate_email_domain() CASCADE;
DROP FUNCTION IF EXISTS public.check_email_domain() CASCADE;

-- Drop all triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP TRIGGER IF EXISTS create_user_profile ON auth.users;
DROP TRIGGER IF EXISTS check_email_domain_trigger ON auth.users;

-- STEP 2: Create clean users table
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    role TEXT NOT NULL DEFAULT 'technician',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 3: Create tools table
CREATE TABLE public.tools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    status TEXT NOT NULL DEFAULT 'Available',
    tool_type TEXT NOT NULL DEFAULT 'inventory',
    assigned_to UUID REFERENCES public.users(id),
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    image_url TEXT,
    serial_number TEXT,
    location TEXT,
    condition TEXT DEFAULT 'Good',
    value DECIMAL(10,2),
    notes TEXT
);

-- STEP 4: NO RLS - Keep it simple
-- (No RLS policies - just grant permissions)

-- STEP 5: Grant ALL permissions
GRANT ALL ON public.users TO postgres, anon, authenticated, service_role;
GRANT ALL ON public.tools TO postgres, anon, authenticated, service_role;
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;

-- STEP 6: Create simple trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
    -- Simple insert, no validation
    INSERT INTO public.users (id, email, full_name, role, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- STEP 7: Migrate existing auth users
INSERT INTO public.users (id, email, full_name, role, created_at)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) as full_name,
    COALESCE(au.raw_user_meta_data->>'role', 'technician') as role,
    au.created_at
FROM auth.users au
ON CONFLICT (id) DO NOTHING;

-- STEP 8: Show results
SELECT 
    'Auth Users' as table_name,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Public Users' as table_name,
    COUNT(*) as count
FROM public.users;

-- Show all users
SELECT 
    'All Users' as info,
    email,
    role,
    created_at
FROM public.users
ORDER BY created_at DESC;

-- SUCCESS
SELECT 'DATABASE REBUILT SUCCESSFULLY!' as status;



