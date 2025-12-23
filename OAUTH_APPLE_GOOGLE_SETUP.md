# Apple and Google OAuth Setup Guide

## Overview

This guide will help you configure real Apple Sign-In and Google Sign-In with Supabase OAuth. Currently, the app has OAuth buttons but they need proper configuration in Supabase and the OAuth provider consoles.

## Prerequisites

1. **Supabase Project** - Your project must be set up
2. **Apple Developer Account** (for Apple Sign-In)
3. **Google Cloud Console Account** (for Google Sign-In)

---

## Part 1: Supabase Configuration

### Step 1: Enable OAuth Providers in Supabase

1. Go to your **Supabase Dashboard**
2. Navigate to **Authentication** → **Providers**
3. Enable the providers you want:
   - ✅ **Google** - Toggle ON
   - ✅ **Apple** - Toggle ON (iOS/macOS only)

### Step 2: Configure Redirect URLs

1. Go to **Authentication** → **URL Configuration**
2. **Site URL**: `com.rgs.app://`
3. **Redirect URLs** - Add these:
   ```
   com.rgs.app://
   com.rgs.app://auth/callback
   com.rgs.app://callback
   ```

---

## Part 2: Google Sign-In Setup

### Step 1: Create OAuth 2.0 Credentials in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project (or create a new one)
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**

### Step 2: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** (unless you have Google Workspace)
3. Fill in required fields:
   - **App name**: RGS Tools
   - **User support email**: Your email
   - **Developer contact information**: Your email
4. Click **Save and Continue**
5. Add scopes (if needed):
   - `email`
   - `profile`
   - `openid`
6. Click **Save and Continue**
7. Add test users (if in testing mode)
8. Click **Save and Continue**

### Step 3: Create OAuth Client ID

1. Go to **Credentials** → **Create Credentials** → **OAuth client ID**
2. Choose **Application type**: 
   - **iOS** (for iOS app)
   - **Android** (for Android app)
   - **Web application** (for Supabase redirect)
3. Fill in details:

**For iOS:**
- **Name**: RGS Tools iOS
- **Bundle ID**: `com.rgs.app`

**For Android:**
- **Name**: RGS Tools Android
- **Package name**: `com.rgs.app`
- **SHA-1 certificate fingerprint**: (Get from your keystore)

**For Web (Supabase):**
- **Name**: RGS Tools Web
- **Authorized redirect URIs**: 
  ```
  https://[YOUR_PROJECT_REF].supabase.co/auth/v1/callback
  ```
  Replace `[YOUR_PROJECT_REF]` with your Supabase project reference (found in your Supabase dashboard URL)

### Step 4: Get Credentials

After creating, you'll get:
- **Client ID** (for iOS/Android)
- **Client Secret** (for Web - this goes in Supabase)

### Step 5: Configure in Supabase

1. Go to **Supabase Dashboard** → **Authentication** → **Providers** → **Google**
2. Enter:
   - **Client ID (for OAuth)**: Your Web Client ID from Google
   - **Client Secret (for OAuth)**: Your Web Client Secret from Google
3. Click **Save**

### Step 6: Update Flutter Code (if needed)

The current implementation should work, but we need to ensure redirect URLs are properly configured:

```dart
await client.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'com.rgs.app://auth/callback',
);
```

---

## Part 3: Apple Sign-In Setup

### Step 1: Create App ID in Apple Developer

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Go to **Identifiers** → **App IDs**
4. Click **+** to create new
5. Select **App IDs** → **Continue**
6. Select **App** → **Continue**
7. Fill in:
   - **Description**: RGS Tools
   - **Bundle ID**: `com.rgs.app`
   - **Capabilities**: Enable **Sign In with Apple**
8. Click **Continue** → **Register**

### Step 2: Create Service ID

1. Go to **Identifiers** → **Services IDs**
2. Click **+** to create new
3. Fill in:
   - **Description**: RGS Tools Sign In
   - **Identifier**: `com.rgs.app.signin` (or similar)
4. Click **Continue** → **Register**
5. Click on the new Service ID
6. Enable **Sign In with Apple**
7. Click **Configure**
8. **Primary App ID**: Select `com.rgs.app`
9. **Website URLs**:
   - **Domains**: `[YOUR_PROJECT_REF].supabase.co`
   - **Return URLs**: 
     ```
     https://[YOUR_PROJECT_REF].supabase.co/auth/v1/callback
     ```
10. Click **Save** → **Continue** → **Save**

### Step 3: Create Key for Sign In with Apple

1. Go to **Keys**
2. Click **+** to create new
3. Fill in:
   - **Key Name**: RGS Tools Sign In Key
   - **Enable**: **Sign In with Apple**
4. Click **Configure** → Select your Primary App ID → **Save**
5. Click **Continue** → **Register**
6. **Download the key file** (`.p8` file) - You can only download once!
7. Note the **Key ID**

### Step 4: Get Your Team ID

1. Go to **Membership** in Apple Developer Portal
2. Note your **Team ID** (10-character string)

### Step 5: Configure in Supabase

1. Go to **Supabase Dashboard** → **Authentication** → **Providers** → **Apple**
2. Enter:
   - **Services ID**: `com.rgs.app.signin` (from Step 2)
   - **Team ID**: Your Team ID (from Step 4)
   - **Key ID**: Your Key ID (from Step 3)
   - **Private Key**: Upload the `.p8` file content (open in text editor, copy entire content including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
3. Click **Save**

---

## Part 4: Update Flutter Code

The current implementation needs to be updated to properly handle OAuth redirects. Here's what needs to be done:

### Current Implementation

The code currently calls:
```dart
await client.auth.signInWithOAuth(OAuthProvider.google);
```

### Updated Implementation Needed

We need to:
1. Add proper redirect URL
2. Handle OAuth callbacks in deep link handler
3. Ensure proper error handling

---

## Part 5: Testing

### Test Google Sign-In

1. Click "Sign in with Google" button
2. Should open Google sign-in page
3. After signing in, should redirect back to app
4. User should be logged in

### Test Apple Sign-In (iOS/macOS only)

1. Click "Sign in with Apple" button
2. Should show Apple sign-in sheet
3. After signing in, should redirect back to app
4. User should be logged in

---

## Troubleshooting

### Google Sign-In Issues

- **"redirect_uri_mismatch"**: Check redirect URLs in Google Console match Supabase
- **"invalid_client"**: Check Client ID and Secret in Supabase
- **"access_denied"**: Check OAuth consent screen is configured

### Apple Sign-In Issues

- **"invalid_client"**: Check Service ID, Team ID, Key ID in Supabase
- **"invalid_request"**: Check private key is correctly uploaded
- **"unauthorized_client"**: Check Bundle ID matches in Apple Developer and app

### General Issues

- **Deep link not working**: Check URL scheme in `Info.plist` (iOS) and `AndroidManifest.xml` (Android)
- **OAuth callback not handled**: Check deep link handler in `main.dart`

---

## Next Steps

After configuring in Supabase and OAuth provider consoles, we'll update the Flutter code to:
1. Add proper redirect URLs
2. Handle OAuth callbacks
3. Create user records for OAuth users
4. Handle role assignment for OAuth users
