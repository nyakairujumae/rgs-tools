-- ============================================================================
-- MASTER SETUP SCRIPT — New Supabase Project (talzuhfantkxnwyahzyp)
-- ============================================================================
-- Run this ONCE in the Supabase SQL Editor on a fresh project.
-- Combines V2_001 → V2_005 + Admin Bootstrap Guard in correct dependency order.
-- ============================================================================


-- ============================================================================
-- PART 1: EXTENSIONS & ORGANIZATIONS (V2_001)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS organizations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  logo_url TEXT,
  address TEXT,
  phone TEXT,
  website TEXT,
  industry TEXT DEFAULT 'general',
  worker_label TEXT DEFAULT 'Technician',
  worker_label_plural TEXT DEFAULT 'Technicians',
  setup_completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read organizations" ON organizations;
CREATE POLICY "Authenticated users can read organizations"
  ON organizations FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert organizations" ON organizations;
CREATE POLICY "Authenticated users can insert organizations"
  ON organizations FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Org members can update own org" ON organizations;
CREATE POLICY "Org members can update own org"
  ON organizations FOR UPDATE TO authenticated
  USING (id IN (SELECT organization_id FROM users WHERE id = auth.uid() AND organization_id IS NOT NULL))
  WITH CHECK (true);

-- updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations;
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- PART 2: USERS + HELPER FUNCTIONS (V2_002 — core tables)
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  email TEXT NOT NULL,
  full_name TEXT,
  role TEXT CHECK (role IN ('admin', 'technician')) DEFAULT 'technician',
  position_id UUID,  -- filled after admin_positions table is created
  phone TEXT,
  profile_picture_url TEXT,
  department TEXT,
  employee_id TEXT,
  status TEXT CHECK (status IN ('Active', 'Inactive', 'Pending')) DEFAULT 'Active',
  is_approved BOOLEAN DEFAULT false,
  approved_at TIMESTAMP WITH TIME ZONE,
  approved_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_organization ON users(organization_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own data" ON users;
CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON users;
CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Allow inserts for authenticated users" ON users;
CREATE POLICY "Allow inserts for authenticated users" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can read same org" ON users;
CREATE POLICY "Users can read same org" ON users
  FOR SELECT USING (
    organization_id = (SELECT organization_id FROM users WHERE id = auth.uid())
    OR organization_id IS NULL
  );

DROP POLICY IF EXISTS "Admins can manage users in their org" ON users;
CREATE POLICY "Admins can manage users in their org" ON users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users AS u
      WHERE u.id = auth.uid() AND u.role = 'admin'
        AND u.organization_id = users.organization_id
    )
  );

-- Helper: get current user's org
CREATE OR REPLACE FUNCTION public.current_organization_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT organization_id FROM users WHERE id = auth.uid() LIMIT 1;
$$;

-- Helper: check if user belongs to org
CREATE OR REPLACE FUNCTION public.user_belongs_to_org(org_id UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND organization_id = org_id
  );
$$;

-- Trigger: auto-create user row on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_org_id UUID;
BEGIN
  v_org_id := (NEW.raw_user_meta_data->>'organization_id')::UUID;
  INSERT INTO public.users (id, email, full_name, role, organization_id)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
    v_org_id
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- PART 3: TECHNICIANS (V2_002)
-- ============================================================================

