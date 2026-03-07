# iOS Push Notifications Diagnosis

## ✅ What's Already Configured

1. ✅ **APNs Authentication Keys** - Uploaded to Firebase Console (Development & Production)
2. ✅ **AppDelegate.swift** - Has APNs token registration
3. ✅ **Info.plist** - Has `UIBackgroundModes` with `remote-notification`
4. ✅ **Firebase Messaging Service** - Code exists to save iOS tokens

## 🔍 What to Check Next

Since APNs is configured but iOS notifications don't work, check these:

### Step 1: Verify iOS FCM Tokens Are Saved

**Run this SQL in Supabase:**
```sql
SELECT * FROM user_fcm_tokens WHERE platform = 'ios';
```

**Expected:** Should see iOS tokens with `platform = 'ios'`

**If no iOS tokens:**
- Check app logs for `✅ [FCM] Token saved to Supabase successfully`
- Check if iOS notification permissions are granted
- Verify user is logged in when token is obtained

### Step 2: Check iOS Notification Permissions

**On iOS Device:**
1. Go to **Settings** → **RGS** → **Notifications**
2. Verify **Allow Notifications** is **ON**
3. Check that **Lock Screen**, **Notification Center**, and **Banners** are enabled

**In App Logs:**
- Look for: `✅ [FCM] Notification permission granted`
- If you see permission denied, user needs to enable in Settings

### Step 3: Check iOS Entitlements

**Check if entitlements file exists:**
- Look for `ios/Runner/Runner.entitlements` or similar
- Should contain:
```xml
<key>aps-environment</key>
<string>development</string>
```
(Or `production` for release builds)

**If missing:**
- Need to create entitlements file
- Add to Xcode project
- Enable Push Notifications capability in Xcode

### Step 4: Verify You're Testing on Real Device

**Important:** Push notifications **DO NOT WORK** on iOS Simulator
- Must test on **real iOS device**
- Simulator cannot receive APNs notifications

### Step 5: Check App Logs When Getting FCM Token

**When app starts, look for:**
- `✅ [FCM] Notification permission granted`
- `✅ APNs token registered: ...` (from AppDelegate)
- `✅ [FCM] Token obtained: ...`
- `✅ [FCM] Token saved to Supabase successfully`

**If you see errors:**
- `❌ [FCM] Error getting token` - Check permissions
- `❌ [FCM] Error saving token` - Check RLS policies

### Step 6: Test Token from Firebase Console

1. Get your iOS FCM token from database:
```sql
SELECT fcm_token FROM user_fcm_tokens WHERE platform = 'ios' LIMIT 1;
```

2. Go to **Firebase Console** → **Cloud Messaging** → **Send test message**
3. Enter your iOS FCM token
4. Enter title and body
5. Click **Test**

**If this works:**
- ✅ Token is valid
- ✅ APNs is configured correctly
- Issue might be with Edge Function or app code

**If this doesn't work:**
- ❌ Token might be invalid
- ❌ APNs configuration issue
- ❌ Device/permission issue

---

## 🎯 Most Likely Issues (in order)

1. **iOS FCM tokens not being saved** - Check database first
2. **Missing entitlements file** - Check if `Runner.entitlements` exists
3. **Notification permissions not granted** - Check device settings
4. **Testing on simulator** - Must use real device
5. **Entitlements not linked in Xcode** - Check Xcode project settings

---

## 📋 Quick Diagnostic Checklist

- [ ] Run SQL query to check iOS tokens exist
- [ ] Check iOS notification permissions on device
- [ ] Verify entitlements file exists and has `aps-environment`
- [ ] Confirm testing on real device (not simulator)
- [ ] Check app logs for FCM token saving
- [ ] Test token from Firebase Console directly

---

## 🔧 Next Steps

1. **First:** Run `VERIFY_IOS_PUSH_NOTIFICATIONS.sql` to check if iOS tokens exist
2. **Second:** Check iOS device notification settings
3. **Third:** Verify entitlements file exists
4. **Fourth:** Test from Firebase Console with iOS token

Share the results and we can pinpoint the exact issue!

