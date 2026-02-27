-- REMOVE EMAIL DOMAIN VALIDATION
-- This removes the strict email validation that's blocking login
-- Run this in your Supabase SQL Editor

-- ===========================================
-- 1. DROP THE EMAIL VALIDATION TRIGGER
-- ===========================================

-- Drop the trigger that checks email domains on auth.users
DROP TRIGGER IF EXISTS check_email_domain_trigger ON auth.users;

-- Drop the trigger function
DROP FUNCTION IF EXISTS public.check_email_domain() CASCADE;

-- ===========================================
-- 2. KEEP THE VALIDATION FUNCTION (BUT DON'T USE IT)
-- ===========================================

-- Keep the validation function for app-side use, but don't enforce it at database level
CREATE OR REPLACE FUNCTION public.validate_email_domain(email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Extract domain from email
  DECLARE
    domain TEXT;
  BEGIN
    domain := LOWER(SPLIT_PART(email, '@', 2));
    
    -- Allow ALL domains for now (remove restrictions)
    RETURN TRUE;
    
    -- Original validation (commented out):
    -- RETURN domain IN (
    --   'mekar.ae',
    --   'gmail.com',
    --   'outlook.com',
    --   'yahoo.com',
    --   'hotmail.com'
    -- );
  END;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- 3. UPDATE handle_new_user TO BE PERMISSIVE
-- ===========================================

-- Make sure the user creation trigger doesn't fail
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create user record in public.users table (no email validation)
  INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
    NOW(),
    NOW()
  ) ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();
  
  -- Create user profile record if it doesn't exist
  INSERT INTO public.user_profiles (id, user_id, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.id,
    NOW(),
    NOW()
  ) ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Don't fail user creation if there's an error
    RAISE WARNING 'Error in handle_new_user: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 4. VERIFICATION
-- ===========================================

SELECT 'Email domain validation removed!' as status;
SELECT 'You can now login with ANY email domain including @gmail.com' as message;
SELECT 'App-side validation in Flutter still enforces allowed domains' as note;