CREATE TABLE IF NOT EXISTS technicians (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  employee_id TEXT,
  phone TEXT,
  email TEXT,
  department TEXT,
  hire_date DATE,
  status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
  profile_picture_url TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_technicians_organization ON technicians(organization_id);
CREATE INDEX IF NOT EXISTS idx_technicians_status ON technicians(status);
CREATE INDEX IF NOT EXISTS idx_technicians_employee_id ON technicians(employee_id);

ALTER TABLE technicians ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tenant can manage technicians" ON technicians;
CREATE POLICY "Tenant can manage technicians" ON technicians
  FOR ALL
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

DROP TRIGGER IF EXISTS update_technicians_updated_at ON technicians;
CREATE TRIGGER update_technicians_updated_at
  BEFORE UPDATE ON technicians FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- PART 4: TOOLS (V2_002)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tools (
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
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tools_organization ON tools(organization_id);
CREATE INDEX IF NOT EXISTS idx_tools_category ON tools(category);
CREATE INDEX IF NOT EXISTS idx_tools_status ON tools(status);
CREATE INDEX IF NOT EXISTS idx_tools_tool_type ON tools(tool_type);
CREATE INDEX IF NOT EXISTS idx_tools_assigned_to ON tools(assigned_to);

ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tenant can manage tools" ON tools;
CREATE POLICY "Tenant can manage tools" ON tools
  FOR ALL
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

DROP TRIGGER IF EXISTS update_tools_updated_at ON tools;
CREATE TRIGGER update_tools_updated_at
  BEFORE UPDATE ON tools FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- PART 5: ADMIN POSITIONS (V2_003)
-- ============================================================================

CREATE TABLE IF NOT EXISTS admin_positions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  level INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE INDEX IF NOT EXISTS idx_admin_positions_organization ON admin_positions(organization_id);

ALTER TABLE admin_positions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Org members can read admin positions" ON admin_positions;
CREATE POLICY "Org members can read admin positions" ON admin_positions
  FOR SELECT USING (organization_id = public.current_organization_id());

DROP POLICY IF EXISTS "Admins can manage admin positions" ON admin_positions;
CREATE POLICY "Admins can manage admin positions" ON admin_positions
  FOR ALL USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- Now add FK from users to admin_positions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_position_id_fkey'
  ) THEN
    ALTER TABLE users ADD CONSTRAINT users_position_id_fkey
      FOREIGN KEY (position_id) REFERENCES admin_positions(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Seed default positions for a new org
CREATE OR REPLACE FUNCTION public.seed_default_positions_for_org(p_org_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO admin_positions (organization_id, name, description, level)
  VALUES
    (p_org_id, 'Super Admin',     'Full system access',           5),
    (p_org_id, 'Manager',         'Manage team and tools',         4),
    (p_org_id, 'Supervisor',      'Oversee daily operations',      3),
    (p_org_id, 'Coordinator',     'Coordinate assignments',        2),
    (p_org_id, 'Support Staff',   'General support',               1)
  ON CONFLICT (organization_id, name) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.seed_default_positions_for_org TO authenticated;

DROP TRIGGER IF EXISTS update_admin_positions_updated_at ON admin_positions;
CREATE TRIGGER update_admin_positions_updated_at
  BEFORE UPDATE ON admin_positions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- PART 6: PENDING USER APPROVALS (V2_003)
-- ============================================================================

CREATE TABLE IF NOT EXISTS pending_user_approvals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  department TEXT,
  employee_id TEXT,
  role TEXT DEFAULT 'technician',
  status TEXT CHECK (status IN ('Pending', 'Approved', 'Rejected')) DEFAULT 'Pending',
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pending_approvals_organization ON pending_user_approvals(organization_id);
CREATE INDEX IF NOT EXISTS idx_pending_approvals_status ON pending_user_approvals(status);
CREATE INDEX IF NOT EXISTS idx_pending_approvals_user_id ON pending_user_approvals(user_id);

ALTER TABLE pending_user_approvals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own approval" ON pending_user_approvals;
CREATE POLICY "Users can view own approval" ON pending_user_approvals
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can manage pending approvals" ON pending_user_approvals;
CREATE POLICY "Admins can manage pending approvals" ON pending_user_approvals
  FOR ALL USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Allow insert for authenticated users" ON pending_user_approvals;
CREATE POLICY "Allow insert for authenticated users" ON pending_user_approvals
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP TRIGGER IF EXISTS update_pending_approvals_updated_at ON pending_user_approvals;
CREATE TRIGGER update_pending_approvals_updated_at
  BEFORE UPDATE ON pending_user_approvals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- PART 7: TOOL ISSUES (V2_003)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tool_issues (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  tool_id UUID REFERENCES tools(id) ON DELETE CASCADE,
  reported_by UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  description TEXT,
  severity TEXT CHECK(severity IN ('Low', 'Medium', 'High', 'Critical')) DEFAULT 'Medium',
  status TEXT CHECK(status IN ('Open', 'In Progress', 'Resolved', 'Closed')) DEFAULT 'Open',
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tool_issues_organization ON tool_issues(organization_id);
CREATE INDEX IF NOT EXISTS idx_tool_issues_tool_id ON tool_issues(tool_id);
CREATE INDEX IF NOT EXISTS idx_tool_issues_status ON tool_issues(status);

ALTER TABLE tool_issues ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tenant can manage tool issues" ON tool_issues;
CREATE POLICY "Tenant can manage tool issues" ON tool_issues
  FOR ALL
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

DROP TRIGGER IF EXISTS update_tool_issues_updated_at ON tool_issues;
CREATE TRIGGER update_tool_issues_updated_at
  BEFORE UPDATE ON tool_issues FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- PART 8: ADMIN NOTIFICATIONS (V2_003)
-- ============================================================================

CREATE TABLE IF NOT EXISTS admin_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  admin_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_notifications_organization ON admin_notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_admin_id ON admin_notifications(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_is_read ON admin_notifications(is_read);

ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read own notifications" ON admin_notifications;
CREATE POLICY "Admins can read own notifications" ON admin_notifications
  FOR SELECT USING (admin_id = auth.uid());

DROP POLICY IF EXISTS "Admins can update own notifications" ON admin_notifications;
CREATE POLICY "Admins can update own notifications" ON admin_notifications
  FOR UPDATE USING (admin_id = auth.uid());

DROP POLICY IF EXISTS "Service can insert notifications" ON admin_notifications;
CREATE POLICY "Service can insert notifications" ON admin_notifications
  FOR INSERT WITH CHECK (organization_id = public.current_organization_id());


-- ============================================================================
-- PART 9: TECHNICIAN NOTIFICATIONS (V2_003)
-- ============================================================================

CREATE TABLE IF NOT EXISTS technician_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  technician_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tech_notifications_organization ON technician_notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_tech_notifications_user_id ON technician_notifications(technician_user_id);

ALTER TABLE technician_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Technicians can read own notifications" ON technician_notifications;
CREATE POLICY "Technicians can read own notifications" ON technician_notifications
  FOR SELECT USING (technician_user_id = auth.uid());

DROP POLICY IF EXISTS "Technicians can update own notifications" ON technician_notifications;
CREATE POLICY "Technicians can update own notifications" ON technician_notifications
  FOR UPDATE USING (technician_user_id = auth.uid());

DROP POLICY IF EXISTS "Service can insert tech notifications" ON technician_notifications;
CREATE POLICY "Service can insert tech notifications" ON technician_notifications
  FOR INSERT WITH CHECK (organization_id = public.current_organization_id());


-- ============================================================================
-- PART 10: USER FCM TOKENS (V2_003)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_fcm_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT CHECK(platform IN ('ios', 'android', 'web')) DEFAULT 'ios',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);

ALTER TABLE user_fcm_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own FCM tokens" ON user_fcm_tokens;
CREATE POLICY "Users can manage own FCM tokens" ON user_fcm_tokens
  FOR ALL USING (user_id = auth.uid());


-- ============================================================================
-- PART 11: APPROVAL WORKFLOWS (V2_003)
-- ============================================================================

CREATE TABLE IF NOT EXISTS approval_workflows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  request_type TEXT NOT NULL CHECK (request_type IN ('Tool Assignment', 'Tool Purchase', 'Tool Disposal', 'Maintenance', 'Transfer', 'Repair', 'Calibration', 'Certification')),
  title TEXT NOT NULL,
  description TEXT,
  requester_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  requester_name TEXT NOT NULL,
  requester_role TEXT NOT NULL,
  status TEXT CHECK (status IN ('Pending', 'Approved', 'Rejected', 'Cancelled')) DEFAULT 'Pending',
  priority TEXT CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')) DEFAULT 'Medium',
  request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  due_date TIMESTAMP WITH TIME ZONE,
  assigned_to UUID REFERENCES auth.users(id),
  assigned_to_role TEXT,
  comments TEXT,
  rejection_reason TEXT,
  approved_date TIMESTAMP WITH TIME ZONE,
  rejected_date TIMESTAMP WITH TIME ZONE,
  approved_by UUID REFERENCES auth.users(id),
  rejected_by UUID REFERENCES auth.users(id),
  request_data JSONB,
  location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_approval_workflows_organization ON approval_workflows(organization_id);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_status ON approval_workflows(status);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_requester_id ON approval_workflows(requester_id);

ALTER TABLE approval_workflows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view all approval workflows" ON approval_workflows;
CREATE POLICY "Admins can view all approval workflows" ON approval_workflows
  FOR SELECT USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Technicians can view own approval workflows" ON approval_workflows;
CREATE POLICY "Technicians can view own approval workflows" ON approval_workflows
  FOR SELECT USING (requester_id = auth.uid());

DROP POLICY IF EXISTS "Authenticated users can insert approval workflows" ON approval_workflows;
CREATE POLICY "Authenticated users can insert approval workflows" ON approval_workflows
  FOR INSERT WITH CHECK (
    organization_id = public.current_organization_id()
    AND requester_id = auth.uid()
  );

DROP POLICY IF EXISTS "Admins can update approval workflows" ON approval_workflows;
CREATE POLICY "Admins can update approval workflows" ON approval_workflows
  FOR UPDATE USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

DROP TRIGGER IF EXISTS update_approval_workflows_updated_at ON approval_workflows;
CREATE TRIGGER update_approval_workflows_updated_at
  BEFORE UPDATE ON approval_workflows FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================================
-- PART 12: ORGANIZATION DEPARTMENTS (V2_005)
-- ============================================================================

CREATE TABLE IF NOT EXISTS organization_departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE INDEX IF NOT EXISTS idx_org_departments_org ON organization_departments(organization_id);

ALTER TABLE organization_departments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Org members can read departments" ON organization_departments;
CREATE POLICY "Org members can read departments" ON organization_departments
  FOR SELECT TO authenticated
  USING (organization_id = public.current_organization_id());

DROP POLICY IF EXISTS "Org admins can manage departments" ON organization_departments;
CREATE POLICY "Org admins can manage departments" ON organization_departments
  FOR ALL TO authenticated
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());


-- ============================================================================
-- PART 13: ORGANIZATION TOOL CATEGORIES (V2_005)
-- ============================================================================

CREATE TABLE IF NOT EXISTS organization_tool_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon_name TEXT DEFAULT 'category',
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE INDEX IF NOT EXISTS idx_org_tool_categories_org ON organization_tool_categories(organization_id);

ALTER TABLE organization_tool_categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Org members can read tool categories" ON organization_tool_categories;
CREATE POLICY "Org members can read tool categories" ON organization_tool_categories
  FOR SELECT TO authenticated
  USING (organization_id = public.current_organization_id());

DROP POLICY IF EXISTS "Org admins can manage tool categories" ON organization_tool_categories;
CREATE POLICY "Org admins can manage tool categories" ON organization_tool_categories
  FOR ALL TO authenticated
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());


-- ============================================================================
-- PART 14: RPCs — Organization Setup & Industry Config (V2_004 + V2_005)
-- ============================================================================

-- Seed industry defaults (departments + categories)
CREATE OR REPLACE FUNCTION public.seed_industry_defaults(p_org_id UUID, p_industry TEXT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_departments TEXT[];
  v_categories  TEXT[];
  v_dept TEXT; v_cat TEXT; v_order INTEGER;
BEGIN
  CASE lower(p_industry)
    WHEN 'hvac' THEN
      v_departments := ARRAY['Maintenance', 'Installation', 'Repair', 'Retrofit'];
      v_categories  := ARRAY['HVAC Equipment', 'Power Tools', 'Testing Equipment', 'Safety Equipment', 'Measuring Tools', 'Other'];
    WHEN 'electrical' THEN
      v_departments := ARRAY['Installation', 'Maintenance', 'Testing', 'Projects'];
      v_categories  := ARRAY['Electrical Tools', 'Power Tools', 'Testing Equipment', 'Safety Equipment', 'Cable Management', 'Other'];
    WHEN 'fm' THEN
      v_departments := ARRAY['Mechanical', 'Electrical', 'Plumbing', 'Civil', 'Cleaning'];
      v_categories  := ARRAY['Hand Tools', 'Power Tools', 'Safety Equipment', 'Measuring Tools', 'Plumbing Tools', 'Other'];
    WHEN 'construction' THEN
      v_departments := ARRAY['Civil', 'Structural', 'MEP', 'Finishing', 'Groundworks'];
      v_categories  := ARRAY['Hand Tools', 'Power Tools', 'Cutting Tools', 'Fastening Tools', 'Safety Equipment', 'Other'];
    ELSE
      v_departments := ARRAY['Operations', 'Maintenance', 'Projects', 'Logistics'];
      v_categories  := ARRAY['Hand Tools', 'Power Tools', 'Safety Equipment', 'Testing Equipment', 'Measuring Tools', 'Other'];
  END CASE;
  v_order := 0;
  FOREACH v_dept IN ARRAY v_departments LOOP
    INSERT INTO organization_departments (organization_id, name, sort_order)
    VALUES (p_org_id, v_dept, v_order) ON CONFLICT (organization_id, name) DO NOTHING;
    v_order := v_order + 1;
  END LOOP;
  v_order := 0;
  FOREACH v_cat IN ARRAY v_categories LOOP
    INSERT INTO organization_tool_categories (organization_id, name, sort_order)
    VALUES (p_org_id, v_cat, v_order) ON CONFLICT (organization_id, name) DO NOTHING;
    v_order := v_order + 1;
  END LOOP;
END;
$$;
GRANT EXECUTE ON FUNCTION public.seed_industry_defaults TO authenticated;

-- Create org + assign first admin user (called from company setup wizard)
CREATE OR REPLACE FUNCTION public.create_organization_and_assign_user(
  p_name TEXT,
  p_slug TEXT,
  p_logo_url TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_website TEXT DEFAULT NULL,
  p_industry TEXT DEFAULT 'general',
  p_worker_label TEXT DEFAULT 'Technician',
  p_worker_label_plural TEXT DEFAULT 'Technicians'
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_org_id UUID;
  v_user_id UUID;
  v_super_admin_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Must be authenticated to create organization';
  END IF;
  IF EXISTS (SELECT 1 FROM users WHERE id = v_user_id AND organization_id IS NOT NULL) THEN
    RAISE EXCEPTION 'User already belongs to an organization';
  END IF;
  INSERT INTO organizations (
    name, slug, logo_url, address, phone, website,
    industry, worker_label, worker_label_plural, setup_completed_at
  )
  VALUES (
    p_name, p_slug, p_logo_url, p_address, p_phone, p_website,
    p_industry, p_worker_label, p_worker_label_plural, NOW()
  )
  RETURNING id INTO v_org_id;
  UPDATE users SET organization_id = v_org_id, role = 'admin', updated_at = NOW()
  WHERE id = v_user_id;
  PERFORM public.seed_default_positions_for_org(v_org_id);
  SELECT id INTO v_super_admin_id FROM admin_positions
  WHERE organization_id = v_org_id AND name = 'Super Admin' LIMIT 1;
  IF v_super_admin_id IS NOT NULL THEN
    UPDATE users SET position_id = v_super_admin_id WHERE id = v_user_id;
  END IF;
  PERFORM public.seed_industry_defaults(v_org_id, p_industry);
  RETURN v_org_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.create_organization_and_assign_user TO authenticated;

-- Update org details (logo, address, etc.)
CREATE OR REPLACE FUNCTION public.update_organization_setup(
  p_org_id UUID,
  p_logo_url TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_website TEXT DEFAULT NULL
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.user_belongs_to_org(p_org_id) THEN
    RAISE EXCEPTION 'Not authorized to update this organization';
  END IF;
  UPDATE organizations SET
    logo_url = COALESCE(p_logo_url, logo_url),
    address = COALESCE(p_address, address),
    phone = COALESCE(p_phone, phone),
    website = COALESCE(p_website, website),
    setup_completed_at = COALESCE(setup_completed_at, NOW()),
    updated_at = NOW()
  WHERE id = p_org_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.update_organization_setup TO authenticated;

-- Update worker label
CREATE OR REPLACE FUNCTION public.update_organization_worker_label(
  p_org_id UUID, p_worker_label TEXT, p_worker_label_plural TEXT
)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.user_belongs_to_org(p_org_id) THEN
    RAISE EXCEPTION 'Not authorized to update this organization';
  END IF;
  UPDATE organizations SET
    worker_label = p_worker_label,
    worker_label_plural = p_worker_label_plural,
    updated_at = NOW()
  WHERE id = p_org_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.update_organization_worker_label TO authenticated;


-- ============================================================================
-- PART 15: ADMIN BOOTSTRAP GUARD
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO app_settings (key, value)
VALUES ('allow_admin_bootstrap', 'true')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.can_bootstrap_admin()
RETURNS BOOLEAN AS $$
DECLARE
  allow_flag BOOLEAN;
  admin_count INTEGER;
BEGIN
  SELECT value::BOOLEAN INTO allow_flag
  FROM app_settings WHERE key = 'allow_admin_bootstrap';
  IF allow_flag IS NULL THEN allow_flag := true; END IF;
  SELECT COUNT(*) INTO admin_count FROM public.users WHERE role = 'admin';
  RETURN allow_flag AND admin_count = 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.can_bootstrap_admin() TO anon, authenticated;


-- ============================================================================
-- PART 16: STORAGE BUCKETS
-- ============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('organization-logos', 'organization-logos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('tool-images', 'tool-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
DROP POLICY IF EXISTS "Authenticated users can upload logos" ON storage.objects;
CREATE POLICY "Authenticated users can upload logos" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'organization-logos');

DROP POLICY IF EXISTS "Public can read logos" ON storage.objects;
CREATE POLICY "Public can read logos" ON storage.objects
  FOR SELECT USING (bucket_id = 'organization-logos');

DROP POLICY IF EXISTS "Authenticated users can upload profile pictures" ON storage.objects;
CREATE POLICY "Authenticated users can upload profile pictures" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'profile-pictures');

DROP POLICY IF EXISTS "Public can read profile pictures" ON storage.objects;
CREATE POLICY "Public can read profile pictures" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile-pictures');

DROP POLICY IF EXISTS "Authenticated users can upload tool images" ON storage.objects;
CREATE POLICY "Authenticated users can upload tool images" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'tool-images');

DROP POLICY IF EXISTS "Public can read tool images" ON storage.objects;
CREATE POLICY "Public can read tool images" ON storage.objects
  FOR SELECT USING (bucket_id = 'tool-images');


-- ============================================================================
-- DONE
-- ============================================================================
SELECT '✅ Master setup complete. All tables, RLS, functions, and storage ready.' AS status;
