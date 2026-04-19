-- ===========================================
-- ADMIN REVIEW BOOTSTRAP – CLOSE (run after the reviewer is done)
-- ===========================================
-- Counterpart to ADMIN_REVIEW_BOOTSTRAP_OPEN.sql. Forces the quota to 0,
-- removes the auto-decrement trigger, and restores the original
-- can_bootstrap_admin() behaviour (only allowed when no admins exist AND
-- the global allow flag is true).
--
-- Safe to run any time, even if OPEN was never run.

SET search_path = public;

-- ---------------------------------------------------------------------------
-- 1. Force quota to 0 (so even if the trigger is somehow gone, the door is shut)
-- ---------------------------------------------------------------------------
INSERT INTO app_settings (key, value, updated_at)
VALUES ('admin_bootstrap_quota', '0', NOW())
ON CONFLICT (key) DO UPDATE SET value = '0', updated_at = NOW();

-- ---------------------------------------------------------------------------
-- 2. Drop the auto-decrement trigger and helper function (no longer needed)
-- ---------------------------------------------------------------------------
DROP TRIGGER  IF EXISTS trg_consume_admin_bootstrap_quota ON public.users;
DROP FUNCTION IF EXISTS public.consume_admin_bootstrap_quota();

-- ---------------------------------------------------------------------------
-- 3. Restore the original can_bootstrap_admin() body — quota is ignored.
--    (Identical to ADMIN_BOOTSTRAP_GUARD.sql.)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_bootstrap_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  allow_flag  BOOLEAN;
  admin_count INTEGER;
BEGIN
  SELECT value::BOOLEAN
    INTO allow_flag
    FROM app_settings
   WHERE key = 'allow_admin_bootstrap';

  IF allow_flag IS NULL THEN
    allow_flag := TRUE;
  END IF;

  SELECT COUNT(*)
    INTO admin_count
    FROM public.users
   WHERE role = 'admin';

  RETURN allow_flag AND admin_count = 0;
END;
$$;

GRANT EXECUTE ON FUNCTION public.can_bootstrap_admin() TO anon, authenticated;

SELECT 'Admin review bootstrap CLOSED. Quota = 0, trigger removed, original guard restored.' AS status;
