-- Fix user_fcm_tokens table to support multiple tokens per user (one per platform)
-- This allows users to have both Android and iOS tokens

-- Step 1: Drop the unique constraint on user_id (allows multiple tokens per user)
ALTER TABLE public.user_fcm_tokens 
DROP CONSTRAINT IF EXISTS user_fcm_tokens_user_id_key;

-- Step 2: Add unique constraint on (user_id, platform) instead
-- This allows one token per user per platform
DO $$ 
BEGIN
  -- Drop existing constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'user_fcm_tokens_user_id_platform_key'
  ) THEN
    ALTER TABLE public.user_fcm_tokens 
    DROP CONSTRAINT user_fcm_tokens_user_id_platform_key;
  END IF;
  
  -- Add new unique constraint on (user_id, platform)
  ALTER TABLE public.user_fcm_tokens 
  ADD CONSTRAINT user_fcm_tokens_user_id_platform_key 
  UNIQUE (user_id, platform);
END $$;

-- Step 3: Update RLS policies to ensure they work correctly
DROP POLICY IF EXISTS "Users can read own FCM tokens" ON public.user_fcm_tokens;
DROP POLICY IF EXISTS "Users can insert own FCM tokens" ON public.user_fcm_tokens;
DROP POLICY IF EXISTS "Users can update own FCM tokens" ON public.user_fcm_tokens;
DROP POLICY IF EXISTS "Users can delete own FCM tokens" ON public.user_fcm_tokens;
DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON public.user_fcm_tokens;

-- Recreate policies
CREATE POLICY "Users can read own FCM tokens"
  ON public.user_fcm_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own FCM tokens"
  ON public.user_fcm_tokens
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own FCM tokens"
  ON public.user_fcm_tokens
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own FCM tokens"
  ON public.user_fcm_tokens
  FOR DELETE
  USING (auth.uid() = user_id);

-- Step 4: Verify the changes
SELECT 
  '✅ Table structure updated' as status,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public' 
  AND table_name = 'user_fcm_tokens'
  AND constraint_type = 'UNIQUE';

SELECT '✅ user_fcm_tokens table now supports multiple tokens per user (one per platform)!' as status;
