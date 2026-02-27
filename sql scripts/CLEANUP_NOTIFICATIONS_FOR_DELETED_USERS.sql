-- =====================================================
-- CLEANUP NOTIFICATIONS FOR DELETED USERS
-- =====================================================
-- This script provides options to handle notifications
-- for users that have been deleted from the system.
-- 
-- IMPORTANT: Notifications are historical records.
-- Consider carefully before deleting them.
-- =====================================================

SET search_path = public;

-- ===========================================
-- STEP 1: Check notifications for deleted users
-- ===========================================

-- Find notifications where the technician_email doesn't exist in public.users
SELECT 
  'Notifications for deleted users' as status,
  COUNT(*) as count
FROM admin_notifications an
LEFT JOIN public.users u ON an.technician_email = u.email
WHERE u.email IS NULL;

-- Show details of notifications for deleted users
SELECT 
  an.id,
  an.title,
  an.message,
  an.technician_name,
  an.technician_email,
  an.type,
  an.timestamp,
  an.is_read,
  CASE 
    WHEN u.email IS NULL THEN 'User Deleted'
    ELSE 'User Exists'
  END as user_status
FROM admin_notifications an
LEFT JOIN public.users u ON an.technician_email = u.email
WHERE u.email IS NULL
ORDER BY an.timestamp DESC
LIMIT 50;

-- ===========================================
-- STEP 2: OPTION A - Anonymize notifications
-- ===========================================
-- This keeps the notifications but removes identifying information
-- Uncomment to run:

-- UPDATE admin_notifications an
-- SET 
--   technician_name = '[Deleted User]',
--   technician_email = '[deleted@user.removed]'
-- WHERE NOT EXISTS (
--   SELECT 1 FROM public.users u 
--   WHERE u.email = an.technician_email
-- );

-- ===========================================
-- STEP 3: OPTION B - Delete notifications for deleted users
-- ===========================================
-- WARNING: This permanently deletes historical notification records
-- Only use if you're sure you want to lose this history
-- Uncomment to run:

-- DELETE FROM admin_notifications an
-- WHERE NOT EXISTS (
--   SELECT 1 FROM public.users u 
--   WHERE u.email = an.technician_email
-- );

-- ===========================================
-- STEP 4: OPTION C - Mark notifications as archived
-- ===========================================
-- If you have an 'archived' or 'deleted' column, you can mark them instead
-- This example assumes you might add such a column in the future
-- Uncomment and modify if needed:

-- ALTER TABLE admin_notifications 
-- ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;

-- UPDATE admin_notifications an
-- SET is_archived = TRUE
-- WHERE NOT EXISTS (
--   SELECT 1 FROM public.users u 
--   WHERE u.email = an.technician_email
-- );

-- ===========================================
-- STEP 5: Verify cleanup (if you ran Option A or B)
-- ===========================================

-- After running Option A or B, check remaining notifications
-- SELECT 
--   'Remaining notifications for deleted users' as status,
--   COUNT(*) as count
-- FROM admin_notifications an
-- LEFT JOIN public.users u ON an.technician_email = u.email
-- WHERE u.email IS NULL;

-- ===========================================
-- RECOMMENDATION
-- ===========================================
-- 
-- **Option A (Anonymize)** is recommended because:
-- - Preserves historical notification data
-- - Maintains audit trail
-- - Removes identifying information for deleted users
-- 
-- **Option B (Delete)** should only be used if:
-- - You need to free up database space
-- - You don't need historical notification records
-- - You're certain you won't need this data later
-- 
-- **Keeping notifications as-is** is also valid because:
-- - They're historical records (like a log)
-- - They don't affect email availability checks
-- - They provide a complete audit trail
-- 
-- ===========================================
