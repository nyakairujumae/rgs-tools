# Setup Supabase Storage Bucket for Tool Images

## The Issue
Your app is showing: "Tool saved with local image (cloud upload failed: Storage bucket not found. Please create the "tool-images" bucket in Supabase Storage.)"

## The Solution
You need to create a storage bucket in your Supabase project.

## Step-by-Step Instructions

### 1. Go to Supabase Dashboard
- Open your Supabase project dashboard
- Navigate to **Storage** in the left sidebar

### 2. Create Storage Bucket
- Click **"New bucket"** or **"Create bucket"**
- **Bucket name**: `tool-images`
- **Public bucket**: ✅ **YES** (check this box)
- Click **"Create bucket"**

### 3. Set Bucket Policies (Optional but Recommended)
- Click on the `tool-images` bucket
- Go to **"Policies"** tab
- Click **"New policy"**
- **Policy name**: `Allow authenticated users to upload images`
- **Policy definition**:
```sql
(bucket_id = 'tool-images'::text) AND (auth.role() = 'authenticated'::text)
```
- **Operations**: Select **INSERT**, **UPDATE**, **DELETE**
- Click **"Save policy"**

### 4. Alternative: Use SQL to Create Bucket
If the UI doesn't work, you can create the bucket using SQL:

```sql
-- Create the storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('tool-images', 'tool-images', true);

-- Create policy for authenticated users
CREATE POLICY "Allow authenticated users to upload images" ON storage.objects
FOR ALL USING (bucket_id = 'tool-images' AND auth.role() = 'authenticated');
```

## After Setup
Once the bucket is created:
1. **Restart your Flutter app**
2. **Try adding a tool with an image**
3. **The image should upload successfully to the cloud**

## Benefits
- ✅ **Images stored in cloud** - Accessible from any device
- ✅ **Faster loading** - Images load from CDN
- ✅ **Backup** - Images are safely stored
- ✅ **Sharing** - Images can be shared between users

## Troubleshooting
If you still get errors:
1. **Check bucket permissions** - Make sure it's public
2. **Verify bucket name** - Must be exactly `tool-images`
3. **Check RLS policies** - Ensure authenticated users can upload
4. **Restart app** - Sometimes needs a fresh start

Your tools are saving successfully - this is just the final step for image storage! 🚀
