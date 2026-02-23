# Badge Count on Homescreen - Implementation Details

## ✅ Implementation Status

The badge count feature **IS implemented** for when the app is closed or in the background (on the device homescreen).

## 🔄 How It Works

### When App is Closed/Terminated (Homescreen)

1. **Push Notification Arrives**
   - FCM sends notification to device
   - iOS/Android system receives notification

2. **Background Handler Executes**
   - `firebaseMessagingBackgroundHandler()` runs in a separate isolate
   - This handler works even when app is completely closed

3. **Badge is Updated**
   - `BadgeService.incrementBadge()` is called
   - Badge count is incremented in SharedPreferences
   - `FlutterAppBadger.updateBadgeCount()` updates the app icon badge
   - Badge appears on homescreen app icon

4. **Local Notification is Shown**
   - Notification is displayed in notification center
   - Badge number is included in notification payload
   - User sees notification with badge count

### When App is in Background

1. **Same Process as Terminated**
   - Background handler runs
   - Badge is updated
   - Notification is shown

### When App Opens

1. **Badge Syncs with Database**
   - `BadgeService.initializeBadge()` is called
   - Queries database for actual unread count
   - Updates badge to match database
   - Ensures accuracy

## 📱 Platform-Specific Behavior

### iOS
- ✅ Badge appears on app icon on homescreen
- ✅ Badge number is set via `FlutterAppBadger.updateBadgeCount()`
- ✅ Badge persists even when app is closed
- ✅ Badge number included in notification payload

### Android
- ✅ Badge appears on app icon (launcher-dependent)
- ✅ Badge number is set via `FlutterAppBadger.updateBadgeCount()`
- ✅ Notification shows badge number
- ✅ Badge persists even when app is closed

## 🔍 Code Flow

### Background Handler (`firebase_messaging_service.dart`)
```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Initialize Firebase (if needed)
  // 2. Initialize local notifications plugin
  // 3. Create notification channel
  // 4. Increment badge count
  await BadgeService.incrementBadge();
  // 5. Get updated badge count
  final badgeCount = await BadgeService.getBadgeCount();
  // 6. Show notification with badge number
  // 7. Badge appears on homescreen icon
}
```

### BadgeService (`badge_service.dart`)
```dart
static Future<void> incrementBadge() async {
  // 1. Get current count from SharedPreferences
  // 2. Increment by 1
  // 3. Save to SharedPreferences
  // 4. Update app icon badge via FlutterAppBadger
  await FlutterAppBadger.updateBadgeCount(badgeCount);
}
```

## ✅ Verification Checklist

To verify badge works on homescreen:

1. **Close the app completely** (swipe away from recent apps)
2. **Send a test push notification** from backend/Firebase Console
3. **Check homescreen** - Badge should appear on app icon
4. **Open notification** - Badge should persist
5. **Open app** - Badge should sync with database

## 🎯 Key Points

- ✅ Badge works when app is **closed/terminated**
- ✅ Badge works when app is in **background**
- ✅ Badge persists on **homescreen app icon**
- ✅ Badge syncs with database when **app opens**
- ✅ Badge updates in **real-time** when notifications arrive

## 🔧 Technical Details

### Background Handler Requirements
- Must be top-level function (not a class method)
- Must be marked with `@pragma('vm:entry-point')`
- Runs in separate isolate (can't access BuildContext)
- Can access SharedPreferences and native plugins

### Badge Persistence
- Badge count stored in SharedPreferences
- Persists across app restarts
- Synced with database on app launch
- Updated immediately when notifications arrive

## 📝 Notes

- The badge count is **incremented locally** when notification arrives in background
- When app opens, it **syncs with database** to ensure accuracy
- This approach ensures badge appears immediately, even if database query fails
- Badge count may be slightly off if multiple notifications arrive while app is closed, but syncs on app open

