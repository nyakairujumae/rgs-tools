-- Disable unused admin positions so they won't appear in the admin invite list
UPDATE admin_positions
SET is_active = false, updated_at = NOW()
WHERE name IN (
  'Viewer',
  'IT/System Admin',
  'IT Admin',
  'Estimation/Quoting',
  'Safety Officer',
  'Customer Success/Contracts',
  'Controls Specialist',
  'QA/QC Manager',
  'Parts/Warehouse Lead',
  'Parts Lead'
);
