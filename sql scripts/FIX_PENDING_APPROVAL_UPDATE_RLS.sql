-- Allow users to update their own pending approval (e.g. add phone, department after signup).
-- Without this, only admins could update pending_user_approvals, so technician registration
-- never saved phone/department before admin approval.
-- Run this in Supabase SQL Editor.

CREATE POLICY "Users can update own pending approval" ON pending_user_approvals
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
