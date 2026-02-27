-- Admin user management RPCs (bypass RLS safely)

CREATE OR REPLACE FUNCTION public.assign_admin_position(
  p_user_id UUID,
  p_position_id UUID,
  p_status TEXT DEFAULT 'Active'
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.users
  SET position_id = p_position_id,
      status = COALESCE(p_status, status),
      updated_at = NOW()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.update_admin_user(
  p_user_id UUID,
  p_full_name TEXT,
  p_status TEXT,
  p_position_id UUID
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.users
  SET full_name = p_full_name,
      status = p_status,
      position_id = p_position_id,
      updated_at = NOW()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.assign_admin_position(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_admin_user(UUID, TEXT, TEXT, UUID) TO authenticated;
