# Push Notifications - Complete Setup Guide

This guide covers everything needed to get push notifications working in the RGS Tools app.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Setup](#firebase-setup)
3. [iOS Configuration](#ios-configuration)
4. [Android Configuration](#android-configuration)
5. [Supabase Edge Function Setup](#supabase-edge-function-setup)
6. [Database Setup](#database-setup)
7. [Code Verification](#code-verification)
8. [Testing](#testing)
9. [Troubleshooting](#troubleshooting)
10. [Checklist](#checklist)

---

## 1. Prerequisites

### Required Accounts & Services
- ✅ **Firebase Project** (free tier is fine)
- ✅ **Supabase Project** (free tier is fine)
- ✅ **Apple Developer Account** (paid $99/year) - **REQUIRED for iOS push notifications**
- ✅ **Google Cloud Project** (linked to Firebase)

### Required Files
- ✅ `GoogleService-Info.plist` (iOS) - Located in `ios/Runner/`
- ✅ `google-services.json` (Android) - Should be in `android/app/`
- ✅ Firebase Service Account JSON (for Edge Function)

---

## 2. Firebase Setup

### Step 1: Create/Verify Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing project
3. Note your **Project ID** (you'll need this later)

### Step 2: Enable Cloud Messaging API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **APIs & Services** → **Library**
4. Search for "Firebase Cloud Messaging API"
5. Click **Enable**

### Step 3: Create Service Account
1. Go to **IAM & Admin** → **Service Accounts**
2. Click **Create Service Account**
3. Name it (e.g., "FCM Service Account")
4. Grant role: **Firebase Cloud Messaging Admin**
5. Click **Done**
6. Click on the service account → **Keys** → **Add Key** → **Create New Key** → **JSON**
7. **Download the JSON file** - You'll need this for Supabase secrets

### Step 4: Add iOS App to Firebase
1. In Firebase Console, go to **Project Settings** → **Your apps**
2. Click **Add app** → **iOS**
3. Enter Bundle ID: `com.rgs.app`
4. Download `GoogleService-Info.plist`
5. Replace the file in `ios/Runner/GoogleService-Info.plist`

### Step 5: Add Android App to Firebase
1. In Firebase Console, go to **Project Settings** → **Your apps**
2. Click **Add app** → **Android**
3. Enter Package name: `com.rgs.app`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

### Step 6: Configure APNs for iOS (IMPORTANT)
1. In Firebase Console → **Project Settings** → **Cloud Messaging** → **Apple app configuration**
2. Upload your **APNs Authentication Key** (`AuthKey_JYM8AT35HZ.p8`)
3. Enter **Key ID**: `JYM8AT35HZ`
4. Enter **Team ID**: (Your Apple Developer Team ID)
5. Click **Upload**

**OR** upload your APNs Certificate (.p12 file)

---

## 3. iOS Configuration

### Step 1: Verify Entitlements
File: `ios/Runner/Runner.entitlements`

Should contain:
```xml
<key>aps-environment</key>
<string>production</string>
```

**Note**: This requires a **paid Apple Developer account** ($99/year). Push notifications will NOT work with a free/personal account.

### Step 2: Verify AppDelegate.swift
File: `ios/Runner/AppDelegate.swift`

Should contain:
- ✅ `import FirebaseMessaging`
- ✅ `import UserNotifications`
- ✅ APNs token registration handlers
- ✅ Notification permission request

**Current Status**: ✅ Already configured

### Step 3: Verify Info.plist
File: `ios/Runner/Info.plist`

Should contain:
- ✅ Background modes (if needed)
- ✅ URL schemes for deep linking

### Step 4: Verify GoogleService-Info.plist
File: `ios/Runner/GoogleService-Info.plist`

Should contain:
- ✅ `PROJECT_ID`
- ✅ `CLIENT_ID`
- ✅ `REVERSED_CLIENT_ID`
- ✅ `API_KEY`
- ✅ `GCM_SENDER_ID`
- ✅ `BUNDLE_ID`: `com.rgs.app`

---

## 4. Android Configuration

### Step 1: Verify AndroidManifest.xml
File: `android/app/src/main/AndroidManifest.xml`

Should contain:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**Current Status**: ✅ Already configured

### Step 2: Verify google-services.json
File: `android/app/google-services.json`

Should exist and contain:
- ✅ `project_id`
- ✅ `client` array with OAuth client IDs
- ✅ `package_name`: `com.rgs.app`

### Step 3: Verify build.gradle
File: `android/build.gradle`

Should contain:
```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

File: `android/app/build.gradle`

Should contain at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## 5. Supabase Edge Function Setup

### Step 1: Deploy Edge Function
The Edge Function is located at: `supabase/functions/send-push-notification/index.ts`

**Deploy it from the project root:**
```bash
# Make sure you're in the project root directory (not inside the function folder)
cd "/Users/jumae/Desktop/rgs app"
supabase functions deploy send-push-notification --project-ref npgwikkvtxebzwtpzwgx
```

**OR** if you've linked your project:
```bash
supabase functions deploy send-push-notification
```

**Important**: Run this command from the **project root**, not from inside the `send-push-notification` directory.

**Note**: The Docker warning is non-critical - deployment will still work.

### Step 2: Set Up Secrets in Supabase
1. Go to **Supabase Dashboard** → **Settings** → **Edge Functions** → **Secrets**
2. Add these three secrets:

#### Secret 1: `GOOGLE_PROJECT_ID`
- **Value**: Your Firebase Project ID
- **Where to find**: Firebase Console → Project Settings → General → Your project

#### Secret 2: `GOOGLE_CLIENT_EMAIL`
- **Value**: Service account email from the JSON file you downloaded
- **Format**: `something@your-project.iam.gserviceaccount.com`
- **Where to find**: In the service account JSON file → `client_email`

#### Secret 3: `GOOGLE_PRIVATE_KEY`
- **Value**: Private key from the service account JSON file
- **Format**: `-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n`
- **Important**: Keep the `\n` characters (newlines) - they're required
- **Where to find**: In the service account JSON file → `private_key`
- **Example**:
  ```
  -----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n
  ```

### Step 3: Verify Edge Function Deployment
1. Go to **Supabase Dashboard** → **Edge Functions**
2. Verify `send-push-notification` appears in the list
3. Click on it to see deployment status

---

## 6. Database Setup

### Step 1: Verify user_fcm_tokens Table
Go to **Supabase Dashboard** → **Table Editor** → `user_fcm_tokens`

**Required columns:**
- ✅ `user_id` (UUID, foreign key to `auth.users`)
- ✅ `fcm_token` (TEXT, unique)
- ✅ `updated_at` (TIMESTAMPTZ)

**Create if missing:**
```sql
CREATE TABLE IF NOT EXISTS public.user_fcm_tokens (
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  fcm_token TEXT NOT NULL UNIQUE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own tokens
CREATE POLICY "Users can read own FCM tokens"
  ON public.user_fcm_tokens
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert/update their own tokens
CREATE POLICY "Users can manage own FCM tokens"
  ON public.user_fcm_tokens
  FOR ALL
  USING (auth.uid() = user_id);
```

### Step 2: Verify users Table
Go to **Supabase Dashboard** → **Table Editor** → `users`

Should exist and have:
- ✅ `id` (UUID, primary key)
- ✅ `email` (TEXT)
- ✅ `role` (TEXT: 'admin' or 'technician')

---

## 7. Code Verification

### Files to Check

#### ✅ `lib/main.dart`
- ✅ Firebase initialization: `Firebase.initializeApp()`
- ✅ Background message handler: `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)`
- ✅ FCM service initialization: `FirebaseMessagingService.initialize()`

**Current Status**: ✅ Already configured

#### ✅ `lib/services/firebase_messaging_service.dart`
- ✅ FCM token retrieval: `_getFCMToken()`
- ✅ Token saved to Supabase: `_sendTokenToServer()`
- ✅ Foreground message handler: `FirebaseMessaging.onMessage`
- ✅ Background message handler: `firebaseMessagingBackgroundHandler`
- ✅ Local notifications setup
- ✅ Badge management

**Current Status**: ✅ Already configured

#### ✅ `lib/services/push_notification_service.dart`
- ✅ `sendToUser()` - Send to specific user
- ✅ `sendToAdmins()` - Send to all admins
- ✅ `sendToToken()` - Send to specific FCM token
- ✅ Edge Function invocation

**Current Status**: ✅ Already configured

#### ✅ `lib/providers/auth_provider.dart`
- ✅ FCM token sent after login: `_sendFCMTokenToServer()`
- ✅ FCM token sent after initialization: `_getFCMTokenIfAvailable()`

**Current Status**: ✅ Already configured

#### ✅ `ios/Runner/AppDelegate.swift`
- ✅ APNs token registration
- ✅ Notification permission request
- ✅ Firebase Messaging integration

**Current Status**: ✅ Already configured

---

## 8. Testing

### Test 1: Verify Firebase Initialization
1. Build and run the app
2. Check console logs for:
   - ✅ `✅ Firebase initialized successfully`
   - ✅ `✅ [FCM] Token obtained: ...`
   - ✅ `✅ [FCM] Token saved to Supabase`

### Test 2: Verify FCM Token in Database
1. Log in to the app
2. Go to **Supabase Dashboard** → **Table Editor** → `user_fcm_tokens`
3. Verify your `user_id` has an `fcm_token` entry

### Test 3: Test Edge Function Directly
1. Get your FCM token from `user_fcm_tokens` table
2. Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification`
3. Click **Invoke**
4. Use this body:
```json
{
  "token": "YOUR_FCM_TOKEN_HERE",
  "title": "Test Notification",
  "body": "This is a test notification"
}
```
5. Check response - should be `200 OK` with `{"success": true}`

### Test 4: Test from App
1. In the app, go to **Technician Home Screen** → **Settings** → **FCM Status**
2. Click **Send Test Notification**
3. You should receive a notification

### Test 5: Test Foreground Notification
1. Keep app open (foreground)
2. Send a test notification
3. You should see a local notification appear

### Test 6: Test Background Notification
1. Put app in background (press home button)
2. Send a test notification
3. You should see a notification in the notification center

### Test 7: Test Terminated State
1. Force close the app
2. Send a test notification
3. Tap the notification
4. App should open

### Test 8: Test Badge Count
1. Receive a notification
2. Check app icon badge count
3. Badge should increment

---

## 9. Troubleshooting

### Issue 1: "Firebase initialization failed"
**Symptoms:**
- `❌ Firebase initialization failed`
- `PlatformException(channel-error)`

**Solutions:**
1. ✅ Already fixed in code - Firebase initializes after `runApp()`
2. Check `firebase_options.dart` exists and is correct
3. Verify `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) are correct
4. **For iOS Simulator**: Push notifications won't work, but Firebase should still initialize

### Issue 2: "FCM token is null"
**Symptoms:**
- `⚠️ [FCM] FCM token is null`
- No token in `user_fcm_tokens` table

**Solutions:**
1. Verify notification permissions are granted (Settings → RGS → Notifications)
2. Check Firebase is initialized: Look for `✅ Firebase initialized successfully`
3. **For iOS**: Requires paid Apple Developer account
4. **For iOS Simulator**: FCM tokens won't work (use real device)

### Issue 3: "Edge Function not found" or 404
**Symptoms:**
- `❌ Edge Function may not be deployed`
- `Function not found`

**Solutions:**
1. Deploy the Edge Function:
   ```bash
   cd supabase/functions/send-push-notification
   supabase functions deploy send-push-notification
   ```
2. Verify in Supabase Dashboard → Edge Functions

### Issue 4: "GOOGLE_PROJECT_ID not configured"
**Symptoms:**
- Edge Function returns: `GOOGLE_PROJECT_ID not configured`

**Solutions:**
1. Go to Supabase Dashboard → Settings → Edge Functions → Secrets
2. Add `GOOGLE_PROJECT_ID` with your Firebase Project ID
3. Redeploy Edge Function if needed

### Issue 5: "Failed to authenticate with Google"
**Symptoms:**
- Edge Function returns: `Failed to authenticate with Google`
- `Failed to get access token`

**Solutions:**
1. Verify `GOOGLE_CLIENT_EMAIL` is correct (from service account JSON)
2. Verify `GOOGLE_PRIVATE_KEY` is correct (keep `\n` characters)
3. Verify service account has **Firebase Cloud Messaging Admin** role
4. Verify **Firebase Cloud Messaging API** is enabled in Google Cloud Console

### Issue 6: "No FCM token found for user"
**Symptoms:**
- `⚠️ [Push] No FCM token found for user: ...`

**Solutions:**
1. Verify user is logged in
2. Check `user_fcm_tokens` table for the user's token
3. If missing, log out and log back in to trigger token save
4. Check console logs for `✅ [FCM] Token saved to Supabase`

### Issue 7: "Notifications not appearing on iOS"
**Symptoms:**
- No notifications appear on iOS device

**Solutions:**
1. **CRITICAL**: Requires **paid Apple Developer account** ($99/year)
2. Verify APNs is configured in Firebase Console
3. Check notification permissions: Settings → RGS → Notifications
4. Verify `aps-environment` is set to `production` in `Runner.entitlements`
5. **For Simulator**: Push notifications don't work - use real device

### Issue 8: "Notifications not appearing on Android"
**Symptoms:**
- No notifications appear on Android device

**Solutions:**
1. Check notification permissions (Android 13+): Settings → Apps → RGS → Notifications
2. Verify `POST_NOTIFICATIONS` permission in `AndroidManifest.xml` ✅ Already added
3. Check notification channel is created (should be automatic)
4. Verify `google-services.json` is correct

### Issue 9: "Badge count not updating"
**Symptoms:**
- Badge count doesn't increment

**Solutions:**
1. Verify `flutter_app_badger` package is installed ✅ Already installed
2. Check notification includes badge data
3. For iOS: Verify badge permission is granted
4. For Android: Badge support depends on device/launcher

---

## 10. Checklist

### Firebase Setup
- [ ] Firebase project created
- [ ] iOS app added to Firebase
- [ ] Android app added to Firebase
- [ ] `GoogleService-Info.plist` downloaded and placed in `ios/Runner/`
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] Service account created with **Firebase Cloud Messaging Admin** role
- [ ] Service account JSON downloaded
- [ ] **Firebase Cloud Messaging API** enabled in Google Cloud Console
- [ ] APNs configured in Firebase Console (iOS)

### iOS Configuration
- [ ] `Runner.entitlements` has `aps-environment` set to `production`
- [ ] `GoogleService-Info.plist` is correct
- [ ] **Paid Apple Developer account** ($99/year) - **REQUIRED**
- [ ] APNs Authentication Key or Certificate uploaded to Firebase

### Android Configuration
- [ ] `POST_NOTIFICATIONS` permission in `AndroidManifest.xml` ✅ Already added
- [ ] `google-services.json` is correct
- [ ] `build.gradle` has Google Services plugin ✅ Should be configured

### Supabase Setup
- [ ] Edge Function `send-push-notification` deployed
- [ ] Secret `GOOGLE_PROJECT_ID` set
- [ ] Secret `GOOGLE_CLIENT_EMAIL` set
- [ ] Secret `GOOGLE_PRIVATE_KEY` set (with `\n` characters)
- [ ] `user_fcm_tokens` table exists
- [ ] RLS policies on `user_fcm_tokens` table

### Code Verification
- [ ] Firebase initialized in `main.dart` ✅ Already configured
- [ ] FCM service initialized ✅ Already configured
- [ ] Background message handler registered ✅ Already configured
- [ ] Token saved to Supabase after login ✅ Already configured

### Testing
- [ ] Firebase initializes successfully
- [ ] FCM token obtained and logged
- [ ] FCM token saved to `user_fcm_tokens` table
- [ ] Edge Function can be invoked successfully
- [ ] Test notification sent from Edge Function works
- [ ] Foreground notifications work
- [ ] Background notifications work
- [ ] Terminated state notifications work
- [ ] Badge count updates correctly

---

## 📝 Important Notes

### iOS Push Notifications
- **REQUIRES paid Apple Developer account** ($99/year)
- Push notifications **WILL NOT WORK** with free/personal developer account
- This is an Apple limitation, not a code issue
- For testing without paid account: Use local notifications or test on Android

### iOS Simulator
- FCM tokens can be obtained on simulator
- Push notifications **WILL NOT WORK** on simulator (APNs limitation)
- Use a **real iOS device** for testing push notifications

### Android
- Push notifications work on both emulator and real device
- Requires Android 13+ for notification permissions
- Badge support depends on device/launcher

### Service Account Private Key
- **CRITICAL**: Keep the `\n` (newline) characters in `GOOGLE_PRIVATE_KEY`
- Format: `-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n`
- Without newlines, authentication will fail

### Edge Function Secrets
- Secrets are case-sensitive
- Must be set in Supabase Dashboard → Settings → Edge Functions → Secrets
- Edge Function must be redeployed after adding secrets (usually not needed)

---

## 🚀 Quick Start (If Everything is Already Configured)

1. **Verify Firebase is initialized**: Check app logs
2. **Verify FCM token is saved**: Check `user_fcm_tokens` table
3. **Test Edge Function**: Invoke from Supabase Dashboard
4. **Test from app**: Use "Send Test Notification" button

---

## 📞 Need Help?

If push notifications still don't work after following this guide:

1. Check **console logs** for error messages
2. Check **Supabase Edge Function logs** for errors
3. Verify all items in the **Checklist** section
4. Review **Troubleshooting** section for your specific issue

---

## ✅ Current Implementation Status

### ✅ Already Implemented
- Firebase initialization
- FCM token retrieval
- FCM token storage in Supabase
- Background message handler
- Foreground message handler
- Local notifications
- Badge management
- Edge Function code
- Push notification service
- iOS AppDelegate configuration
- Android manifest permissions

### ⚠️ Requires Manual Setup
- Firebase project configuration
- Service account creation
- Supabase Edge Function deployment
- Supabase secrets configuration
- APNs configuration (iOS)
- Paid Apple Developer account (iOS)

---

**Last Updated**: Based on current codebase state
**Version**: 1.0.0+17

