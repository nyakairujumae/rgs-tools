# Apple App Store Review – What Apple May Flag

Analysis of the RGS Tools app for common App Store rejection reasons and guideline compliance.

---

## Critical (fix before submit)

### 1. **Info.plist – App Transport Security (ATS)**
- **Issue:** `NSExceptionDomains` contains a placeholder key **"New Exception Domain"** and allows insecure HTTP (`NSExceptionAllowsInsecureHTTPLoads: true`).
- **Apple:** Can reject for vague/invalid ATS configuration or allowing unencrypted traffic without a clear, justified exception.
- **Fix:** Remove this exception if all your APIs (e.g. Supabase) use HTTPS. If you truly need HTTP for a specific host, replace `"New Exception Domain"` with the **exact domain** (e.g. `your-api.example.com`) and keep the exception as narrow as possible.

### 2. **Microphone usage description – unused capability**
- **Issue:** `NSMicrophoneUsageDescription` says "for video recording features", but the app does not use `video_player` (or any video recording) in `lib/`. Only camera and photo library are used for tool images.
- **Apple:** Rejections common for declaring permissions or capabilities that the app doesn’t use (Guideline 5.1.1 / 2.5.13).
- **Fix:** Remove `NSMicrophoneUsageDescription` from `Info.plist` unless you add real video+audio recording. If you keep it, the app must actually use the microphone.

### 3. **Push notifications – release entitlement**
- **Issue:** `ios/Runner/RunnerRelease.entitlements` has `aps-environment: development`. For App Store and TestFlight distribution, it should be **production** so push works in production.
- **Fix:** For release/archive builds you intend to submit, ensure the entitlement is `production` (Xcode often sets this via the Signing & Capabilities tab). If you keep `development` in the file, confirm your archive build doesn’t use it for submission.

---

## High priority (recommended)

### 4. **Privacy manifest (PrivacyInfo.xcprivacy)**
- **Issue:** No `PrivacyInfo.xcprivacy` in the project. Apple requires a privacy manifest when the app (or its SDKs) uses certain “required reason” APIs (e.g. file timestamp, UserDefaults, system boot time).
- **Apple:** Since May 2024, new/updated apps can be rejected if they use these APIs without declaring approved reasons in a privacy manifest.
- **Fix:** Add an App Privacy file in Xcode (File → New → File → App Privacy) or add `PrivacyInfo.xcprivacy` to the iOS app target. Declare:
  - Required reason API usage (if any)
  - Data collection types (e.g. account, usage) if you collect them
  Flutter and plugins (e.g. shared_preferences, file access) may trigger this; the manifest documents why you use those APIs.

### 5. **Unused dependency: video_player**
- **Issue:** `pubspec.yaml` includes `video_player: ^2.8.0`, but there is no `import 'package:video_player/...'` or `VideoPlayer` usage in `lib/`. The app only uses camera/photo for still images.
- **Apple:** Indirect: unused code can bloat the binary and attract questions. Declaring microphone “for video recording” while having no in-app video makes the permission look unjustified.
- **Fix:** If you don’t plan to play or record video, remove `video_player` from `pubspec.yaml` and run `flutter pub get`. Then remove `NSMicrophoneUsageDescription` as in (2).

---

## Already in good shape

- **Sign in with Apple:** Implemented and entitlement `com.apple.developer.applesignin` is set. Required when you offer other third-party sign-in (e.g. email/password via Supabase).
- **Camera & Photo Library:** Usage descriptions are present and match usage (barcode scanning, tool/technician photos).
- **Background modes:** `remote-notification` is declared and matches push usage.
- **URL scheme:** `com.rgs.app` is set for auth/deep links; ensure it’s consistent with Supabase redirect URL.

---

## Quick checklist before submit

- [ ] Remove or replace the ATS “New Exception Domain” with a real domain; avoid broad HTTP allowance.
- [ ] Remove `NSMicrophoneUsageDescription` (or implement real video+audio recording and keep it).
- [ ] Ensure release builds use `aps-environment: production` for push.
- [ ] Add `PrivacyInfo.xcprivacy` and declare required reason APIs and data collection.
- [ ] Remove `video_player` if you don’t use video; run `flutter pub get`.
- [ ] Test login (email + Sign in with Apple), push notifications, and deep links on a real device.
- [ ] Ensure no test accounts, debug toasts, or placeholder content are visible in production builds.

---

## References

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [App Transport Security](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)
