-- Remove Auto-Confirm for Technicians
-- This ensures technicians also receive confirmation emails like admins

-- ===========================================
-- STEP 1: Remove the auto-confirm trigger
-- ===========================================

DROP TRIGGER IF EXISTS on_technician_email_auto_confirm ON auth.users;

-- ===========================================
-- STEP 2: Drop the auto-confirm function
-- ===========================================

DROP FUNCTION IF EXISTS public.auto_confirm_technician_email() CASCADE;

-- ===========================================
-- STEP 3: Verify the trigger is removed
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
-- STEP 4: Check for any other auto-confirm triggers
-- ===========================================

SELECT 
  'Other triggers on auth.users' as info,
  tgname as trigger_name
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass
  AND tgname LIKE '%confirm%'
ORDER BY tgname;

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT '✅ Auto-confirm removed!' as status;
SELECT 'Technicians will now receive confirmation emails just like admins.' as message;

