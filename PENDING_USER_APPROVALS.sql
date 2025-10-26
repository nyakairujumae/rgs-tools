-- Create pending user approvals table
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS pending_user_approvals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
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

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_pending_approvals_status ON pending_user_approvals(status);
CREATE INDEX IF NOT EXISTS idx_pending_approvals_email ON pending_user_approvals(email);
CREATE INDEX IF NOT EXISTS idx_pending_approvals_submitted_at ON pending_user_approvals(submitted_at);

-- Enable Row Level Security (RLS)
ALTER TABLE pending_user_approvals ENABLE ROW LEVEL SECURITY;

-- Create policies for pending approvals table
-- Admins can view all pending approvals
CREATE POLICY "Admins can view all pending approvals" ON pending_user_approvals
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Admins can update pending approvals
CREATE POLICY "Admins can update pending approvals" ON pending_user_approvals
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Users can insert their own pending approval
CREATE POLICY "Users can insert own pending approval" ON pending_user_approvals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can view their own pending approval
CREATE POLICY "Users can view own pending approval" ON pending_user_approvals
  FOR SELECT USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_pending_approvals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_pending_approvals_updated_at 
  BEFORE UPDATE ON pending_user_approvals 
  FOR EACH ROW 
  EXECUTE FUNCTION update_pending_approvals_updated_at();

-- Create function to handle approval
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
        name = approval_record.full_name,
        email = approval_record.email,
        employee_id = approval_record.employee_id,
        phone = approval_record.phone,
        department = approval_record.department,
        hire_date = approval_record.hire_date,
        status = 'Active';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle rejection
CREATE OR REPLACE FUNCTION reject_pending_user(approval_id UUID, reviewer_id UUID, reason TEXT)
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
        status = 'rejected',
        rejection_reason = reason,
        rejection_count = rejection_count + 1,
        reviewed_at = NOW(),
        reviewed_by = reviewer_id
    WHERE id = approval_id;
    
    -- If this is the third rejection, delete the auth user
    IF approval_record.rejection_count + 1 >= 3 THEN
        DELETE FROM auth.users WHERE id = approval_record.user_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
