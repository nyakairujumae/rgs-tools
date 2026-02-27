-- DIAGNOSE THE ACTUAL AUTH ERROR
-- This will help us find what's really blocking authentication
-- Run this in Supabase SQL Editor

-- ===========================================
-- 1. CHECK FOR HIDDEN TRIGGERS ON AUTH.USERS
-- ===========================================

SELECT 'HIDDEN TRIGGERS ON AUTH.USERS:' as section;

SELECT 
    tgname as trigger_name,
    tgenabled as status,
    tgtype as trigger_type,
    '⚠️ This trigger might be blocking auth!' as warning
FROM pg_trigger 
WHERE tgrelid = 'auth.users'::regclass;

-- If no triggers found:
SELECT CASE 
    WHEN COUNT(*) = 0 THEN '✅ No triggers on auth.users (GOOD)'
    ELSE '❌ Found ' || COUNT(*)::text || ' triggers (BAD)'
END as trigger_status
FROM pg_trigger 
WHERE tgrelid = 'auth.users'::regclass;

-- ===========================================
-- 2. CHECK FOR FUNCTIONS THAT MIGHT BE CALLED
-- ===========================================

SELECT 'FUNCTIONS THAT MIGHT BLOCK AUTH:' as section;

SELECT 
    proname as function_name,
    proargnames as arguments,
    prosrc as source_code
FROM pg_proc 
WHERE proname IN (
    'handle_new_user',
    'check_email_domain', 
    'validate_email_domain',
    'handle_user_created',
    'on_auth_user_created'
);

-- ===========================================
-- 3. CHECK RLS ON PUBLIC TABLES
-- ===========================================

SELECT 'RLS STATUS ON PUBLIC TABLES:' as section;

SELECT 
    tablename,
    CASE WHEN rowsecurity THEN '⚠️ ENABLED (may block)' ELSE '✅ DISABLED' END as rls_status,
    CASE WHEN rowsecurity THEN 'This might block INSERT operations!' ELSE 'OK' END as impact
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'user_profiles', 'tools');

-- ===========================================
-- 4. CHECK POLICIES ON PUBLIC TABLES
-- ===========================================

SELECT 'POLICIES ON PUBLIC TABLES:' as section;

SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('users', 'user_profiles', 'tools')
ORDER BY tablename, policyname;

-- ===========================================
-- 5. CHECK TABLE PERMISSIONS
-- ===========================================

SELECT 'TABLE PERMISSIONS FOR AUTHENTICATED:' as section;

SELECT 
    table_name,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name IN ('users', 'user_profiles', 'tools')
AND grantee = 'authenticated'
ORDER BY table_name, privilege_type;

-- ===========================================
-- 6. CHECK IF TABLES EXIST AND ARE ACCESSIBLE
-- ===========================================

SELECT 'TABLE EXISTENCE CHECK:' as section;

-- Check if we can access the tables
DO $$
DECLARE
    user_count INTEGER;
    profile_count INTEGER;
    tool_count INTEGER;
BEGIN
    -- Try to count records in each table
    BEGIN
        SELECT COUNT(*) INTO user_count FROM public.users;
        RAISE NOTICE '✅ users table accessible, % records', user_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ users table error: %', SQLERRM;
    END;
    
    BEGIN
        SELECT COUNT(*) INTO profile_count FROM public.user_profiles;
        RAISE NOTICE '✅ user_profiles table accessible, % records', profile_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ user_profiles table error: %', SQLERRM;
    END;
    
    BEGIN
        SELECT COUNT(*) INTO tool_count FROM public.tools;
        RAISE NOTICE '✅ tools table accessible, % records', tool_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ tools table error: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- 7. CHECK FOR CONSTRAINTS THAT MIGHT FAIL
-- ===========================================

SELECT 'CONSTRAINTS ON PUBLIC TABLES:' as section;

SELECT
    conrelid::regclass AS table_name,
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid IN (
    'public.users'::regclass, 
    'public.user_profiles'::regclass,
    'public.tools'::regclass
)
ORDER BY table_name;

-- ===========================================
-- 8. CHECK AUTH USERS VS PUBLIC USERS
-- ===========================================

SELECT 'AUTH VS PUBLIC USER SYNC:' as section;

SELECT 
    'Auth users: ' || COUNT(*)::text as auth_count
FROM auth.users;

SELECT 
    'Public users: ' || COUNT(*)::text as public_count
FROM public.users;

-- Check for orphaned auth users
SELECT 
    'Orphaned auth users (no public.users record): ' || COUNT(*)::text as orphaned_count
FROM auth.users au
LEFT JOIN public.users pu ON pu.id = au.id
WHERE pu.id IS NULL;

-- ===========================================
-- 9. TEST INSERT PERMISSION
-- ===========================================

SELECT 'TESTING INSERT PERMISSIONS:' as section;

-- Try to insert a test record (will be rolled back)
DO $$
DECLARE
    test_id UUID := gen_random_uuid();
BEGIN
    BEGIN
        INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
        VALUES (test_id, 'test@example.com', 'Test User', 'technician', true, NOW(), NOW());
        
        RAISE NOTICE '✅ INSERT into users table works!';
        
        -- Rollback the test insert
        ROLLBACK;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ INSERT into users table FAILED: %', SQLERRM;
    END;
END $$;

-- ===========================================
-- SUMMARY
-- ===========================================

SELECT '========================' as divider;
SELECT 'COPY ALL OUTPUT ABOVE AND SHARE WITH ME' as instruction;
SELECT 'This will show us exactly what is blocking authentication' as purpose;
SELECT '========================' as divider;





