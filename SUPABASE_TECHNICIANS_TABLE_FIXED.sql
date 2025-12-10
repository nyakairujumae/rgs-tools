-- FIXED: Create technicians table with proper RLS policies
-- Run this in your Supabase SQL Editor

-- First, drop the existing table if it exists (to recreate with correct policies)
DROP TABLE IF EXISTS technicians CASCADE;

-- Create technicians table for technician management
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

-- FIXED: Create policies that allow both admins AND technicians to manage technicians
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage all technicians" ON technicians;
DROP POLICY IF EXISTS "Technicians can view all technicians" ON technicians;

-- Allow both admins and technicians to do everything with technicians
CREATE POLICY "Admins and technicians can manage all technicians" ON technicians
  FOR ALL USING (
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

