-- COMPLETE DATABASE FIX SCRIPT
-- This script fixes all database issues in the correct order
-- Run this in your Supabase SQL Editor

-- ===========================================
-- 1. FIX TOOLS TABLE STRUCTURE
-- ===========================================

-- Drop existing tools table if it exists (backup first if needed)
DROP TABLE IF EXISTS tools CASCADE;

-- Create the new tools table with correct structure
CREATE TABLE tools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    brand TEXT,
    model TEXT,
    serial_number TEXT,
    purchase_date DATE,
    purchase_price DECIMAL(10, 2),
    current_value DECIMAL(10, 2),
    condition TEXT NOT NULL DEFAULT 'Good',
    location TEXT,
    status TEXT NOT NULL DEFAULT 'Available',
    tool_type TEXT NOT NULL DEFAULT 'inventory', -- Default is 'inventory', can be changed to 'shared' by admin
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    image_path TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add RLS policies for the new tools table
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

-- Policy for authenticated users to view all tools
CREATE POLICY "Authenticated users can view tools" ON tools
FOR SELECT USING (auth.role() = 'authenticated');

-- Policy for admins to insert tools
CREATE POLICY "Admins can insert tools" ON tools
FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Policy for admins to update tools
CREATE POLICY "Admins can update tools" ON tools
FOR UPDATE USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Policy for admins to delete tools
CREATE POLICY "Admins can delete tools" ON tools
FOR DELETE USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Policy for technicians to insert their own tools (tool_type 'inventory', assigned_to their ID)
CREATE POLICY "Technicians can insert their own inventory tools" ON tools
FOR INSERT WITH CHECK (
    auth.uid() = assigned_to AND
    tool_type = 'inventory' AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'technician')
);

-- Policy for technicians to update their own tools (e.g., status, notes, image)
CREATE POLICY "Technicians can update their own tools" ON tools
FOR UPDATE USING (
    auth.uid() = assigned_to AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'technician')
) WITH CHECK (
    auth.uid() = assigned_to AND
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'technician')
);

-- Policy for technicians to view tools assigned to them or shared tools
CREATE POLICY "Technicians can view assigned and shared tools" ON tools
FOR SELECT USING (
    auth.uid() = assigned_to OR
    tool_type = 'shared' AND status = 'Available'
);

-- Set up trigger to update 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tools_updated_at
    BEFORE UPDATE ON tools
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- 2. FIX USERS TABLE STRUCTURE
-- ===========================================

-- Drop existing users table if it exists
DROP TABLE IF EXISTS users CASCADE;

-- Create users table for role management
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT CHECK (role IN ('admin', 'technician')) DEFAULT 'technician',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ
);

-- Enable RLS for users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Allow inserts for authenticated users" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Admins can read all users
CREATE POLICY "Admins can read all users" ON users
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ===========================================
-- 3. ADD EMAIL DOMAIN VALIDATION
-- ===========================================

