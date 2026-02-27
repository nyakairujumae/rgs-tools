# Deployment Targets Fix for Firebase

## Issue
Firebase initialization is failing with `PlatformException(channel-error, Unable to establish connection on channel.)`. This can be caused by deployment target mismatches.

## Requirements

### iOS
- **Minimum**: iOS 13.0 (Firebase requirement)
- **Current**: iOS 15.0 (Podfile)
- **Status**: ✅ Correct, but pods need to be enforced

### Android
- **Minimum**: API 21 (Android 5.0 Lollipop) - Firebase requirement
- **Current**: Using Flutter defaults (typically 21+)
- **Status**: ✅ Should be correct

## Changes Made

### 1. iOS Podfile Update
Updated the `post_install` script to ensure ALL pods use at least iOS 13.0:

```ruby
# CRITICAL: Ensure all pods use at least iOS 13.0 (Firebase requirement)
current_target = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
if current_target.nil? || current_target.to_f < 13.0
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
end
```

### 2. Next Steps

1. **Clean and reinstall pods:**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

2. **Clean Flutter build:**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Rebuild the app:**
   ```bash
   flutter run
   ```

## Verification

### iOS
- Podfile platform: `platform :ios, '15.0'` ✅
- Xcode project: `IPHONEOS_DEPLOYMENT_TARGET = 15.0` ✅
- Pod enforcement: All pods ≥ 13.0 ✅

### Android
- Default Flutter minSdk: 21+ ✅
- Firebase requirement: 21+ ✅

## Additional Notes

The channel-error might also be related to:
1. Flutter-to-native bridge not being ready (already handled with retry logic)
2. Pod installation issues (fixed with deployment target enforcement)
3. Xcode build settings mismatch (should be resolved after pod reinstall)

After running the steps above, Firebase should initialize successfully.


