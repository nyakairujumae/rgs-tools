-- ============================================================================
-- V2 MULTI-TENANT REMAINING TABLES
-- Run AFTER V2_001 and V2_002
-- ============================================================================
-- Adds organization_id to: approval_workflows, pending_user_approvals,
-- tool_issues, admin_positions, admin_notifications, technician_notifications.
-- Creates tables if not exist; updates RLS and functions for tenant isolation.
-- ============================================================================

-- ============================================================================
-- 1. APPROVAL_WORKFLOWS (with organization_id)
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
CREATE INDEX IF NOT EXISTS idx_approval_workflows_request_type ON approval_workflows(request_type);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_requester_id ON approval_workflows(requester_id);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_assigned_to ON approval_workflows(assigned_to);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_due_date ON approval_workflows(due_date);

ALTER TABLE approval_workflows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view all approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Admins can update approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Admins can insert approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Technicians can view their own approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Technicians can insert their own approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Authenticated users can view all workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Tenant can manage approval workflows" ON approval_workflows;

CREATE POLICY "Tenant can manage approval workflows" ON approval_workflows
  FOR ALL
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

CREATE POLICY "Technicians can view own approval workflows" ON approval_workflows
  FOR SELECT USING (
    organization_id = public.current_organization_id() AND auth.uid() = requester_id
  );

CREATE POLICY "Technicians can insert own approval workflows" ON approval_workflows
  FOR INSERT WITH CHECK (
    organization_id = public.current_organization_id() AND auth.uid() = requester_id
  );

CREATE OR REPLACE FUNCTION public.update_approval_workflows_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_approval_workflows_updated_at ON approval_workflows;
CREATE TRIGGER update_approval_workflows_updated_at
  BEFORE UPDATE ON approval_workflows
  FOR EACH ROW
  EXECUTE FUNCTION update_approval_workflows_updated_at();

-- ============================================================================
-- 2. APPROVE / REJECT WORKFLOW FUNCTIONS (tenant-aware)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.approve_workflow(workflow_id UUID, approver_comments TEXT DEFAULT NULL)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.approval_workflows
  SET 
    status = 'Approved',
    approved_date = NOW(),
    approved_by = auth.uid(),
    comments = COALESCE(approver_comments, comments),
    updated_at = NOW()
  WHERE id = workflow_id 
    AND status = 'Pending'
    AND organization_id = public.current_organization_id();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval workflow not found or already processed.';
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.reject_workflow(workflow_id UUID, rejection_reason TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.approval_workflows
  SET 
    status = 'Rejected',
    rejected_date = NOW(),
    rejected_by = auth.uid(),
    rejection_reason = rejection_reason,
    updated_at = NOW()
  WHERE id = workflow_id 
    AND status = 'Pending'
    AND organization_id = public.current_organization_id();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval workflow not found or already processed.';
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 3. PENDING_USER_APPROVALS (with organization_id)
-- ============================================================================
CREATE TABLE IF NOT EXISTS pending_user_approvals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  email TEXT NOT NULL,
  full_name TEXT,
  employee_id TEXT,
  phone TEXT,
  department TEXT,
  hire_date DATE,
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
  rejection_reason TEXT,
  rejection_count INTEGER DEFAULT 0,
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pending_approvals_organization ON pending_user_approvals(organization_id);
CREATE INDEX IF NOT EXISTS idx_pending_approvals_status ON pending_user_approvals(status);
CREATE INDEX IF NOT EXISTS idx_pending_approvals_email ON pending_user_approvals(email);
CREATE INDEX IF NOT EXISTS idx_pending_approvals_submitted_at ON pending_user_approvals(submitted_at);

ALTER TABLE pending_user_approvals ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'pending_user_approvals' AND schemaname = 'public') LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON pending_user_approvals';
  END LOOP;
END $$;

CREATE POLICY "Admins can manage same-org pending approvals" ON pending_user_approvals
  FOR ALL
  USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin' AND u.organization_id = pending_user_approvals.organization_id)
  )
  WITH CHECK (organization_id = public.current_organization_id());

CREATE POLICY "Users can insert own pending approval" ON pending_user_approvals
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND organization_id = public.current_organization_id()
  );

