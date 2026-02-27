-- ===========================================
-- APPLE REVIEW MODE – ENABLE (run before App Store submission)
-- ===========================================
-- Lets Sign in with Apple work for reviewers: any new Apple sign-in gets
-- a technician account and approved status so they can use the app.
-- After approval, run APPLE_REVIEW_MODE_DISABLE.sql to restrict again.
-- No app resubmission needed.

SET search_path = public;

-- ---------------------------------------------------------------------------
-- 1. Ensure app_settings table exists and set Apple bypass for review period
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO app_settings (key, value, updated_at)
VALUES ('apple_bypass_approval', 'true', NOW())
ON CONFLICT (key) DO UPDATE SET value = 'true', updated_at = NOW();

-- ---------------------------------------------------------------------------
-- 2. Trigger: on new Apple sign-in, create public.users + approved pending
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_apple_signin_reviewer_access()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  provider_val TEXT;
  user_email TEXT;
  user_name TEXT;
BEGIN
  -- Only run for Apple provider (Supabase sets this in raw_app_meta_data on insert)
  provider_val := COALESCE(NEW.raw_app_meta_data->>'provider', '');
  IF provider_val <> 'apple' THEN
    RETURN NEW;
  END IF;

  user_email := COALESCE(NEW.email, '');
  user_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(user_email, '@', 1),
    'Reviewer'
  );

  BEGIN
    -- Create public.users so the app finds a role (technician)
    INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
    VALUES (
      NEW.id,
      user_email,
      user_name,
      'technician',
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      role = 'technician',
      updated_at = NOW();

    -- Create approved pending approval so they are treated as approved
    -- (If a row already exists we insert another; app uses latest by created_at.)
    INSERT INTO public.pending_user_approvals (
      user_id,
      email,
      full_name,
      status,
      submitted_at,
      reviewed_at
    )
    VALUES (
      NEW.id,
      user_email,
      user_name,
      'approved',
      NOW(),
      NOW()
    );

    RAISE NOTICE 'Apple review access: created/updated user and approval for %', user_email;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'handle_apple_signin_reviewer_access: %', SQLERRM;
  END;

  RETURN NEW;
END;
$$;

-- Drop if exists so we can re-run this script safely
DROP TRIGGER IF EXISTS on_apple_signin_reviewer_access ON auth.users;

CREATE TRIGGER on_apple_signin_reviewer_access
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_apple_signin_reviewer_access();

SELECT 'Apple review mode ENABLED. Run APPLE_REVIEW_MODE_DISABLE.sql after approval.' AS status;
