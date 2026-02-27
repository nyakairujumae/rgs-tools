-- Improved RLS policy fix for admin_notifications
-- This version is more permissive and should work even if users table is missing records
-- Run this in your Supabase SQL Editor

-- Drop ALL existing insert policies
DROP POLICY IF EXISTS "Allow system to insert notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Allow authenticated users to insert notifications" ON admin_notifications;
DROP POLICY IF EXISTS "Technicians can insert notifications" ON admin_notifications;

-- Option 1: Allow any authenticated user to insert (most permissive)
-- This works even if the users table doesn't have a record for the user
CREATE POLICY "Allow authenticated users to insert notifications" ON admin_notifications
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Option 2: If you want to be more restrictive, use this instead (comment out Option 1 first):
-- This checks the users table but also allows if user is authenticated (fallback)
-- CREATE POLICY "Allow authenticated users to insert notifications" ON admin_notifications
--   FOR INSERT WITH CHECK (
--     auth.uid() IS NOT NULL AND (
--       -- User exists in users table with correct role
--       EXISTS (
--         SELECT 1 FROM users 
--         WHERE users.id = auth.uid() 
--         AND users.role IN ('admin', 'technician')
--       )
--       OR
--       -- Fallback: if users table doesn't have record, allow if authenticated
--       NOT EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid())
--     )
--   );

-- Verify the policy was created
SELECT 'admin_notifications insert policies:' as info;
SELECT policyname, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'admin_notifications' 
AND schemaname = 'public' 
AND cmd = 'INSERT';

-- Test query to check current user (run this while logged in as a technician)
-- SELECT auth.uid() as current_user_id, 
--        (SELECT role FROM users WHERE id = auth.uid()) as user_role,
--        (SELECT email FROM auth.users WHERE id = auth.uid()) as user_email;

