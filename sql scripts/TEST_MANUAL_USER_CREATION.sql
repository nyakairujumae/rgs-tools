-- TEST MANUAL USER CREATION
-- This tests if we can manually create user records
-- Run this in Supabase SQL Editor

-- ===========================================
-- 1. TEST INSERTING INTO USERS TABLE
-- ===========================================

-- Try to insert a test user record
DO $$
DECLARE
    test_id UUID := gen_random_uuid();
    insert_success BOOLEAN := false;
BEGIN
    RAISE NOTICE 'Testing manual user creation...';
    RAISE NOTICE 'Test ID: %', test_id;
    
    BEGIN
        INSERT INTO public.users (id, email, full_name, role, is_active, created_at, updated_at)
        VALUES (
            test_id, 
            'test@example.com', 
            'Test User', 
            'technician', 
            true, 
            NOW(), 
            NOW()
        );
        
        insert_success := true;
        RAISE NOTICE '✅ SUCCESS: Manual insert into users table worked!';
        
        -- Clean up the test record
        DELETE FROM public.users WHERE id = test_id;
        RAISE NOTICE '✅ Test record cleaned up';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ FAILED: Manual insert into users table failed!';
        RAISE NOTICE '❌ Error: %', SQLERRM;
        RAISE NOTICE '❌ Error Code: %', SQLSTATE;
    END;
    
    -- Report result
    IF insert_success THEN
        RAISE NOTICE '🎉 CONCLUSION: Manual user creation works!';
        RAISE NOTICE '🎉 The issue is NOT with the users table itself';
        RAISE NOTICE '🎉 The issue is likely with the auth trigger or RLS policies';
    ELSE
        RAISE NOTICE '💥 CONCLUSION: Manual user creation FAILED!';
        RAISE NOTICE '💥 The issue IS with the users table (permissions/constraints)';
    END IF;
    
END $$;

-- ===========================================
-- 2. TEST INSERTING INTO USER_PROFILES TABLE
-- ===========================================

DO $$
DECLARE
    test_id UUID := gen_random_uuid();
    insert_success BOOLEAN := false;
BEGIN
    RAISE NOTICE 'Testing manual user profile creation...';
    
    BEGIN
        INSERT INTO public.user_profiles (id, user_id, created_at, updated_at)
        VALUES (test_id, test_id, NOW(), NOW());
        
        insert_success := true;
        RAISE NOTICE '✅ SUCCESS: Manual insert into user_profiles table worked!';
        
        -- Clean up
        DELETE FROM public.user_profiles WHERE id = test_id;
        RAISE NOTICE '✅ Test profile cleaned up';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ FAILED: Manual insert into user_profiles table failed!';
        RAISE NOTICE '❌ Error: %', SQLERRM;
    END;
    
    IF insert_success THEN
        RAISE NOTICE '🎉 User profiles table is accessible!';
    ELSE
        RAISE NOTICE '💥 User profiles table has issues!';
    END IF;
    
END $$;

-- ===========================================
-- 3. CHECK CURRENT USER CONTEXT
-- ===========================================

SELECT 'CURRENT USER CONTEXT:' as section;

SELECT 
    'Current user: ' || current_user as current_user,
    'Current role: ' || current_role as current_role,
    'Session user: ' || session_user as session_user;

-- ===========================================
-- 4. CHECK IF WE'RE RUNNING AS AUTHENTICATED
-- ===========================================

SELECT 'AUTHENTICATION CONTEXT:' as section;

SELECT 
    'Auth role: ' || auth.role() as auth_role,
    'Auth UID: ' || COALESCE(auth.uid()::text, 'NULL') as auth_uid;

-- ===========================================
-- 5. FINAL DIAGNOSIS
-- ===========================================

SELECT '========================' as divider;
SELECT 'DIAGNOSIS COMPLETE' as status;
SELECT '========================' as divider;
SELECT 'If manual insert works but auth signup fails:' as note1;
SELECT '→ The issue is with the auth trigger or RLS policies' as conclusion1;
SELECT 'If manual insert also fails:' as note2;
SELECT '→ The issue is with table permissions or constraints' as conclusion2;
SELECT '========================' as divider;





