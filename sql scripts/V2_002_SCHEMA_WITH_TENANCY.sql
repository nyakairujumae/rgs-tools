-- ============================================================================
-- V2 SCHEMA WITH MULTI-TENANCY
-- Run AFTER V2_001_MULTI_TENANT_FOUNDATION.sql
-- ============================================================================
-- Base tables: users, technicians, tools, assignments
-- All include organization_id for tenant isolation.
-- ============================================================================

-- Drop in correct order (dependencies)
DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS tools CASCADE;
DROP TABLE IF EXISTS technicians CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================================================
-- 1. USERS (with organization_id)
-- ============================================================================
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT CHECK (role IN ('admin', 'technician')) DEFAULT 'technician',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(organization_id, email)
);

CREATE INDEX idx_users_organization ON users(organization_id);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Allow inserts for authenticated users" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Users in same org can read each other (for admin/technician workflows)
CREATE POLICY "Users can read same org" ON users
  FOR SELECT USING (
    organization_id = (SELECT organization_id FROM users WHERE id = auth.uid())
    OR organization_id IS NULL
  );

-- ============================================================================
-- 2. handle_new_user trigger (supports organization_id from signup metadata)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_org_id UUID;
BEGIN
  -- Get organization_id from signup metadata (invite link, etc.) or NULL
  v_org_id := (NEW.raw_user_meta_data->>'organization_id')::UUID;
  
  INSERT INTO public.users (id, email, full_name, role, organization_id)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
    v_org_id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 3. TECHNICIANS (with organization_id)
-- ============================================================================
CREATE TABLE technicians (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  employee_id TEXT,
  phone TEXT,
  email TEXT,
  department TEXT,
  hire_date DATE,
  status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(organization_id, employee_id)
);

CREATE INDEX idx_technicians_organization ON technicians(organization_id);
CREATE INDEX idx_technicians_status ON technicians(status);
CREATE INDEX idx_technicians_employee_id ON technicians(employee_id);
CREATE INDEX idx_technicians_department ON technicians(department);

ALTER TABLE technicians ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant can manage technicians" ON technicians
  FOR ALL
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

-- ============================================================================
-- 4. TOOLS (with organization_id)
-- ============================================================================
CREATE TABLE tools (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  serial_number TEXT,
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
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(organization_id, serial_number)
);

CREATE INDEX idx_tools_organization ON tools(organization_id);
CREATE INDEX idx_tools_category ON tools(category);
CREATE INDEX idx_tools_status ON tools(status);
CREATE INDEX idx_tools_tool_type ON tools(tool_type);
CREATE INDEX idx_tools_assigned_to ON tools(assigned_to);

ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant can manage tools" ON tools
  FOR ALL
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

-- ============================================================================
-- 5. ASSIGNMENTS (organization_id via tool/technician, add for clarity)
-- ============================================================================
CREATE TABLE assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
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

CREATE INDEX idx_assignments_organization ON assignments(organization_id);
CREATE INDEX idx_assignments_tool_id ON assignments(tool_id);
CREATE INDEX idx_assignments_technician_id ON assignments(technician_id);
CREATE INDEX idx_assignments_status ON assignments(status);

ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Tenant can manage assignments" ON assignments
  FOR ALL
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

-- ============================================================================
-- 6. updated_at triggers
-- ============================================================================
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_technicians_updated_at 
  BEFORE UPDATE ON technicians 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tools_updated_at 
  BEFORE UPDATE ON tools 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_assignments_updated_at 
  BEFORE UPDATE ON assignments 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

SELECT '✅ Base schema with tenancy ready. Run V2_003_* next.' as status;
