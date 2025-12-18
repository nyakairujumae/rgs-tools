# Fix Duplicate Firebase Initialization

## 🔍 Problem Identified

**Symptoms:**
- ✅ Receiving 2 notifications for 1 test message
- ✅ iOS asks twice for notification permissions
- ✅ FCM tokens not being saved properly
- ✅ Multiple Firebase projects (development + production) configured

**Root Cause:**
Firebase is being initialized multiple times, causing:
- Duplicate message handlers
- Duplicate token generation
- Duplicate notification displays
- Conflicting Firebase configurations

## ✅ Fixes Applied

### 1. Added Initialization Guards

**In `lib/main.dart`:**
- ✅ Check if Firebase is already initialized before initializing
- ✅ Log existing Firebase apps to detect duplicates
- ✅ Skip duplicate initialization

**In `lib/services/firebase_messaging_service.dart`:**
- ✅ Added `_isInitialized` flag to prevent duplicate initialization
- ✅ Cancel existing subscriptions before creating new ones
- ✅ Check for multiple Firebase apps and warn
- ✅ Store subscriptions to cancel them if re-initialized

### 2. Handler Subscription Management

**Before:**
```dart
FirebaseMessaging.onMessage.listen(...) // Creates new subscription each time
```

**After:**
```dart
_foregroundSubscription?.cancel(); // Cancel existing first
_foregroundSubscription = FirebaseMessaging.onMessage.listen(...); // Store reference
```

## 🔧 How to Check for Duplicate Firebase Projects

### Step 1: Check Firebase Configuration Files

**Android:**
- Check `android/app/google-services.json`
- Should have ONE `project_info` section
- Should have ONE `project_number`

**iOS:**
- Check `ios/Runner/GoogleService-Info.plist`
- Should have ONE `PROJECT_ID`
- Should have ONE `GCM_SENDER_ID`

### Step 2: Check firebase_options.dart

Run this command to see what's configured:
```bash
cat lib/firebase_options.dart | grep -E "projectId|appId|apiKey"
```

**Expected:** One set of values per platform (android/ios)

**If you see multiple projects:**
- You may have development and production configs mixed
- Need to choose ONE project and remove the other

### Step 3: Check for Multiple Firebase Apps

The code now logs Firebase apps. Check logs for:
```
⚠️ [FCM] WARNING: Multiple Firebase apps detected (2)
⚠️ [FCM] App: [DEFAULT], Project: rgstools-dev
⚠️ [FCM] App: [DEFAULT], Project: rgstools-prod
```

**If you see this:** You have multiple Firebase projects initialized.

## 🛠️ How to Fix

### Option 1: Use Only One Firebase Project (Recommended)

1. **Choose which project to use:**
   - Development (for testing)
   - Production (for release)

2. **Update Firebase configuration:**
   ```bash
   # Remove old config
   rm android/app/google-services.json
   rm ios/Runner/GoogleService-Info.plist
   
   # Download new config from Firebase Console
   # For Android: Project Settings → Your apps → Download google-services.json
   # For iOS: Project Settings → Your apps → Download GoogleService-Info.plist
   
   # Regenerate firebase_options.dart
   flutterfire configure --project=YOUR_PROJECT_ID
   ```

3. **Verify single project:**
   ```bash
   # Check Android
   cat android/app/google-services.json | grep project_id
   
   # Check iOS
   cat ios/Runner/GoogleService-Info.plist | grep PROJECT_ID
   
   # Check Flutter
   cat lib/firebase_options.dart | grep projectId
   ```

**All should show the SAME project ID.**

### Option 2: Use Environment-Based Configuration

If you need both dev and prod:

1. **Create separate config files:**
   - `lib/firebase_options_dev.dart`
   - `lib/firebase_options_prod.dart`

2. **Use build flavors or environment variables:**
   ```dart
   // In main.dart
   final options = kDebugMode 
     ? DefaultFirebaseOptionsDev.currentPlatform
     : DefaultFirebaseOptionsProd.currentPlatform;
   
   await Firebase.initializeApp(options: options);
   ```

3. **Ensure only ONE is used at a time**

## 🧪 Testing After Fix

1. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Check logs on app start:**
   ```
   ✅ Firebase initialized successfully
   ✅ Firebase project: rgstools
   ✅ [FCM] Firebase is initialized (1 app(s))
   ```

3. **Test notification:**
   - Send ONE test message from Firebase Console
   - Should receive ONE notification (not two)
   - iOS should ask for permission ONCE (on first install)

4. **Check for duplicate handlers:**
   - Look for: `⚠️ [FCM] Already initialized, skipping`
   - Should NOT see this on first launch
   - Should see this if initialize() is called twice

## 📋 Checklist

- [ ] Only ONE Firebase project configured
- [ ] `google-services.json` has one project
- `GoogleService-Info.plist` has one project
- [ ] `firebase_options.dart` has one project per platform
- [ ] Logs show "1 app(s)" not "2 app(s)"
- [ ] Test notification sends once, receives once
- [ ] iOS permission asked once on new install
- [ ] No duplicate initialization warnings in logs

## 🐛 If Still Getting Duplicates

1. **Check if initialize() is called multiple times:**
   - Search codebase for `FirebaseMessagingService.initialize()`
   - Should only be called in `main.dart`

2. **Check for hot reload issues:**
   - Hot reload can cause duplicate handlers
   - Do a full restart (stop app, rebuild, run)

3. **Check background handler:**
   - `onBackgroundMessage` can only be called once
   - Subsequent calls are ignored, but check logs

4. **Check for multiple Firebase instances:**
   - Look for `Firebase.initializeApp()` calls
   - Should only be in `main.dart`

## ✅ Expected Behavior After Fix

- ✅ One Firebase project configured
- ✅ One notification per message
- ✅ One permission request on iOS
- ✅ One FCM token per platform per user
- ✅ Logs show "1 app(s)" not multiple
- ✅ No duplicate initialization warnings
