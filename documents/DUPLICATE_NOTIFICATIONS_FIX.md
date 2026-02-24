# Fix Duplicate Notifications

## 🔍 Root Cause Identified

**Problem:** Receiving 2 notifications for 1 message

**Causes:**
1. ✅ **Fixed:** Duplicate handler subscriptions (now cancels old ones)
2. ✅ **Fixed:** Duplicate initialization (now has guards)
3. ✅ **Fixed:** Background handler showing duplicate local notification

**The Issue:**
- When app is in **background**, the system automatically shows notifications
- The background handler was ALSO showing a local notification
- This caused **duplicate notifications** (system + local)

## ✅ Fixes Applied

### 1. Prevent Duplicate Handler Subscriptions

**Before:**
```dart
FirebaseMessaging.onMessage.listen(...) // Creates new subscription each time
```

**After:**
```dart
_foregroundSubscription?.cancel(); // Cancel existing first
_foregroundSubscription = FirebaseMessaging.onMessage.listen(...); // Store reference
```

### 2. Prevent Duplicate Initialization

**Added:**
- `_isInitialized` flag to prevent duplicate `initialize()` calls
- Check in `main.dart` to skip Firebase init if already initialized
- Logs existing Firebase apps to detect duplicates

### 3. Fix Background Handler Duplicate Notifications

**Before:**
- Background handler always showed local notification
- System also showed notification automatically
- Result: 2 notifications

**After:**
- Background handler checks if message has `notification` payload
- If yes: System shows it automatically, handler only updates badge
- If no: Handler shows local notification (data-only message)
- Result: 1 notification

## 📋 How It Works Now

### Foreground (App Open)
1. `onMessage.listen()` receives message
2. Shows local notification via `flutter_local_notifications`
3. Updates badge
4. **Result:** 1 notification

### Background (App Minimized)
1. System automatically shows notification (if message has `notification` payload)
2. Background handler runs
3. Handler checks: Has notification payload?
   - **Yes:** Skip local notification, only update badge
   - **No:** Show local notification (data-only message)
4. **Result:** 1 notification (system OR local, not both)

### Terminated (App Closed)
1. System automatically shows notification (if message has `notification` payload)
2. Background handler runs when app is opened
3. Handler checks: Has notification payload?
   - **Yes:** Skip local notification, only update badge
   - **No:** Show local notification (data-only message)
4. **Result:** 1 notification (system OR local, not both)

## 🧪 Testing

1. **Test foreground notification:**
   - Open app
   - Send test message from Firebase Console
   - **Expected:** 1 notification

2. **Test background notification:**
   - Minimize app (don't close)
   - Send test message from Firebase Console
   - **Expected:** 1 notification (system shows it)

3. **Test terminated notification:**
   - Close app completely
   - Send test message from Firebase Console
   - **Expected:** 1 notification (system shows it)

4. **Check logs:**
   - Should see: `📱 [FCM] Setting up message handlers (previous subscriptions cancelled)`
   - Should see: `✅ [FCM] Firebase is initialized (1 app(s))`
   - Should NOT see: `⚠️ [FCM] Already initialized` (on first launch)

## ✅ Expected Behavior

- ✅ One notification per message
- ✅ iOS permission asked once (on first install)
- ✅ Logs show "1 app(s)" not multiple
- ✅ No duplicate initialization warnings
- ✅ Background handler doesn't show duplicate local notification

## 🐛 If Still Getting Duplicates

1. **Check logs for:**
   - `⚠️ [FCM] Already initialized` - Should only see on hot reload, not first launch
   - `⚠️ [FCM] WARNING: Multiple Firebase apps detected` - Should NOT see this
   - `📱 [FCM] Setting up message handlers` - Should only see once per app launch

2. **Do a full restart:**
   - Stop app completely
   - Clean build: `flutter clean && flutter pub get`
   - Rebuild and run

3. **Check for hot reload issues:**
   - Hot reload can cause duplicate handlers
   - Always do full restart when testing notifications

4. **Verify Firebase configuration:**
   - Only ONE project configured (you already verified this ✅)
   - Both Android and iOS use same project ID: `rgstools`

## 📝 Summary

**What was fixed:**
1. ✅ Duplicate handler subscriptions prevented
2. ✅ Duplicate initialization prevented
3. ✅ Background handler duplicate notifications fixed

**Result:**
- One notification per message
- No duplicate handlers
- No duplicate initialization
- Clean, production-ready implementation
