-- Create technicians table for technician management
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS technicians (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  employee_id TEXT UNIQUE,
  phone TEXT,
  email TEXT,
  department TEXT,
  hire_date DATE,
  status TEXT CHECK(status IN ('Active', 'Inactive')) DEFAULT 'Active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_technicians_status ON technicians(status);
CREATE INDEX IF NOT EXISTS idx_technicians_employee_id ON technicians(employee_id);
CREATE INDEX IF NOT EXISTS idx_technicians_department ON technicians(department);

-- Enable Row Level Security (RLS)
ALTER TABLE technicians ENABLE ROW LEVEL SECURITY;

-- Create policies for technicians table
-- Admins can do everything with technicians
CREATE POLICY "Admins can manage all technicians" ON technicians
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Technicians can view all technicians
CREATE POLICY "Technicians can view all technicians" ON technicians
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_technicians_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_technicians_updated_at 
  BEFORE UPDATE ON technicians 
  FOR EACH ROW 
  EXECUTE FUNCTION update_technicians_updated_at();

