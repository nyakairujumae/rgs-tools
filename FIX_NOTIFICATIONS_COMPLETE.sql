-- Complete fix for notifications: Create technician_notifications table and fix admin_notifications RLS
-- Run this in your Supabase SQL Editor

-- ============================================================================
-- PART 1: Create technician_notifications table
-- ============================================================================

CREATE TABLE IF NOT EXISTS technician_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('tool_request', 'account_approved', 'tool_assigned', 'tool_returned', 'general')),
  is_read BOOLEAN DEFAULT FALSE,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_technician_notifications_user_id ON technician_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_technician_notifications_type ON technician_notifications(type);
CREATE INDEX IF NOT EXISTS idx_technician_notifications_is_read ON technician_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_technician_notifications_timestamp ON technician_notifications(timestamp DESC);

-- Enable Row Level Security
ALTER TABLE technician_notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Technicians can view own notifications" ON technician_notifications;
DROP POLICY IF EXISTS "Technicians can update own notifications" ON technician_notifications;
DROP POLICY IF EXISTS "Allow authenticated users to create technician notifications" ON technician_notifications;
DROP POLICY IF EXISTS "Admins can view all technician notifications" ON technician_notifications;

-- Technicians can view their own notifications
CREATE POLICY "Technicians can view own notifications" ON technician_notifications
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Technicians can update their own notifications (mark as read, etc.)
CREATE POLICY "Technicians can update own notifications" ON technician_notifications
  FOR UPDATE USING (user_id = auth.uid());

-- Allow authenticated users (admins and technicians) to create notifications
CREATE POLICY "Allow authenticated users to create technician notifications" ON technician_notifications
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- Admins can view all technician notifications
CREATE POLICY "Admins can view all technician notifications" ON technician_notifications
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'admin'
    )
  );

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_technician_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS on_technician_notifications_updated ON technician_notifications;
CREATE TRIGGER on_technician_notifications_updated
  BEFORE UPDATE ON technician_notifications
  FOR EACH ROW EXECUTE FUNCTION public.handle_technician_notifications_updated_at();

-- ============================================================================
-- PART 2: Fix admin_notifications RLS policy
-- ============================================================================

-- Drop the existing insert policy if it exists
DROP POLICY IF EXISTS "Allow system to insert notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Allow authenticated users to insert notifications" ON admin_notifications;

-- Create a new policy that allows both admins and technicians to insert notifications
-- Technicians need to be able to create notifications for tool requests, issue reports, etc.
CREATE POLICY "Allow authenticated users to insert notifications" ON admin_notifications
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role IN ('admin', 'technician')
    )
  );

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify the policies were created
SELECT 'admin_notifications policies:' as info;
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'admin_notifications' AND schemaname = 'public';

SELECT 'technician_notifications policies:' as info;
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'technician_notifications' AND schemaname = 'public';

-- Verify tables exist
SELECT 'Tables created:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('admin_notifications', 'technician_notifications');

