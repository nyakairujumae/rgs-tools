# Fix Password Reset Email Template

## Issues
1. **Email flagged as dangerous** - Email client security warning
2. **Link not clickable** - Link appears as plain text instead of hyperlink

## Root Causes
1. Email template may not have proper HTML formatting
2. Deep link URL (`com.rgs.app://`) might look suspicious to email clients
3. Email sender might not be from verified domain
4. Template might be missing proper anchor tag formatting

## Solution

### Step 1: Update Supabase Email Template

Go to **Supabase Dashboard** → **Authentication** → **Emails** → **Reset Password**

**Subject:**
```
Reset Your RGS Tools Password
```

**Template (HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #ffffff; border-radius: 8px; padding: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
        <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #4CAF50; margin: 0;">RGS Tools</h1>
        </div>
        
        <h2 style="color: #333; margin-top: 0;">Reset Your Password</h2>
        
        <p>Hello,</p>
        
        <p>You have been added to RGS Tools. Please set your password by clicking the button below:</p>
        
        <div style="text-align: center; margin: 30px 0;">
            <a href="{{ .ConfirmationURL }}" 
               style="background-color: #4CAF50; 
                      color: #ffffff; 
                      padding: 14px 28px; 
                      text-decoration: none; 
                      border-radius: 6px; 
                      display: inline-block; 
                      font-weight: 600;
                      font-size: 16px;">
                Set Your Password
            </a>
        </div>
        
        <p style="color: #666; font-size: 14px; margin-top: 30px;">
            Or copy and paste this link into your browser:
        </p>
        
        <p style="background-color: #f5f5f5; 
                  padding: 12px; 
                  border-radius: 4px; 
                  word-break: break-all; 
                  font-size: 12px; 
                  color: #666;
                  font-family: monospace;">
            {{ .ConfirmationURL }}
        </p>
        
        <p style="color: #999; font-size: 12px; margin-top: 30px;">
            <strong>Important:</strong> This link will expire in 1 hour. If you didn't request this, please ignore this email.
        </p>
        
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        
        <p style="color: #999; font-size: 12px; text-align: center; margin: 0;">
            RGS Tools - HVAC Tools Management System<br>
            This is an automated message, please do not reply.
        </p>
    </div>
</body>
</html>
```

### Step 2: Verify Email Sender Configuration

Go to **Supabase Dashboard** → **Settings** → **Auth** → **SMTP Settings**

**Required:**
- ✅ **Enable Custom SMTP**: ON
- ✅ **Sender Email**: Use verified domain (e.g., `noreply@rgstools.app`)
- ✅ **Sender Name**: `RGS Tools`
- ✅ **SMTP Provider**: Configured (Resend/SendGrid/etc.)

### Step 3: Verify Redirect URLs

Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**

**Add these redirect URLs:**
```
com.rgs.app://reset-password
https://rgstools.app/reset-password
```

**Site URL:**
```
https://rgstools.app
```

### Step 4: Alternative - Use Web Redirect (Recommended)

Instead of direct deep link, use a web URL that redirects to the app:

1. **Create a web redirect page** at `https://rgstools.app/reset-password`
2. **This page redirects** to `com.rgs.app://reset-password?token=xxx`
3. **Update redirect URL** in code to use web URL first

This is less likely to be flagged by email clients.

### Step 5: Update Code to Use Web URL

Update `resetPassword()` method to use web URL:

```dart
Future<void> resetPassword(String email, {String? redirectTo}) async {
  try {
    // Use web URL that redirects to app (less likely to be flagged)
    final redirectUrl = redirectTo ?? 'https://rgstools.app/reset-password';
    
    await SupabaseService.client.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectUrl,
    );
  } catch (e) {
    debugPrint('Error resetting password: $e');
    rethrow;
  }
}
```

## Testing Checklist

- [ ] Update email template in Supabase
- [ ] Verify sender email is from verified domain
- [ ] Test email delivery
- [ ] Verify link is clickable (not plain text)
- [ ] Test link opens app correctly
- [ ] Check email is not flagged as spam
- [ ] Test on multiple email clients (Gmail, Apple Mail, Outlook)

## Why This Fixes the Issues

1. **Proper HTML formatting** - Link is properly formatted as anchor tag
2. **Professional template** - Less likely to be flagged as spam
3. **Verified sender** - Email from verified domain builds trust
4. **Web redirect** - Using web URL first is less suspicious than direct deep link
5. **Clear instructions** - Users know what to do

## If Issues Persist

1. **Check SPF/DKIM records** for your email domain
2. **Verify domain reputation** in email security tools
3. **Test with different email providers** (Gmail, Outlook, etc.)
4. **Check Supabase email logs** for delivery issues
5. **Consider using a dedicated email service** (Resend, SendGrid) with better deliverability
