-- Create tool_issues table for tracking tool problems and issues
CREATE TABLE IF NOT EXISTS tool_issues (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
  tool_name TEXT NOT NULL,
  reported_by TEXT NOT NULL,
  issue_type TEXT NOT NULL CHECK (issue_type IN ('Faulty', 'Lost', 'Damaged', 'Missing Parts', 'Other')),
  description TEXT NOT NULL,
  priority TEXT NOT NULL CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
  status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
  assigned_to TEXT,
  resolution TEXT,
  reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  attachments TEXT[],
  location TEXT,
  estimated_cost DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tool_issues_tool_id ON tool_issues(tool_id);
CREATE INDEX IF NOT EXISTS idx_tool_issues_status ON tool_issues(status);
CREATE INDEX IF NOT EXISTS idx_tool_issues_priority ON tool_issues(priority);
CREATE INDEX IF NOT EXISTS idx_tool_issues_reported_at ON tool_issues(reported_at);
CREATE INDEX IF NOT EXISTS idx_tool_issues_reported_by ON tool_issues(reported_by);

-- Enable Row Level Security
ALTER TABLE tool_issues ENABLE ROW LEVEL SECURITY;

-- Create policies for tool_issues table
-- Admins can do everything
CREATE POLICY "Admins can manage all tool issues" ON tool_issues
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Technicians can view and create issues
CREATE POLICY "Technicians can view and create tool issues" ON tool_issues
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'technician'
    )
  );

CREATE POLICY "Technicians can create tool issues" ON tool_issues
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'technician'
    )
  );

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_tool_issues_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_tool_issues_updated_at
  BEFORE UPDATE ON tool_issues
  FOR EACH ROW
  EXECUTE FUNCTION update_tool_issues_updated_at();

-- Create a view for issue statistics
CREATE OR REPLACE VIEW tool_issue_stats AS
SELECT 
  COUNT(*) as total_issues,
  COUNT(*) FILTER (WHERE status = 'Open') as open_issues,
  COUNT(*) FILTER (WHERE status = 'In Progress') as in_progress_issues,
  COUNT(*) FILTER (WHERE status = 'Resolved') as resolved_issues,
  COUNT(*) FILTER (WHERE status = 'Closed') as closed_issues,
  COUNT(*) FILTER (WHERE priority = 'Critical') as critical_issues,
  COUNT(*) FILTER (WHERE priority = 'High') as high_priority_issues,
  COUNT(*) FILTER (WHERE issue_type = 'Faulty') as faulty_tools,
  COUNT(*) FILTER (WHERE issue_type = 'Lost') as lost_tools,
  COUNT(*) FILTER (WHERE issue_type = 'Damaged') as damaged_tools,
  ROUND(
    (COUNT(*) FILTER (WHERE status IN ('Resolved', 'Closed'))::DECIMAL / 
     NULLIF(COUNT(*), 0)) * 100, 2
  ) as resolution_rate,
  AVG(
    CASE 
      WHEN resolved_at IS NOT NULL 
      THEN EXTRACT(EPOCH FROM (resolved_at - reported_at)) / 86400 
      ELSE NULL 
    END
  ) as avg_resolution_days
FROM tool_issues;

