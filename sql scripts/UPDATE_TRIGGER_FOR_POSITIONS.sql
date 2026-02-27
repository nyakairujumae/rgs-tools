-- ===========================================
-- Update Email Confirmation Trigger to Handle Position ID
-- ===========================================
-- This updates the existing trigger to save position_id from user metadata

CREATE OR REPLACE FUNCTION public.handle_email_confirmed_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_full_name TEXT;
  user_position_id TEXT;
BEGIN
  -- Only create user record if email is confirmed
  -- Check if email_confirmed_at changed from NULL to NOT NULL
  IF NEW.email_confirmed_at IS NOT NULL AND (OLD.email_confirmed_at IS NULL OR OLD.email_confirmed_at IS DISTINCT FROM NEW.email_confirmed_at) THEN
    -- Email was just confirmed - now create the user record
    user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'technician');
    user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));
    user_position_id := NEW.raw_user_meta_data->>'position_id'; -- Get position_id from metadata
    
    BEGIN
      -- Create user record in public.users table
      -- Include position_id if it exists and role is admin
      INSERT INTO public.users (id, email, full_name, role, position_id, created_at, updated_at)
      VALUES (
        NEW.id,
        NEW.email,
        user_full_name,
        user_role,
        CASE 
          WHEN user_role = 'admin' AND user_position_id IS NOT NULL AND user_position_id != '' 
          THEN user_position_id::UUID 
          ELSE NULL 
        END,
        NOW(),
        NOW()
      )
      ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        role = EXCLUDED.role,
        position_id = CASE 
          WHEN EXCLUDED.role = 'admin' AND EXCLUDED.position_id IS NOT NULL 
          THEN EXCLUDED.position_id 
          ELSE users.position_id -- Keep existing if not provided
        END,
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
        -- For admins, log position assignment
        IF user_position_id IS NOT NULL AND user_position_id != '' THEN
          RAISE NOTICE 'Created user record for admin with position_id %: %', user_position_id, NEW.email;
        ELSE
          RAISE NOTICE 'Created user record for admin (no position assigned): %', NEW.email;
        END IF;
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

-- Verify the trigger exists
SELECT 
  'Trigger function updated successfully' as status,
  proname as function_name
FROM pg_proc
WHERE proname = 'handle_email_confirmed_user';



