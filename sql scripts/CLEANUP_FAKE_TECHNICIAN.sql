-- Clean up fake technician and fix technician registration
-- Run this in your Supabase SQL Editor

-- 1. Remove any fake/test technicians from the technicians table
DELETE FROM technicians WHERE name ILIKE '%fake%' OR name ILIKE '%test%' OR name ILIKE '%demo%';

-- 2. Check what technicians currently exist
SELECT id, name, email, status, created_at FROM technicians ORDER BY created_at DESC;

-- 3. Check what users exist in the users table
SELECT id, email, full_name, role, created_at FROM users ORDER BY created_at DESC;

-- 4. Create a function to sync technician data from users table to technicians table
CREATE OR REPLACE FUNCTION sync_technician_from_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process technician role users
  IF NEW.role = 'technician' THEN
    -- Insert or update technician record
    INSERT INTO technicians (
      id,
      name,
      email,
      status,
      created_at
    ) VALUES (
      NEW.id,
      NEW.full_name,
      NEW.email,
      'Active',
      NEW.created_at
    )
    ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      email = EXCLUDED.email,
      status = EXCLUDED.status,
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create trigger to automatically sync technician data
DROP TRIGGER IF EXISTS sync_technician_on_user_insert ON users;
CREATE TRIGGER sync_technician_on_user_insert
  AFTER INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION sync_technician_from_user();

DROP TRIGGER IF EXISTS sync_technician_on_user_update ON users;
CREATE TRIGGER sync_technician_on_user_update
  AFTER UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION sync_technician_from_user();

-- 6. Sync existing technician users to technicians table
INSERT INTO technicians (
  id,
  name,
  email,
  status,
  created_at
)
SELECT 
  id,
  full_name,
  email,
  'Active',
  created_at
FROM users 
WHERE role = 'technician'
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  email = EXCLUDED.email,
  status = EXCLUDED.status,
  updated_at = NOW();

-- 7. Verify the sync worked
SELECT 'After sync - Technicians:' as info;
SELECT id, name, email, status, created_at FROM technicians ORDER BY created_at DESC;

SELECT 'After sync - Users:' as info;
SELECT id, email, full_name, role, created_at FROM users ORDER BY created_at DESC;
