-- Fix Email Confirmation User Creation
-- This ensures user records are created after email confirmation even if role check fails
-- The trigger should create user records when email is confirmed and role exists in metadata

SET search_path = public;

-- ===========================================
-- STEP 1: Update handle_email_confirmed_user to be more robust
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_email_confirmed_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_full_name TEXT;
BEGIN
  -- Only create user record if email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at) THEN
    -- Email was just confirmed - now create the user record
    -- Get role from metadata - use ->> operator to get text directly
    user_role := NEW.raw_user_meta_data->>'role';
    user_full_name := COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      split_part(NEW.email, '@', 1)
    );
    
    -- Log what we found for debugging
    RAISE NOTICE 'Email confirmed for user: %, role in metadata: %, full_name: %', 
      NEW.email, user_role, user_full_name;
    
    -- Only proceed if role is explicitly set (not null and not empty)
    IF user_role IS NULL OR user_role = '' OR user_role = 'null' THEN
      RAISE WARNING 'User % has no valid role in metadata (found: %) - skipping user record creation. User must register with explicit role.', 
        NEW.email, user_role;
      RETURN NEW; -- Don't create user record if role is not set
    END IF;
    
    BEGIN
      -- Create user record in public.users table
      INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
      VALUES (
        NEW.id,
        NEW.email,
        user_full_name,
        user_role, -- Use explicit role from metadata
        NOW(),
        NOW()
      )
      ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        updated_at = NOW();
      
      RAISE NOTICE '✅ Created user record for % with role: %', NEW.email, user_role;
      
      -- For technicians, create pending approval
      IF LOWER(user_role) = 'technician' THEN
        -- Create pending approval record
        INSERT INTO public.pending_user_approvals (
          user_id,
          email,
          full_name,
          status,
          submitted_at
        )
        VALUES (
          NEW.id,
          NEW.email,
          user_full_name,
          'pending',
          NOW()
        )
        ON CONFLICT (user_id) DO NOTHING;
        
        RAISE NOTICE '✅ Created pending approval for technician: %', NEW.email;
      ELSE
        RAISE NOTICE '✅ User record created for %: %', user_role, NEW.email;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- Log error but don't fail the trigger
        RAISE WARNING '❌ Error creating user record for %: % (SQLSTATE: %)', 
          NEW.email, SQLERRM, SQLSTATE;
    END;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the trigger
    RAISE WARNING '❌ Error in handle_email_confirmed_user for %: % (SQLSTATE: %)', 
      NEW.email, SQLERRM, SQLSTATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ===========================================
-- STEP 2: Verify trigger exists and is active
-- ===========================================

-- Drop and recreate trigger to ensure it's active
DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;

CREATE TRIGGER on_email_confirmed
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  WHEN (NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at))
  EXECUTE FUNCTION public.handle_email_confirmed_user();

-- ===========================================
-- STEP 3: Backfill any users who confirmed email but don't have user records
-- ===========================================

-- Create user records for confirmed users who don't have records yet
-- Only if they have a role in metadata
INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  COALESCE(
    au.raw_user_meta_data->>'full_name',
    split_part(au.email, '@', 1)
  ) as full_name,
  au.raw_user_meta_data->>'role' as role,
  au.created_at,
  NOW()
FROM auth.users au
WHERE au.email_confirmed_at IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = au.id
  )
  AND (
    au.raw_user_meta_data->>'role' IS NOT NULL 
    AND au.raw_user_meta_data->>'role' != ''
    AND au.raw_user_meta_data->>'role' != 'null'
  )
ON CONFLICT (id) DO NOTHING;

-- ===========================================
-- STEP 4: Verify the fix
-- ===========================================

-- Check if trigger exists
SELECT 
  'Trigger Status' as info,
  tgname as trigger_name,
  tgenabled as enabled
FROM pg_trigger
WHERE tgname = 'on_email_confirmed';

-- Check function exists
SELECT 
  'Function Status' as info,
  proname as function_name,
  prosrc as source_code
FROM pg_proc
WHERE proname = 'handle_email_confirmed_user';

-- Show any users who confirmed email but don't have user records (should be 0 after fix)
SELECT 
  'Users needing records' as info,
  COUNT(*) as count
FROM auth.users au
WHERE au.email_confirmed_at IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = au.id
  )
  AND (
    au.raw_user_meta_data->>'role' IS NOT NULL 
    AND au.raw_user_meta_data->>'role' != ''
    AND au.raw_user_meta_data->>'role' != 'null'
  );



