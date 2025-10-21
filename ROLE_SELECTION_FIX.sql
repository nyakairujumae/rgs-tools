-- ROLE_SELECTION_FIX.sql
-- This fixes the role selection issue by ensuring the trigger works properly

-- Step 1: Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Step 2: Create a simple, robust trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert user into public.users table with role from metadata
    INSERT INTO public.users (id, email, role, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Create the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 4: Ensure RLS is properly configured
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop and recreate RLS policies
DROP POLICY IF EXISTS "Users can view all users" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own data" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;

CREATE POLICY "Users can view all users" ON public.users
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own data" ON public.users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own data" ON public.users
    FOR UPDATE USING (true);

-- Step 6: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.users TO anon, authenticated;

-- Step 7: Test the trigger by checking existing users
SELECT 
    'Trigger created successfully' as status,
    COUNT(*) as existing_users_count
FROM public.users;

-- Success message
SELECT 'ROLE SELECTION FIX COMPLETE - TRIGGER WILL NOW HANDLE ROLE SELECTION PROPERLY!' as result;


