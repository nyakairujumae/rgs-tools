-- ============================================================================
-- V2_005 INDUSTRY CONFIG (Whitelabel Multi-Tenant)
-- Run AFTER V2_001 through V2_004
-- ============================================================================
-- Adds industry-specific configuration per tenant:
--   - organizations.industry, worker_label, worker_label_plural
--   - organization_departments table (admin-managed)
--   - organization_tool_categories table (admin-managed)
--   - seed_industry_defaults() RPC to pre-populate from preset
--   - Updates create_organization_and_assign_user() to accept industry/labels
-- ============================================================================

-- ============================================================================
-- 1. EXTEND ORGANIZATIONS TABLE
-- ============================================================================
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS industry TEXT DEFAULT 'general';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS worker_label TEXT DEFAULT 'Technician';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS worker_label_plural TEXT DEFAULT 'Technicians';

COMMENT ON COLUMN organizations.industry IS 'Industry preset: hvac | electrical | fm | construction | general';
COMMENT ON COLUMN organizations.worker_label IS 'Singular label for field workers, e.g. Technician, Electrician, Operative';
COMMENT ON COLUMN organizations.worker_label_plural IS 'Plural label for field workers, e.g. Technicians, Electricians, Operatives';

-- ============================================================================
-- 2. ORGANIZATION DEPARTMENTS TABLE
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
CREATE POLICY "Org members can read departments"
  ON organization_departments FOR SELECT
  TO authenticated
  USING (organization_id = public.current_organization_id());

DROP POLICY IF EXISTS "Org admins can manage departments" ON organization_departments;
CREATE POLICY "Org admins can manage departments"
  ON organization_departments FOR ALL
  TO authenticated
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

-- ============================================================================
-- 3. ORGANIZATION TOOL CATEGORIES TABLE
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
CREATE POLICY "Org members can read tool categories"
  ON organization_tool_categories FOR SELECT
  TO authenticated
  USING (organization_id = public.current_organization_id());

DROP POLICY IF EXISTS "Org admins can manage tool categories" ON organization_tool_categories;
CREATE POLICY "Org admins can manage tool categories"
  ON organization_tool_categories FOR ALL
  TO authenticated
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

-- ============================================================================
-- 4. RPC: seed_industry_defaults
-- Inserts default departments + tool categories for a given industry preset.
-- Called by create_organization_and_assign_user().
-- ============================================================================
CREATE OR REPLACE FUNCTION public.seed_industry_defaults(
  p_org_id UUID,
  p_industry TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_departments TEXT[];
  v_categories  TEXT[];
  v_dept        TEXT;
  v_cat         TEXT;
  v_order       INTEGER;
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
      -- general (default)
      v_departments := ARRAY['Operations', 'Maintenance', 'Projects', 'Logistics'];
      v_categories  := ARRAY['Hand Tools', 'Power Tools', 'Safety Equipment', 'Testing Equipment', 'Measuring Tools', 'Other'];
  END CASE;

  -- Insert departments
  v_order := 0;
  FOREACH v_dept IN ARRAY v_departments LOOP
    INSERT INTO organization_departments (organization_id, name, sort_order)
    VALUES (p_org_id, v_dept, v_order)
    ON CONFLICT (organization_id, name) DO NOTHING;
    v_order := v_order + 1;
  END LOOP;

  -- Insert tool categories
  v_order := 0;
  FOREACH v_cat IN ARRAY v_categories LOOP
    INSERT INTO organization_tool_categories (organization_id, name, sort_order)
    VALUES (p_org_id, v_cat, v_order)
    ON CONFLICT (organization_id, name) DO NOTHING;
    v_order := v_order + 1;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.seed_industry_defaults TO authenticated;

-- ============================================================================
-- 5. UPDATE: create_organization_and_assign_user
-- Adds p_industry, p_worker_label, p_worker_label_plural parameters.
-- ============================================================================
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
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org_id UUID;
  v_user_id UUID;
  v_super_admin_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Must be authenticated to create organization';
  END IF;

  -- User must not already belong to an org
  IF EXISTS (SELECT 1 FROM users WHERE id = v_user_id AND organization_id IS NOT NULL) THEN
    RAISE EXCEPTION 'User already belongs to an organization';
  END IF;

  -- Create organization
  INSERT INTO organizations (
    name, slug, logo_url, address, phone, website,
    industry, worker_label, worker_label_plural,
    setup_completed_at
  )
  VALUES (
    p_name, p_slug, p_logo_url, p_address, p_phone, p_website,
    p_industry, p_worker_label, p_worker_label_plural,
    NOW()
  )
  RETURNING id INTO v_org_id;

  -- Assign user to org as admin
  UPDATE users
  SET organization_id = v_org_id, role = 'admin', updated_at = NOW()
  WHERE id = v_user_id;

  -- Seed default admin positions
  PERFORM public.seed_default_positions_for_org(v_org_id);

  -- Assign Super Admin position
  SELECT id INTO v_super_admin_id
  FROM admin_positions
  WHERE organization_id = v_org_id AND name = 'Super Admin'
  LIMIT 1;

  IF v_super_admin_id IS NOT NULL THEN
    UPDATE users SET position_id = v_super_admin_id WHERE id = v_user_id;
  END IF;

  -- Seed industry-specific departments and tool categories
  PERFORM public.seed_industry_defaults(v_org_id, p_industry);

  RETURN v_org_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_organization_and_assign_user TO authenticated;

-- ============================================================================
-- 6. RPC: update_organization_industry
-- Allows admin to update worker label (and regenerate defaults if needed).
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_organization_worker_label(
  p_org_id UUID,
  p_worker_label TEXT,
  p_worker_label_plural TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.user_belongs_to_org(p_org_id) THEN
    RAISE EXCEPTION 'Not authorized to update this organization';
  END IF;

  UPDATE organizations
  SET
    worker_label = p_worker_label,
    worker_label_plural = p_worker_label_plural,
    updated_at = NOW()
  WHERE id = p_org_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_organization_worker_label TO authenticated;

SELECT '✅ V2_005 industry config ready. Run company setup wizard to pick industry preset.' AS status;
