-- ===========================================
-- HVAC Admin Positions - Seed Data
-- ===========================================
-- Adds HVAC-focused admin positions and permissions.
-- Safe to run multiple times (idempotent).

INSERT INTO admin_positions (name, description, is_active)
VALUES
  ('Operations Manager', 'Full operational access, cannot manage admins or delete data', true),
  ('Service Manager', 'Service management access, no admin management or financial editing', true),
  ('Maintenance Supervisor', 'Maintenance access with limited edits and no admin management', true),
  ('Field Supervisor', 'Field operations access, no admin or financial privileges', true),
  ('Dispatch Coordinator', 'Dispatch access with limited edits and no admin management', true),
  ('Procurement Manager', 'Procurement access with reports and finance view only', true),
  ('Project Manager', 'Project oversight access without admin management', true),
  ('HVAC Engineer', 'Technical review access with read-only tools and reports', true),
  ('Training Coordinator', 'Training-related access with reports only', true),
  ('Admin Assistant', 'Limited admin support access without admin management', true)
ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active;

DO $$
DECLARE
  operations_manager_id UUID;
  service_manager_id UUID;
  maintenance_supervisor_id UUID;
  field_supervisor_id UUID;
  dispatch_coordinator_id UUID;
  procurement_manager_id UUID;
  project_manager_id UUID;
  hvac_engineer_id UUID;
  training_coordinator_id UUID;
  admin_assistant_id UUID;
