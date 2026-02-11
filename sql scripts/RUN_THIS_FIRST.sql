-- ============================================================================
-- COMPLETE APPROVAL WORKFLOWS SETUP - Run this in Supabase SQL Editor
-- ============================================================================
-- Copy and paste this ENTIRE file into Supabase SQL Editor and run it
-- Do NOT copy line by line - copy the entire file

-- Step 1: Create table if it doesn't exist
CREATE TABLE IF NOT EXISTS approval_workflows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
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

-- Step 2: Create indexes
CREATE INDEX IF NOT EXISTS idx_approval_workflows_status ON approval_workflows(status);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_request_type ON approval_workflows(request_type);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_requester_id ON approval_workflows(requester_id);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_assigned_to ON approval_workflows(assigned_to);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_due_date ON approval_workflows(due_date);

-- Step 3: Enable RLS
ALTER TABLE approval_workflows ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop existing policies
DROP POLICY IF EXISTS "Admins can view all approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Admins can update approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Admins can insert approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Technicians can view their own approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Technicians can insert their own approval workflows" ON approval_workflows;
DROP POLICY IF EXISTS "Authenticated users can view all workflows" ON approval_workflows;

-- Step 5: Create RLS policies
CREATE POLICY "Authenticated users can view all workflows" ON approval_workflows
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can update approval workflows" ON approval_workflows
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
    OR
    (auth.jwt() ->> 'user_role') = 'admin'
  );

CREATE POLICY "Admins can insert approval workflows" ON approval_workflows
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
    OR
    (auth.jwt() ->> 'user_role') = 'admin'
  );

CREATE POLICY "Technicians can view their own approval workflows" ON approval_workflows
  FOR SELECT USING (auth.uid() = requester_id);

CREATE POLICY "Technicians can insert their own approval workflows" ON approval_workflows
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

-- Step 6: Create approve/reject functions
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
  WHERE id = workflow_id AND status = 'Pending';

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
  WHERE id = workflow_id AND status = 'Pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Approval workflow not found or already processed.';
  END IF;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Step 7: Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_approval_workflows_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

DROP TRIGGER IF EXISTS update_approval_workflows_updated_at ON approval_workflows;
CREATE TRIGGER update_approval_workflows_updated_at
  BEFORE UPDATE ON approval_workflows
  FOR EACH ROW
  EXECUTE FUNCTION update_approval_workflows_updated_at();

-- Step 8: Grant permissions
GRANT SELECT, INSERT, UPDATE ON approval_workflows TO authenticated;
GRANT SELECT ON approval_workflows TO anon;

-- Step 9: Create function to create approval workflows
CREATE OR REPLACE FUNCTION public.create_approval_workflow(
    p_request_type TEXT,
    p_title TEXT,
    p_description TEXT,
    p_requester_id UUID,
    p_requester_name TEXT,
    p_requester_role TEXT DEFAULT 'Technician',
    p_status TEXT DEFAULT 'Pending',
    p_priority TEXT DEFAULT 'Medium',
    p_location TEXT DEFAULT NULL,
    p_request_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO approval_workflows (
        request_type,
        title,
        description,
        requester_id,
        requester_name,
        requester_role,
        status,
        priority,
        request_date,
        location,
        request_data
    )
    VALUES (
        p_request_type,
        p_title,
        p_description,
        p_requester_id,
        p_requester_name,
        p_requester_role,
        p_status,
        p_priority,
        NOW(),
        p_location,
        p_request_data
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_approval_workflow TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_approval_workflow TO anon;

-- Step 10: Update create_admin_notification to auto-create workflows
CREATE OR REPLACE FUNCTION public.create_admin_notification(
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
    v_workflow_id UUID;
    v_requester_id UUID;
    v_tool_name TEXT;
    v_requester_name TEXT;
BEGIN
    INSERT INTO admin_notifications (
        title,
        message,
        technician_name,
        technician_email,
        type,
        is_read,
        timestamp,
        data
    )
    VALUES (
        p_title,
        p_message,
        p_technician_name,
        p_technician_email,
        p_type,
        false,
        NOW(),
        p_data
    )
    RETURNING id INTO v_notification_id;
    
    IF p_type = 'tool_request' AND p_data IS NOT NULL THEN
        v_requester_id := (p_data->>'requester_id')::UUID;
        v_tool_name := COALESCE(p_data->>'tool_name', 'Unknown Tool');
        v_requester_name := COALESCE(p_data->>'requester_name', p_technician_name);
        
        IF v_requester_id IS NOT NULL THEN
            BEGIN
                SELECT public.create_approval_workflow(
                    p_request_type := 'Tool Assignment',
                    p_title := 'Tool Assignment Request: ' || v_tool_name,
                    p_description := v_requester_name || ' requested the tool "' || v_tool_name || '"',
                    p_requester_id := v_requester_id,
                    p_requester_name := v_requester_name,
                    p_requester_role := 'Technician',
                    p_status := 'Pending',
                    p_priority := 'Medium',
                    p_location := p_data->>'location',
                    p_request_data := p_data
                ) INTO v_workflow_id;
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;
        END IF;
    END IF;
    
    RETURN v_notification_id;
END;
$$;

-- Success message
SELECT '✅ Approval workflows setup complete!' as status;


