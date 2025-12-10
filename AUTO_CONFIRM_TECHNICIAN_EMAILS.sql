-- Auto-Confirm Technician Emails
-- This database function automatically confirms technician emails after registration
-- Admins still need to manually confirm their email for security

-- Step 1: Create a function to auto-confirm technician emails
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
    SET email_confirmed_at = NOW()
    WHERE id = NEW.id AND email_confirmed_at IS NULL;
    
    RAISE NOTICE 'Auto-confirmed email for technician: %', NEW.email;
  ELSE
    RAISE NOTICE 'Admin email requires manual confirmation: %', NEW.email;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 2: Create a trigger that runs after user creation
DROP TRIGGER IF EXISTS on_technician_email_auto_confirm ON auth.users;
CREATE TRIGGER on_technician_email_auto_confirm
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_confirm_technician_email();

-- Step 3: Verify the trigger was created
SELECT 
  'Trigger created successfully' as status,
  tgname as trigger_name,
  tgrelid::regclass as table_name
FROM pg_trigger
WHERE tgname = 'on_technician_email_auto_confirm';

-- Note: This requires SECURITY DEFINER to update auth.users table
-- Make sure your Supabase project allows this level of access

