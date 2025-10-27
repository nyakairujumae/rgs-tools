-- Update PENDING_USER_APPROVALS.sql to handle existing policies
-- Run this in your Supabase SQL Editor

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Admins can view all pending approvals" ON pending_user_approvals;
DROP POLICY IF EXISTS "Admins can update pending approvals" ON pending_user_approvals;
DROP POLICY IF EXISTS "Technicians can view their own pending approval" ON pending_user_approvals;
DROP POLICY IF EXISTS "Allow inserts for authenticated users" ON pending_user_approvals;

-- Recreate the policies
CREATE POLICY "Admins can view all pending approvals" ON pending_user_approvals
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admins can update pending approvals" ON pending_user_approvals
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Technicians can view their own pending approval" ON pending_user_approvals
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Allow inserts for authenticated users" ON pending_user_approvals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Update the approve_pending_user function to handle role transitions properly
CREATE OR REPLACE FUNCTION approve_pending_user(approval_id UUID, reviewer_id UUID)
RETURNS VOID AS $$
DECLARE
    approval_record RECORD;
BEGIN
    -- Get the approval record
    SELECT * INTO approval_record 
    FROM pending_user_approvals 
    WHERE id = approval_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pending approval not found or already processed';
    END IF;
    
    -- Update the approval status
    UPDATE pending_user_approvals 
    SET 
        status = 'approved',
        reviewed_at = NOW(),
        reviewed_by = reviewer_id
    WHERE id = approval_id;
    
    -- Update the user's role to technician in the users table
    INSERT INTO users (id, email, full_name, role, created_at)
    VALUES (
        approval_record.user_id,
        approval_record.email,
        approval_record.full_name,
        'technician',
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        role = 'technician',
        updated_at = NOW();
    
    -- Update the auth.users metadata to change role from 'pending' to 'technician'
    UPDATE auth.users 
    SET raw_user_meta_data = raw_user_meta_data || '{"role": "technician"}'::jsonb
    WHERE id = approval_record.user_id;
    
    -- Create technician record
    INSERT INTO technicians (id, name, email, employee_id, phone, department, hire_date, status, created_at)
    VALUES (
        approval_record.user_id,
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
        name = EXCLUDED.name,
        email = EXCLUDED.email,
        employee_id = COALESCE(EXCLUDED.employee_id, technicians.employee_id),
        phone = COALESCE(EXCLUDED.phone, technicians.phone),
        department = COALESCE(EXCLUDED.department, technicians.department),
        hire_date = COALESCE(EXCLUDED.hire_date, technicians.hire_date),
        status = 'Active',
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the reject_pending_user function
CREATE OR REPLACE FUNCTION reject_pending_user(approval_id UUID, reason TEXT, reviewer_id UUID)
RETURNS VOID AS $$
DECLARE
    approval_record RECORD;
    rejection_count INTEGER;
BEGIN
    -- Get the approval record and increment rejection count
    UPDATE pending_user_approvals 
    SET 
        status = 'rejected',
        rejection_reason = reason,
        rejection_count = rejection_count + 1,
        reviewed_at = NOW(),
        reviewed_by = reviewer_id
    WHERE id = approval_id AND status = 'pending'
    RETURNING * INTO approval_record;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pending approval not found or already processed';
    END IF;
    
    -- Get the updated rejection count
    SELECT rejection_count INTO rejection_count 
    FROM pending_user_approvals 
    WHERE id = approval_id;
    
    -- Implement "three strikes" rule
    IF rejection_count >= 3 THEN
        -- Delete the user from auth.users (which cascades to public.users and public.technicians)
        DELETE FROM auth.users WHERE id = approval_record.user_id;
        RAISE NOTICE 'User % deleted due to three rejections.', approval_record.user_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
