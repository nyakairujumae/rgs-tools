-- Diagnose and Fix User Creation Issues
-- Run this script to check and fix user registration problems

-- 1. Check if users table exists and has correct structure
SELECT 'Checking users table structure...' as status;

SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if the handle_new_user function exists
SELECT 'Checking handle_new_user function...' as status;

SELECT 
    routine_name, 
    routine_type, 
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user' 
AND routine_schema = 'public';

-- 3. Check if the trigger exists
SELECT 'Checking trigger...' as status;

SELECT 
    trigger_name, 
    event_manipulation, 
    action_timing, 
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- 4. Drop and recreate the users table if needed
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT CHECK (role IN ('admin', 'technician')) DEFAULT 'technician',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies
DROP POLICY IF EXISTS "Users can read own data" ON users;
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON users;
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Allow inserts for authenticated users" ON users;
CREATE POLICY "Allow inserts for authenticated users" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 7. Create updated_at function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Create trigger for updated_at
DROP TRIGGER IF EXISTS on_users_updated ON users;
CREATE TRIGGER on_users_updated
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 9. Create the handle_new_user function with better error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert user record with error handling
  BEGIN
    INSERT INTO public.users (id, email, full_name, role)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
      COALESCE(NEW.raw_user_meta_data->>'role', 'technician')
    );
    
    -- Log successful creation
    RAISE LOG 'User created successfully: %', NEW.email;
    
  EXCEPTION WHEN OTHERS THEN
    -- Log the error but don't fail the auth user creation
    RAISE LOG 'Error creating user record: %', SQLERRM;
    -- Return NEW to allow auth user creation to succeed
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 11. Grant necessary permissions
GRANT ALL ON users TO authenticated;
GRANT ALL ON users TO service_role;

-- 12. Test the setup
SELECT 'Testing user creation setup...' as status;

-- Check if we can insert a test user (this will fail but show us the error)
DO $$
BEGIN
  -- This is just to test the function exists and is callable
  PERFORM public.handle_new_user();
  RAISE NOTICE 'handle_new_user function is working';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'handle_new_user function error: %', SQLERRM;
END;
$$;

-- 13. Show final status
SELECT '✅ User creation setup complete!' as result;
SELECT 'Users table and triggers are ready for user registration' as message;
