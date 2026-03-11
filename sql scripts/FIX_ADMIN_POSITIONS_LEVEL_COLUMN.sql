-- FIX: Add missing 'level' column to admin_positions table
-- Run this in Supabase SQL editor if you get:
--   column "level" of relation "admin_positions" does not exist

ALTER TABLE admin_positions
  ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1;

-- Recreate seed_default_positions_for_org to use level values
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
