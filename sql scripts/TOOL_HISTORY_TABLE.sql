-- Tool History Table - v1
-- Tracks tool movements: badge, release, transfer, assign, maintenance, etc.
-- Run this in your Supabase SQL Editor.

CREATE TABLE IF NOT EXISTS tool_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
  tool_name TEXT NOT NULL,
  action TEXT NOT NULL,
  description TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  performed_by TEXT,
  performed_by_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  performed_by_role TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  location TEXT,
  notes TEXT,
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_tool_history_tool_id ON tool_history(tool_id);
CREATE INDEX IF NOT EXISTS idx_tool_history_timestamp ON tool_history(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_tool_history_action ON tool_history(action);

ALTER TABLE tool_history ENABLE ROW LEVEL SECURITY;

-- Admins and technicians can read history (both roles perform and view movements)
CREATE POLICY "Admins and technicians can read tool history" ON tool_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'technician')
    )
  );

-- Admins and technicians can insert history (recorded when they perform actions)
CREATE POLICY "Admins and technicians can insert tool history" ON tool_history
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('admin', 'technician')
    )
  );

SELECT '✅ tool_history table created. Run TOOL_HISTORY_TABLE.sql if not already run.' as status;
