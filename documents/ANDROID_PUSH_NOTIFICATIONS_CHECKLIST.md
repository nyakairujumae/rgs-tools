# Android Push Notifications Setup Checklist

## ✅ Configuration Status

### 1. **Firebase Configuration** ✅
- [x] `google-services.json` exists in `android/app/`
- [x] Project ID: `rgstools`
- [x] Package name: `com.rgs.app` (matches)
- [x] Google Services plugin applied in `build.gradle.kts`
- [x] Firebase dependencies in `pubspec.yaml`:
  - `firebase_core: 2.32.0`
  - `firebase_messaging: 14.7.10`
  - `flutter_local_notifications: 17.2.1`

### 2. **AndroidManifest.xml** ✅
- [x] `POST_NOTIFICATIONS` permission declared (Android 13+)
- [x] FCM default notification icon: `@mipmap/ic_launcher`
- [x] FCM default notification channel: `rgs_notifications` ✅ (FIXED - was `default_channel`)
- [x] MainActivity has `launchMode="singleTop"` (good for notifications)

### 3. **Notification Channel** ✅
- [x] Channel ID: `rgs_notifications`
- [x] Channel Name: `RGS Notifications`
- [x] Channel created in code with `Importance.high`
- [x] Channel matches AndroidManifest default channel

### 4. **Code Implementation** ✅
- [x] Firebase initialized in `main.dart`
- [x] FCM service initialized
- [x] Background message handler registered
- [x] Local notifications initialized
- [x] Token saved to Supabase `user_fcm_tokens` table
- [x] Foreground message handler set up
- [x] Background message handler implemented

### 5. **Build Configuration** ✅
- [x] Google Services plugin version: `4.4.0`
- [x] Compile SDK: 36
- [x] Kotlin configured

## ⚠️ Potential Issues to Check

### 1. **Internet Permission** (Usually auto-added, but verify)
Check if `INTERNET` permission is present (usually auto-added by Flutter, but verify in AndroidManifest.xml)

### 2. **ProGuard Rules** (If using release builds)
If you're building release APK with ProGuard, ensure Firebase classes aren't being stripped:
```proguard
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
```

### 3. **Notification Icon**
- Verify `@mipmap/ic_launcher` exists (✅ confirmed in res folder)
- For better notifications, consider creating a white/transparent icon specifically for notifications

### 4. **MinSdk Version**
- Check if `minSdk` supports all Firebase features (should be 21+)
- POST_NOTIFICATIONS requires API 33+ (Android 13)

## 🔍 Testing Steps

### Step 1: Verify Token Generation
1. Run app on real Android device
2. Check logs for: `✅ [FCM] Token obtained: ...`
3. Check logs for: `✅ [FCM] Token saved to Supabase successfully`
4. Verify token exists in Supabase `user_fcm_tokens` table

### Step 2: Test from Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send test message"
3. Enter the FCM token from logs
4. Send notification
5. Check if notification appears on device

### Step 3: Test from Your Backend
1. Use FCM REST API or Admin SDK
2. Send to the token
3. Verify notification appears

### Step 4: Test Different App States
- **Foreground**: App open → Should show local notification
- **Background**: App minimized → Should show system notification
- **Terminated**: App closed → Should show system notification when tapped

## 🐛 Common Issues & Solutions

### Issue: Token not generated
**Solution**: 
- Check Firebase initialization logs
- Verify `google-services.json` is correct
- Ensure device has Google Play Services
- Check for permission errors

### Issue: Token generated but notifications not received
**Solution**:
- Verify token is saved to Supabase
- Check Firebase Console → Cloud Messaging → check if message was sent
- Verify notification payload has `notification` field (not just `data`)
- Check device notification settings for the app

### Issue: Notifications work in foreground but not background
**Solution**:
- Verify background handler is registered before `runApp()`
- Check background handler implementation
- Ensure local notifications plugin is initialized in background handler

### Issue: Notifications don't appear at all
**Solution**:
- Check device notification permissions (Settings → Apps → RGS → Notifications)
- Verify notification channel is created
- Check if battery optimization is blocking notifications
- Verify `google-services.json` matches Firebase project

## 📝 Next Steps

1. **Test on real device** (not emulator - emulators may not have Google Play Services)
2. **Check Supabase `user_fcm_tokens` table** - verify token is being saved
3. **Send test notification from Firebase Console** using the saved token
4. **Check device logs** for any FCM errors
5. **Verify notification channel** is created (check Android system settings)

## 🔗 Useful Commands

```bash
# Check if token is in Supabase
# Run in Supabase SQL Editor:
SELECT * FROM user_fcm_tokens WHERE platform = 'android' ORDER BY updated_at DESC;

# Check Android logs
adb logcat | grep -i "fcm\|firebase\|notification"
```

## ✅ Summary

**Everything looks correctly configured!** The main fix was updating the notification channel ID from `default_channel` to `rgs_notifications` to match the code.

**If notifications still don't work:**
1. Test on a **real device** (not emulator)
2. Verify the **FCM token is being generated and saved**
3. Send a **test notification from Firebase Console** using the exact token
4. Check **device notification settings** for the app
5. Review **device logs** for FCM errors



