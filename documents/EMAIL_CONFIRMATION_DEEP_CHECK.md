# Email Confirmation Deep Check - Complete Diagnostic

## 🔍 Step-by-Step Verification

### 1. Verify Email Confirmation is Enabled in Supabase

**Location**: Supabase Dashboard → Authentication → Settings

- [ ] **"Enable email confirmations"** toggle is **ON** (enabled)
- [ ] Click **Save** after enabling
- [ ] Verify the setting is saved (refresh page and check again)

### 2. Verify SMTP Configuration

**Location**: Supabase Dashboard → Settings → Auth → SMTP Settings

**Required Settings:**
```
✅ Enable Custom SMTP: ON
✅ SMTP Host: smtp.resend.com
✅ SMTP Port: 587
✅ SMTP User: resend
✅ SMTP Password: re_... (your full Resend API key)
✅ Sender Email: noreply@rgstools.app (or your verified domain email)
✅ Sender Name: RGS Tools
```

**Test SMTP:**
- [ ] Click **"Send Test Email"** button
- [ ] Enter your email address
- [ ] Check if you receive the test email
- [ ] If test email fails → SMTP configuration is wrong

### 3. Verify Redirect URLs in Supabase

**Location**: Supabase Dashboard → Authentication → URL Configuration

**Required Redirect URLs:**
```
com.rgs.app://
com.rgs.app://auth/callback
com.rgs.app://reset-password
```

**Site URL:**
```
com.rgs.app://
```

**Important:**
- [ ] All redirect URLs are added (one per line)
- [ ] No trailing slashes (except for the base URL)
- [ ] Click **Save** after adding URLs
- [ ] Verify URLs are saved (refresh and check)

### 4. Check Email Templates

**Location**: Supabase Dashboard → Authentication → Email Templates

**Confirm Signup Template:**
- [ ] Template is **active** (not disabled)
- [ ] Contains `{{ .ConfirmationURL }}` in the template
- [ ] The link should point to your redirect URL

**Example Template:**
```html
<h2>Confirm Your Email</h2>
<p>Click the link below to confirm your email:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm Email</a></p>
```

### 5. Verify Resend Domain Status

**Location**: Resend Dashboard → Domains

- [ ] `rgstools.app` domain is **verified** (green checkmark)
- [ ] All DNS records are correct
- [ ] Domain is not pending verification

### 6. Check Resend Email Logs

**Location**: Resend Dashboard → Emails

- [ ] Check if ANY emails are being sent to your address
- [ ] Look for emails with subject "Confirm your signup" or similar
- [ ] Check delivery status:
  - ✅ **Delivered**: Email was sent successfully
  - ⚠️ **Pending**: Email is queued
  - ❌ **Failed**: Check error message

### 7. Check Supabase Auth Logs

**Location**: Supabase Dashboard → Logs → Auth Logs

**What to Look For:**
- [ ] Recent registration attempts
- [ ] Email sending attempts
- [ ] Error messages (especially SMTP errors)
- [ ] "Failed to send email" errors
- [ ] Authentication errors

**Common Errors:**
- `SMTP authentication failed` → Check SMTP credentials
- `Connection timeout` → Check SMTP host/port
- `Invalid sender email` → Check sender email domain
- `Rate limit exceeded` → Wait or upgrade plan

### 8. Verify App Code Configuration

**Check `lib/providers/auth_provider.dart`:**

The `signUp` method should include:
```dart
emailRedirectTo: 'com.rgs.app://auth/callback',
```

**Current Code Check:**
- [ ] `emailRedirectTo` is set to `'com.rgs.app://auth/callback'`
- [ ] This matches one of the redirect URLs in Supabase

### 9. Test Email Delivery

**Test 1: Direct Resend Test**
1. Go to Resend Dashboard → Send Email
2. Send a test email FROM `noreply@rgstools.app` TO your email
3. Check if you receive it
4. If YES → Domain works, check Supabase config
5. If NO → Domain issue, check DNS records

