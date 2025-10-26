# iOS Build Setup for GitHub Actions

This repository includes GitHub Actions workflows to automatically build iOS IPAs for testing.

## Workflows

### 1. Development Build (`build-ios-dev.yml`)
- **Trigger:** Push to main branch or manual dispatch
- **Output:** Debug IPA file
- **Purpose:** Quick testing builds without code signing
- **Installation:** Requires Xcode or Apple Configurator 2

### 2. Release Build (`build-ios.yml`)
- **Trigger:** Push to main branch or manual dispatch  
- **Output:** Release IPA with code signing
- **Purpose:** Production-ready builds
- **Requirements:** Apple Developer account and certificates

## Setup Instructions

### For Development Builds (Recommended for Testing)

1. **No additional setup required** - the development workflow will work immediately
2. **Access builds:** Go to Actions tab → Select workflow run → Download artifact
3. **Install on device:** Use Xcode or Apple Configurator 2

### For Release Builds (Requires Apple Developer Account)

1. **Get Apple Developer Certificates:**
   - Export your development certificate as `.p12` file
   - Note the password used for export

2. **Add GitHub Secrets:**
   - Go to repository Settings → Secrets and variables → Actions
   - Add these secrets:
     - `CERTIFICATES_P12`: Base64 encoded .p12 file content
     - `CERTIFICATES_P12_PASSWORD`: Password for the .p12 file
     - `APPSTORE_ISSUER_ID`: Your App Store Connect issuer ID
     - `APPSTORE_API_KEY_ID`: Your App Store Connect API key ID  
     - `APPSTORE_API_PRIVATE_KEY`: Your App Store Connect private key

3. **Update ExportOptions.plist:**
   - Replace `YOUR_TEAM_ID` with your actual Apple Developer Team ID

## Usage

### Manual Build
1. Go to Actions tab in GitHub
2. Select "Build iOS Development IPA" workflow
3. Click "Run workflow" → "Run workflow"
4. Wait for completion and download the IPA

### Automatic Build
- Pushes to main branch automatically trigger builds
- Check Actions tab for build status
- Download artifacts when build completes

## Build Artifacts

- **Development IPA:** Available for 7 days
- **Release IPA:** Available for 30 days
- **TestFlight:** Automatically uploaded (if configured)

## Troubleshooting

### Common Issues

1. **Build fails with "No iOS devices connected"**
   - This is normal for CI builds
   - The workflow uses `--no-codesign` flag for development builds

2. **Code signing errors**
   - Ensure certificates are properly exported and uploaded as secrets
   - Check that Team ID is correct in ExportOptions.plist

3. **Flutter version issues**
   - Update the flutter-version in workflow files if needed
   - Current version: 3.24.0

### Getting Help

- Check the Actions tab for detailed build logs
- Ensure all required secrets are properly configured
- Verify iOS deployment target matches your device (iOS 18.0)

## Build Information

- **iOS Deployment Target:** 18.0
- **Flutter Version:** 3.24.0
- **Xcode Version:** 15.4
- **Bundle ID:** com.rgsapp.hvacToolsManager
