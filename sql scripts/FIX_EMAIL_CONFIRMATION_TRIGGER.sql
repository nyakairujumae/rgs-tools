-- Fix Email Confirmation Trigger
-- CRITICAL: Technicians should NOT have a user record until approved
-- Only create pending approval when email is confirmed
-- User record is created by approve_pending_user() function when admin approves

-- ===========================================
-- STEP 1: Update handle_email_confirmed_user function
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_email_confirmed_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_full_name TEXT;
BEGIN
  -- Only process if email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at) THEN
    -- Email was just confirmed
    user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'technician');
    user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));
    
    BEGIN
      IF user_role = 'admin' THEN
        -- For admins, create user record immediately after email confirmation
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
        
        RAISE NOTICE 'Created user record for admin: %', NEW.email;
      ELSIF user_role = 'technician' THEN
        -- CRITICAL: For technicians, ONLY create pending approval
        -- DO NOT create user record - that happens when admin approves
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
        
        RAISE NOTICE 'Created pending approval for technician: % (user record will be created on approval)', NEW.email;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        -- Log error but don't fail the trigger
        RAISE WARNING 'Error in handle_email_confirmed_user for %: %', NEW.email, SQLERRM;
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

-- ===========================================
-- STEP 2: Ensure trigger exists
-- ===========================================

DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;

CREATE TRIGGER on_email_confirmed
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  WHEN (NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at))
  EXECUTE FUNCTION public.handle_email_confirmed_user();

-- ===========================================
-- STEP 3: Clean up any user records created for unapproved technicians
-- ===========================================

-- Delete user records for technicians who have pending approval (not yet approved)
DELETE FROM public.users u
WHERE u.role = 'technician'
  AND EXISTS (
    SELECT 1 FROM public.pending_user_approvals pua
    WHERE pua.user_id = u.id
      AND pua.status = 'pending'
  );

-- ===========================================
-- STEP 4: Verify
-- ===========================================

SELECT 
  '✅ Email confirmation trigger updated' as status,
  tgname as trigger_name,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'on_email_confirmed';

SELECT 
  '✅ Function updated' as status,
  proname as function_name
FROM pg_proc
WHERE proname = 'handle_email_confirmed_user'
  AND pronamespace = 'public'::regnamespace;

SELECT '✅ Trigger fixed! Technicians will only have pending approval after email confirmation. User record is created when admin approves.' as message;
