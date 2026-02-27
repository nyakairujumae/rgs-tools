# Firebase Push Notifications - Complete Setup Guide

## 🔥 Step 1: Firebase Console Setup

### 1.1 Create/Verify Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **rgstools** (or create a new one if needed)
3. Project ID: `rgstools`
4. Make sure you're in the correct project

### 1.2 Add iOS App to Firebase

1. In Firebase Console, click **"Add app"** → Select **iOS**
2. **iOS bundle ID**: `com.rgs.app`
3. **App nickname** (optional): `RGS Tools iOS`
4. **App Store ID** (optional): Leave blank for now
5. Click **"Register app"**

### 1.3 Download GoogleService-Info.plist

1. After registering, download **GoogleService-Info.plist**
2. **IMPORTANT**: Place it in: `ios/Runner/GoogleService-Info.plist`
3. Make sure it's in the correct location (not in a subfolder)

### 1.4 Add Android App to Firebase (if needed)

1. In Firebase Console, click **"Add app"** → Select **Android**
2. **Android package name**: `com.rgs.app`
3. **App nickname** (optional): `RGS Tools Android`
4. Click **"Register app"**
5. Download **google-services.json**
6. Place it in: `android/app/google-services.json`

### 1.5 Enable Cloud Messaging API

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **"Cloud Messaging API (Legacy)"**
3. Make sure it's **enabled**
4. Also check **"Cloud Messaging API (V1)"** is enabled

### 1.6 Get Server Key (for Supabase/Backend)

1. In Firebase Console, go to **Project Settings** → **Cloud Messaging** tab
2. Under **"Cloud Messaging API (Legacy)"**, find **"Server key"**
3. Copy this key - you'll need it if you want to send notifications from your backend
4. **Note**: Keep this key secret!

### 1.7 Configure APNs for iOS (Required for iOS Push)

1. In Firebase Console, go to **Project Settings** → **Cloud Messaging** tab
2. Scroll to **"Apple app configuration"**
3. You need to upload your **APNs Authentication Key** or **APNs Certificates**:
   - **Option A (Recommended)**: Upload APNs Authentication Key (.p8 file)
     - Go to Apple Developer → Certificates, Identifiers & Profiles
     - Create an APNs Authentication Key
     - Download the .p8 file
     - Upload it to Firebase Console
   - **Option B**: Upload APNs Certificates (.p12 file)
     - Create APNs Certificate in Apple Developer
     - Download and upload to Firebase

### 1.8 Verify Configuration

1. In Firebase Console, go to **Project Settings**
2. Under **"Your apps"**, verify:
   - ✅ iOS app is listed with bundle ID: `com.rgs.app`
   - ✅ Android app is listed (if using Android)
3. Check that **GoogleService-Info.plist** is downloaded and in the correct location

---

## 📱 Step 2: iOS Xcode Configuration

### 2.1 Add GoogleService-Info.plist to Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click on **Runner** folder in Project Navigator
3. Select **"Add Files to Runner..."**
4. Navigate to `ios/Runner/GoogleService-Info.plist`
5. Make sure **"Copy items if needed"** is checked
6. Make sure **"Runner"** target is selected
7. Click **"Add"**

### 2.2 Enable Push Notifications Capability

1. In Xcode, select **Runner** target
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"**
4. Add **"Push Notifications"**
5. Add **"Background Modes"** and check:
   - ✅ Remote notifications

### 2.3 Verify Info.plist

1. Open `ios/Runner/Info.plist`
2. Make sure it contains:
   - `CFBundleIdentifier`: `com.rgs.app`
   - Background modes for remote notifications

---

## 🤖 Step 3: Android Configuration

### 3.1 Add google-services.json

1. Place `google-services.json` in `android/app/` directory
2. Make sure it's in the correct location

### 3.2 Update build.gradle

1. Open `android/build.gradle` (project level)
2. Make sure you have:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```

3. Open `android/app/build.gradle`
4. At the bottom, add:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### 3.3 Update AndroidManifest.xml

1. Open `android/app/src/main/AndroidManifest.xml`
2. Make sure you have:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```

---

## ✅ Step 4: Verification Checklist

Before proceeding to code implementation, verify:

- [ ] Firebase project created: `rgstools`
- [ ] iOS app added with bundle ID: `com.rgs.app`
- [ ] Android app added with package: `com.rgs.app` (if using Android)
- [ ] `GoogleService-Info.plist` downloaded and placed in `ios/Runner/`
- [ ] `google-services.json` downloaded and placed in `android/app/` (if using Android)
- [ ] APNs Authentication Key or Certificate uploaded to Firebase Console
- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes enabled in Xcode
- [ ] Cloud Messaging API enabled in Firebase Console

---

## 🧪 Step 5: Test Push Notification

Once code is implemented, test with:

1. **Firebase Console Test**:
   - Go to Firebase Console → Cloud Messaging
   - Click **"Send test message"**
   - Enter your FCM token (from app logs)
   - Send notification
   - Check if it appears on device

2. **Check Logs**:
   - Look for FCM token in app logs
   - Verify token is saved to Supabase
   - Check for any initialization errors

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Setup](https://firebase.flutter.dev/docs/overview)
- [iOS Push Notifications Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)

---

**Once you've completed these steps, let me know and I'll implement the code side!**



