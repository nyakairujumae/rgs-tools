# 🔧 Email Confirmation Deep Link Fix

## 🚨 Problem

Email confirmation emails are being sent (SMTP works), but clicking the confirmation link doesn't work properly.

## 🔍 Root Causes to Check

### 1. **Supabase Redirect URL Configuration** ⚠️ MOST COMMON ISSUE

**Check in Supabase Dashboard**:
1. Go to **Authentication** → **URL Configuration**
2. Verify these redirect URLs are added:
   ```
   com.rgs.app://auth/callback
   com.rgs.app://reset-password
   com.rgs.app://email-confirmation
   ```
3. **Site URL** should be: `com.rgs.app://`

**If missing, add them!**

### 2. **Email Template URL Format**

**Check in Supabase Dashboard**:
1. Go to **Authentication** → **Emails** → **Confirm signup**
2. The template should use: `{{ .ConfirmationURL }}`
3. This automatically uses your configured redirect URLs

**Common Issue**: If the template has a hardcoded URL, it won't use your deep link!

### 3. **Deep Link Handler Code**

The code in `lib/main.dart` looks for:
- `auth/callback` in the URL path
- `access_token` or `type` query parameters

**Current handler** (lines 440-524):
- ✅ Handles `com.rgs.app://auth/callback?access_token=...&type=signup`
- ✅ Handles `com.rgs.app://auth/callback?access_token=...&type=recovery`

### 4. **URL Scheme Configuration**

**iOS** (`ios/Runner/Info.plist`):
- ✅ URL scheme: `com.rgs.app` (configured)

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Need to verify intent filter is configured

## ✅ Step-by-Step Fix

### Step 1: Verify Supabase Redirect URLs

1. **Go to Supabase Dashboard**
2. **Navigate to**: Authentication → URL Configuration
3. **Check "Redirect URLs"** section
4. **Add these if missing**:
   ```
   com.rgs.app://auth/callback
   com.rgs.app://reset-password
   com.rgs.app://email-confirmation
   ```
5. **Set "Site URL"** to: `com.rgs.app://`
6. **Click Save**

### Step 2: Check Email Template

1. **Go to**: Authentication → Emails → Confirm signup
2. **Verify the template uses**: `{{ .ConfirmationURL }}`
3. **Should NOT have hardcoded URLs** like `https://...`
4. **Save if changed**

### Step 3: Verify Android Deep Link

Check `android/app/src/main/AndroidManifest.xml` has:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="com.rgs.app"
        android:host="auth"
        android:path="/callback" />
</intent-filter>
```

### Step 4: Test the Flow

1. **Register a new user**
2. **Check email** - click the confirmation link
3. **Check logs** for:
   - `🔐 Email confirmation deep link detected`
   - `✅ Email confirmation detected, getting session from URL...`
   - `✅ Session created from email confirmation`

## 🐛 Common Issues

### Issue 1: Link Opens Browser Instead of App

**Cause**: Redirect URL not configured in Supabase

**Fix**: Add `com.rgs.app://auth/callback` to Supabase redirect URLs

### Issue 2: Link Opens App But Nothing Happens

**Cause**: Deep link handler not matching the URL format

**Fix**: Check the actual URL format in the email and update handler if needed

### Issue 3: "Invalid redirect URL" Error

**Cause**: URL in email doesn't match configured redirect URLs

**Fix**: Ensure Supabase redirect URLs exactly match what's in the email

### Issue 4: Session Not Created After Clicking Link

**Cause**: `getSessionFromUrl` failing

**Fix**: Check logs for error, verify token format

## 🔍 Debugging Steps

### 1. Check What URL is in the Email

1. Register a test user
2. Open the confirmation email
3. **Right-click the link** → Copy link address
4. Check the format - should be:
   ```
   https://[your-project].supabase.co/auth/v1/verify?token=...&type=signup&redirect_to=com.rgs.app://auth/callback
   ```

### 2. Check App Logs

When clicking the link, look for:
```
🔐 Email confirmation deep link detected: com.rgs.app://auth/callback?...
✅ Email confirmation detected, getting session from URL...
✅ Session created from email confirmation
```

### 3. Check Supabase Auth Logs

1. Go to **Logs** → **Auth Logs**
2. Look for email confirmation attempts
3. Check for errors

## 📋 Verification Checklist

- [ ] Supabase redirect URLs include `com.rgs.app://auth/callback`
- [ ] Site URL is set to `com.rgs.app://`
- [ ] Email template uses `{{ .ConfirmationURL }}`
- [ ] iOS URL scheme configured in Info.plist
- [ ] Android intent filter configured in AndroidManifest.xml
- [ ] Deep link handler code matches URL format
- [ ] Test email confirmation link works

## 🚀 Quick Test

1. **Register a test user**
2. **Check email** - verify link format
3. **Click link** - should open app
4. **Check logs** - should see confirmation messages
5. **Verify user** - check Supabase → Users → email should be confirmed

---

**Most likely issue**: Redirect URLs not configured in Supabase! Check that first! ✅



