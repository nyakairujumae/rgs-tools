# FCM Notifications Fix Guide

## ✅ Issues Fixed

### 1. Push Notifications Re-enabled
- **Fixed**: Re-enabled `aps-environment` in `ios/Runner/Runner.entitlements`
- **Note**: This requires a **paid Apple Developer account** ($99/year) for push notifications to work
- **For sideloading**: Push notifications won't work with a free/personal developer account

### 2. Background Message Handler Registered
- **Fixed**: Registered `firebaseMessagingBackgroundHandler` in `main.dart`
- **What it does**: Handles notifications when app is in background or terminated

### 3. iOS Notification Permissions
- **Fixed**: Added notification permission request in `AppDelegate.swift`
- **What it does**: Requests notification permissions on app launch

### 4. AppDelegate Updated
- **Fixed**: Added APNs token registration handlers
- **What it does**: Registers device token with Apple Push Notification service

## ⚠️ Important Notes

### Push Notifications Require Paid Developer Account
- **Free/Personal Developer Account**: Push notifications **WILL NOT WORK**
- **Paid Developer Account ($99/year)**: Push notifications **WILL WORK**
- This is an Apple limitation, not a code issue

### For Testing Without Paid Account
You can test notifications locally using:
1. **Local notifications** (work without paid account)
2. **Foreground notifications** (work without paid account)
3. **Badge updates** (work without paid account)

## 🔍 Troubleshooting Steps

### 1. Check Notification Permissions
1. Go to **Settings** → **RGS** → **Notifications**
2. Make sure notifications are **enabled**
3. Check that **Allow Notifications** is **ON**
4. Enable **Badges**, **Sounds**, and **Alerts**

### 2. Check Console Logs
When the app starts, look for these messages:
- `✅ Notification permission granted`
- `✅ APNs token registered: ...`
- `🔥 FCM Token: ...`
- `✅ FCM token saved to Supabase successfully`

### 3. Check FCM Token in Supabase
1. Go to **Supabase Dashboard** → **Table Editor** → `user_fcm_tokens`
2. Check if your user has an FCM token saved
3. Verify the token is not null/empty

### 4. Test Notification Sending
You can test notifications using:
- **Firebase Console** → **Cloud Messaging** → **Send test message**
- Enter your FCM token
- Send a test notification

### 5. Check Badge Support
The app checks if badges are supported:
- iOS: Badges are supported
- Android: Badges depend on device/launcher

## 📱 Testing Notifications

### Test 1: Foreground Notifications
1. Open the app
2. Send a test notification from Firebase Console
3. You should see a notification appear

### Test 2: Background Notifications
1. Put the app in background (home button)
2. Send a test notification
3. You should see a notification appear

### Test 3: Badge Count
1. Receive a notification
2. Check the app icon badge count
3. Badge should increment

### Test 4: Registration Notification
1. Register a new technician account
2. Admin should receive a notification (if backend is set up)
3. Check admin's device for notification

## 🔧 Backend Setup Required

For notifications to be sent when a new user registers, you need:

1. **Supabase Function or Edge Function** that:
   - Listens for new registrations in `pending_user_approvals` table
   - Sends FCM notification to admins
   - Uses FCM tokens from `user_fcm_tokens` table

2. **Firebase Cloud Messaging API** configured in your backend

## 📋 Checklist

- [x] Push notifications re-enabled in entitlements
- [x] Background message handler registered
- [x] iOS notification permissions requested
- [x] AppDelegate updated with APNs handlers
- [ ] **Paid Apple Developer account** (required for push notifications)
- [ ] Notification permissions granted on device
- [ ] FCM token saved to Supabase
- [ ] Backend function to send notifications on registration
- [ ] Test notification sent successfully

## 🚨 Common Issues

### Issue 1: "No notifications appearing"
**Possible causes**:
- Free developer account (push notifications won't work)
- Notification permissions not granted
- FCM token not saved to Supabase
- Backend not sending notifications

**Solution**:
1. Check notification permissions in Settings
2. Check console logs for FCM token
3. Verify token is saved in Supabase
4. Test with Firebase Console

### Issue 2: "Badge not showing"
**Possible causes**:
- Badge permissions not granted
- Badge count not being updated
- Device doesn't support badges

**Solution**:
1. Check badge permission in Settings
2. Check console logs for badge updates
3. Verify `FlutterAppBadger.isAppBadgeSupported()` returns true

### Issue 3: "Notifications work in foreground but not background"
**Possible causes**:
- Background handler not registered
- APNs token not registered
- App not configured for background notifications

**Solution**:
1. Verify background handler is registered in `main.dart`
2. Check APNs token registration in console
3. Verify `UIBackgroundModes` includes `remote-notification` in Info.plist

## 📝 Next Steps

1. **Rebuild the app** with the fixes
2. **Test notification permissions** - grant when prompted
3. **Check console logs** for FCM token and APNs registration
4. **Verify token is saved** in Supabase `user_fcm_tokens` table
5. **Set up backend function** to send notifications on registration
6. **Test with Firebase Console** to verify notifications work

---

**Note**: Push notifications require a paid Apple Developer account. For testing without a paid account, you can use local notifications or test on Android.