**Test 2: Supabase Test Email**
1. Go to Supabase → Settings → Auth → SMTP Settings
2. Click "Send Test Email"
3. Enter your email
4. Check if you receive it
5. If YES → SMTP works, check email confirmation settings
6. If NO → SMTP configuration issue

**Test 3: Registration Test**
1. Register a new user with your email
2. Immediately check:
   - Resend Dashboard → Emails (should see email attempt)
   - Supabase → Logs → Auth Logs (should see email sending attempt)
   - Your email inbox (check spam too)

### 10. Check Deep Link Configuration

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.rgs.app</string>
        </array>
    </dict>
</array>
```

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.rgs.app" android:host="auth" android:path="/callback" />
</intent-filter>
```

### 11. Common Issues and Solutions

#### Issue: Emails Not Being Sent at All

**Check:**
1. Supabase Auth Logs for errors
2. Resend Dashboard for any email attempts
3. SMTP test email works
4. Email confirmation is enabled

**Solution:**
- Fix SMTP configuration
- Verify email confirmation is enabled
- Check Resend API key is active

#### Issue: Emails Sent but Not Received

**Check:**
1. Spam folder
2. Resend Dashboard → Email delivery status
3. Email provider filters
4. Domain reputation

**Solution:**
- Check spam folder
- Mark as "Not Spam"
- Check Resend delivery status
- Try different email provider for testing

#### Issue: Email Link Doesn't Work

**Check:**
1. Redirect URLs in Supabase
2. Deep link configuration in app
3. URL scheme matches

**Solution:**
- Add correct redirect URLs
- Verify deep link config
- Test deep link manually: `com.rgs.app://auth/callback`

#### Issue: "Email Already Confirmed" Error

**Check:**
1. User's email_confirmed_at in Supabase
2. If already confirmed, user should be able to login

**Solution:**
- Check user status in Supabase → Authentication → Users
- If confirmed, user should login directly
- If not confirmed, resend confirmation email

### 12. Quick Diagnostic Commands

**Check if email confirmation is enabled (via Supabase API):**
```bash
# This would require Supabase API access
# Check in Dashboard instead
```

**Test Deep Link (iOS Simulator):**
```bash
xcrun simctl openurl booted "com.rgs.app://auth/callback?type=signup&token=test"
```

**Test Deep Link (Android):**
```bash
adb shell am start -a android.intent.action.VIEW -d "com.rgs.app://auth/callback?type=signup&token=test"
```

## 📋 Complete Checklist

Before reporting issues, verify:

- [ ] Email confirmation is **ENABLED** in Supabase
- [ ] SMTP is configured and **test email works**
- [ ] Redirect URLs are added in Supabase
- [ ] Resend domain is **verified**
- [ ] Resend API key is **active**
- [ ] Email template contains `{{ .ConfirmationURL }}`
- [ ] App code has `emailRedirectTo: 'com.rgs.app://auth/callback'`
- [ ] Deep links are configured in iOS/Android
- [ ] Checked Supabase Auth Logs for errors
- [ ] Checked Resend Dashboard for email attempts
- [ ] Checked spam folder
- [ ] Tested with different email provider

## 🎯 Next Steps

After checking all the above:

1. **If SMTP test fails**: Fix SMTP configuration
2. **If emails not being sent**: Check Supabase Auth Logs for errors
3. **If emails sent but not received**: Check Resend dashboard and spam folder
4. **If link doesn't work**: Check redirect URLs and deep link config

## 📞 What to Report

If still not working, provide:

1. **Supabase Auth Logs** - Screenshot or copy error messages
2. **Resend Dashboard** - Screenshot showing email attempts (or lack thereof)
3. **SMTP Test Result** - Did test email work?
4. **Redirect URLs** - List of URLs you added
5. **Email Confirmation Setting** - Is it ON or OFF?



