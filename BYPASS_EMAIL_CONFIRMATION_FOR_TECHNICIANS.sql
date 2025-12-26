-- Bypass Email Confirmation for Technicians
-- This automatically confirms technician emails after registration
-- Admins still need to manually confirm their email for security

-- ===========================================
-- STEP 1: Create function to auto-confirm technician emails
-- ===========================================

CREATE OR REPLACE FUNCTION public.auto_confirm_technician_email()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Get the role from user metadata
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'technician');
  
  -- Only auto-confirm if the user is a technician
  IF user_role = 'technician' THEN
    -- Update the email_confirmed_at timestamp to auto-confirm
    UPDATE auth.users
    SET email_confirmed_at = COALESCE(NEW.email_confirmed_at, NOW())
    WHERE id = NEW.id AND email_confirmed_at IS NULL;
    
    RAISE NOTICE 'Auto-confirmed email for technician: %', NEW.email;
  ELSE
    RAISE NOTICE 'Admin email requires manual confirmation: %', NEW.email;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- STEP 2: Create trigger that runs after user creation
-- ===========================================

DROP TRIGGER IF EXISTS on_technician_email_auto_confirm ON auth.users;

CREATE TRIGGER on_technician_email_auto_confirm
  AFTER INSERT ON auth.users
  FOR EACH ROW
  WHEN (NEW.email_confirmed_at IS NULL)
  EXECUTE FUNCTION public.auto_confirm_technician_email();

-- ===========================================
-- STEP 3: Also auto-confirm existing technician emails that are unconfirmed
-- ===========================================

UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL
  AND raw_user_meta_data->>'role' = 'technician';

-- ===========================================
-- STEP 4: Verify the trigger was created
-- ===========================================

SELECT 
  '✅ Trigger created successfully' as status,
  tgname as trigger_name,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'on_technician_email_auto_confirm';

-- ===========================================
-- SUCCESS MESSAGE
-- ===========================================

SELECT '✅ Email confirmation bypass for technicians is now active!' as message;
SELECT 'Technicians will be auto-confirmed immediately after registration. Admins still require email confirmation.' as note;
