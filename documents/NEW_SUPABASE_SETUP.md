# New Supabase Project Setup

## 🚀 Quick Setup Guide

### 1. Create New Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Click **"New Project"**
3. Name: **"RGS Tools Clean"**
4. Set strong database password
5. Choose region close to you
6. Click **"Create new project"**

### 2. Get Credentials
Once project is created:
1. Go to **Settings** → **API**
2. Copy:
   - **Project URL** (starts with https://)
   - **anon public key** (starts with eyJ)

### 3. Update Flutter App
Update these files with new credentials:

**lib/services/supabase_service.dart:**
```dart
class SupabaseService {
  static const String supabaseUrl = 'YOUR_NEW_PROJECT_URL';
  static const String supabaseAnonKey = 'YOUR_NEW_ANON_KEY';
  // ... rest of the code
}
```

### 4. Run Database Setup
1. Go to **SQL Editor** in new Supabase project
2. Run the **CLEAN_DATABASE_SETUP.sql** script
3. This creates clean users and tools tables

### 5. Test Authentication
1. Try signing up with a new email
2. Try logging in
3. Check if roles work properly

## ✅ What This Fixes
- ✅ No more "Database error granting user"
- ✅ Clean, simple database structure
- ✅ Proper authentication flow
- ✅ Role selection works correctly
- ✅ No legacy issues or broken constraints

## 🎯 Expected Results
- Signup should work immediately
- Login should work immediately  
- Admin/Technician roles should work correctly
- No database constraint errors

