-- Fix user_fcm_tokens table structure and RLS policies
-- This ensures FCM tokens can be saved properly

-- ===========================================
-- STEP 1: Create table if it doesn't exist
-- ===========================================

CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  fcm_token TEXT NOT NULL,
  platform TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, platform) -- Ensure one token per user per platform
);

-- ===========================================
-- STEP 2: Add missing columns if they exist
-- ===========================================

-- Add platform column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'user_fcm_tokens' 
    AND column_name = 'platform'
  ) THEN
    ALTER TABLE public.user_fcm_tokens ADD COLUMN platform TEXT;
  END IF;
END $$;

-- Add created_at column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'user_fcm_tokens' 
    AND column_name = 'created_at'
  ) THEN
    ALTER TABLE public.user_fcm_tokens ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- ===========================================
-- STEP 3: Ensure unique constraint on (user_id, platform)
-- ===========================================

-- Drop old unique constraints if they exist
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'user_fcm_tokens_user_id_key'
  ) THEN
    ALTER TABLE public.user_fcm_tokens DROP CONSTRAINT user_fcm_tokens_user_id_key;
  END IF;
END $$;

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'user_fcm_tokens_user_id_platform_key'
  ) THEN
    ALTER TABLE public.user_fcm_tokens DROP CONSTRAINT user_fcm_tokens_user_id_platform_key;
  END IF;
END $$;

-- Add unique constraint on (user_id, platform)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'user_fcm_tokens_user_id_platform_key'
  ) THEN
    ALTER TABLE public.user_fcm_tokens 
    ADD CONSTRAINT user_fcm_tokens_user_id_platform_key 
    UNIQUE (user_id, platform);
  END IF;
END $$;

-- ===========================================
-- STEP 3.1: Enforce one active token per user/platform
-- ===========================================

CREATE OR REPLACE FUNCTION public.enforce_single_fcm_token()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM public.user_fcm_tokens
  WHERE user_id = NEW.user_id
    AND platform = NEW.platform;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_single_fcm_token_trigger ON public.user_fcm_tokens;

CREATE TRIGGER enforce_single_fcm_token_trigger
BEFORE INSERT ON public.user_fcm_tokens
FOR EACH ROW
EXECUTE FUNCTION public.enforce_single_fcm_token();

-- ===========================================
-- STEP 4: Enable RLS
-- ===========================================

ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- STEP 5: Drop existing policies (if any)
-- ===========================================

DROP POLICY IF EXISTS "Users can read own FCM tokens" ON public.user_fcm_tokens;
DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON public.user_fcm_tokens;
DROP POLICY IF EXISTS "Users can insert own FCM tokens" ON public.user_fcm_tokens;
DROP POLICY IF EXISTS "Users can update own FCM tokens" ON public.user_fcm_tokens;
DROP POLICY IF EXISTS "Users can delete own FCM tokens" ON public.user_fcm_tokens;

-- ===========================================
-- STEP 6: Create RLS policies
-- ===========================================

-- Policy: Users can read their own tokens
CREATE POLICY "Users can read own FCM tokens"
  ON public.user_fcm_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own tokens
CREATE POLICY "Users can insert own FCM tokens"
  ON public.user_fcm_tokens
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own tokens
CREATE POLICY "Users can update own FCM tokens"
  ON public.user_fcm_tokens
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own tokens
CREATE POLICY "Users can delete own FCM tokens"
  ON public.user_fcm_tokens
  FOR DELETE
  USING (auth.uid() = user_id);

-- ===========================================
-- STEP 7: Create index for faster lookups
-- ===========================================

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON public.user_fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_fcm_token ON public.user_fcm_tokens(fcm_token);

-- ===========================================
-- STEP 8: Verify table structure
-- ===========================================

SELECT 
  '✅ Table structure verified' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'user_fcm_tokens'
ORDER BY ordinal_position;

-- ===========================================
-- STEP 9: Verify RLS policies
-- ===========================================

SELECT 
  '✅ RLS policies verified' as status,
  policyname,
  cmd as operation
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'user_fcm_tokens';

-- ===========================================
-- STEP 9: Cleanup old tokens (optional scheduled job)
-- ===========================================

CREATE OR REPLACE FUNCTION public.cleanup_old_fcm_tokens(max_age_days integer DEFAULT 90)
RETURNS void AS $$
BEGIN
  DELETE FROM public.user_fcm_tokens
  WHERE updated_at < NOW() - make_interval(days => max_age_days);
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF NOT EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup_fcm_tokens') THEN
      PERFORM cron.schedule(
        'cleanup_fcm_tokens',
        '0 3 * * *',
        'select public.cleanup_old_fcm_tokens(90);'
      );
    END IF;
  END IF;
END $$;

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT '✅ user_fcm_tokens table fixed and ready!' as status;
SELECT 'Users can now save FCM tokens. Make sure to log in and the app will automatically save tokens.' as message;
