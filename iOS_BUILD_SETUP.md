# iOS Build Setup for AltStore Sideloading

This repository includes GitHub Actions workflows to automatically build iOS IPAs optimized for AltStore sideloading.

## Workflows

### 1. AltStore Build (`build-ios-dev.yml`) - **RECOMMENDED**
- **Trigger:** Push to main branch or manual dispatch
- **Output:** Release IPA optimized for AltStore
- **Purpose:** Sideloading without Apple Developer account
- **Installation:** AltStore on iOS device

### 2. Release Build (`build-ios.yml`)
- **Trigger:** Push to main branch or manual dispatch  
- **Output:** Release IPA with code signing
- **Purpose:** Production-ready builds
- **Requirements:** Apple Developer account and certificates

## AltStore Setup Instructions

### Prerequisites
1. **AltStore installed on your iOS device**
2. **AltServer running on your computer**
3. **No Apple Developer account required**

### Getting Your IPA

1. **Automatic Build:**
   - Push code to main branch
   - Go to Actions tab → Select latest "Build iOS IPA for AltStore Sideloading" run
   - Download the IPA artifact

2. **Manual Build:**
   - Go to Actions tab in GitHub
   - Select "Build iOS IPA for AltStore Sideloading" workflow
   - Click "Run workflow" → "Run workflow"
   - Wait for completion and download the IPA

### Installing with AltStore

1. **Download the IPA** from GitHub Actions artifacts
2. **Open AltStore** on your iOS device
3. **Tap the "+" button** in AltStore
4. **Select the IPA file** you downloaded
5. **Wait for installation** to complete
6. **Trust the developer certificate:**
   - Go to Settings → General → VPN & Device Management
   - Find your developer certificate and tap "Trust"

## Build Information

- **iOS Deployment Target:** 18.0
- **Flutter Version:** 3.24.0
- **Xcode Version:** 15.4
- **Bundle ID:** com.rgsapp.hvacToolsManager
- **Build Type:** Release (optimized for performance)

## AltStore Limitations

- **7-day validity:** Apps expire after 7 days
- **Refresh required:** Use AltStore to refresh apps before expiration
- **3 app limit:** Free AltStore accounts can install 3 apps max
- **Internet required:** AltServer needs internet connection for refresh

## Troubleshooting

### Common Issues

1. **"Unable to install" error**
   - Ensure AltServer is running on your computer
   - Check that your device is connected to the same WiFi network
   - Try refreshing AltStore first

2. **App crashes on launch**
   - Delete the app and reinstall
   - Ensure iOS version is 18.0 or higher
   - Check device storage space

3. **Build fails in GitHub Actions**
   - Check the Actions tab for detailed error logs
   - Ensure Flutter dependencies are up to date
   - Verify iOS deployment target settings

### Getting Help

- Check GitHub Actions logs for build issues
- AltStore documentation: https://altstore.io/
- Verify your iOS device meets requirements (iOS 18.0+)

## Benefits of This Setup

- ✅ **No Xcode required** on your local machine
- ✅ **No Apple Developer account** needed
- ✅ **Automatic builds** on code changes
- ✅ **Easy sideloading** with AltStore
- ✅ **iOS 18 compatibility** built-in
- ✅ **Release builds** for better performance
