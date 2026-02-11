-- SIMPLE FIX: Allow technicians to insert into admin_notifications
-- Run this in your Supabase SQL Editor - that's it!

-- Remove any existing INSERT policies
DROP POLICY IF EXISTS "Allow system to insert notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Allow authenticated users to insert notifications" ON admin_notifications;

-- Allow ANY authenticated user to insert notifications
CREATE POLICY "Allow authenticated users to insert notifications" ON admin_notifications
  FOR INSERT 
  WITH CHECK (auth.uid() IS NOT NULL);

