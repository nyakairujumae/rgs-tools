-- CHECK DATABASE STATUS
-- Run this to see what's wrong
-- Copy the output and share it with me

-- ===========================================
-- 1. CHECK IF TABLES EXIST
-- ===========================================

SELECT 'TABLES CHECK:' as section;

SELECT 
    tablename,
    CASE WHEN tablename IN (
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM (
    VALUES ('users'), ('user_profiles'), ('tools')
) AS t(tablename);

-- ===========================================
-- 2. CHECK TRIGGERS ON AUTH.USERS
-- ===========================================

SELECT 'TRIGGERS ON AUTH.USERS:' as section;

SELECT 
    tgname as trigger_name,
    '⚠️ BLOCKING AUTH' as status
FROM pg_trigger 
WHERE tgrelid = 'auth.users'::regclass;

-- If no triggers:
SELECT CASE 
    WHEN COUNT(*) = 0 THEN '✅ No triggers (GOOD)'
    ELSE '❌ Triggers found (BAD)'
END as trigger_status
FROM pg_trigger 
WHERE tgrelid = 'auth.users'::regclass;

-- ===========================================
-- 3. CHECK RLS STATUS
-- ===========================================

SELECT 'RLS STATUS:' as section;

SELECT 
    tablename,
    CASE WHEN rowsecurity THEN '⚠️ ENABLED (may block)' ELSE '✅ DISABLED' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'user_profiles', 'tools');

-- ===========================================
-- 4. CHECK POLICIES
-- ===========================================

SELECT 'POLICIES:' as section;

SELECT 
    tablename,
    COUNT(*) as policy_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ No policies'
        ELSE '⚠️ ' || COUNT(*)::text || ' policies (may block)'
    END as status
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('users', 'user_profiles', 'tools')
GROUP BY tablename;

-- ===========================================
-- 5. CHECK USER COUNTS
-- ===========================================

SELECT 'USER COUNTS:' as section;

SELECT 
    'Auth users:' as type,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Public users:' as type,
    COUNT(*) as count
FROM public.users
UNION ALL
SELECT 
    'User profiles:' as type,
    COUNT(*) as count
FROM public.user_profiles;

-- ===========================================
-- 6. CHECK FOR ORPHANED AUTH USERS
-- ===========================================

SELECT 'ORPHANED AUTH USERS (no public.users record):' as section;

SELECT 
    au.email,
    au.created_at,
    '❌ No public record' as issue
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id
WHERE u.id IS NULL;

-- ===========================================
-- 7. CHECK PERMISSIONS
-- ===========================================

SELECT 'TABLE PERMISSIONS:' as section;

SELECT 
    table_name,
    grantee,
    string_agg(privilege_type, ', ') as privileges
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name IN ('users', 'user_profiles', 'tools')
AND grantee IN ('authenticated', 'anon')
GROUP BY table_name, grantee
ORDER BY table_name, grantee;

-- ===========================================
-- 8. CHECK FOR CONSTRAINTS THAT MIGHT FAIL
-- ===========================================

SELECT 'CONSTRAINTS:' as section;

SELECT
    conrelid::regclass AS table_name,
    conname AS constraint_name,
    contype AS constraint_type
FROM pg_constraint
WHERE conrelid IN ('public.users'::regclass, 'public.user_profiles'::regclass)
ORDER BY table_name;

-- ===========================================
-- SUMMARY
-- ===========================================

SELECT '========================' as divider;
SELECT 'COPY ALL OUTPUT ABOVE AND SHARE WITH ME' as instruction;
SELECT '========================' as divider;






