-- COMPLETE RECREATION: Recreate all tables from scratch
-- Run this in your Supabase SQL Editor

-- Drop all existing tables in the correct order (to avoid foreign key constraints)
DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS tools CASCADE;
DROP TABLE IF EXISTS technicians CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Create users table first (referenced by other tables)
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  role TEXT CHECK (role IN ('admin', 'technician')) DEFAULT 'technician',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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

-- Create function to automatically create user record on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
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

-- Create trigger to automatically create user record
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Create technicians table
CREATE TABLE technicians (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  employee_id TEXT UNIQUE,
  phone TEXT,
  email TEXT,
  department TEXT,
  hire_date DATE,
  status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for technicians
CREATE INDEX idx_technicians_status ON technicians(status);
CREATE INDEX idx_technicians_employee_id ON technicians(employee_id);
CREATE INDEX idx_technicians_department ON technicians(department);

-- Enable RLS for technicians
ALTER TABLE technicians ENABLE ROW LEVEL SECURITY;

-- Create policy for technicians
CREATE POLICY "Admins and technicians can manage all technicians" ON technicians
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- 3. Create tools table
CREATE TABLE tools (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  serial_number TEXT UNIQUE,
  purchase_date DATE,
  purchase_price DECIMAL(10,2),
  current_value DECIMAL(10,2),
  condition TEXT CHECK(condition IN ('Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair')) DEFAULT 'Good',
  location TEXT,
  assigned_to TEXT,
  status TEXT CHECK(status IN ('Available', 'In Use', 'Maintenance', 'Retired', 'Assigned')) DEFAULT 'Available',
  tool_type TEXT CHECK(tool_type IN ('inventory', 'shared', 'assigned')) DEFAULT 'inventory',
  image_path TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for tools
CREATE INDEX idx_tools_category ON tools(category);
CREATE INDEX idx_tools_status ON tools(status);
CREATE INDEX idx_tools_serial_number ON tools(serial_number);
CREATE INDEX idx_tools_tool_type ON tools(tool_type);
CREATE INDEX idx_tools_assigned_to ON tools(assigned_to);

-- Enable RLS for tools
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

-- Create policy for tools
CREATE POLICY "Admins and technicians can manage all tools" ON tools
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- 4. Create assignments table
CREATE TABLE assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tool_id UUID REFERENCES tools(id) ON DELETE CASCADE,
  technician_id UUID REFERENCES technicians(id) ON DELETE CASCADE,
  assignment_type TEXT CHECK(assignment_type IN ('permanent', 'temporary')) NOT NULL,
  status TEXT CHECK(status IN ('Active', 'Returned', 'Cancelled')) DEFAULT 'Active',
  assigned_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expected_return_date TIMESTAMP WITH TIME ZONE,
  actual_return_date TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for assignments
CREATE INDEX idx_assignments_tool_id ON assignments(tool_id);
CREATE INDEX idx_assignments_technician_id ON assignments(technician_id);
CREATE INDEX idx_assignments_status ON assignments(status);

-- Enable RLS for assignments
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;

-- Create policy for assignments
CREATE POLICY "Admins and technicians can manage assignments" ON assignments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_technicians_updated_at 
  BEFORE UPDATE ON technicians 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tools_updated_at 
  BEFORE UPDATE ON tools 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assignments_updated_at 
  BEFORE UPDATE ON assignments 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Note: Users will be created automatically when they sign up through the app
-- The trigger handle_new_user() will create user records in this table
