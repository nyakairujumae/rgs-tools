-- Create approval_workflows table for tool assignments, purchases, etc.
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_approval_workflows_status ON approval_workflows(status);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_request_type ON approval_workflows(request_type);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_requester_id ON approval_workflows(requester_id);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_assigned_to ON approval_workflows(assigned_to);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_due_date ON approval_workflows(due_date);

-- Enable RLS
ALTER TABLE approval_workflows ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Admins can view all approval workflows
CREATE POLICY "Admins can view all approval workflows" ON approval_workflows
  FOR SELECT USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin'));

-- Admins can update approval workflows
CREATE POLICY "Admins can update approval workflows" ON approval_workflows
  FOR UPDATE USING (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin'));

-- Admins can insert approval workflows
CREATE POLICY "Admins can insert approval workflows" ON approval_workflows
  FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'admin'));

-- Technicians can view their own approval workflows
CREATE POLICY "Technicians can view their own approval workflows" ON approval_workflows
  FOR SELECT USING (auth.uid() = requester_id);

-- Technicians can insert their own approval workflows
CREATE POLICY "Technicians can insert their own approval workflows" ON approval_workflows
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

-- Function to approve an approval workflow
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to reject an approval workflow
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert some sample data
INSERT INTO approval_workflows (
  request_type, title, description, requester_id, requester_name, requester_role,
  status, priority, due_date, assigned_to_role, location, request_data
) VALUES 
(
  'Tool Assignment',
  'Assign Digital Multimeter to Ahmed Hassan',
  'Request to assign Digital Multimeter (Serial: FL123456) to Ahmed Hassan for Site A project',
  (SELECT id FROM auth.users WHERE email = 'admin@royalgulf.ae' LIMIT 1),
  'Ahmed Hassan',
  'Technician',
  'Pending',
  'Medium',
  NOW() + INTERVAL '3 days',
  'Manager',
  'Site A - Downtown',
  '{"tool_id": 1, "tool_name": "Digital Multimeter", "technician_id": 1, "technician_name": "Ahmed Hassan", "project": "Site A HVAC Installation"}'
),
(
  'Tool Purchase',
  'Purchase New Refrigerant Manifold Gauge Set',
  'Request to purchase 5 new Yellow Jacket manifold gauge sets for upcoming projects',
  (SELECT id FROM auth.users WHERE email = 'admin@royalgulf.ae' LIMIT 1),
  'Mohammed Ali',
  'Supervisor',
  'Approved',
  'High',
  NOW() - INTERVAL '1 day',
  'Manager',
  'Main Office',
  '{"tool_name": "Yellow Jacket Manifold Gauge Set", "quantity": 5, "unit_price": 150.0, "total_cost": 750.0, "supplier": "HVAC Supplies Dubai"}'
);

-- Update trigger for updated_at
CREATE OR REPLACE FUNCTION update_approval_workflows_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_approval_workflows_updated_at
  BEFORE UPDATE ON approval_workflows
  FOR EACH ROW
  EXECUTE FUNCTION update_approval_workflows_updated_at();
