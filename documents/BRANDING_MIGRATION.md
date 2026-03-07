# Branding Migration - Removing RGS References

This document summarizes changes made to remove hardcoded RGS branding from the app.

## Configurable App Name

- **AppConfig.appName** – Reads from `.env` `APP_NAME` (default: "Tools")
- **AppConfig.appShortName** – Truncated version for compact UI

Set `APP_NAME=Your Brand Name` in `.env` to customize.

## Changes Made

### Code
- `lib/config/app_config.dart` – Added `appName`, `appShortName`; removed `rgs_` from database/API defaults
- `lib/widgets/common/app_logo.dart` – New generic logo widget (replaces `rgs_logo.dart`)
- `lib/screens/onboarding_screen.dart` – Uses `AppConfig.appName`
- `lib/main.dart` – Uses `AppConfig.appName` for title and splash
- `lib/services/report_service.dart` – Report filenames and headers use `AppConfig.appName`
- `lib/providers/pending_approvals_provider.dart` – Generic approval message
- `lib/providers/admin_notification_provider.dart` – Generic notification text
- `lib/screens/technician_registration_screen.dart` – Generic registration text
- `lib/screens/privacy_policy_screen.dart` – Generic privacy text
- `lib/services/firebase_messaging_service_*.dart` – Generic notification channel names
- `lib/utils/upload_logo_helper.dart` – Generic logo upload (renamed from RGS-specific)

### Platform
- **Android**: `android:label="Tools"`, notification channel `tools_notifications`
- **iOS**: `CFBundleDisplayName` and `CFBundleName` = "Tools"
- **Web**: `manifest.json` – "Tools - Professional Tools Management"

### Localization (arb)
- `appTitle` → "Tools" (en), "Herramientas" (es), "أدوات" (ar), "Outils" (fr)
- Removed RGS from login, registration, and approval strings

### Package
- `pubspec.yaml`: `name: toolsapp`, `description: "Professional Tools Management System"`

## Adding Your Icons and Logos

1. **App icons**: Replace assets in `android/app/src/main/res/`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
2. **Logo for UI**: Add your logo image to `assets/images/` and update `lib/widgets/common/app_logo.dart` to display it instead of text
3. **Supabase storage**: Use `UploadLogoHelper.uploadLogo()` or upload manually to the `tool-images` bucket as `logo.jpg`