-- Create function to validate email domains
CREATE OR REPLACE FUNCTION public.validate_email_domain(email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Extract domain from email
  DECLARE
    domain TEXT;
  BEGIN
    domain := LOWER(SPLIT_PART(email, '@', 2));
    
    -- Check if domain is in allowed list
    RETURN domain IN (
      'mekar.ae',
      'gmail.com',
      'outlook.com',
      'yahoo.com',
      'hotmail.com'
    );
  END;
END;
$$ LANGUAGE plpgsql;

-- ===========================================
-- 4. CREATE USER PROFILES TABLE
-- ===========================================

-- Create user profiles table for extended user data
CREATE TABLE user_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  profile_picture_url TEXT,
  phone_number TEXT,
  department TEXT,
  position TEXT,
  employee_id TEXT UNIQUE,
  hire_date DATE,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  address TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  country TEXT DEFAULT 'UAE',
  bio TEXT,
  skills TEXT[], -- Array of skills
  certifications TEXT[], -- Array of certifications
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for user_profiles
CREATE POLICY "Users can read own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Admins can read all profiles
CREATE POLICY "Admins can read all profiles" ON user_profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- ===========================================
-- 5. CREATE TRIGGER FUNCTIONS
-- ===========================================

-- Create function to automatically create user record on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate email domain before creating user record
  IF NOT public.validate_email_domain(NEW.email) THEN
    RAISE EXCEPTION 'Email domain not allowed. Please use @mekar.ae or other approved domains.';
  END IF;
  
  -- Create user record in public.users table
  INSERT INTO public.users (id, email, full_name, role, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
    NOW(),
    NOW()
  );
  
  -- Create user profile record
  INSERT INTO public.user_profiles (id, user_id, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.id,
    NOW(),
    NOW()
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user record
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update last login
CREATE OR REPLACE FUNCTION public.update_last_login()
RETURNS TRIGGER AS $$
BEGIN
  -- Update last_login in users table
  UPDATE users 
  SET last_login = NOW(), updated_at = NOW()
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for login updates
DROP TRIGGER IF EXISTS on_auth_login ON auth.users;
CREATE TRIGGER on_auth_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.update_last_login();

-- Create function to update updated_at timestamp for users
CREATE OR REPLACE FUNCTION public.handle_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at for users
DROP TRIGGER IF EXISTS on_users_updated ON users;
CREATE TRIGGER on_users_updated
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION public.handle_users_updated_at();

-- Create function to update updated_at timestamp for user_profiles
CREATE OR REPLACE FUNCTION public.handle_user_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at for user_profiles
DROP TRIGGER IF EXISTS on_user_profiles_updated ON user_profiles;
CREATE TRIGGER on_user_profiles_updated
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_profiles_updated_at();

-- ===========================================
-- 6. CREATE UTILITY FUNCTIONS
-- ===========================================

-- Create function to get user statistics
CREATE OR REPLACE FUNCTION public.get_user_stats()
RETURNS TABLE (
  total_users BIGINT,
  active_users BIGINT,
  admin_count BIGINT,
  technician_count BIGINT,
  recent_signups BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE is_active = true) as active_users,
    COUNT(*) FILTER (WHERE role = 'admin') as admin_count,
    COUNT(*) FILTER (WHERE role = 'technician') as technician_count,
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '30 days') as recent_signups
  FROM users;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update user profile
CREATE OR REPLACE FUNCTION public.update_user_profile(
  p_user_id UUID,
  p_profile_data JSONB
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Update user_profiles table
  UPDATE user_profiles 
  SET 
    phone_number = COALESCE((p_profile_data->>'phone_number')::TEXT, phone_number),
    department = COALESCE((p_profile_data->>'department')::TEXT, department),
    position = COALESCE((p_profile_data->>'position')::TEXT, position),
    employee_id = COALESCE((p_profile_data->>'employee_id')::TEXT, employee_id),
    emergency_contact_name = COALESCE((p_profile_data->>'emergency_contact_name')::TEXT, emergency_contact_name),
    emergency_contact_phone = COALESCE((p_profile_data->>'emergency_contact_phone')::TEXT, emergency_contact_phone),
    address = COALESCE((p_profile_data->>'address')::TEXT, address),
    city = COALESCE((p_profile_data->>'city')::TEXT, city),
    state = COALESCE((p_profile_data->>'state')::TEXT, state),
    postal_code = COALESCE((p_profile_data->>'postal_code')::TEXT, postal_code),
    country = COALESCE((p_profile_data->>'country')::TEXT, country),
    bio = COALESCE((p_profile_data->>'bio')::TEXT, bio),
    skills = COALESCE((p_profile_data->>'skills')::TEXT[], skills),
    certifications = COALESCE((p_profile_data->>'certifications')::TEXT[], certifications),
    updated_at = NOW()
  WHERE id = p_user_id;
  
  -- Update users table if needed
  UPDATE users 
  SET 
    full_name = COALESCE((p_profile_data->>'full_name')::TEXT, full_name),
    updated_at = NOW()
  WHERE id = p_user_id;
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 7. CREATE VIEWS AND INDEXES
-- ===========================================

-- Create a view for user dashboard data
CREATE OR REPLACE VIEW user_dashboard AS
SELECT 
  u.id,
  u.email,
  u.full_name,
  u.role,
  u.is_active,
  u.created_at,
  u.last_login,
  up.phone_number,
  up.department,
  up.position,
  up.employee_id,
  up.profile_picture_url
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id;

-- Grant access to the view
GRANT SELECT ON user_dashboard TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_employee_id ON user_profiles(employee_id);
CREATE INDEX IF NOT EXISTS idx_tools_assigned_to ON tools(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tools_tool_type ON tools(tool_type);
CREATE INDEX IF NOT EXISTS idx_tools_status ON tools(status);

-- ===========================================
-- 8. GRANT PERMISSIONS
-- ===========================================

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.validate_email_domain(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_profile(UUID, JSONB) TO authenticated;

-- ===========================================
-- 9. INSERT DEFAULT ADMIN USER (OPTIONAL)
-- ===========================================

-- Uncomment and modify the email below to create an admin user
-- This will only work if the user already exists in auth.users
-- INSERT INTO users (id, email, full_name, role)
-- VALUES (
--   (SELECT id FROM auth.users WHERE email = 'jumae@mekar.ae' LIMIT 1),
--   'jumae@mekar.ae',
--   'Jumae',
--   'admin'
-- ) ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- ===========================================
-- 10. VERIFICATION QUERIES
-- ===========================================

-- Test the setup (optional - remove after testing)
-- SELECT 'Database setup complete!' as status;
-- SELECT * FROM get_user_stats();
-- SELECT COUNT(*) as tools_count FROM tools;
-- SELECT COUNT(*) as users_count FROM users;