BEGIN
  SELECT id INTO operations_manager_id FROM admin_positions WHERE name = 'Operations Manager';
  SELECT id INTO service_manager_id FROM admin_positions WHERE name = 'Service Manager';
  SELECT id INTO maintenance_supervisor_id FROM admin_positions WHERE name = 'Maintenance Supervisor';
  SELECT id INTO field_supervisor_id FROM admin_positions WHERE name = 'Field Supervisor';
  SELECT id INTO dispatch_coordinator_id FROM admin_positions WHERE name = 'Dispatch Coordinator';
  SELECT id INTO procurement_manager_id FROM admin_positions WHERE name = 'Procurement Manager';
  SELECT id INTO project_manager_id FROM admin_positions WHERE name = 'Project Manager';
  SELECT id INTO hvac_engineer_id FROM admin_positions WHERE name = 'HVAC Engineer';
  SELECT id INTO training_coordinator_id FROM admin_positions WHERE name = 'Training Coordinator';
  SELECT id INTO admin_assistant_id FROM admin_positions WHERE name = 'Admin Assistant';

  -- Operations Manager
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (operations_manager_id, 'can_manage_users', false),
    (operations_manager_id, 'can_manage_admins', false),
    (operations_manager_id, 'can_delete_users', false),
    (operations_manager_id, 'can_view_all_tools', true),
    (operations_manager_id, 'can_add_tools', true),
    (operations_manager_id, 'can_edit_tools', true),
    (operations_manager_id, 'can_delete_tools', false),
    (operations_manager_id, 'can_manage_tool_assignments', true),
    (operations_manager_id, 'can_update_tool_condition', true),
    (operations_manager_id, 'can_manage_technicians', true),
    (operations_manager_id, 'can_approve_technicians', true),
    (operations_manager_id, 'can_view_reports', true),
    (operations_manager_id, 'can_export_reports', true),
    (operations_manager_id, 'can_view_financial_data', true),
    (operations_manager_id, 'can_view_approval_workflows', true),
    (operations_manager_id, 'can_manage_settings', false),
    (operations_manager_id, 'can_bulk_import', true),
    (operations_manager_id, 'can_delete_data', false),
    (operations_manager_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Service Manager
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (service_manager_id, 'can_manage_users', false),
    (service_manager_id, 'can_manage_admins', false),
    (service_manager_id, 'can_delete_users', false),
    (service_manager_id, 'can_view_all_tools', true),
    (service_manager_id, 'can_add_tools', true),
    (service_manager_id, 'can_edit_tools', true),
    (service_manager_id, 'can_delete_tools', false),
    (service_manager_id, 'can_manage_tool_assignments', true),
    (service_manager_id, 'can_update_tool_condition', true),
    (service_manager_id, 'can_manage_technicians', true),
    (service_manager_id, 'can_approve_technicians', true),
    (service_manager_id, 'can_view_reports', true),
    (service_manager_id, 'can_export_reports', true),
    (service_manager_id, 'can_view_financial_data', false),
    (service_manager_id, 'can_view_approval_workflows', true),
    (service_manager_id, 'can_manage_settings', false),
    (service_manager_id, 'can_bulk_import', false),
    (service_manager_id, 'can_delete_data', false),
    (service_manager_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Maintenance Supervisor
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (maintenance_supervisor_id, 'can_manage_users', false),
    (maintenance_supervisor_id, 'can_manage_admins', false),
    (maintenance_supervisor_id, 'can_delete_users', false),
    (maintenance_supervisor_id, 'can_view_all_tools', true),
    (maintenance_supervisor_id, 'can_add_tools', false),
    (maintenance_supervisor_id, 'can_edit_tools', false),
    (maintenance_supervisor_id, 'can_delete_tools', false),
    (maintenance_supervisor_id, 'can_manage_tool_assignments', true),
    (maintenance_supervisor_id, 'can_update_tool_condition', true),
    (maintenance_supervisor_id, 'can_manage_technicians', true),
    (maintenance_supervisor_id, 'can_approve_technicians', false),
    (maintenance_supervisor_id, 'can_view_reports', true),
    (maintenance_supervisor_id, 'can_export_reports', false),
    (maintenance_supervisor_id, 'can_view_financial_data', false),
    (maintenance_supervisor_id, 'can_view_approval_workflows', true),
    (maintenance_supervisor_id, 'can_manage_settings', false),
    (maintenance_supervisor_id, 'can_bulk_import', false),
    (maintenance_supervisor_id, 'can_delete_data', false),
    (maintenance_supervisor_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Field Supervisor
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (field_supervisor_id, 'can_manage_users', false),
    (field_supervisor_id, 'can_manage_admins', false),
    (field_supervisor_id, 'can_delete_users', false),
    (field_supervisor_id, 'can_view_all_tools', true),
    (field_supervisor_id, 'can_add_tools', false),
    (field_supervisor_id, 'can_edit_tools', false),
    (field_supervisor_id, 'can_delete_tools', false),
    (field_supervisor_id, 'can_manage_tool_assignments', true),
    (field_supervisor_id, 'can_update_tool_condition', true),
    (field_supervisor_id, 'can_manage_technicians', true),
    (field_supervisor_id, 'can_approve_technicians', false),
    (field_supervisor_id, 'can_view_reports', true),
    (field_supervisor_id, 'can_export_reports', false),
    (field_supervisor_id, 'can_view_financial_data', false),
    (field_supervisor_id, 'can_view_approval_workflows', true),
    (field_supervisor_id, 'can_manage_settings', false),
    (field_supervisor_id, 'can_bulk_import', false),
    (field_supervisor_id, 'can_delete_data', false),
    (field_supervisor_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Dispatch Coordinator
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (dispatch_coordinator_id, 'can_manage_users', false),
    (dispatch_coordinator_id, 'can_manage_admins', false),
    (dispatch_coordinator_id, 'can_delete_users', false),
    (dispatch_coordinator_id, 'can_view_all_tools', true),
    (dispatch_coordinator_id, 'can_add_tools', false),
    (dispatch_coordinator_id, 'can_edit_tools', false),
    (dispatch_coordinator_id, 'can_delete_tools', false),
    (dispatch_coordinator_id, 'can_manage_tool_assignments', true),
    (dispatch_coordinator_id, 'can_update_tool_condition', false),
    (dispatch_coordinator_id, 'can_manage_technicians', true),
    (dispatch_coordinator_id, 'can_approve_technicians', false),
    (dispatch_coordinator_id, 'can_view_reports', true),
    (dispatch_coordinator_id, 'can_export_reports', false),
    (dispatch_coordinator_id, 'can_view_financial_data', false),
    (dispatch_coordinator_id, 'can_view_approval_workflows', true),
    (dispatch_coordinator_id, 'can_manage_settings', false),
    (dispatch_coordinator_id, 'can_bulk_import', false),
    (dispatch_coordinator_id, 'can_delete_data', false),
    (dispatch_coordinator_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Procurement Manager
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (procurement_manager_id, 'can_manage_users', false),
    (procurement_manager_id, 'can_manage_admins', false),
    (procurement_manager_id, 'can_delete_users', false),
    (procurement_manager_id, 'can_view_all_tools', true),
    (procurement_manager_id, 'can_add_tools', true),
    (procurement_manager_id, 'can_edit_tools', true),
    (procurement_manager_id, 'can_delete_tools', false),
    (procurement_manager_id, 'can_manage_tool_assignments', false),
    (procurement_manager_id, 'can_update_tool_condition', false),
    (procurement_manager_id, 'can_manage_technicians', false),
    (procurement_manager_id, 'can_approve_technicians', false),
    (procurement_manager_id, 'can_view_reports', true),
    (procurement_manager_id, 'can_export_reports', true),
    (procurement_manager_id, 'can_view_financial_data', true),
    (procurement_manager_id, 'can_view_approval_workflows', true),
    (procurement_manager_id, 'can_manage_settings', false),
    (procurement_manager_id, 'can_bulk_import', false),
    (procurement_manager_id, 'can_delete_data', false),
    (procurement_manager_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Project Manager
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (project_manager_id, 'can_manage_users', false),
    (project_manager_id, 'can_manage_admins', false),
    (project_manager_id, 'can_delete_users', false),
    (project_manager_id, 'can_view_all_tools', true),
    (project_manager_id, 'can_add_tools', false),
    (project_manager_id, 'can_edit_tools', false),
    (project_manager_id, 'can_delete_tools', false),
    (project_manager_id, 'can_manage_tool_assignments', true),
    (project_manager_id, 'can_update_tool_condition', false),
    (project_manager_id, 'can_manage_technicians', true),
    (project_manager_id, 'can_approve_technicians', false),
    (project_manager_id, 'can_view_reports', true),
    (project_manager_id, 'can_export_reports', false),
    (project_manager_id, 'can_view_financial_data', false),
    (project_manager_id, 'can_view_approval_workflows', true),
    (project_manager_id, 'can_manage_settings', false),
    (project_manager_id, 'can_bulk_import', false),
    (project_manager_id, 'can_delete_data', false),
    (project_manager_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- HVAC Engineer
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (hvac_engineer_id, 'can_manage_users', false),
    (hvac_engineer_id, 'can_manage_admins', false),
    (hvac_engineer_id, 'can_delete_users', false),
    (hvac_engineer_id, 'can_view_all_tools', true),
    (hvac_engineer_id, 'can_add_tools', false),
    (hvac_engineer_id, 'can_edit_tools', false),
    (hvac_engineer_id, 'can_delete_tools', false),
    (hvac_engineer_id, 'can_manage_tool_assignments', false),
    (hvac_engineer_id, 'can_update_tool_condition', false),
    (hvac_engineer_id, 'can_manage_technicians', false),
    (hvac_engineer_id, 'can_approve_technicians', false),
    (hvac_engineer_id, 'can_view_reports', true),
    (hvac_engineer_id, 'can_export_reports', false),
    (hvac_engineer_id, 'can_view_financial_data', false),
    (hvac_engineer_id, 'can_view_approval_workflows', true),
    (hvac_engineer_id, 'can_manage_settings', false),
    (hvac_engineer_id, 'can_bulk_import', false),
    (hvac_engineer_id, 'can_delete_data', false),
    (hvac_engineer_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Training Coordinator
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (training_coordinator_id, 'can_manage_users', false),
    (training_coordinator_id, 'can_manage_admins', false),
    (training_coordinator_id, 'can_delete_users', false),
    (training_coordinator_id, 'can_view_all_tools', true),
    (training_coordinator_id, 'can_add_tools', false),
    (training_coordinator_id, 'can_edit_tools', false),
    (training_coordinator_id, 'can_delete_tools', false),
    (training_coordinator_id, 'can_manage_tool_assignments', false),
    (training_coordinator_id, 'can_update_tool_condition', false),
    (training_coordinator_id, 'can_manage_technicians', true),
    (training_coordinator_id, 'can_approve_technicians', false),
    (training_coordinator_id, 'can_view_reports', true),
    (training_coordinator_id, 'can_export_reports', false),
    (training_coordinator_id, 'can_view_financial_data', false),
    (training_coordinator_id, 'can_view_approval_workflows', true),
    (training_coordinator_id, 'can_manage_settings', false),
    (training_coordinator_id, 'can_bulk_import', false),
    (training_coordinator_id, 'can_delete_data', false),
    (training_coordinator_id, 'can_manage_notifications', false)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;

  -- Admin Assistant
  INSERT INTO position_permissions (position_id, permission_name, is_granted)
  VALUES
    (admin_assistant_id, 'can_manage_users', false),
    (admin_assistant_id, 'can_manage_admins', false),
    (admin_assistant_id, 'can_delete_users', false),
    (admin_assistant_id, 'can_view_all_tools', true),
    (admin_assistant_id, 'can_add_tools', false),
    (admin_assistant_id, 'can_edit_tools', false),
    (admin_assistant_id, 'can_delete_tools', false),
    (admin_assistant_id, 'can_manage_tool_assignments', false),
    (admin_assistant_id, 'can_update_tool_condition', false),
    (admin_assistant_id, 'can_manage_technicians', false),
    (admin_assistant_id, 'can_approve_technicians', false),
    (admin_assistant_id, 'can_view_reports', true),
    (admin_assistant_id, 'can_export_reports', false),
    (admin_assistant_id, 'can_view_financial_data', false),
    (admin_assistant_id, 'can_view_approval_workflows', true),
    (admin_assistant_id, 'can_manage_settings', false),
    (admin_assistant_id, 'can_bulk_import', false),
    (admin_assistant_id, 'can_delete_data', false),
    (admin_assistant_id, 'can_manage_notifications', true)
  ON CONFLICT (position_id, permission_name) DO UPDATE SET is_granted = EXCLUDED.is_granted;
END $$;