CREATE POLICY "Users can view own pending approval" ON pending_user_approvals
  FOR SELECT USING (
    auth.uid() = user_id
    OR (organization_id = public.current_organization_id() AND EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  );

CREATE OR REPLACE FUNCTION update_pending_approvals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_pending_approvals_updated_at ON pending_user_approvals;
CREATE TRIGGER update_pending_approvals_updated_at
  BEFORE UPDATE ON pending_user_approvals
  FOR EACH ROW
  EXECUTE FUNCTION update_pending_approvals_updated_at();

-- Approve/reject functions (tenant-aware, use organization_id from approval)
CREATE OR REPLACE FUNCTION public.approve_pending_user(approval_id UUID, reviewer_id UUID)
RETURNS VOID AS $$
DECLARE
  approval_record RECORD;
BEGIN
  SELECT * INTO approval_record
  FROM pending_user_approvals
  WHERE id = approval_id 
    AND status = 'pending'
    AND organization_id = public.current_organization_id();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending approval not found or already processed';
  END IF;

  UPDATE pending_user_approvals
  SET status = 'approved', reviewed_at = NOW(), reviewed_by = reviewer_id
  WHERE id = approval_id;

  INSERT INTO users (id, email, full_name, role, organization_id, created_at)
  VALUES (
    approval_record.user_id,
    approval_record.email,
    approval_record.full_name,
    'technician',
    approval_record.organization_id,
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    role = 'technician',
    organization_id = approval_record.organization_id,
    updated_at = NOW();

  UPDATE auth.users
  SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('role', 'technician', 'organization_id', approval_record.organization_id::text)
  WHERE id = approval_record.user_id;

  INSERT INTO technicians (id, organization_id, name, email, employee_id, phone, department, hire_date, status, created_at)
  VALUES (
    approval_record.user_id,
    approval_record.organization_id,
    approval_record.full_name,
    approval_record.email,
    approval_record.employee_id,
    approval_record.phone,
    approval_record.department,
    approval_record.hire_date,
    'Active',
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    organization_id = approval_record.organization_id,
    name = approval_record.full_name,
    email = approval_record.email,
    employee_id = approval_record.employee_id,
    phone = approval_record.phone,
    department = approval_record.department,
    hire_date = approval_record.hire_date,
    status = 'Active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.reject_pending_user(approval_id UUID, reviewer_id UUID, reason TEXT)
RETURNS VOID AS $$
DECLARE
  approval_record RECORD;
BEGIN
  SELECT * INTO approval_record
  FROM pending_user_approvals
  WHERE id = approval_id 
    AND status = 'pending'
    AND organization_id = public.current_organization_id();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Pending approval not found or already processed';
  END IF;

  UPDATE pending_user_approvals
  SET status = 'rejected', rejection_reason = reason, rejection_count = rejection_count + 1,
      reviewed_at = NOW(), reviewed_by = reviewer_id
  WHERE id = approval_id;

  IF approval_record.rejection_count + 1 >= 3 THEN
    DELETE FROM auth.users WHERE id = approval_record.user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 4. TOOL_ISSUES (with organization_id via tools FK; add for clarity & RLS)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.tool_issues (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  tool_id UUID NOT NULL REFERENCES public.tools(id) ON DELETE CASCADE,
  tool_name TEXT NOT NULL,
  reported_by TEXT NOT NULL,
  reported_by_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  issue_type TEXT NOT NULL CHECK (issue_type IN ('Faulty', 'Lost', 'Damaged', 'Missing Parts', 'Other')),
  description TEXT NOT NULL,
  priority TEXT NOT NULL CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
  status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
  assigned_to TEXT,
  assigned_to_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  resolution TEXT,
  reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  attachments TEXT[],
  location TEXT,
  estimated_cost DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tool_issues_organization ON public.tool_issues(organization_id);
CREATE INDEX IF NOT EXISTS idx_tool_issues_tool_id ON public.tool_issues(tool_id);
CREATE INDEX IF NOT EXISTS idx_tool_issues_status ON public.tool_issues(status);
CREATE INDEX IF NOT EXISTS idx_tool_issues_priority ON public.tool_issues(priority);
CREATE INDEX IF NOT EXISTS idx_tool_issues_reported_at ON public.tool_issues(reported_at);

ALTER TABLE public.tool_issues ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'tool_issues' AND schemaname = 'public') LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON public.tool_issues';
  END LOOP;
END $$;

CREATE POLICY "Tenant can manage tool issues" ON public.tool_issues
  FOR ALL
  USING (organization_id = public.current_organization_id())
  WITH CHECK (organization_id = public.current_organization_id());

CREATE OR REPLACE FUNCTION public.handle_tool_issues_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_tool_issues_updated ON public.tool_issues;
CREATE TRIGGER on_tool_issues_updated
  BEFORE UPDATE ON public.tool_issues
  FOR EACH ROW EXECUTE FUNCTION public.handle_tool_issues_updated_at();

-- Add organization_id to existing tool_issues if table existed without it (migration helper)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tool_issues' AND column_name = 'organization_id') THEN
    ALTER TABLE public.tool_issues ADD COLUMN organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;
  END IF;
EXCEPTION WHEN undefined_table THEN NULL;
END $$;

-- ============================================================================
-- 5. ADMIN_POSITIONS (org-specific)
-- ============================================================================
CREATE TABLE IF NOT EXISTS admin_positions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(organization_id, name)
);

CREATE INDEX IF NOT EXISTS idx_admin_positions_organization ON admin_positions(organization_id);
CREATE INDEX IF NOT EXISTS idx_admin_positions_active ON admin_positions(is_active) WHERE is_active = true;

CREATE TABLE IF NOT EXISTS position_permissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  position_id UUID REFERENCES admin_positions(id) ON DELETE CASCADE,
  permission_name TEXT NOT NULL,
  is_granted BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(position_id, permission_name)
);

ALTER TABLE admin_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE position_permissions ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'admin_positions' AND schemaname = 'public') LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON admin_positions';
  END LOOP;
