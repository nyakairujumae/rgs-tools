-- ============================================================================
-- FIX: Drop duplicate overloaded functions, then recreate the correct version
-- Run this in Supabase SQL Editor
-- ============================================================================

-- Drop ALL versions of the function (both old and new signatures)
DROP FUNCTION IF EXISTS public.create_organization_and_assign_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_organization_and_assign_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Also drop update_organization_setup if it has duplicates
DROP FUNCTION IF EXISTS public.update_organization_setup(UUID, TEXT, TEXT, TEXT, TEXT);

-- Also drop update_organization_worker_label if it has duplicates
DROP FUNCTION IF EXISTS public.update_organization_worker_label(UUID, TEXT, TEXT);

-- Also drop seed_industry_defaults if it has duplicates
DROP FUNCTION IF EXISTS public.seed_industry_defaults(UUID, TEXT);

-- Also drop seed_default_positions_for_org if it has duplicates
DROP FUNCTION IF EXISTS public.seed_default_positions_for_org(UUID);

-- Also drop can_bootstrap_admin if it has duplicates
DROP FUNCTION IF EXISTS public.can_bootstrap_admin();

-- ============================================================================
-- Now recreate all functions cleanly
-- ============================================================================

-- Seed default admin positions for a new org
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

-- Seed industry-specific departments + tool categories
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

-- Create org + assign first admin (with industry support)
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

-- Update org details
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

-- Bootstrap guard
CREATE OR REPLACE FUNCTION public.can_bootstrap_admin()
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
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
$$;
GRANT EXECUTE ON FUNCTION public.can_bootstrap_admin() TO anon, authenticated;

SELECT '✅ Functions recreated cleanly. Try registering as Admin now.' AS status;
