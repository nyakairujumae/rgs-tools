-- Cleanup Email Confirmation Bypass
-- This removes any auto-confirm triggers that bypass email confirmation
-- Run this to ensure email confirmation works properly for technicians

-- ===========================================
-- STEP 1: Check if auto-confirm trigger exists
-- ===========================================

SELECT 
  'Checking for auto-confirm triggers...' as status,
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  CASE WHEN tgenabled = 'O' THEN 'Enabled ⚠️' ELSE 'Disabled ✅' END as status
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
  AND (tgname LIKE '%auto_confirm%' OR tgname LIKE '%confirm%')
ORDER BY tgname;

-- ===========================================
-- STEP 2: Remove auto-confirm trigger if it exists
-- ===========================================

DROP TRIGGER IF EXISTS on_technician_email_auto_confirm ON auth.users;

-- ===========================================
-- STEP 3: Drop auto-confirm function if it exists
-- ===========================================

DROP FUNCTION IF EXISTS public.auto_confirm_technician_email() CASCADE;

-- ===========================================
-- STEP 4: Verify the trigger is removed
-- ===========================================

SELECT 
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ Auto-confirm trigger removed successfully'
    ELSE '⚠️ Trigger still exists: ' || string_agg(tgname, ', ')
  END as status
FROM pg_trigger
WHERE tgname = 'on_technician_email_auto_confirm'
  AND tgrelid = 'auth.users'::regclass;

-- ===========================================
-- STEP 5: Verify email confirmation trigger exists
-- ===========================================

SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Email confirmation trigger exists'
    ELSE '⚠️ Email confirmation trigger NOT found - run FIX_EMAIL_CONFIRMATION_FLOW.sql'
  END as status,
  string_agg(tgname, ', ') as trigger_names
FROM pg_trigger
WHERE tgname = 'on_email_confirmed'
  AND tgrelid = 'auth.users'::regclass;

-- ===========================================
-- STEP 6: Check handle_email_confirmed_user function
-- ===========================================

SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ handle_email_confirmed_user function exists'
    ELSE '⚠️ Function NOT found - run FIX_EMAIL_CONFIRMATION_FLOW.sql'
  END as status
FROM pg_proc
WHERE proname = 'handle_email_confirmed_user'
  AND pronamespace = 'public'::regnamespace;

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT '✅ Cleanup complete!' as status;
SELECT 'Email confirmation bypass removed. Technicians will now receive confirmation emails and go to pending approval screen after confirming.' as message;
