-- Clean up invalid reviewed_by references in pending_user_approvals
-- This fixes the foreign key constraint violation

-- Step 1: Find all invalid reviewed_by references
-- (references to users that don't exist in public.users)
SELECT 
  'Invalid reviewed_by references' as info,
  id,
  user_id,
  email,
  reviewed_by,
  status
FROM public.pending_user_approvals
WHERE reviewed_by IS NOT NULL
  AND reviewed_by NOT IN (SELECT id FROM public.users);

-- Step 2: Set invalid reviewed_by references to NULL
UPDATE public.pending_user_approvals
SET reviewed_by = NULL
WHERE reviewed_by IS NOT NULL
  AND reviewed_by NOT IN (SELECT id FROM public.users);

-- Step 3: Verify cleanup
SELECT 
  'Cleanup verification' as info,
  COUNT(*) as remaining_invalid_references
FROM public.pending_user_approvals
WHERE reviewed_by IS NOT NULL
  AND reviewed_by NOT IN (SELECT id FROM public.users);

-- Step 4: Now fix the constraint to prevent future issues
ALTER TABLE public.pending_user_approvals
DROP CONSTRAINT IF EXISTS pending_user_approvals_reviewed_by_fkey;

ALTER TABLE public.pending_user_approvals
ADD CONSTRAINT pending_user_approvals_reviewed_by_fkey
FOREIGN KEY (reviewed_by)
REFERENCES public.users(id)
ON DELETE SET NULL;

SELECT '✅ Invalid reviewed_by references cleaned up and constraint fixed!' as status;
