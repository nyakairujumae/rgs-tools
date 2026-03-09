# iOS Push Notifications Fix Guide

## 🔍 Problem Diagnosis

**Symptom:** Test message from Firebase Console works on Android but NOT on iOS

**This means:**
- ✅ FCM tokens are valid (Android works)
- ✅ Firebase configuration is correct (Android works)
- ❌ **iOS-specific issue** - Most likely APNs not configured

---

## 🎯 Most Common Issue: APNs Not Configured in Firebase

### What is APNs?
- **APNs** = Apple Push Notification service
- iOS requires APNs to deliver push notifications
- Firebase needs APNs credentials to send notifications to iOS devices

### How to Check:
1. Go to **Firebase Console** → Your Project
2. Go to **Project Settings** (gear icon) → **Cloud Messaging** tab
3. Scroll to **Apple app configuration** section
4. Check if **APNs Authentication Key** or **APNs Certificates** are uploaded

**If empty/not configured:**
- ❌ This is why iOS notifications don't work
- ✅ This is why Android works (Android doesn't need APNs)

---

## ✅ Step-by-Step Fix

### Step 1: Create APNs Authentication Key

1. Go to **Apple Developer Portal**: https://developer.apple.com/account
2. Navigate to **Certificates, Identifiers & Profiles**
3. Go to **Keys** section
4. Click **+** (Create a new key)
5. Enter a name (e.g., "RGS Push Notifications Key")
6. Check **Apple Push Notifications service (APNs)**
7. Click **Continue** → **Register**
8. **Download the key** (`.p8` file) - **You can only download it once!**
9. **Note the Key ID** (shown on the page)

### Step 2: Upload APNs Key to Firebase

1. Go to **Firebase Console** → Your Project
2. Go to **Project Settings** (gear icon) → **Cloud Messaging** tab
3. Scroll to **Apple app configuration** section
4. Click **Upload** under **APNs Authentication Key**
5. Upload your `.p8` file
6. Enter:
   - **Key ID**: (from Step 1)
   - **Team ID**: (Your Apple Developer Team ID - found in Apple Developer Portal)
7. Click **Upload**

### Step 3: Verify iOS FCM Token is Saved

**Run this SQL in Supabase:**
```sql
SELECT user_id, platform, LEFT(fcm_token, 30) || '...' as token_preview, updated_at
FROM user_fcm_tokens
WHERE platform = 'ios'
ORDER BY updated_at DESC;
```

**Expected:**
- Should see iOS tokens with `platform = 'ios'`
- `updated_at` should be recent

**If no iOS tokens:**
- Check app logs for `✅ [FCM] Token saved to Supabase successfully`
- Check if iOS notification permissions are granted
- Verify user is logged in when token is obtained

### Step 4: Test Again

1. Get your iOS FCM token from database:
```sql
SELECT fcm_token FROM user_fcm_tokens WHERE platform = 'ios' LIMIT 1;
```

2. Go to **Firebase Console** → **Cloud Messaging** → **Send test message**
3. Enter your iOS FCM token
4. Enter title and body
5. Click **Test**

**Expected:** Notification should appear on iOS device

---

## 🔍 Additional Checks

### Check 1: iOS Notification Permissions

**On iOS Device:**
1. Go to **Settings** → **RGS** → **Notifications**
2. Verify **Allow Notifications** is **ON**
3. Check that **Lock Screen**, **Notification Center**, and **Banners** are enabled

**In App:**
- Check app logs for: `✅ [FCM] Notification permission granted`
- If denied, user needs to enable in Settings

### Check 2: iOS Entitlements

**File:** `ios/Runner/Runner.entitlements`

Should contain:
```xml
<key>aps-environment</key>
<string>development</string>
```

**For production builds:**
```xml
<key>aps-environment</key>
<string>production</string>
```

### Check 3: AppDelegate Configuration

**File:** `ios/Runner/AppDelegate.swift`

Should have:
```swift
override func application(_ application: UIApplication,
                        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
  // APNs token registration
  if FirebaseApp.app() != nil {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

### Check 4: Info.plist Background Modes

**File:** `ios/Runner/Info.plist`

Should contain:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

---

## 🐛 Troubleshooting

### Issue 1: "No iOS tokens in database"

**Symptoms:**
- SQL query returns no iOS tokens
- Android tokens exist but iOS don't

**Solutions:**
1. Check app logs for `✅ [FCM] Token saved to Supabase successfully`
2. Verify iOS notification permissions are granted
3. Check RLS policies on `user_fcm_tokens` table
4. Verify user is logged in when token is obtained
5. Check if `Platform.isIOS` is correctly detecting iOS

### Issue 2: "APNs key uploaded but still not working"

**Check:**
1. Verify Key ID matches the one in Apple Developer Portal
2. Verify Team ID is correct
3. Check if key has expired (APNs keys don't expire, but verify)
4. Try re-uploading the key
5. Check Firebase Console logs for APNs errors

### Issue 3: "Notification permissions denied"

**Solutions:**
1. Go to iOS Settings → RGS → Notifications → Enable
2. Reinstall app and grant permissions again
3. Check app logs for permission status

### Issue 4: "Test from Firebase Console works but app notifications don't"

**This means:**
- ✅ APNs is configured correctly
- ✅ FCM tokens are valid
- ❌ Edge Function might be the issue

**Check:**
1. Edge Function logs in Supabase
2. Verify Edge Function is sending to correct token
3. Check if Edge Function is handling iOS differently

---

## 📋 Quick Checklist

- [ ] APNs Authentication Key created in Apple Developer Portal
- [ ] APNs Key uploaded to Firebase Console
- [ ] Key ID and Team ID entered correctly in Firebase
- [ ] iOS FCM tokens exist in `user_fcm_tokens` table
- [ ] iOS notification permissions granted
- [ ] `aps-environment` set in `Runner.entitlements`
- [ ] `UIBackgroundModes` includes `remote-notification` in `Info.plist`
- [ ] AppDelegate has APNs token registration
- [ ] Test message from Firebase Console works

---

## 🎯 Most Likely Solution

**99% of the time, the issue is:**

❌ **APNs Authentication Key not uploaded to Firebase Console**

✅ **Fix:** Upload APNs key to Firebase Console (Steps 1-2 above)

---

## 📝 Next Steps

1. **Check Firebase Console** → Project Settings → Cloud Messaging → APNs configuration
2. **If empty:** Follow Steps 1-2 to create and upload APNs key
3. **Verify iOS tokens** in database (Step 3)
4. **Test again** from Firebase Console (Step 4)

If APNs is configured and iOS tokens exist, but notifications still don't work, check:
- Edge Function logs
- App logs when triggering notifications
- iOS device notification settings

