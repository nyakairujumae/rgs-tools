-- Setup Tool Issues Table for RGS HVAC Tools Management System
-- This script creates the tool_issues table and sets up proper permissions

-- Create tool_issues table for tracking tool problems and issues
CREATE TABLE IF NOT EXISTS public.tool_issues (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tool_id UUID NOT NULL REFERENCES public.tools(id) ON DELETE CASCADE,
  tool_name TEXT NOT NULL,
  reported_by TEXT NOT NULL, -- Technician name and ID
  reported_by_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Link to user account
  issue_type TEXT NOT NULL CHECK (issue_type IN ('Faulty', 'Lost', 'Damaged', 'Missing Parts', 'Other')),
  description TEXT NOT NULL,
  priority TEXT NOT NULL CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
  status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'In Progress', 'Resolved', 'Closed')),
  assigned_to TEXT,
  assigned_to_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Link to assigned user
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
CREATE INDEX IF NOT EXISTS idx_tool_issues_tool_id ON public.tool_issues(tool_id);
CREATE INDEX IF NOT EXISTS idx_tool_issues_status ON public.tool_issues(status);
CREATE INDEX IF NOT EXISTS idx_tool_issues_priority ON public.tool_issues(priority);
CREATE INDEX IF NOT EXISTS idx_tool_issues_reported_at ON public.tool_issues(reported_at);
CREATE INDEX IF NOT EXISTS idx_tool_issues_reported_by ON public.tool_issues(reported_by);
CREATE INDEX IF NOT EXISTS idx_tool_issues_reported_by_user_id ON public.tool_issues(reported_by_user_id);
CREATE INDEX IF NOT EXISTS idx_tool_issues_assigned_to_user_id ON public.tool_issues(assigned_to_user_id);
CREATE INDEX IF NOT EXISTS idx_tool_issues_issue_type ON public.tool_issues(issue_type);

-- Enable Row Level Security
ALTER TABLE public.tool_issues ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage all tool issues" ON public.tool_issues;
DROP POLICY IF EXISTS "Technicians can view and create tool issues" ON public.tool_issues;
DROP POLICY IF EXISTS "Technicians can create tool issues" ON public.tool_issues;

-- Create policies for tool_issues table
-- Admins can do everything
CREATE POLICY "Admins can manage all tool issues" ON public.tool_issues
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE public.users.id = auth.uid() 
      AND public.users.role = 'admin'
    )
  );

-- Technicians can view and create issues
CREATE POLICY "Technicians can view and create tool issues" ON public.tool_issues
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE public.users.id = auth.uid() 
      AND public.users.role = 'technician'
    )
  );

CREATE POLICY "Technicians can create tool issues" ON public.tool_issues
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE public.users.id = auth.uid() 
      AND public.users.role = 'technician'
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_tool_issues_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS on_tool_issues_updated ON public.tool_issues;
CREATE TRIGGER on_tool_issues_updated
  BEFORE UPDATE ON public.tool_issues
  FOR EACH ROW EXECUTE FUNCTION public.handle_tool_issues_updated_at();

-- Insert some sample data for testing (optional)
INSERT INTO public.tool_issues (
  tool_id,
  tool_name,
  reported_by,
  issue_type,
  description,
  priority,
  status,
  location
) VALUES (
  (SELECT id FROM public.tools LIMIT 1),
  'Sample Tool',
  'Test User',
  'Faulty',
  'Tool not working properly',
  'High',
  'Open',
  'Workshop'
) ON CONFLICT DO NOTHING;

-- Verify the table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tool_issues' 
AND table_schema = 'public'
ORDER BY ordinal_position;