END $$;

CREATE POLICY "Tenant can read positions" ON admin_positions
  FOR SELECT USING (organization_id = public.current_organization_id());

CREATE POLICY "Admins can manage same-org positions" ON admin_positions
  FOR ALL
  USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin' AND u.organization_id = admin_positions.organization_id)
  )
  WITH CHECK (organization_id = public.current_organization_id());

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'position_permissions' AND schemaname = 'public') LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON position_permissions';
  END LOOP;
END $$;

CREATE POLICY "Tenant can read position permissions" ON position_permissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM admin_positions ap
      WHERE ap.id = position_permissions.position_id
      AND ap.organization_id = public.current_organization_id()
    )
  );

-- Add position_id to users if not exists
ALTER TABLE users ADD COLUMN IF NOT EXISTS position_id UUID REFERENCES admin_positions(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_users_position_id ON users(position_id) WHERE role = 'admin';

-- Seed default positions for a new organization (call after creating org)
CREATE OR REPLACE FUNCTION public.seed_default_positions_for_org(p_org_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  super_admin_id UUID;
  admin_id UUID;
  inventory_manager_id UUID;
  hr_admin_id UUID;
  finance_admin_id UUID;
  viewer_id UUID;
BEGIN
  INSERT INTO admin_positions (organization_id, name, description, is_active)
  VALUES
    (p_org_id, 'Super Admin', 'Full system access with all permissions', true),
    (p_org_id, 'Admin', 'Standard admin with most permissions, cannot manage other admins', true),
    (p_org_id, 'Inventory Manager', 'Can manage tools and view reports, cannot manage users', true),
    (p_org_id, 'HR Admin', 'Can manage technicians and view reports, cannot manage tools', true),
    (p_org_id, 'Finance Admin', 'Can view and export reports, read-only access', true),
    (p_org_id, 'Viewer', 'Read-only access to tools and reports', true)
  ON CONFLICT (organization_id, name) DO NOTHING;

  SELECT id INTO super_admin_id FROM admin_positions WHERE organization_id = p_org_id AND name = 'Super Admin' LIMIT 1;
  SELECT id INTO admin_id FROM admin_positions WHERE organization_id = p_org_id AND name = 'Admin' LIMIT 1;
  SELECT id INTO inventory_manager_id FROM admin_positions WHERE organization_id = p_org_id AND name = 'Inventory Manager' LIMIT 1;
  SELECT id INTO hr_admin_id FROM admin_positions WHERE organization_id = p_org_id AND name = 'HR Admin' LIMIT 1;
  SELECT id INTO finance_admin_id FROM admin_positions WHERE organization_id = p_org_id AND name = 'Finance Admin' LIMIT 1;
  SELECT id INTO viewer_id FROM admin_positions WHERE organization_id = p_org_id AND name = 'Viewer' LIMIT 1;

  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (super_admin_id, 'can_manage_users', true), (super_admin_id, 'can_manage_admins', true),
    (super_admin_id, 'can_delete_users', true), (super_admin_id, 'can_view_all_tools', true),
    (super_admin_id, 'can_add_tools', true), (super_admin_id, 'can_edit_tools', true),
    (super_admin_id, 'can_delete_tools', true), (super_admin_id, 'can_manage_tool_assignments', true),
    (super_admin_id, 'can_update_tool_condition', true), (super_admin_id, 'can_manage_technicians', true),
    (super_admin_id, 'can_approve_technicians', true), (super_admin_id, 'can_view_reports', true),
    (super_admin_id, 'can_export_reports', true), (super_admin_id, 'can_view_financial_data', true),
    (super_admin_id, 'can_view_approval_workflows', true), (super_admin_id, 'can_manage_settings', true),
    (super_admin_id, 'can_bulk_import', true), (super_admin_id, 'can_delete_data', true),
    (super_admin_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (admin_id, 'can_manage_users', false), (admin_id, 'can_manage_admins', false), (admin_id, 'can_delete_users', false),
    (admin_id, 'can_view_all_tools', true), (admin_id, 'can_add_tools', true), (admin_id, 'can_edit_tools', true),
    (admin_id, 'can_delete_tools', false), (admin_id, 'can_manage_tool_assignments', true),
    (admin_id, 'can_update_tool_condition', true), (admin_id, 'can_manage_technicians', true),
    (admin_id, 'can_approve_technicians', true), (admin_id, 'can_view_reports', true),
    (admin_id, 'can_export_reports', true), (admin_id, 'can_view_financial_data', true),
    (admin_id, 'can_view_approval_workflows', true), (admin_id, 'can_manage_settings', false),
    (admin_id, 'can_bulk_import', false), (admin_id, 'can_delete_data', false),
    (admin_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (inventory_manager_id, 'can_manage_users', false), (inventory_manager_id, 'can_manage_admins', false),
    (inventory_manager_id, 'can_delete_users', false), (inventory_manager_id, 'can_view_all_tools', true),
    (inventory_manager_id, 'can_add_tools', true), (inventory_manager_id, 'can_edit_tools', true),
    (inventory_manager_id, 'can_delete_tools', false), (inventory_manager_id, 'can_manage_tool_assignments', true),
    (inventory_manager_id, 'can_update_tool_condition', true), (inventory_manager_id, 'can_manage_technicians', false),
    (inventory_manager_id, 'can_approve_technicians', false), (inventory_manager_id, 'can_view_reports', true),
    (inventory_manager_id, 'can_export_reports', true), (inventory_manager_id, 'can_view_financial_data', false),
    (inventory_manager_id, 'can_view_approval_workflows', false), (inventory_manager_id, 'can_manage_settings', false),
    (inventory_manager_id, 'can_bulk_import', false), (inventory_manager_id, 'can_delete_data', false),
    (inventory_manager_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (hr_admin_id, 'can_manage_technicians', true), (hr_admin_id, 'can_approve_technicians', true),
    (hr_admin_id, 'can_view_reports', true), (hr_admin_id, 'can_export_reports', true),
    (hr_admin_id, 'can_view_approval_workflows', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (finance_admin_id, 'can_view_reports', true), (finance_admin_id, 'can_export_reports', true),
    (finance_admin_id, 'can_view_financial_data', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (viewer_id, 'can_view_all_tools', true), (viewer_id, 'can_view_reports', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;
END;
$$;

-- user_has_permission: check permission for user (tenant-aware via user's org)
CREATE OR REPLACE FUNCTION public.user_has_permission(user_id_param UUID, permission_name_param TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  user_role TEXT;
  user_position_id UUID;
  has_permission BOOLEAN;
BEGIN
  SELECT role, position_id INTO user_role, user_position_id FROM users WHERE id = user_id_param;
  IF user_role != 'admin' OR user_position_id IS NULL THEN
    RETURN false;
  END IF;
  SELECT is_granted INTO has_permission FROM position_permissions
  WHERE position_id = user_position_id AND permission_name = permission_name_param;
  RETURN COALESCE(has_permission, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 6. ADMIN_NOTIFICATIONS (create if not exist, with organization_id)
-- ============================================================================
CREATE TABLE IF NOT EXISTS admin_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  technician_name TEXT NOT NULL,
  technician_email TEXT NOT NULL,
  type TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add organization_id if table existed without it
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'admin_notifications' AND column_name = 'organization_id') THEN
    ALTER TABLE admin_notifications ADD COLUMN organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;
  END IF;
EXCEPTION WHEN undefined_table THEN
  NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_admin_notifications_organization ON admin_notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_timestamp ON admin_notifications(timestamp DESC);

ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'admin_notifications' AND schemaname = 'public') LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON admin_notifications';
  END LOOP;
END $$;

CREATE POLICY "Admins can view same-org notifications" ON admin_notifications
  FOR SELECT USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin')
  );

CREATE POLICY "Admins can update same-org notifications" ON admin_notifications
  FOR UPDATE USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin')
  );

CREATE POLICY "Admins can delete same-org notifications" ON admin_notifications
  FOR DELETE USING (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin')
  );

-- Insert via SECURITY DEFINER (uses current user's org)
CREATE OR REPLACE FUNCTION public.insert_admin_notification(
  p_title TEXT,
  p_message TEXT,
  p_technician_name TEXT,
  p_technician_email TEXT,
  p_type TEXT,
  p_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification_id UUID;
  v_user_id UUID;
  v_org_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to create notifications';
  END IF;

  v_org_id := public.current_organization_id();
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'User must belong to an organization to create notifications';
  END IF;

  INSERT INTO admin_notifications (
    organization_id, title, message, technician_name, technician_email, type, is_read, timestamp, data
  ) VALUES (
    v_org_id, p_title, p_message, p_technician_name, p_technician_email, p_type, false, NOW(), p_data
  )
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.insert_admin_notification TO authenticated;

-- ============================================================================
-- 7. TECHNICIAN_NOTIFICATIONS (with organization_id)
-- ============================================================================
CREATE TABLE IF NOT EXISTS technician_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('tool_request', 'account_approved', 'tool_assigned', 'tool_returned', 'general')),
  is_read BOOLEAN DEFAULT FALSE,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add organization_id if table existed without it
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'technician_notifications' AND column_name = 'organization_id') THEN
    ALTER TABLE technician_notifications ADD COLUMN organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;
  END IF;
EXCEPTION WHEN undefined_table THEN
  NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_technician_notifications_organization ON technician_notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_technician_notifications_user_id ON technician_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_technician_notifications_timestamp ON technician_notifications(timestamp DESC);

ALTER TABLE technician_notifications ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'technician_notifications' AND schemaname = 'public') LOOP
    EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON technician_notifications';
  END LOOP;
END $$;

CREATE POLICY "Users can view own technician notifications" ON technician_notifications
  FOR SELECT USING (
    user_id = auth.uid()
    AND organization_id = public.current_organization_id()
  );

CREATE POLICY "Users can update own technician notifications" ON technician_notifications
  FOR UPDATE USING (user_id = auth.uid() AND organization_id = public.current_organization_id());

CREATE POLICY "Tenant can create technician notifications" ON technician_notifications
  FOR INSERT WITH CHECK (
    organization_id = public.current_organization_id()
    AND EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('admin', 'technician'))
  );

CREATE OR REPLACE FUNCTION public.handle_technician_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_technician_notifications_updated ON technician_notifications;
CREATE TRIGGER on_technician_notifications_updated
  BEFORE UPDATE ON technician_notifications
  FOR EACH ROW EXECUTE FUNCTION public.handle_technician_notifications_updated_at();

-- ============================================================================
-- 8. USER_FCM_TOKENS (no organization_id - user-scoped; RLS unchanged)
-- ============================================================================
-- user_fcm_tokens stays user-scoped. Users access only their own tokens.
-- Push targeting by org is done via users.organization_id join.
-- Run FIX_USER_FCM_TOKENS_TABLE.sql separately if needed.

SELECT '✅ V2 multi-tenant tables ready.' as status;
