-- Fix RLS policies for tool_issues table to allow technicians to create issues
-- Run this in your Supabase SQL Editor

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage all tool issues" ON tool_issues;
DROP POLICY IF EXISTS "Technicians can view and create tool issues" ON tool_issues;
DROP POLICY IF EXISTS "Technicians can view tool issues" ON tool_issues;
DROP POLICY IF EXISTS "Technicians can create tool issues" ON tool_issues;
DROP POLICY IF EXISTS "Technicians can update own issues" ON tool_issues;

-- Create updated policies
-- Admins can do everything
CREATE POLICY "Admins can manage all tool issues" ON tool_issues
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Technicians can view all issues (allow any authenticated user)
CREATE POLICY "Technicians can view tool issues" ON tool_issues
  FOR SELECT USING (
    -- Allow if user is admin
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
    OR
    -- Allow any authenticated user to view issues
    auth.uid() IS NOT NULL
  );

-- Technicians can create issues (allow any authenticated user)
CREATE POLICY "Technicians can create tool issues" ON tool_issues
  FOR INSERT WITH CHECK (
    -- Allow if user is admin
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
    OR
    -- Allow any authenticated user to create issues
    -- (Since they're logged in, they're either admin or technician)
    auth.uid() IS NOT NULL
  );

-- Note: UPDATE policy removed to avoid type casting issues
-- Admins can update through the "Admins can manage all tool issues" policy above
-- If you need technicians to update their own issues, add the column first and fix types

