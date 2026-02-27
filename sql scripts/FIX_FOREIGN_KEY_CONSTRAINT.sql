-- Fix the foreign key constraint on pending_user_approvals.reviewed_by
-- This allows us to set reviewed_by to NULL when deleting users

-- Option 1: Drop and recreate the constraint with ON DELETE SET NULL
-- This is the cleanest solution

-- First, check the current constraint
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
LEFT JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
  AND rc.constraint_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'pending_user_approvals'
  AND kcu.column_name = 'reviewed_by';

-- Drop the existing constraint
ALTER TABLE public.pending_user_approvals
DROP CONSTRAINT IF EXISTS pending_user_approvals_reviewed_by_fkey;

-- First, set all invalid reviewed_by references to NULL
-- (references to users that no longer exist in public.users)
UPDATE public.pending_user_approvals
SET reviewed_by = NULL
WHERE reviewed_by IS NOT NULL
  AND reviewed_by NOT IN (SELECT id FROM public.users);

-- Recreate with ON DELETE SET NULL (allows NULL when user is deleted)
-- This ensures that when a user is deleted, reviewed_by is automatically set to NULL
ALTER TABLE public.pending_user_approvals
ADD CONSTRAINT pending_user_approvals_reviewed_by_fkey
FOREIGN KEY (reviewed_by)
REFERENCES public.users(id)
ON DELETE SET NULL;

-- Verify the constraint was created correctly
SELECT
  'Constraint updated successfully' as status,
  tc.constraint_name,
  rc.delete_rule
FROM information_schema.table_constraints AS tc
LEFT JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
  AND rc.constraint_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'pending_user_approvals'
  AND tc.constraint_name = 'pending_user_approvals_reviewed_by_fkey';
