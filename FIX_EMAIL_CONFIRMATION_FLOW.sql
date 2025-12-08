-- Fix Email Confirmation Flow
-- This ensures users are only created AFTER email confirmation
-- Admins: Must confirm email before user record is created
-- Technicians: Must confirm email before user record is created

-- ===========================================
-- STEP 1: Remove the old trigger that creates users immediately
-- ===========================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- ===========================================
-- STEP 2: Create new trigger that only creates user AFTER email confirmation
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_email_confirmed_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Only create user record if email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;

-- Create trigger that fires when email_confirmed_at changes from NULL to NOT NULL
CREATE TRIGGER on_email_confirmed
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  WHEN (NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL)
  EXECUTE FUNCTION public.handle_email_confirmed_user();

-- ===========================================
-- STEP 3: Handle users who already confirmed but don't have user record
-- ===========================================

-- Create user records for any existing confirmed users who don't have a record
INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)),
  COALESCE(au.raw_user_meta_data->>'role', 'technician'),
  au.created_at,
  NOW()
FROM auth.users au
WHERE au.email_confirmed_at IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.users u WHERE u.id = au.id
  )
ON CONFLICT (id) DO NOTHING;

-- ===========================================
-- STEP 4: Verify triggers
-- ===========================================

SELECT 
  'Email confirmation trigger created' as status,
  tgname as trigger_name,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'on_email_confirmed';


