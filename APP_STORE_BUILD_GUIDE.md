# App Store Connect Build Guide

## Version and Build Number

**Current Version:** `1.0.0+2`
- **Version Number (CFBundleShortVersionString):** `1.0.0` - User-facing version
- **Build Number (CFBundleVersion):** `2` - Must be incremented for each App Store upload

## For Each New Build

### If keeping the same version (1.0.0):
1. **Increment build number only** in `pubspec.yaml`:
   ```yaml
   version: 1.0.0+3  # Increment the number after the +
   ```

### If releasing a new version:
1. **Update version number** in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+1  # New version, reset build to 1
   ```

## Building for App Store Connect

### Option 1: Using Xcode (Recommended)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" or "Generic iOS Device" as the target
3. Go to **Product** → **Archive**
4. Once archived, click **Distribute App**
5. Select **App Store Connect**
6. Follow the distribution wizard

### Option 2: Using Flutter Command Line
```bash
# Build the iOS app
flutter build ipa --release

# The IPA will be at: build/ios/ipa/rgs.ipa
# Upload this to App Store Connect via:
# - Xcode Organizer (Window → Organizer)
# - Transporter app
# - App Store Connect website
```

### Option 3: Using Fastlane (if configured)
```bash
fastlane ios beta  # For TestFlight
fastlane ios release  # For App Store
```

## Important Notes

1. **Build Number Must Be Unique**: Each build uploaded to App Store Connect must have a unique, incrementing build number. You cannot reuse build numbers.

2. **Version vs Build**:
   - **Version** (1.0.0): What users see in the App Store
   - **Build** (+2): Internal tracking number, must always increment

3. **TestFlight**: You can upload multiple builds with the same version number, but each must have a unique build number.

4. **App Store Review**: When submitting for review, you can use the same version number, but the build number must be higher than any previously submitted build.

## Current Configuration

- **Bundle ID:** `com.rgs.app`
- **App Name:** RGS
- **Version:** 1.0.0
- **Build:** 2

## Next Steps

1. ✅ Build number incremented to 2
2. Build the app using one of the methods above
3. Upload to App Store Connect
4. For next build, increment to `1.0.0+3`


