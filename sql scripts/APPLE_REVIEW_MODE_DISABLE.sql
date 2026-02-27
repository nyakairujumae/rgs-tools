-- ===========================================
-- APPLE REVIEW MODE – DISABLE (run after App Store approval)
-- ===========================================
-- Removes the trigger that gave Sign in with Apple users automatic technician
-- access, and turns off the bypass flag. New Apple sign-ins will no longer
-- get a user record (effectively restricted). No app update required.

SET search_path = public;

-- ---------------------------------------------------------------------------
-- 1. Drop the Apple reviewer access trigger
-- ---------------------------------------------------------------------------
DROP TRIGGER IF EXISTS on_apple_signin_reviewer_access ON auth.users;

-- Optionally drop the function (keeps DB tidy; trigger is already inactive)
-- DROP FUNCTION IF EXISTS public.handle_apple_signin_reviewer_access();

-- ---------------------------------------------------------------------------
-- 2. Disable Apple bypass so Sign in with Apple is restricted again
-- ---------------------------------------------------------------------------
INSERT INTO app_settings (key, value, updated_at)
VALUES ('apple_bypass_approval', 'false', NOW())
ON CONFLICT (key) DO UPDATE SET value = 'false', updated_at = NOW();

SELECT 'Apple review mode DISABLED. New Apple sign-ins are restricted.' AS status;
