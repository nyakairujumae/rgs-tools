-- ===========================================
-- Admin Bootstrap Guard (Option B)
-- ===========================================
-- Allows exactly one admin to self-register when bootstrap is open.
-- After the first admin is created, can_bootstrap_admin() returns false.

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO app_settings (key, value)
VALUES ('allow_admin_bootstrap', 'true')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.can_bootstrap_admin()
RETURNS BOOLEAN AS $$
DECLARE
  allow_flag BOOLEAN;
  admin_count INTEGER;
BEGIN
  SELECT value::BOOLEAN INTO allow_flag
  FROM app_settings
  WHERE key = 'allow_admin_bootstrap';

  IF allow_flag IS NULL THEN
    allow_flag := true;
  END IF;

  SELECT COUNT(*) INTO admin_count
  FROM public.users
  WHERE role = 'admin';

  RETURN allow_flag AND admin_count = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.can_bootstrap_admin() TO anon, authenticated;

-- Optional: close bootstrap manually
-- UPDATE app_settings SET value = 'false', updated_at = NOW() WHERE key = 'allow_admin_bootstrap';
