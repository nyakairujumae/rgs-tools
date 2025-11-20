# IPA Sideloading Guide

## ✅ IPA File Created Successfully

**Location**: `/Users/jumae/Desktop/rgs app/rgs-app.ipa`  
**Size**: ~15 MB  
**Status**: Built without code signing (unsigned)

## 📱 How to Sideload the IPA

### Option 1: Using Xcode (Recommended for Development)

1. **Connect your iPhone/iPad** to your Mac via USB
2. **Open Xcode** on your Mac
3. **Go to**: Window → Devices and Simulators
4. **Select your device** from the left sidebar
5. **Click the "+" button** under "Installed Apps"
6. **Navigate to** `/Users/jumae/Desktop/rgs app/rgs-app.ipa`
7. **Select the IPA file** and click "Open"
8. Xcode will sign and install the app on your device

**Note**: You'll need to trust the developer certificate on your device:
- Settings → General → VPN & Device Management
- Tap on your developer account
- Tap "Trust [Your Name]"

### Option 2: Using AltStore (Free, No Developer Account Needed)

1. **Install AltStore** on your Mac from [altstore.io](https://altstore.io)
2. **Install AltServer** on your Mac
3. **Install AltStore app** on your iPhone via AltServer
4. **Transfer the IPA** to your iPhone (via AirDrop, email, or cloud storage)
5. **Open AltStore** on your iPhone
6. **Tap the "+" button** and select the IPA file
7. AltStore will sign and install the app

**Limitations**: 
- Apps expire after 7 days (free account)
- Need to refresh weekly via AltServer
- Requires AltServer running on your Mac

### Option 3: Using Sideloadly (Free, Windows/Mac)

1. **Download Sideloadly** from [sideloadly.io](https://sideloadly.io)
2. **Connect your iPhone** to your computer
3. **Open Sideloadly**
4. **Select the IPA file**: `/Users/jumae/Desktop/rgs app/rgs-app.ipa`
5. **Enter your Apple ID** (or use an app-specific password)
6. **Click "Start"** to sign and install

**Note**: Sideloadly will use your Apple ID to sign the app. Apps expire after 7 days.

### Option 4: Using 3uTools (Windows/Mac)

1. **Download 3uTools** from [3u.com](https://www.3u.com)
2. **Connect your iPhone** to your computer
3. **Open 3uTools** and go to "Toolbox" → "IPA Installer"
4. **Drag and drop** the IPA file
5. **Click "Install"**

## ⚠️ Important Notes

### Push Notifications Disabled
- Push notifications capability has been **temporarily disabled** in the entitlements file
- This is because personal/free Apple Developer accounts don't support push notifications
- The app will work, but push notifications won't function until you:
  - Upgrade to a paid Apple Developer account ($99/year)
  - Re-enable push notifications in `ios/Runner/Runner.entitlements`

### Code Signing
- The IPA is **unsigned** (built with `--no-codesign`)
- You'll need to sign it during installation using one of the methods above
- Each signing method has different expiration times:
  - **Xcode**: 7 days (free account) or 1 year (paid account)
  - **AltStore**: 7 days (free account)
  - **Sideloadly**: 7 days (free account)

### Bundle Identifier
- Current: `com.rgs.app`
- Make sure this matches your Apple Developer account if using Xcode

## 🔧 Troubleshooting

### "Untrusted Developer" Error
1. Go to Settings → General → VPN & Device Management
2. Find your developer account
3. Tap "Trust [Your Name]"

### "App Installation Failed"
- Make sure you have enough storage space
- Try restarting your device
- Make sure the device is unlocked during installation

### "Provisioning Profile Expired"
- Apps signed with a free account expire after 7 days
- Re-install the app using the same method
- Consider upgrading to a paid Apple Developer account for 1-year validity

### Push Notifications Not Working
- This is expected - push notifications are disabled for free accounts
- Upgrade to a paid Apple Developer account to enable them
- Then re-enable in `ios/Runner/Runner.entitlements` and rebuild

## 📋 Next Steps

1. **Choose a sideloading method** from the options above
2. **Install the IPA** on your device
3. **Test the app** to make sure everything works
4. **For production**: Consider upgrading to a paid Apple Developer account for:
   - 1-year app validity
   - Push notifications support
   - App Store distribution (optional)

## 🔄 Rebuilding the IPA

If you need to rebuild the IPA:

```bash
cd "/Users/jumae/Desktop/rgs app"
flutter clean
flutter pub get
flutter build ios --release --no-codesign
mkdir -p build/ios/ipa/Payload
cp -r build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
cd build/ios/ipa
zip -r ../../../rgs-app.ipa Payload
cd ../../..
```

---

**IPA File**: `rgs-app.ipa` (15 MB)  
**Location**: `/Users/jumae/Desktop/rgs app/rgs-app.ipa`  
**Build Date**: November 20, 2025


