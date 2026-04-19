-- ===========================================
-- ADMIN REVIEW BOOTSTRAP – OPEN (run before App Store / Play Store review)
-- ===========================================
-- Temporarily allows ONE additional admin to self-register, even though
-- admins already exist in the system. After that single registration the
-- quota self-decrements via a trigger and admin self-registration closes
-- again automatically. No app update required.
--
-- Re-running this script resets the quota back to 1.
-- To bump it (e.g. allow 2 reviewers), edit `bootstrap_quota` value below
-- before running, or run the script multiple times — it sets, not adds.
--
-- To force-close at any time, run ADMIN_REVIEW_BOOTSTRAP_CLOSE.sql.

SET search_path = public;

-- ---------------------------------------------------------------------------
-- 1. Ensure app_settings exists (defined in ADMIN_BOOTSTRAP_GUARD.sql but
--    we re-declare here so this script is self-contained).
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ---------------------------------------------------------------------------
-- 2. Set / reset the quota to 1 (one extra admin allowed)
-- ---------------------------------------------------------------------------
INSERT INTO app_settings (key, value, updated_at)
VALUES ('admin_bootstrap_quota', '1', NOW())
ON CONFLICT (key) DO UPDATE SET value = '1', updated_at = NOW();

-- ---------------------------------------------------------------------------
-- 3. Replace can_bootstrap_admin() so it ALSO honours the quota.
--    Original behaviour (zero admins + allow flag) is preserved.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_bootstrap_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  allow_flag    BOOLEAN;
  admin_count   INTEGER;
  quota_value   INTEGER;
BEGIN
  -- Original guard flag (defaults to true for backward compatibility)
  SELECT value::BOOLEAN
    INTO allow_flag
    FROM app_settings
   WHERE key = 'allow_admin_bootstrap';
  IF allow_flag IS NULL THEN
    allow_flag := TRUE;
  END IF;

  -- Review-mode quota (defaults to 0 when missing)
  SELECT COALESCE(NULLIF(value, '')::INTEGER, 0)
    INTO quota_value
    FROM app_settings
   WHERE key = 'admin_bootstrap_quota';
  IF quota_value IS NULL THEN
    quota_value := 0;
  END IF;

  SELECT COUNT(*)
    INTO admin_count
    FROM public.users
   WHERE role = 'admin';

  -- Allow when:
  --   a) original bootstrap path: no admins yet AND flag enabled, OR
  --   b) review path:            quota > 0 (independent of admin count).
  RETURN (allow_flag AND admin_count = 0) OR (quota_value > 0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.can_bootstrap_admin() TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Auto-decrement the quota the moment a new admin row is inserted, so
--    after the reviewer signs up the door closes again with no human
--    intervention.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.consume_admin_bootstrap_quota()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_quota INTEGER;
BEGIN
  IF NEW.role <> 'admin' THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(NULLIF(value, '')::INTEGER, 0)
    INTO current_quota
    FROM app_settings
   WHERE key = 'admin_bootstrap_quota';

  IF current_quota IS NULL OR current_quota <= 0 THEN
    RETURN NEW;
  END IF;

  UPDATE app_settings
     SET value = (current_quota - 1)::TEXT,
         updated_at = NOW()
   WHERE key = 'admin_bootstrap_quota';

  RAISE NOTICE 'admin_bootstrap_quota decremented from % to %',
    current_quota, current_quota - 1;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_consume_admin_bootstrap_quota ON public.users;
CREATE TRIGGER trg_consume_admin_bootstrap_quota
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.consume_admin_bootstrap_quota();

SELECT 'Admin review bootstrap OPEN. Quota = 1. Will auto-close after first admin signs up. Run ADMIN_REVIEW_BOOTSTRAP_CLOSE.sql to revoke manually.' AS status;
