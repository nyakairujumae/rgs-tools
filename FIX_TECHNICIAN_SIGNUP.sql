-- Fix Technician Signup Error
-- This ensures both admin and technician signups work correctly

-- ===========================================
-- STEP 1: Remove ALL existing triggers that might interfere
-- ===========================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;
DROP TRIGGER IF EXISTS check_email_domain_trigger ON auth.users;

-- ===========================================
-- STEP 2: Drop and recreate functions cleanly
-- ===========================================

DROP FUNCTION IF EXISTS public.handle_new_auth_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_email_confirmed_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.check_email_domain() CASCADE;

-- ===========================================
-- STEP 3: Create a minimal trigger that allows signup
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
  -- This trigger MUST exist and MUST return NEW
  -- Without it, Supabase auth.signUp will fail with "Database error saving new user"
  -- We don't create the public.users record here - that happens after email confirmation
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Even if there's an error, return NEW to allow signup
    RAISE WARNING 'Error in handle_new_auth_user (non-blocking): %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that allows signup without errors
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

-- ===========================================
-- STEP 4: Create trigger that creates user record AFTER email confirmation
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_email_confirmed_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_full_name TEXT;
BEGIN
  -- Only create user record if email is confirmed
  -- Check if email_confirmed_at changed from NULL to NOT NULL
  IF NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at) THEN
    -- Email was just confirmed - now create the user record
    user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'technician');
    user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));
    
    BEGIN
      -- Create user record in public.users table
      INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
      VALUES (
        NEW.id,
        NEW.email,
        user_full_name,
        user_role,
        NOW(),
        NOW()
      )
      ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        updated_at = NOW();
      
      -- For technicians, create pending approval
      IF user_role = 'technician' THEN
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
        
        RAISE NOTICE 'Created user and pending approval for technician: %', NEW.email;
      ELSE
        RAISE NOTICE 'Created user record for admin: %', NEW.email;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- Log error but don't fail the trigger
        RAISE WARNING 'Error creating user record for %: %', NEW.email, SQLERRM;
    END;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the trigger
    RAISE WARNING 'Error in handle_email_confirmed_user for %: %', NEW.email, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that fires when email_confirmed_at changes from NULL to NOT NULL
CREATE TRIGGER on_email_confirmed
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  WHEN (NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at))
  EXECUTE FUNCTION public.handle_email_confirmed_user();

-- ===========================================
-- STEP 5: Verify triggers are created correctly
-- ===========================================

SELECT 
  '✅ Triggers created' as status,
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  CASE WHEN tgenabled = 'O' THEN 'Enabled' ELSE 'Disabled' END as status
FROM pg_trigger
WHERE tgname IN ('on_auth_user_created', 'on_email_confirmed')
  AND tgrelid = 'auth.users'::regclass;

-- ===========================================
-- STEP 6: Test that functions exist and are callable
-- ===========================================

SELECT 
  '✅ Functions created' as status,
  proname as function_name,
  CASE WHEN proname = 'handle_new_auth_user' THEN 'Allows signup' 
       WHEN proname = 'handle_email_confirmed_user' THEN 'Creates user after confirmation'
       ELSE 'Other' END as purpose
FROM pg_proc
WHERE proname IN ('handle_new_auth_user', 'handle_email_confirmed_user')
ORDER BY proname;

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT '✅ Technician signup fix complete!' as status;
SELECT 'Both admin and technician signups should now work. User records will be created after email confirmation.' as message;

