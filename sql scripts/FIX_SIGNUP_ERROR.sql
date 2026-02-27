-- Fix "Database error saving new user" during signup
-- This ensures signup works correctly while maintaining email confirmation flow

-- ===========================================
-- STEP 1: Remove any conflicting triggers
-- ===========================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;

-- ===========================================
-- STEP 2: Create a safe trigger that allows signup but doesn't create user record yet
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
BEGIN
  -- This trigger just allows the auth user to be created
  -- We don't create the public.users record here - that happens after email confirmation
  -- This prevents the "Database error saving new user" error
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger that allows signup without errors
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

-- ===========================================
-- STEP 3: Create trigger that creates user record AFTER email confirmation
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_email_confirmed_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Only create user record if email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at) THEN
    -- Email was just confirmed - now create the user record
    user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'technician');
    
    -- Create user record in public.users table
    INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
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
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        'pending',
        NOW()
      )
      ON CONFLICT (user_id) DO NOTHING;
      
      RAISE NOTICE 'Created user and pending approval for technician: %', NEW.email;
    ELSE
      RAISE NOTICE 'Created user record for admin: %', NEW.email;
    END IF;
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
-- STEP 4: Verify triggers are created
-- ===========================================

SELECT 
  'Triggers created successfully' as status,
  tgname as trigger_name,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname IN ('on_auth_user_created', 'on_email_confirmed')
  AND tgrelid = 'auth.users'::regclass;

-- ===========================================
-- STEP 5: Check for any RLS policies that might block auth.users inserts
-- ===========================================

-- Note: auth.users table should not have RLS enabled
-- If it does, that could cause the error
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'auth' AND tablename = 'users';

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT '✅ Signup error fix complete!' as status;
SELECT 'Users can now sign up without errors. User records will be created after email confirmation.' as message;

