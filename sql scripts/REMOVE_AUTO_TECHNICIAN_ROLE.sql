-- Remove Automatic Technician Role Assignment
-- This ensures roles are only assigned explicitly, not automatically

-- ===========================================
-- STEP 1: Update handle_email_confirmed_user function
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_email_confirmed_user()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
  user_full_name TEXT;
BEGIN
  -- Only create user record if email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    -- Email was just confirmed - now create the user record
    -- Get role from metadata - if not set, don't create user record (role must be explicit)
    user_role := NEW.raw_user_meta_data->>'role';
    user_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1));
    
    -- Only proceed if role is explicitly set
    IF user_role IS NULL OR user_role = '' THEN
      RAISE WARNING 'User % has no role in metadata - skipping user record creation', NEW.email;
      RETURN NEW; -- Don't create user record if role is not set
    END IF;
    
    BEGIN
      -- Create user record in public.users table
      INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
      VALUES (
        NEW.id,
        NEW.email,
        user_full_name,
        user_role, -- Use explicit role, no default
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
        RAISE NOTICE 'Created user record for %: %', user_role, NEW.email;
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ===========================================
-- STEP 2: Update handle_new_user function (if it exists)
-- ===========================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Get role from metadata - if not set, don't create user record
  DECLARE
    user_role TEXT;
  BEGIN
    user_role := NEW.raw_user_meta_data->>'role';
    
    -- Only create user record if role is explicitly set
    IF user_role IS NULL OR user_role = '' THEN
      RAISE WARNING 'User % has no role in metadata - skipping user record creation', NEW.email;
      RETURN NEW; -- Don't create user record if role is not set
    END IF;
    
    INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
      user_role, -- Use explicit role, no default
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      role = EXCLUDED.role,
      updated_at = NOW();
    
    RETURN NEW;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'Error in handle_new_user for %: %', NEW.email, SQLERRM;
      RETURN NEW;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ===========================================
-- STEP 3: Remove default from users table (make role nullable or require explicit value)
-- ===========================================

-- First, check current constraint
SELECT 
  'Current table structure' as info,
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND column_name = 'role';

-- Remove default constraint (if possible)
-- Note: If role is NOT NULL, we can't remove the default easily
-- Instead, we'll ensure triggers don't use defaults

-- ===========================================
-- STEP 4: Update auto_confirm_technician_email function
-- ===========================================

CREATE OR REPLACE FUNCTION public.auto_confirm_technician_email()
RETURNS TRIGGER AS $$
DECLARE
  user_role TEXT;
BEGIN
  -- Get the role from user metadata - must be explicitly set
  user_role := NEW.raw_user_meta_data->>'role';
  
  -- Only auto-confirm if the user is EXPLICITLY a technician
  -- Don't default to technician
  IF user_role = 'technician' THEN
    -- Update the email_confirmed_at timestamp to auto-confirm
    UPDATE auth.users
    SET email_confirmed_at = NOW()
    WHERE id = NEW.id AND email_confirmed_at IS NULL;
    
    RAISE NOTICE 'Auto-confirmed email for technician: %', NEW.email;
  ELSE
    RAISE NOTICE 'User role is % - email requires manual confirmation: %', COALESCE(user_role, 'NULL'), NEW.email;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ===========================================
-- STEP 5: Verify changes
-- ===========================================

SELECT 
  '✅ Functions updated to require explicit roles' as status,
  proname as function_name
FROM pg_proc
WHERE proname IN ('handle_email_confirmed_user', 'handle_new_user', 'auto_confirm_technician_email')
  AND pronamespace = 'public'::regnamespace;

SELECT '✅ Automatic technician role assignment removed!' as message;
SELECT 'Roles must now be explicitly set during registration' as note;
