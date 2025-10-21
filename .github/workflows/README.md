# GitHub Actions CI/CD Workflows

This directory contains automated build workflows for the RGS Tools app.

## Available Workflows

### 1. Build iOS IPA (`build-ios.yml`)
- **Triggers**: Push to `main`, Pull requests, Manual dispatch
- **Runner**: macOS (required for iOS builds)
- **Outputs**: 
  - Debug IPA file
  - Uploaded as GitHub artifact (30 days retention)
  - Auto-release on version tags

### 2. Build Android APK (`build-android.yml`)
- **Triggers**: Push to `main`, Pull requests, Manual dispatch
- **Runner**: Ubuntu Linux
- **Outputs**:
  - Debug APK
  - Release APK
  - Release App Bundle (.aab)
  - All uploaded as GitHub artifacts

## How to Use

### Download Built Apps

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select a completed workflow run
4. Scroll to **Artifacts** section
5. Download the IPA or APK file

### Manual Build

1. Go to **Actions** tab
2. Select the workflow you want to run
3. Click **Run workflow** dropdown
4. Select branch and click **Run workflow**

### Create a Release

To automatically create a release with IPA/APK files:

```bash
# Tag your commit
git tag v1.0.0
git push origin v1.0.0
```

The workflow will automatically:
- Build the apps
- Create a GitHub release
- Attach the IPA and APK files

## iOS Production Builds (TestFlight/App Store)

For production iOS builds with proper code signing, you need to:

1. **Set up Apple Developer Account**
   - Enroll in Apple Developer Program ($99/year)
   - Create App ID in Apple Developer Portal

2. **Generate Certificates & Provisioning Profiles**
   - Distribution Certificate
   - App Store Provisioning Profile

3. **Add GitHub Secrets**
   Go to Repository Settings → Secrets and Variables → Actions:
   - `APPLE_CERTIFICATE_BASE64` - Base64 encoded P12 certificate
   - `APPLE_CERTIFICATE_PASSWORD` - Certificate password
   - `APPLE_PROVISIONING_PROFILE_BASE64` - Base64 encoded profile
   - `APP_STORE_CONNECT_API_KEY_ID` - App Store Connect API key
   - `APP_STORE_CONNECT_ISSUER_ID` - API issuer ID

4. **Enable TestFlight Upload**
   - Uncomment the TestFlight section in `build-ios.yml`
   - Change `if: false` to `if: true`

## Android Production Builds (Play Store)

For production Android builds with signing:

1. **Generate Upload Key**
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

2. **Create key.properties**
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

3. **Add GitHub Secrets**
   - `ANDROID_KEYSTORE_BASE64` - Base64 encoded keystore
   - `ANDROID_KEYSTORE_PASSWORD` - Keystore password
   - `ANDROID_KEY_ALIAS` - Key alias
   - `ANDROID_KEY_PASSWORD` - Key password

4. **Update build-android.yml**
   - Add keystore setup steps
   - Update build commands to use signing config

## Troubleshooting

### iOS Build Fails
- Check Xcode version compatibility
- Verify CocoaPods installation
- Check for platform-specific dependencies

### Android Build Fails
- Verify Java version (17 required)
- Check Gradle configuration
- Review dependency conflicts

### Artifacts Not Appearing
- Build must complete successfully
- Check workflow logs for errors
- Verify artifact paths are correct

## Notes

- **Debug builds** are not code-signed and are for testing only
- **Release builds** require proper certificates/keys
- Free GitHub accounts have limited Action minutes for private repos
- macOS runners consume minutes 10x faster than Linux runners

