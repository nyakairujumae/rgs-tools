-- =============================================================
-- Tool Issue Lifecycle — Migration
-- =============================================================
-- Run once in the Supabase SQL editor.
-- Adds lifecycle columns to tool_issues and creates the
-- tool_issue_actions audit table.
-- =============================================================

-- 1. Add lifecycle columns to tool_issues
ALTER TABLE tool_issues
  ADD COLUMN IF NOT EXISTS seen_at         TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS seen_by         TEXT,
  ADD COLUMN IF NOT EXISTS resolution_type TEXT,        -- 'Repaired' | 'Replaced' | 'No Action'
  ADD COLUMN IF NOT EXISTS actioned_by_name TEXT;

-- 2. Create the audit / activity-log table
CREATE TABLE IF NOT EXISTS tool_issue_actions (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  issue_id         UUID        NOT NULL REFERENCES tool_issues(id) ON DELETE CASCADE,
  action           TEXT        NOT NULL,   -- 'seen' | 'in_review' | 'repaired' | 'replaced' | 'no_action'
  performed_by_id   UUID,
  performed_by_name TEXT,
  message_to_tech  TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3. Enable RLS on the new table
ALTER TABLE tool_issue_actions ENABLE ROW LEVEL SECURITY;

-- Admins: full access
CREATE POLICY "admins_all_issue_actions" ON tool_issue_actions
  FOR ALL TO authenticated
  USING  (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

-- Technicians: read only for issues they reported
CREATE POLICY "techs_read_own_issue_actions" ON tool_issue_actions
  FOR SELECT TO authenticated
  USING (
    issue_id IN (
      SELECT id FROM tool_issues WHERE reported_by_user_id = auth.uid()
    )
  );

-- =============================================================
-- To verify:
-- SELECT column_name FROM information_schema.columns
--   WHERE table_name = 'tool_issues' AND column_name IN ('seen_at','seen_by','resolution_type','actioned_by_name');
-- SELECT * FROM tool_issue_actions LIMIT 5;
-- =============================================================
