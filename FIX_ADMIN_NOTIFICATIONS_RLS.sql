-- Fix RLS policies for admin_notifications to allow technicians to create notifications
-- Run this in your Supabase SQL Editor
-- 
-- NOTE: This script only fixes admin_notifications. 
-- For a complete fix including technician_notifications table creation, 
-- use FIX_NOTIFICATIONS_COMPLETE.sql instead.

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

-- Verify the policy was created
SELECT 'admin_notifications policies:' as info;
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'admin_notifications' AND schemaname = 'public';

