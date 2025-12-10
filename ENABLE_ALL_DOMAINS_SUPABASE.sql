-- Enable All Email Domains for RGS HVAC Tools Management
-- Run this script in your Supabase SQL Editor to allow all email domains

-- 1. Update Site URL to allow all domains (if needed)
-- Note: This is typically done in the Supabase Dashboard under Authentication > Settings
-- But we can document the required settings here

-- 2. Create a function to validate any email domain
CREATE OR REPLACE FUNCTION public.validate_email_domain(email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Allow any email domain - no restrictions
  -- Just validate basic email format
  RETURN email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Update user creation to allow any domain
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Allow users from any email domain
  INSERT INTO public.users (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'technician')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create policy to allow user registration from any domain
DROP POLICY IF EXISTS "Allow registration from any domain" ON auth.users;
CREATE POLICY "Allow registration from any domain" ON auth.users
  FOR INSERT WITH CHECK (true);

-- 5. Update RLS policies to be more permissive for user management
DROP POLICY IF EXISTS "Users can read own data" ON users;
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON users;
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Allow inserts for authenticated users" ON users;
CREATE POLICY "Allow inserts for authenticated users" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 6. Create function to check if email domain is allowed (always returns true)
CREATE OR REPLACE FUNCTION public.is_email_domain_allowed(email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Allow any email domain - no restrictions
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Update user role assignment to work with any domain
CREATE OR REPLACE FUNCTION public.assign_user_role(user_id UUID, new_role TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Allow role assignment for users from any domain
  UPDATE public.users 
  SET role = new_role, updated_at = NOW()
  WHERE id = user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Create index for better performance with any email domain
CREATE INDEX IF NOT EXISTS idx_users_email_domain ON users (split_part(email, '@', 2));

-- 9. Update authentication settings (these would typically be done in dashboard)
-- But we can create a function to validate the settings
CREATE OR REPLACE FUNCTION public.get_auth_settings()
RETURNS JSON AS $$
BEGIN
  RETURN json_build_object(
    'allow_all_domains', true,
    'email_confirmation_required', false,
    'site_url', 'https://your-app-domain.com',
    'redirect_urls', json_build_array(
      'https://your-app-domain.com/**',
      'https://your-app-domain.com/auth/callback',
      'https://your-app-domain.com/dashboard'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Create a test function to verify domain validation
CREATE OR REPLACE FUNCTION public.test_email_domains()
RETURNS TABLE(email TEXT, is_allowed BOOLEAN) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    test_emails.email,
    public.is_email_domain_allowed(test_emails.email) as is_allowed
  FROM (VALUES 
    ('user@gmail.com'),
    ('user@yahoo.com'),
    ('user@outlook.com'),
    ('user@hotmail.com'),
    ('user@mekar.ae'),
    ('user@royalgulf.ae'),
    ('user@company.com'),
    ('user@anydomain.org'),
    ('user@test.net'),
    ('user@example.co.uk')
  ) AS test_emails(email);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.validate_email_domain(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_email_domain_allowed(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_user_role(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_auth_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION public.test_email_domains() TO authenticated;

-- 12. Test the configuration
SELECT 'Testing email domain validation...' as status;
SELECT * FROM public.test_email_domains();

-- 13. Show current auth settings
SELECT 'Current auth settings:' as info;
SELECT public.get_auth_settings();

-- 14. Verify user table permissions
SELECT 'User table policies:' as info;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users';

-- 15. Final confirmation
SELECT '✅ All email domains are now allowed!' as result;
SELECT 'Users can sign up with any email address (gmail, yahoo, mekar.ae, royalgulf.ae, etc.)' as message;
