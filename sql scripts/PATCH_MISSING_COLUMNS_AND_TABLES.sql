-- ============================================================================
-- PATCH SCRIPT — Add missing columns/tables to existing V2 schema
-- Run this if you already ran V2_001 through V2_005 but hit errors.
-- Safe to re-run: uses IF NOT EXISTS / ON CONFLICT everywhere.
-- ============================================================================


-- ============================================================================
-- 1. ADD MISSING COLUMNS TO users TABLE
-- ============================================================================
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS department TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS employee_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS status TEXT CHECK (status IN ('Active', 'Inactive', 'Pending')) DEFAULT 'Active';
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS approved_by UUID;
ALTER TABLE users ADD COLUMN IF NOT EXISTS position_id UUID;

-- Add missing indexes
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- ============================================================================
-- 2. ADD MISSING COLUMNS TO organizations TABLE
-- ============================================================================
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS setup_completed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS industry TEXT DEFAULT 'general';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS worker_label TEXT DEFAULT 'Technician';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS worker_label_plural TEXT DEFAULT 'Technicians';

-- ============================================================================
-- 3. ADD MISSING COLUMNS TO technicians TABLE
-- ============================================================================
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS profile_picture_url TEXT;
ALTER TABLE technicians ADD COLUMN IF NOT EXISTS notes TEXT;

-- ============================================================================
-- 4. ADMIN POSITIONS TABLE (if not exists)
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

-- Add FK from users.position_id → admin_positions.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_position_id_fkey'
  ) THEN
    ALTER TABLE users ADD CONSTRAINT users_position_id_fkey
      FOREIGN KEY (position_id) REFERENCES admin_positions(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Trigger
DROP TRIGGER IF EXISTS update_admin_positions_updated_at ON admin_positions;
CREATE TRIGGER update_admin_positions_updated_at
  BEFORE UPDATE ON admin_positions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to seed default positions
CREATE OR REPLACE FUNCTION public.seed_default_positions_for_org(p_org_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO admin_positions (organization_id, name, description, level)
  VALUES
    (p_org_id, 'Super Admin',   'Full system access',        5),
    (p_org_id, 'Manager',       'Manage team and tools',     4),
    (p_org_id, 'Supervisor',    'Oversee daily operations',  3),
    (p_org_id, 'Coordinator',   'Coordinate assignments',    2),
    (p_org_id, 'Support Staff', 'General support',           1)
  ON CONFLICT (organization_id, name) DO NOTHING;
END;
$$;
GRANT EXECUTE ON FUNCTION public.seed_default_positions_for_org TO authenticated;

-- ============================================================================
-- 5. PENDING USER APPROVALS TABLE (if not exists)
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
  BEFORE UPDATE ON pending_user_approvals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. ORGANIZATION DEPARTMENTS TABLE (if not exists)
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
-- 7. ORGANIZATION TOOL CATEGORIES TABLE (if not exists)
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
-- 8. USER FCM TOKENS TABLE (if not exists)
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
-- 9. ADMIN BOOTSTRAP GUARD (if not exists)
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
-- 10. RPC FUNCTIONS (create or replace — safe to re-run)
-- ============================================================================

-- seed_industry_defaults
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

-- create_organization_and_assign_user (updated version with industry params)
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

-- update_organization_setup
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

-- update_organization_worker_label
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
-- 11. STORAGE BUCKETS (if not exists)
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

DROP POLICY IF EXISTS "Authenticated users can upload logos" ON storage.objects;
CREATE POLICY "Authenticated users can upload logos" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'organization-logos');

DROP POLICY IF EXISTS "Public can read logos" ON storage.objects;
CREATE POLICY "Public can read logos" ON storage.objects
  FOR SELECT USING (bucket_id = 'organization-logos');

DROP POLICY IF EXISTS "Authenticated users can upload profile pictures" ON storage.objects;
CREATE POLICY "Authenticated users can upload profile pictures" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profile-pictures');

DROP POLICY IF EXISTS "Public can read profile pictures" ON storage.objects;
CREATE POLICY "Public can read profile pictures" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile-pictures');

DROP POLICY IF EXISTS "Authenticated users can upload tool images" ON storage.objects;
CREATE POLICY "Authenticated users can upload tool images" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'tool-images');

DROP POLICY IF EXISTS "Public can read tool images" ON storage.objects;
CREATE POLICY "Public can read tool images" ON storage.objects
  FOR SELECT USING (bucket_id = 'tool-images');

-- ============================================================================
-- DONE
-- ============================================================================
SELECT '✅ Patch complete. All missing columns, tables, and functions added.' AS status;
