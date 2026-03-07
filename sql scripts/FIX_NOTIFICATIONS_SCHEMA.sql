-- ============================================================================
-- FIX: Notifications tables schema + missing columns
-- Run this in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. FIX admin_notifications
-- ============================================================================

-- Add missing columns if they don't exist
ALTER TABLE admin_notifications ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;
ALTER TABLE admin_notifications ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE admin_notifications ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE admin_notifications ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE admin_notifications ADD COLUMN IF NOT EXISTS body TEXT;
ALTER TABLE admin_notifications ADD COLUMN IF NOT EXISTS data JSONB;
ALTER TABLE admin_notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- Update NOT NULL columns that may be missing values
UPDATE admin_notifications SET type = 'general' WHERE type IS NULL;
UPDATE admin_notifications SET title = 'Notification' WHERE title IS NULL;

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_admin_notifications_organization ON admin_notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_admin_id ON admin_notifications(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_is_read ON admin_notifications(is_read);

-- Enable RLS
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;

-- Recreate policies
DROP POLICY IF EXISTS "Admins can read own notifications" ON admin_notifications;
CREATE POLICY "Admins can read own notifications" ON admin_notifications
  FOR SELECT USING (admin_id = auth.uid());

DROP POLICY IF EXISTS "Admins can update own notifications" ON admin_notifications;
CREATE POLICY "Admins can update own notifications" ON admin_notifications
  FOR UPDATE USING (admin_id = auth.uid());

DROP POLICY IF EXISTS "Service can insert notifications" ON admin_notifications;
CREATE POLICY "Service can insert notifications" ON admin_notifications
  FOR INSERT WITH CHECK (true);

-- ============================================================================
-- 2. FIX technician_notifications
-- ============================================================================

ALTER TABLE technician_notifications ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;
ALTER TABLE technician_notifications ADD COLUMN IF NOT EXISTS technician_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE technician_notifications ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE technician_notifications ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE technician_notifications ADD COLUMN IF NOT EXISTS body TEXT;
ALTER TABLE technician_notifications ADD COLUMN IF NOT EXISTS data JSONB;
ALTER TABLE technician_notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

UPDATE technician_notifications SET type = 'general' WHERE type IS NULL;
UPDATE technician_notifications SET title = 'Notification' WHERE title IS NULL;

CREATE INDEX IF NOT EXISTS idx_tech_notifications_organization ON technician_notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_tech_notifications_user_id ON technician_notifications(technician_user_id);

ALTER TABLE technician_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Technicians can read own notifications" ON technician_notifications;
CREATE POLICY "Technicians can read own notifications" ON technician_notifications
  FOR SELECT USING (technician_user_id = auth.uid());

DROP POLICY IF EXISTS "Technicians can update own notifications" ON technician_notifications;
CREATE POLICY "Technicians can update own notifications" ON technician_notifications
  FOR UPDATE USING (technician_user_id = auth.uid());

DROP POLICY IF EXISTS "Service can insert tech notifications" ON technician_notifications;
CREATE POLICY "Service can insert tech notifications" ON technician_notifications
  FOR INSERT WITH CHECK (true);

-- ============================================================================
-- 3. STORAGE BUCKETS (in case not yet created)
-- ============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('organization-logos', 'organization-logos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-pictures', 'profile-pictures', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('tool-images', 'tool-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Authenticated users can upload logos" ON storage.objects;
CREATE POLICY "Authenticated users can upload logos" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'organization-logos');

DROP POLICY IF EXISTS "Public can read logos" ON storage.objects;
CREATE POLICY "Public can read logos" ON storage.objects
  FOR SELECT USING (bucket_id = 'organization-logos');

DROP POLICY IF EXISTS "Authenticated users can upload profile pictures" ON storage.objects;
CREATE POLICY "Authenticated users can upload profile pictures" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profile-pictures');

DROP POLICY IF EXISTS "Public can read profile pictures" ON storage.objects;
CREATE POLICY "Public can read profile pictures" ON storage.objects
  FOR SELECT USING (bucket_id = 'profile-pictures');

DROP POLICY IF EXISTS "Authenticated users can upload tool images" ON storage.objects;
CREATE POLICY "Authenticated users can upload tool images" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'tool-images');

DROP POLICY IF EXISTS "Public can read tool images" ON storage.objects;
CREATE POLICY "Public can read tool images" ON storage.objects
  FOR SELECT USING (bucket_id = 'tool-images');

SELECT '✅ Notifications schema fixed. Ready to use.' AS status;
