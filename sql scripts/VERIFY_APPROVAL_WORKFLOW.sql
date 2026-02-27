-- Verify that the approval workflow is still intact
-- This checks all components needed for "wait for approval" functionality

-- ===========================================
-- STEP 1: Check if pending_user_approvals table exists and has correct structure
-- ===========================================

SELECT 
  'Table Structure Check' as check_type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'pending_user_approvals'
ORDER BY ordinal_position;

-- ===========================================
-- STEP 2: Check RLS policies on pending_user_approvals
-- ===========================================

SELECT 
  'RLS Policies Check' as check_type,
  policyname,
  cmd as operation,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'pending_user_approvals';

-- ===========================================
-- STEP 3: Check foreign key constraints
-- ===========================================

SELECT 
  'Foreign Key Check' as check_type,
  tc.constraint_name,
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
  AND tc.table_name = 'pending_user_approvals';

-- ===========================================
-- STEP 4: Check if approval functions exist
-- ===========================================

SELECT 
  'Functions Check' as check_type,
  proname as function_name,
  proargnames as parameters
FROM pg_proc
WHERE proname IN ('approve_pending_user', 'reject_pending_user')
  AND pronamespace = 'public'::regnamespace;

-- ===========================================
-- STEP 5: Check sample pending approvals
-- ===========================================

SELECT 
  'Sample Data Check' as check_type,
  COUNT(*) as total_pending_approvals,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
  COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_count,
  COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_count
FROM public.pending_user_approvals;

-- ===========================================
-- STEP 6: Verify reviewed_by constraint allows NULL
-- ===========================================

SELECT 
  'Reviewed By Constraint Check' as check_type,
  COUNT(*) as records_with_null_reviewed_by,
  COUNT(*) FILTER (WHERE reviewed_by IS NOT NULL) as records_with_reviewed_by
FROM public.pending_user_approvals;

-- ===========================================
-- SUMMARY
-- ===========================================

SELECT 
  '✅ Approval workflow verification complete!' as status,
  'Check the results above to ensure all components are intact' as message;
