-- ============================================================================
-- FIX: Remove the old 6-param version of create_organization_and_assign_user
-- that V2_004 created, and keep only the correct 9-param version.
-- Run this after V2_004 fails or after running V2_004.
-- ============================================================================

-- Drop the old 6-parameter version (created by V2_004)
DROP FUNCTION IF EXISTS public.create_organization_and_assign_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Drop the 9-parameter version too (so we can cleanly recreate it)
DROP FUNCTION IF EXISTS public.create_organization_and_assign_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Recreate the correct 9-parameter version (with industry support)
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

SELECT '✅ Function conflict resolved. DB setup complete.' AS status;
