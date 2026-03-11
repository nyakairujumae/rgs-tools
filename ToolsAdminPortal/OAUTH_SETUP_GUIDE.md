# OAuth Setup Guide - Google and Apple Sign-In

## Overview

This guide will help you configure Google and Apple OAuth authentication in your Supabase project so that users can sign in with their Google or Apple accounts instead of creating email/password accounts.

## Current Implementation

The app already has OAuth support implemented:
- ✅ OAuth buttons in login screen
- ✅ Deep link callback handling
- ✅ Role assignment for OAuth users
- ✅ Role selection screen for first-time OAuth users

## What Needs to be Configured

You need to configure the OAuth providers in your **Supabase Dashboard**. The app code is ready, but Supabase needs to know:
1. Your OAuth app credentials (Client ID, Client Secret, etc.)
2. Where to redirect users after OAuth (your app's deep link)

---

## Step 1: Configure Redirect URLs in Supabase

**Go to**: Supabase Dashboard → Authentication → URL Configuration

**Add these Redirect URLs:**
```
com.rgs.app://auth/callback
com.rgs.app://
```

**Site URL** (for web fallback):
```
https://rgstools.app
```

**Note**: These URLs must match exactly what's in your app code (`lib/providers/auth_provider.dart` line 1621).

---

## Step 2: Configure Google OAuth

### 2.1 Create Google OAuth Credentials

1. **Go to**: [Google Cloud Console](https://console.cloud.google.com/)
2. **Create or select a project**
3. **Enable Google+ API**:
   - Go to "APIs & Services" → "Library"
   - Search for "Google+ API" and enable it
4. **Create OAuth 2.0 Credentials**:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: **iOS** (for mobile app)
   - Name: "RGS Tools iOS"
   - Bundle ID: `com.rgs.app`
   - Click "Create"
   - **Save the Client ID** (you'll need this)

5. **Create Web OAuth Client** (for Supabase):
   - Click "Create Credentials" → "OAuth client ID" again
   - Application type: **Web application**
   - Name: "RGS Tools Web (Supabase)"
   - Authorized redirect URIs: Add:
     ```
     https://[YOUR_SUPABASE_PROJECT_REF].supabase.co/auth/v1/callback
     ```
     (Replace `[YOUR_SUPABASE_PROJECT_REF]` with your actual Supabase project reference)
   - Click "Create"
   - **Save both Client ID and Client Secret**

### 2.2 Configure in Supabase Dashboard

**Go to**: Supabase Dashboard → Authentication → Providers → Google

**Enable Google Provider**:
- ✅ Toggle "Enable Google provider" to ON
- **Client ID (for OAuth)**: Paste the **Web Client ID** from step 2.1
- **Client Secret (for OAuth)**: Paste the **Web Client Secret** from step 2.1
- Click "Save"

**Important**: Use the **Web** credentials (not iOS) for Supabase, as Supabase acts as the OAuth server.

---

## Step 3: Configure Apple Sign-In

### 3.1 Create Apple App ID and Service ID

1. **Go to**: [Apple Developer Portal](https://developer.apple.com/account/)
2. **Create App ID** (if not already created):
   - Go to "Certificates, Identifiers & Profiles" → "Identifiers"
   - Click "+" → "App IDs" → "App"
   - Description: "RGS Tools"
   - Bundle ID: `com.rgs.app`
   - Enable "Sign In with Apple"
   - Click "Continue" → "Register"

3. **Create Service ID** (for OAuth):
   - Go to "Identifiers" → Click "+" → "Services IDs"
   - Description: "RGS Tools OAuth"
   - Identifier: `com.rgs.app.oauth` (or similar)
   - Enable "Sign In with Apple"
   - Click "Configure"
   - **Primary App ID**: Select your App ID (`com.rgs.app`)
   - **Website URLs**:
     - Domains: `[YOUR_SUPABASE_PROJECT_REF].supabase.co`
     - Return URLs: `https://[YOUR_SUPABASE_PROJECT_REF].supabase.co/auth/v1/callback`
   - Click "Save" → "Continue" → "Register"
   - **Save the Service ID** (you'll need this)

4. **Create Key for Sign In with Apple**:
   - Go to "Keys" → Click "+"
   - Key Name: "RGS Tools Sign In with Apple"
   - Enable "Sign In with Apple"
   - Click "Configure" → Select your Primary App ID
   - Click "Save" → "Continue" → "Register"
   - **Download the .p8 key file** (you can only download it once!)
   - **Note the Key ID** (shown after creation)

5. **Get your Team ID**:
   - Go to "Membership" → Your Team ID is shown at the top

### 3.2 Configure in Supabase Dashboard

**Go to**: Supabase Dashboard → Authentication → Providers → Apple

**Enable Apple Provider**:
- ✅ Toggle "Enable Apple provider" to ON
- **Services ID**: Paste your Service ID (e.g., `com.rgs.app.oauth`)
- **Team ID**: Paste your Apple Team ID
- **Key ID**: Paste the Key ID from step 3.1
- **Private Key**: Open the `.p8` file you downloaded and paste its entire contents
- Click "Save"

---

## Step 4: Test OAuth Sign-In

### Testing Google Sign-In:

1. Open your app
2. Go to Login screen
3. Tap the Google button
4. You should be redirected to Google sign-in
5. After signing in, you should be redirected back to the app
6. If it's your first time, you'll see the role selection screen
7. Select "Admin" or "Technician"
8. You should be logged in with your Google account

### Testing Apple Sign-In:

1. Open your app (on iOS device)
2. Go to Login screen
3. Tap the Apple button
4. You should see Apple Sign-In dialog
5. After signing in, you should be redirected back to the app
6. If it's your first time, you'll see the role selection screen
7. Select "Admin" or "Technician"
8. You should be logged in with your Apple account

---

## Troubleshooting

### Issue: "Redirect URI mismatch"

**Solution**: 
- Check that `com.rgs.app://auth/callback` is added in Supabase URL Configuration
- Verify the redirect URL in code matches exactly

### Issue: "OAuth provider not configured"

**Solution**:
- Make sure the provider is enabled in Supabase Dashboard
- Verify all credentials are correct (Client ID, Client Secret, etc.)
- Check that redirect URLs are configured

### Issue: "User created but no role assigned"

**Solution**:
- This is expected for first-time OAuth users
- They should see the role selection screen
- After selecting a role, it will be saved to the database

### Issue: OAuth works but user can't log in again

**Solution**:
- Check that the user record was created in `public.users` table
- Verify the role was assigned correctly
- Check database triggers are working

---

## How It Works

1. **User taps OAuth button** → App calls `signInWithGoogle()` or `signInWithApple()`
2. **Supabase redirects** → User is sent to Google/Apple sign-in page
3. **User signs in** → Google/Apple verifies credentials
4. **Callback to app** → Deep link `com.rgs.app://auth/callback` is triggered
5. **App processes callback** → `main.dart` deep link handler catches it
6. **Session created** → Supabase creates auth session
7. **Role check** → If no role exists, user sees role selection screen
8. **Role assigned** → User selects Admin or Technician, role is saved
9. **User logged in** → App navigates to appropriate home screen

---

## Database Requirements

The following database tables/columns are used:
- `public.users` - Stores user records with roles
- `pending_user_approvals` - Created for technicians (requires admin approval)
- `auth.users` - Managed by Supabase (contains OAuth metadata)

**No additional database setup needed** - the existing schema supports OAuth users.

---

## Security Notes

1. **Never commit OAuth credentials** to git
2. **Use environment variables** for sensitive data (if needed)
3. **Keep private keys secure** - the Apple `.p8` key should be stored safely
4. **Rotate credentials** if compromised
5. **Monitor OAuth usage** in Supabase Dashboard

---

## Next Steps

After configuring OAuth:
1. Test both Google and Apple sign-in
2. Verify users can select roles
3. Test that users can log in again after first sign-in
4. Check that admin approval works for OAuth technicians

If you encounter any issues, check the Supabase Dashboard logs and your app's debug console for error messages.

