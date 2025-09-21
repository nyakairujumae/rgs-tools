-- Create tools table for tool management
-- Run this in your Supabase SQL Editor

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
  status TEXT CHECK(status IN ('Available', 'In Use', 'Maintenance', 'Retired')) DEFAULT 'Available',
  image_path TEXT,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_tools_category ON tools(category);
CREATE INDEX IF NOT EXISTS idx_tools_status ON tools(status);
CREATE INDEX IF NOT EXISTS idx_tools_serial_number ON tools(serial_number);

-- Enable Row Level Security (RLS)
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;

-- Create policies for tools table
-- Admins can do everything with tools
CREATE POLICY "Admins can manage all tools" ON tools
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Technicians can view all tools
CREATE POLICY "Technicians can view all tools" ON tools
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
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
  EXECUTE FUNCTION update_updated_at_column();
