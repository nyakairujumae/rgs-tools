# Password Reset Configuration Guide

## 📋 Overview

This guide explains how password reset works in the RGS Tools app and how to configure it in Supabase.

## 🔄 How Password Reset Works

1. **User clicks "Forgot Password?"** on the login screen
2. **User enters email** in the dialog
3. **App sends reset request** to Supabase
4. **Supabase sends email** with reset link
5. **User clicks link** in email
6. **App opens** and navigates to reset password screen
7. **User enters new password**
8. **Password is updated** and user is redirected to login

## ⚙️ Supabase Configuration

### Step 1: Configure Redirect URLs

1. Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**

2. Add the following redirect URLs:

   **For iOS:**
   ```
   com.rgs.app://reset-password
   ```

   **For Android:**
   ```
   com.rgs.app://reset-password
   ```

   **For Web (if applicable):**
   ```
   https://yourdomain.com/reset-password
   ```

3. **Site URL** should be set to:
   ```
   com.rgs.app://
   ```

### Step 2: Configure Email Template

1. Go to **Authentication** → **Emails** → **Reset Password**

2. **Subject**: `Reset Your RGS Tools Password`

3. **Template**:
```html
<h2>Reset Your Password</h2>
<p>Hello,</p>
<p>You requested to reset your password for your RGS Tools account.</p>
<p>Click the link below to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}" style="background-color: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; display: inline-block; margin: 16px 0;">Reset Password</a></p>
<p>Or copy and paste this link into your browser:</p>
<p style="word-break: break-all; color: #666;">{{ .ConfirmationURL }}</p>
<p><strong>This link will expire in 1 hour.</strong></p>
<p>If you didn't request this password reset, please ignore this email.</p>
<p>Best regards,<br>RGS Tools Team</p>
```

4. Click **Save**

### Step 3: Verify Deep Link Configuration

#### iOS (`ios/Runner/Info.plist`)

Make sure you have the URL scheme configured:

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

#### Android (`android/app/src/main/AndroidManifest.xml`)

Make sure you have the intent filter configured:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.rgs.app" />
</intent-filter>
```

## 🧪 Testing Password Reset

### Test Flow:

1. **Open the app** and go to login screen
2. **Click "Forgot Password?"**
3. **Enter a valid email** address
4. **Check your email** for the reset link
5. **Click the link** in the email
6. **App should open** and show the reset password screen
7. **Enter new password** (twice)
8. **Click "Reset Password"**
9. **Should see success message** and be redirected to login
10. **Try logging in** with the new password

### Troubleshooting:

#### Issue: Email not received
- Check spam folder
- Verify email address is correct
- Check Supabase email rate limits
- Verify SMTP is configured (see `RATE_LIMITS_AND_SMTP_GUIDE.md`)

#### Issue: Link doesn't open app
- Verify URL scheme is configured correctly
- Check redirect URLs in Supabase dashboard
- Test deep link manually: `com.rgs.app://reset-password`

#### Issue: "Invalid or expired link"
- Reset links expire after 1 hour
- Request a new reset link
- Verify the link wasn't already used

#### Issue: App opens but shows error
- Check that the reset password screen route is configured
- Verify Supabase session is being set correctly
- Check app logs for errors

## 🔒 Security Considerations

1. **Link Expiration**: Reset links expire after 1 hour (configurable in Supabase)

2. **One-Time Use**: Each reset link can only be used once

3. **Email Verification**: Only emails registered in the system can request resets

4. **Rate Limiting**: Supabase rate limits prevent abuse (see `RATE_LIMITS_AND_SMTP_GUIDE.md`)

5. **Password Requirements**: Minimum 6 characters (enforced in app)

## 📱 App Implementation Details

### Files Involved:

1. **`lib/screens/auth/login_screen.dart`**
   - "Forgot Password?" button
   - Email input dialog
   - Calls `authProvider.resetPassword()`

2. **`lib/screens/auth/reset_password_screen.dart`**
   - New password input form
   - Password confirmation
   - Updates password via Supabase

3. **`lib/providers/auth_provider.dart`**
   - `resetPassword()` method
   - Sends reset request to Supabase

4. **`lib/main.dart`**
   - Deep link handling
   - Route configuration
   - Auth state change listener

### Deep Link Format:

```
com.rgs.app://reset-password?access_token=xxx&refresh_token=xxx&type=recovery
```

The app automatically extracts these parameters and navigates to the reset password screen.

## ✅ Pre-Production Checklist

- [ ] Configure redirect URLs in Supabase
- [ ] Customize email template
- [ ] Test password reset flow end-to-end
- [ ] Verify deep links work on iOS
- [ ] Verify deep links work on Android
- [ ] Test with expired links
- [ ] Test with invalid links
- [ ] Verify email delivery
- [ ] Check email spam rates
- [ ] Set up SMTP (if not already done)
- [ ] Configure email rate limits

## 🎯 Quick Reference

**Supabase Dashboard:**
- Authentication → URL Configuration → Redirect URLs
- Authentication → Emails → Reset Password

**App Deep Link:**
- `com.rgs.app://reset-password`

**Email Template Variables:**
- `{{ .ConfirmationURL }}` - The reset link
- `{{ .Email }}` - User's email address
- `{{ .Token }}` - Reset token (usually not needed)

## 📞 Need Help?

If password reset isn't working:

1. Check Supabase logs for errors
2. Verify redirect URLs are configured
3. Test deep link manually
4. Check app logs for routing errors
5. Verify email template is saved correctly

---

**Note**: Make sure you've set up SMTP before production (see `RATE_LIMITS_AND_SMTP_GUIDE.md`). The default email rate limit of 2/hour is too low for production use.


