-- Fix jumae user's role to admin
-- Run this in your Supabase SQL editor

-- First, check current role
SELECT id, email, full_name, role, created_at 
FROM users 
WHERE email = 'jumae@example.com' OR full_name ILIKE '%jumae%';

-- Update jumae's role to admin
UPDATE users 
SET role = 'admin', updated_at = now()
WHERE email = 'jumae@example.com' OR full_name ILIKE '%jumae%';

-- Verify the change
SELECT id, email, full_name, role, updated_at 
FROM users 
WHERE email = 'jumae@example.com' OR full_name ILIKE '%jumae%';

-- If the user doesn't exist, you can create them manually:
-- INSERT INTO users (id, email, full_name, role, created_at, updated_at)
-- VALUES (
--   'your-user-id-here',  -- Get this from Supabase Auth users table
--   'jumae@example.com',
--   'Jumae',
--   'admin',
--   now(),
--   now()
-- );

