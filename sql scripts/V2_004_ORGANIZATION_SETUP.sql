-- ============================================================================
-- V2 ORGANIZATION SETUP (Company Onboarding)
-- Run AFTER V2_001, V2_002, V2_003
-- ============================================================================
-- Extends organizations table for company setup wizard.
-- Adds RPC to create org and assign first user.
-- ============================================================================

-- ============================================================================
-- 1. EXTEND ORGANIZATIONS TABLE
-- ============================================================================
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS setup_completed_at TIMESTAMP WITH TIME ZONE;

COMMENT ON COLUMN organizations.setup_completed_at IS 'NULL = company setup wizard not yet completed';

-- ============================================================================
-- 2. RPC: Create organization and assign user (for first-time signup)
-- ============================================================================
-- Caller must be authenticated. Creates org, assigns user as admin, seeds positions.
CREATE OR REPLACE FUNCTION public.create_organization_and_assign_user(
  p_name TEXT,
  p_slug TEXT,
  p_logo_url TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_website TEXT DEFAULT NULL
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

  -- User must not already belong to an org (first-time setup only)
  IF EXISTS (SELECT 1 FROM users WHERE id = v_user_id AND organization_id IS NOT NULL) THEN
    RAISE EXCEPTION 'User already belongs to an organization';
  END IF;

  -- Create organization
  INSERT INTO organizations (name, slug, logo_url, address, phone, website, setup_completed_at)
  VALUES (p_name, p_slug, p_logo_url, p_address, p_phone, p_website, NOW())
  RETURNING id INTO v_org_id;

  -- Assign user to org and set as admin
  UPDATE users
  SET organization_id = v_org_id, role = 'admin', updated_at = NOW()
  WHERE id = v_user_id;

  -- Seed default admin positions
  PERFORM public.seed_default_positions_for_org(v_org_id);

  -- Assign user to Super Admin position
  SELECT id INTO v_super_admin_id
  FROM admin_positions
  WHERE organization_id = v_org_id AND name = 'Super Admin'
  LIMIT 1;

  IF v_super_admin_id IS NOT NULL THEN
    UPDATE users SET position_id = v_super_admin_id WHERE id = v_user_id;
  END IF;

  RETURN v_org_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_organization_and_assign_user TO authenticated;

-- ============================================================================
-- 3. RPC: Update organization (logo, details) - for setup wizard step 2/3
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_organization_setup(
  p_org_id UUID,
  p_logo_url TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_website TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- User must belong to this org
  IF NOT public.user_belongs_to_org(p_org_id) THEN
    RAISE EXCEPTION 'Not authorized to update this organization';
  END IF;

  UPDATE organizations
  SET
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

-- ============================================================================
-- 4. POLICY: Allow users to update their org (for setup)
-- ============================================================================
DROP POLICY IF EXISTS "Authenticated users can insert organizations" ON organizations;

CREATE POLICY "Authenticated users can insert organizations"
  ON organizations FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Users can update orgs they belong to (for setup wizard)
CREATE POLICY "Org members can update own org"
  ON organizations FOR UPDATE
  TO authenticated
  USING (
    id IN (SELECT organization_id FROM users WHERE id = auth.uid() AND organization_id IS NOT NULL)
  )
  WITH CHECK (true);

SELECT '✅ V2 organization setup ready. Run company setup wizard in app.' as status;
