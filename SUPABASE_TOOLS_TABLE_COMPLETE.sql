-- COMPLETE: Recreate tools table after database restore
-- Run this in your Supabase SQL Editor

-- First, drop the existing table if it exists (to recreate with correct structure)
DROP TABLE IF EXISTS tools CASCADE;

-- Create tools table for tool management
CREATE TABLE IF NOT EXISTS tools (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  brand TEXT,
  model TEXT,
  serial_number TEXT UNIQUE,
  purchase_date DATE,
  purchase_price DECIMAL(10,2),
  current_value DECIMAL(10,2),
  condition TEXT CHECK(condition IN ('Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair')) DEFAULT 'Good',
  location TEXT,
  assigned_to TEXT,
  status TEXT CHECK(status IN ('Available', 'In Use', 'Maintenance', 'Retired', 'Assigned')) DEFAULT 'Available',
  tool_type TEXT CHECK(tool_type IN ('inventory', 'shared', 'assigned')) DEFAULT 'inventory',
  image_path TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tools_category ON tools(category);
CREATE INDEX IF NOT EXISTS idx_tools_status ON tools(status);
CREATE INDEX IF NOT EXISTS idx_tools_serial_number ON tools(serial_number);
CREATE INDEX IF NOT EXISTS idx_tools_tool_type ON tools(tool_type);
CREATE INDEX IF NOT EXISTS idx_tools_assigned_to ON tools(assigned_to);

-- Enable Row Level Security (RLS)
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

-- Create policies for tools table
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage all tools" ON tools;
DROP POLICY IF EXISTS "Technicians can view all tools" ON tools;

-- Allow both admins and technicians to manage tools
CREATE POLICY "Admins and technicians can manage all tools" ON tools
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_tools_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_tools_updated_at 
  BEFORE UPDATE ON tools 
  FOR EACH ROW 
  EXECUTE FUNCTION update_tools_updated_at();

-- Create assignments table for tool assignments
CREATE TABLE IF NOT EXISTS assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tool_id UUID REFERENCES tools(id) ON DELETE CASCADE,
  technician_id UUID REFERENCES technicians(id) ON DELETE CASCADE,
  assignment_type TEXT CHECK(assignment_type IN ('permanent', 'temporary')) NOT NULL,
  status TEXT CHECK(status IN ('Active', 'Returned', 'Cancelled')) DEFAULT 'Active',
  assigned_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expected_return_date TIMESTAMP WITH TIME ZONE,
  actual_return_date TIMESTAMP WITH TIME ZONE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for assignments
CREATE INDEX IF NOT EXISTS idx_assignments_tool_id ON assignments(tool_id);
CREATE INDEX IF NOT EXISTS idx_assignments_technician_id ON assignments(technician_id);
CREATE INDEX IF NOT EXISTS idx_assignments_status ON assignments(status);

-- Enable RLS for assignments
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;

-- Create policy for assignments
CREATE POLICY "Admins and technicians can manage assignments" ON assignments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- Create trigger for assignments updated_at
CREATE TRIGGER update_assignments_updated_at 
  BEFORE UPDATE ON assignments 
  FOR EACH ROW 
  EXECUTE FUNCTION update_tools_updated_at();

