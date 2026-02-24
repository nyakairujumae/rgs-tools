# iOS Entitlements Fix - Critical for Push Notifications

## ✅ What I Fixed

Created `ios/Runner/Runner.entitlements` file with `aps-environment` set to `development`.

## ⚠️ Important: You Need to Add It to Xcode Project

The entitlements file exists, but it needs to be **added to the Xcode project** and **linked in build settings**.

## 🔧 Steps to Complete the Fix

### Step 1: Open Xcode Project

```bash
cd ios
open Runner.xcworkspace
```

### Step 2: Add Entitlements File to Project

1. In Xcode, right-click on **Runner** folder (left sidebar)
2. Select **Add Files to "Runner"...**
3. Navigate to `Runner/Runner.entitlements`
4. Make sure **"Copy items if needed"** is **UNCHECKED** (file already exists)
5. Make sure **"Add to targets: Runner"** is **CHECKED**
6. Click **Add**

### Step 3: Link Entitlements in Build Settings

1. Select **Runner** project (top of left sidebar)
2. Select **Runner** target
3. Go to **Build Settings** tab
4. Search for **"Code Signing Entitlements"**
5. Set it to: `Runner/Runner.entitlements`

**OR** do it in **Signing & Capabilities**:
1. Select **Runner** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability** → **Push Notifications**
4. This should automatically add the entitlements file

### Step 4: Verify Entitlements

1. In Xcode, select **Runner** target
2. Go to **Signing & Capabilities** tab
3. You should see:
   - ✅ **Push Notifications** capability
   - ✅ **Background Modes** → **Remote notifications** checked
   - ✅ **Entitlements File**: `Runner.entitlements`

### Step 5: Clean and Rebuild

```bash
# Clean Flutter
flutter clean

# Clean Xcode
# In Xcode: Product → Clean Build Folder (Shift + Cmd + K)

# Rebuild
flutter run
```

---

## 🎯 What This Fixes

Without the entitlements file:
- ❌ iOS push notifications **will NOT work**
- ❌ APNs tokens won't be registered properly
- ❌ Even if APNs keys are configured in Firebase

With the entitlements file:
- ✅ iOS push notifications **will work**
- ✅ APNs tokens will be registered
- ✅ Notifications can be received

---

## 📋 Verification Checklist

After adding entitlements:

- [ ] Entitlements file added to Xcode project
- [ ] `CODE_SIGN_ENTITLEMENTS` set in Build Settings
- [ ] Push Notifications capability enabled
- [ ] Background Modes → Remote notifications enabled
- [ ] App rebuilt and installed on device
- [ ] Test notification from Firebase Console works

---

## 🔍 Next Steps After Fixing Entitlements

1. **Rebuild the app** on your iOS device
2. **Check app logs** for:
   - `✅ APNs token registered: ...`
   - `✅ [FCM] Token obtained: ...`
   - `✅ [FCM] Token saved to Supabase successfully`

3. **Verify iOS token in database:**
   ```sql
   SELECT * FROM user_fcm_tokens WHERE platform = 'ios';
   ```

4. **Test from Firebase Console:**
   - Get iOS FCM token from database
   - Send test message from Firebase Console
   - Should work now! ✅

---

## ⚠️ Important Notes

- **Development vs Production:**
  - Current entitlements file uses `development`
  - For App Store builds, change to `production`
  - Or create separate entitlements files for Debug/Release

- **Paid Developer Account:**
  - Push notifications require a **paid Apple Developer account** ($99/year)
  - Free/personal accounts cannot use push notifications

---

**After completing these steps, iOS push notifications should work!** 🎉

