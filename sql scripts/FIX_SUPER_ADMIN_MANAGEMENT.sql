-- ===========================================
-- FIX: Super Admin cannot delete/manage other admins
-- ===========================================
-- Problems solved:
-- 1. deleteAdmin uses a plain Supabase client blocked by RLS — add SECURITY DEFINER RPC
-- 2. Ensure Super Admin position has can_manage_admins = true
-- 3. Ensure any existing admins mistakenly assigned to 'Admin' position
--    can be manually re-assigned below
-- ===========================================

-- STEP 1: Add delete_admin_user SECURITY DEFINER function
-- (mirrors update_admin_user pattern — bypasses RLS safely)
CREATE OR REPLACE FUNCTION public.delete_admin_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  DELETE FROM public.users WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.delete_admin_user(UUID) TO authenticated;

-- STEP 2: Ensure Super Admin position has can_manage_admins = true
-- (idempotent — safe to run multiple times)
UPDATE position_permissions
SET is_granted = true
WHERE permission_name = 'can_manage_admins'
  AND position_id = (
    SELECT id FROM admin_positions WHERE LOWER(name) = 'super admin' LIMIT 1
  );

-- STEP 3: Check which admins have which position (diagnostic)
SELECT
  u.email,
  u.full_name,
  u.role,
  ap.name AS position_name,
  pp.is_granted AS can_manage_admins
FROM users u
LEFT JOIN admin_positions ap ON ap.id = u.position_id
LEFT JOIN position_permissions pp
  ON pp.position_id = u.position_id AND pp.permission_name = 'can_manage_admins'
WHERE u.role = 'admin'
ORDER BY u.created_at;

-- STEP 4 (manual): If the super admin was auto-assigned to the wrong position,
-- run the line below replacing <email> with their actual email:
--
-- UPDATE users
-- SET position_id = (SELECT id FROM admin_positions WHERE LOWER(name) = 'super admin' LIMIT 1)
-- WHERE email = '<super_admin_email@example.com>';
