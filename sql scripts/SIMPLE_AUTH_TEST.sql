-- SIMPLE AUTH TEST
-- This will quickly identify the authentication issue
-- Run this in Supabase SQL Editor

-- ===========================================
-- 1. CHECK IF TABLES EXIST
-- ===========================================

SELECT 'STEP 1: CHECKING TABLES' as test;

-- Test if we can access the users table
SELECT 
    'users table exists: ' || 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') 
        THEN 'YES ✅' 
        ELSE 'NO ❌' 
    END as result;

-- Test if we can access user_profiles table
SELECT 
    'user_profiles table exists: ' || 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') 
        THEN 'YES ✅' 
        ELSE 'NO ❌' 
    END as result;

-- ===========================================
-- 2. CHECK RLS STATUS
-- ===========================================

SELECT 'STEP 2: CHECKING RLS' as test;

SELECT 
    tablename,
    CASE WHEN rowsecurity THEN 'ENABLED ⚠️' ELSE 'DISABLED ✅' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'user_profiles', 'tools');

-- ===========================================
-- 3. CHECK PERMISSIONS
-- ===========================================

SELECT 'STEP 3: CHECKING PERMISSIONS' as test;

SELECT 
    table_name,
    privilege_type,
    grantee
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name IN ('users', 'user_profiles')
AND grantee = 'authenticated'
ORDER BY table_name, privilege_type;

-- ===========================================
-- 4. TEST MANUAL INSERT
-- ===========================================

SELECT 'STEP 4: TESTING MANUAL INSERT' as test;

-- Try to insert a test record
DO $$
DECLARE
    test_id UUID := gen_random_uuid();
BEGIN
    -- Try to insert into users table
    BEGIN
        INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
        VALUES (test_id, 'test@example.com', 'Test User', 'technician', true, NOW(), NOW());
        
        RAISE NOTICE '✅ SUCCESS: Can insert into users table';
        
        -- Clean up
        DELETE FROM public.users WHERE id = test_id;
        RAISE NOTICE '✅ Test record cleaned up';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ FAILED: Cannot insert into users table';
        RAISE NOTICE '❌ Error: %', SQLERRM;
        RAISE NOTICE '❌ Error Code: %', SQLSTATE;
    END;
END $$;

-- ===========================================
-- 5. CHECK AUTH USERS
-- ===========================================

SELECT 'STEP 5: CHECKING AUTH USERS' as test;

SELECT 
    'Auth users count: ' || COUNT(*)::text as auth_users
FROM auth.users;

SELECT 
    'Public users count: ' || COUNT(*)::text as public_users
FROM public.users;

-- ===========================================
-- 6. FINAL DIAGNOSIS
-- ===========================================

SELECT '========================' as divider;
SELECT 'SIMPLE AUTH TEST COMPLETE' as status;
SELECT '========================' as divider;
SELECT 'Copy ALL output above and share with me' as instruction;





