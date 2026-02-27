-- DIAGNOSE_REAL_ISSUE.sql
-- Let's systematically diagnose what's actually happening

-- Step 1: Check if users table exists and its structure
SELECT 
    'USERS TABLE CHECK' as step,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') as table_exists;

-- Step 2: Check users table structure
SELECT 
    'USERS TABLE STRUCTURE' as step,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 3: Check if there are any foreign key constraints
SELECT 
    'FOREIGN KEY CONSTRAINTS' as step,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'users'
    AND tc.table_schema = 'public';

-- Step 4: Check RLS status
SELECT 
    'RLS STATUS' as step,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Step 5: Check existing policies
SELECT 
    'EXISTING POLICIES' as step,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public';

-- Step 6: Check if trigger exists
SELECT 
    'TRIGGER CHECK' as step,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' AND event_object_schema = 'auth';

-- Step 7: Check function exists
SELECT 
    'FUNCTION CHECK' as step,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user' AND routine_schema = 'public';

-- Step 8: Count existing users
SELECT 
    'USER COUNTS' as step,
    (SELECT COUNT(*) FROM auth.users) as auth_users_count,
    (SELECT COUNT(*) FROM public.users) as public_users_count;

-- Step 9: Check recent auth.users entries
SELECT 
    'RECENT AUTH USERS' as step,
    id,
    email,
    created_at,
    email_confirmed_at,
    raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- Step 10: Check if there are any errors in logs (if accessible)
SELECT 
    'DIAGNOSIS COMPLETE' as step,
    'Check the results above to identify the issue' as next_step;


