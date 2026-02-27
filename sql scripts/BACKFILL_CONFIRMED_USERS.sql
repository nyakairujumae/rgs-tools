-- Backfill public.users records for all confirmed users
-- This fixes the issue where users confirmed their email but don't have a public.users record

-- ===========================================
-- STEP 1: Create user records for all confirmed users who don't have one
-- ===========================================

INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) as full_name,
  COALESCE(au.raw_user_meta_data->>'role', 'technician') as role,
  au.created_at,
  NOW() as updated_at
FROM auth.users au
WHERE au.email_confirmed_at IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = au.id
  )
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = COALESCE(EXCLUDED.full_name, users.full_name),
  role = COALESCE(EXCLUDED.role, users.role),
  updated_at = NOW();

-- ===========================================
-- STEP 2: Create pending approvals for confirmed technicians who don't have one
-- ===========================================

INSERT INTO public.pending_user_approvals (
  user_id,
  email,
  full_name,
  status,
  submitted_at
)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) as full_name,
  'pending' as status,
  NOW() as submitted_at
FROM auth.users au
INNER JOIN public.users u ON u.id = au.id
WHERE au.email_confirmed_at IS NOT NULL
  AND COALESCE(au.raw_user_meta_data->>'role', 'technician') = 'technician'
  AND NOT EXISTS (
    SELECT 1 FROM public.pending_user_approvals pua WHERE pua.user_id = au.id
  )
ON CONFLICT (user_id) DO NOTHING;

-- ===========================================
-- STEP 3: Show summary of what was created
-- ===========================================

SELECT 
  '✅ Backfill complete!' as status,
  COUNT(*) as users_backfilled
FROM auth.users au
WHERE au.email_confirmed_at IS NOT NULL
  AND EXISTS (SELECT 1 FROM public.users u WHERE u.id = au.id);

-- Show users that were backfilled
SELECT 
  'Backfilled Users' as info,
  u.email,
  u.role,
  u.created_at
FROM public.users u
INNER JOIN auth.users au ON au.id = u.id
WHERE au.email_confirmed_at IS NOT NULL
ORDER BY u.created_at DESC;

