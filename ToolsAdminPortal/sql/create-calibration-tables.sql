-- ============================================
-- Create certifications and maintenance_schedules tables
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================

-- 1. Create certifications table
CREATE TABLE IF NOT EXISTS certifications (
  id SERIAL PRIMARY KEY,
  tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
  tool_name TEXT NOT NULL,
  certification_type TEXT NOT NULL,
  certification_number TEXT NOT NULL,
  issuing_authority TEXT NOT NULL,
  issue_date TEXT NOT NULL,
  expiry_date TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Valid',
  notes TEXT,
  document_path TEXT,
  inspector_name TEXT,
  inspector_id TEXT,
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create maintenance_schedules table
CREATE TABLE IF NOT EXISTS maintenance_schedules (
  id SERIAL PRIMARY KEY,
  tool_id UUID NOT NULL REFERENCES tools(id) ON DELETE CASCADE,
  tool_name TEXT NOT NULL,
  maintenance_type TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  scheduled_date TEXT NOT NULL,
  completed_date TEXT,
  status TEXT NOT NULL DEFAULT 'Scheduled',
  priority TEXT NOT NULL DEFAULT 'Medium',
  assigned_to TEXT,
  notes TEXT,
  estimated_cost NUMERIC,
  actual_cost NUMERIC,
  parts_used TEXT,
  next_maintenance_date TEXT,
  interval_days INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Enable RLS on both tables
ALTER TABLE certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_schedules ENABLE ROW LEVEL SECURITY;

-- 4. RLS policies for certifications
CREATE POLICY "Allow authenticated select on certifications"
  ON certifications FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated insert on certifications"
  ON certifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated update on certifications"
  ON certifications FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated delete on certifications"
  ON certifications FOR DELETE
  TO authenticated
  USING (true);

-- 5. RLS policies for maintenance_schedules
CREATE POLICY "Allow authenticated select on maintenance_schedules"
  ON maintenance_schedules FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow authenticated insert on maintenance_schedules"
  ON maintenance_schedules FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated update on maintenance_schedules"
  ON maintenance_schedules FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow authenticated delete on maintenance_schedules"
  ON maintenance_schedules FOR DELETE
  TO authenticated
  USING (true);

-- 6. Enable Realtime on both tables
ALTER PUBLICATION supabase_realtime ADD TABLE certifications;
ALTER PUBLICATION supabase_realtime ADD TABLE maintenance_schedules;
