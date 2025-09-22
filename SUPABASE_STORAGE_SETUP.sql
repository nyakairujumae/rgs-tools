-- Supabase Storage Setup for Tool Images
-- Run this in your Supabase SQL Editor to set up image storage

-- 1. Create the storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('tool-images', 'tool-images', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Create RLS policies for public read access
CREATE POLICY "Public Access for Tool Images" ON storage.objects
FOR SELECT USING (bucket_id = 'tool-images');

-- 3. Create RLS policies for authenticated users to upload
CREATE POLICY "Authenticated Upload for Tool Images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'tool-images' 
  AND auth.role() = 'authenticated'
);

-- 4. Create RLS policies for authenticated users to update their own images
CREATE POLICY "Authenticated Update for Tool Images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'tool-images' 
  AND auth.role() = 'authenticated'
);

-- 5. Create RLS policies for authenticated users to delete their own images
CREATE POLICY "Authenticated Delete for Tool Images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'tool-images' 
  AND auth.role() = 'authenticated'
);

-- 6. Verify the bucket was created
SELECT * FROM storage.buckets WHERE id = 'tool-images';

-- 7. Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
