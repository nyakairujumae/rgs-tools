-- ============================================================
-- Tool Assignment Accept/Decline Feature Setup
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Allow admins to insert into technician_notifications
--    (so the assignment notification can be sent from the admin session)
DROP POLICY IF EXISTS "Admins can insert technician notifications" ON technician_notifications;
CREATE POLICY "Admins can insert technician notifications"
  ON technician_notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- 2. Allow technicians to update tools they are assigned to
--    (for accept: status Pending Acceptance -> Assigned)
--    (for decline: status Pending Acceptance -> Available, clear assigned_to)
DROP POLICY IF EXISTS "Technicians can accept or decline their own assignment" ON tools;
CREATE POLICY "Technicians can accept or decline their own assignment"
  ON tools
  FOR UPDATE
  TO authenticated
  USING (assigned_to = auth.uid())
  WITH CHECK (true);

-- 3. Index for faster pending assignment queries
CREATE INDEX IF NOT EXISTS idx_tools_pending_acceptance
  ON tools (assigned_to, status)
  WHERE status = 'Pending Acceptance';
