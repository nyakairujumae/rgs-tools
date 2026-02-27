-- =====================================================
-- SIMPLE AUTH TEST
-- =====================================================
-- This will test if the basic auth setup works
-- =====================================================

-- Check if we can insert into users table manually
INSERT INTO public.users (id, email, full_name, role, created_at)
VALUES (
    gen_random_uuid(),
    'test@example.com',
    'Test User',
    'technician',
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Check if the insert worked
SELECT 
    'Manual Insert Test' as test,
    COUNT(*) as count
FROM public.users
WHERE email = 'test@example.com';

-- Check auth.users table
SELECT 
    'Auth Users Count' as info,
    COUNT(*) as count
FROM auth.users;

-- Check if trigger exists
SELECT 
    'Trigger Check' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Check if function exists
SELECT 
    'Function Check' as info,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- Show all users
SELECT 
    'All Users' as info,
    email,
    role,
    created_at
FROM public.users
ORDER BY created_at DESC;



