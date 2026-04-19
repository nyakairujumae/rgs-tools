-- ===========================================
-- ADMIN REVIEW BOOTSTRAP – OPEN (run before App Store / Play Store review)
-- ===========================================
-- Temporarily allows ONE additional admin to self-register, even though
-- admins already exist in the system. After that single registration the
-- quota self-decrements via a trigger and admin self-registration closes
-- again automatically. No app update required.
--
-- Re-running this script resets the quota back to 1.
-- To force-close at any time, run ADMIN_REVIEW_BOOTSTRAP_CLOSE.sql.
--
-- HOW TO RUN: paste this whole file into the Supabase SQL editor and
-- click Run once. can_bootstrap_admin() is written in LANGUAGE sql
-- (no DECLARE/BEGIN), which avoids editor parsers that occasionally
-- mis-split plpgsql bodies on internal semicolons.

-- ---------------------------------------------------------------------------
-- 1. Ensure app_settings exists (defined in ADMIN_BOOTSTRAP_GUARD.sql but
--    we re-declare here so this script is self-contained).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- 2. Set / reset the quota to 1 (one extra admin allowed)
-- ---------------------------------------------------------------------------
INSERT INTO public.app_settings (key, value, updated_at)
VALUES ('admin_bootstrap_quota', '1', NOW())
ON CONFLICT (key) DO UPDATE SET value = '1', updated_at = NOW();

-- ---------------------------------------------------------------------------
-- 3. Replace can_bootstrap_admin() so it ALSO honours the quota.
--    Pure SQL function — single expression, no DECLARE/INTO blocks.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_bootstrap_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $func$
  SELECT
    (
      COALESCE(
        (SELECT value::BOOLEAN
           FROM public.app_settings
          WHERE key = 'allow_admin_bootstrap'),
        TRUE
      )
      AND
      (SELECT COUNT(*) FROM public.users WHERE role = 'admin') = 0
    )
    OR
    (
      COALESCE(
        (SELECT NULLIF(value, '')::INTEGER
           FROM public.app_settings
          WHERE key = 'admin_bootstrap_quota'),
        0
      ) > 0
    );
$func$;

GRANT EXECUTE ON FUNCTION public.can_bootstrap_admin() TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Auto-decrement the quota the moment a new admin row is inserted, so
--    after the reviewer signs up the door closes again with no human
--    intervention. plpgsql is required for triggers but the body is
--    deliberately tiny.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.consume_admin_bootstrap_quota()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $trg$
BEGIN
  IF NEW.role = 'admin' THEN
    UPDATE public.app_settings
       SET value = GREATEST(
                     COALESCE(NULLIF(value, '')::INTEGER, 0) - 1,
                     0
                   )::TEXT,
           updated_at = NOW()
     WHERE key = 'admin_bootstrap_quota';
  END IF;
  RETURN NEW;
END;
$trg$;

DROP TRIGGER IF EXISTS trg_consume_admin_bootstrap_quota ON public.users;
CREATE TRIGGER trg_consume_admin_bootstrap_quota
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.consume_admin_bootstrap_quota();

SELECT 'Admin review bootstrap OPEN. Quota = 1. Will auto-close after first admin signs up. Run ADMIN_REVIEW_BOOTSTRAP_CLOSE.sql to revoke manually.' AS status;
