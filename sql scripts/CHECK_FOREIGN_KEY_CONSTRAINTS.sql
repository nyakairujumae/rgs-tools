-- Check foreign key constraints on pending_user_approvals table
-- This will help us understand what the constraint actually references

-- Check all foreign key constraints on pending_user_approvals
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'pending_user_approvals';

-- Check the data type of reviewed_by column
SELECT
  column_name,
  data_type,
  udt_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'pending_user_approvals'
  AND column_name = 'reviewed_by';

-- Check sample data to see what reviewed_by contains
SELECT
  id,
  user_id,
  reviewed_by,
  pg_typeof(reviewed_by) as reviewed_by_type,
  status
FROM public.pending_user_approvals
LIMIT 5;
