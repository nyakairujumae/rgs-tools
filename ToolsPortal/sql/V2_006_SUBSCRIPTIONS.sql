-- ============================================================================
-- V2_006 SUBSCRIPTIONS
-- Adds billing/subscription tracking to organizations.
-- Run AFTER V2_005.
-- ============================================================================

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS paddle_customer_id      TEXT,
  ADD COLUMN IF NOT EXISTS paddle_subscription_id  TEXT,
  ADD COLUMN IF NOT EXISTS subscription_plan        TEXT DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS subscription_status      TEXT DEFAULT 'trialing',
  ADD COLUMN IF NOT EXISTS trial_ends_at            TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS subscription_ends_at     TIMESTAMP WITH TIME ZONE;

-- subscription_plan:  'none' | 'starter' | 'pro'
-- subscription_status: 'trialing' | 'active' | 'past_due' | 'cancelled' | 'paused'

COMMENT ON COLUMN organizations.subscription_plan   IS 'Current plan: none, starter, pro';
COMMENT ON COLUMN organizations.subscription_status IS 'trialing | active | past_due | cancelled | paused';
COMMENT ON COLUMN organizations.trial_ends_at        IS 'When the free trial expires (14 days after signup)';
COMMENT ON COLUMN organizations.subscription_ends_at IS 'When the current billing period ends';

-- ============================================================================
-- Set trial_ends_at for any existing orgs that don't have it yet
-- ============================================================================
UPDATE organizations
SET
  trial_ends_at     = created_at + INTERVAL '14 days',
  subscription_status = 'trialing'
WHERE trial_ends_at IS NULL;

-- ============================================================================
-- RPC: get_subscription_status
-- Returns the effective access state for an org.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_subscription_status(p_org_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_org organizations%ROWTYPE;
  v_has_access BOOLEAN;
  v_reason TEXT;
BEGIN
  SELECT * INTO v_org FROM organizations WHERE id = p_org_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('has_access', false, 'reason', 'org_not_found');
  END IF;

  -- Active subscription
  IF v_org.subscription_status = 'active' THEN
    v_has_access := true;
    v_reason := 'active';

  -- Trialing and trial not expired
  ELSIF v_org.subscription_status = 'trialing'
    AND v_org.trial_ends_at IS NOT NULL
    AND v_org.trial_ends_at > NOW() THEN
    v_has_access := true;
    v_reason := 'trialing';

  -- Trial expired
  ELSIF v_org.subscription_status = 'trialing'
    AND (v_org.trial_ends_at IS NULL OR v_org.trial_ends_at <= NOW()) THEN
    v_has_access := false;
    v_reason := 'trial_expired';

  ELSE
    v_has_access := false;
    v_reason := v_org.subscription_status;
  END IF;

  RETURN jsonb_build_object(
    'has_access',          v_has_access,
    'reason',              v_reason,
    'plan',                COALESCE(v_org.subscription_plan, 'none'),
    'status',              COALESCE(v_org.subscription_status, 'trialing'),
    'trial_ends_at',       v_org.trial_ends_at,
    'subscription_ends_at', v_org.subscription_ends_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_subscription_status TO authenticated;

-- ============================================================================
-- Update create_organization_and_assign_user to set trial on org creation
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

  IF EXISTS (SELECT 1 FROM users WHERE id = v_user_id AND organization_id IS NOT NULL) THEN
    RAISE EXCEPTION 'User already belongs to an organization';
  END IF;

  INSERT INTO organizations (
    name, slug, logo_url, address, phone, website,
    industry, worker_label, worker_label_plural,
    setup_completed_at,
    subscription_plan, subscription_status, trial_ends_at
  )
  VALUES (
    p_name, p_slug, p_logo_url, p_address, p_phone, p_website,
    p_industry, p_worker_label, p_worker_label_plural,
    NOW(),
    'pro', 'trialing', NOW() + INTERVAL '14 days'
  )
  RETURNING id INTO v_org_id;

  UPDATE users
  SET organization_id = v_org_id, role = 'admin', updated_at = NOW()
  WHERE id = v_user_id;

  PERFORM public.seed_default_positions_for_org(v_org_id);

  SELECT id INTO v_super_admin_id
  FROM admin_positions
  WHERE organization_id = v_org_id AND name = 'Super Admin'
  LIMIT 1;

  IF v_super_admin_id IS NOT NULL THEN
    UPDATE users SET position_id = v_super_admin_id WHERE id = v_user_id;
  END IF;

  PERFORM public.seed_industry_defaults(v_org_id, p_industry);

  RETURN v_org_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_organization_and_assign_user TO authenticated;
