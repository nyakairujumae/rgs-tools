-- Fix User Role Persistence Issues
-- Run this script to ensure user roles are properly maintained

-- 1. Check current user roles in the database
SELECT 'Current user roles:' as info;
SELECT id, email, role, created_at, updated_at 
FROM public.users 
ORDER BY created_at DESC;

-- 2. Create a function to safely update user roles
CREATE OR REPLACE FUNCTION public.safe_update_user_role(
  user_id UUID,
  new_role TEXT
)
RETURNS JSON AS $$
DECLARE
  user_exists BOOLEAN;
  current_role TEXT;
  result JSON;
BEGIN
  -- Check if user exists
  SELECT EXISTS(
    SELECT 1 FROM public.users WHERE id = user_id
  ) INTO user_exists;
  
  IF NOT user_exists THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found',
      'user_id', user_id
    );
  END IF;
  
  -- Get current role
  SELECT role INTO current_role 
  FROM public.users 
  WHERE id = user_id;
  
  -- Update role if it's different
  IF current_role != new_role THEN
    UPDATE public.users 
    SET role = new_role, updated_at = NOW()
    WHERE id = user_id;
    
    result := json_build_object(
      'success', true,
      'user_id', user_id,
      'old_role', current_role,
      'new_role', new_role,
      'updated_at', NOW()
    );
  ELSE
    result := json_build_object(
      'success', true,
      'user_id', user_id,
      'role', current_role,
      'message', 'Role unchanged'
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create a function to get user role with fallback
CREATE OR REPLACE FUNCTION public.get_user_role_safe(user_id UUID)
RETURNS JSON AS $$
DECLARE
  user_role TEXT;
  user_email TEXT;
  result JSON;
BEGIN
  -- Get user role and email
  SELECT role, email INTO user_role, user_email
  FROM public.users 
  WHERE id = user_id;
  
  IF user_role IS NULL THEN
    -- If no role found, set default to technician
    UPDATE public.users 
    SET role = 'technician', updated_at = NOW()
    WHERE id = user_id;
    
    user_role := 'technician';
  END IF;
  
  result := json_build_object(
    'user_id', user_id,
    'email', user_email,
    'role', user_role,
    'retrieved_at', NOW()
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create a function to ensure all users have roles
CREATE OR REPLACE FUNCTION public.ensure_all_users_have_roles()
RETURNS JSON AS $$
DECLARE
  updated_count INTEGER := 0;
  result JSON;
BEGIN
  -- Update users without roles
  UPDATE public.users 
  SET role = 'technician', updated_at = NOW()
  WHERE role IS NULL OR role = '';
  
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  
  result := json_build_object(
    'updated_users', updated_count,
    'message', 'All users now have roles assigned',
    'timestamp', NOW()
  );
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create a function to backup user roles
CREATE OR REPLACE FUNCTION public.backup_user_roles()
RETURNS JSON AS $$
DECLARE
  backup_data JSON;
BEGIN
  -- Create a backup of current user roles
  SELECT json_agg(
    json_build_object(
      'user_id', id,
      'email', email,
      'role', role,
      'backed_up_at', NOW()
    )
  ) INTO backup_data
  FROM public.users;
  
  RETURN json_build_object(
    'backup_created', true,
    'user_count', json_array_length(backup_data),
    'backup_data', backup_data,
    'created_at', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Grant permissions
GRANT EXECUTE ON FUNCTION public.safe_update_user_role(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_role_safe(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_all_users_have_roles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.backup_user_roles() TO authenticated;

-- 7. Ensure all users have roles
SELECT 'Ensuring all users have roles...' as status;
SELECT public.ensure_all_users_have_roles();

-- 8. Create backup of current roles
SELECT 'Creating role backup...' as status;
SELECT public.backup_user_roles();

-- 9. Test the safe role functions
SELECT 'Testing role functions...' as status;

-- Test getting a user role safely
DO $$
DECLARE
  test_user_id UUID;
  role_result JSON;
BEGIN
  -- Get a test user ID
  SELECT id INTO test_user_id FROM public.users LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    SELECT public.get_user_role_safe(test_user_id) INTO role_result;
    RAISE NOTICE 'Test role retrieval: %', role_result;
  END IF;
END;
$$;

-- 10. Show final user roles
SELECT 'Final user roles after fixes:' as info;
SELECT id, email, role, created_at, updated_at 
FROM public.users 
ORDER BY created_at DESC;

-- 11. Create an index for better role queries
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- 12. Final status
SELECT '✅ User role persistence fixes complete!' as result;
SELECT 'All users now have proper roles assigned' as message;
SELECT 'Role changes will be properly persisted' as note;
