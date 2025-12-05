# Upload RGS Logo to Supabase Storage

## Quick Method (Recommended)

### Step 1: Go to Supabase Dashboard
1. Open your Supabase project: https://npgwikkvtxebzwtpzwgx.supabase.co
2. Navigate to **Storage** in the left sidebar
3. Click on the **`tool-images`** bucket (or create it if it doesn't exist)

### Step 2: Upload the File
1. Click **"Upload file"** or **"Upload"** button
2. Select `assets/images/rgs.jpg` from your project
3. Name it: `rgs.jpg` (or keep the original name)
4. Click **"Upload"**

### Step 3: Make Bucket Public (if not already)
1. Go to bucket settings
2. Make sure **"Public bucket"** is checked ✅
3. Save changes

### Step 4: Get the Public URL
Once uploaded, the public URL will be:

```
https://npgwikkvtxebzwtpzwgx.supabase.co/storage/v1/object/public/tool-images/rgs.jpg
```

Or if you create a separate `logos` bucket:

```
https://npgwikkvtxebzwtpzwgx.supabase.co/storage/v1/object/public/logos/rgs.jpg
```

## Alternative: Create a Logos Bucket

If you want a separate bucket for logos:

1. In Supabase Storage, click **"New bucket"**
2. Name: `logos`
3. **Public bucket**: ✅ YES
4. Click **"Create bucket"**
5. Upload `rgs.jpg` to this bucket
6. URL will be: `https://npgwikkvtxebzwtpzwgx.supabase.co/storage/v1/object/public/logos/rgs.jpg`

## Using the URL in Your App

Once you have the URL, you can use it anywhere in your app:

```dart
const String rgsLogoUrl = 'https://npgwikkvtxebzwtpzwgx.supabase.co/storage/v1/object/public/tool-images/rgs.jpg';

// Use in Image.network()
Image.network(rgsLogoUrl)
```


