# Email Template Configuration Guide

## 📧 Current Email Template

The default "Confirm signup" email template in Supabase is:

```html
<h2>Confirm your signup</h2>

<p>Follow this link to confirm your user:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm your mail</a></p>
```

## ✅ Does It Need Modification?

**Short answer**: The default template will work, but you should customize it for:
1. **Better branding** - Match your app's style
2. **Better mobile experience** - Clear instructions for mobile users
3. **Professional appearance** - More polished emails

## 🔧 Recommended Email Template

Here's an improved template for your RGS Tools app:

### Subject Line:
```
Confirm Your RGS Tools Account
```

### Email Body (HTML):
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
    <div style="background-color: #f8f9fa; border-radius: 8px; padding: 30px; text-align: center;">
        <h1 style="color: #2c3e50; margin-bottom: 10px;">Welcome to RGS Tools</h1>
        <p style="color: #7f8c8d; font-size: 16px; margin-bottom: 30px;">Thank you for signing up!</p>
        
        <div style="background-color: white; border-radius: 8px; padding: 30px; margin: 20px 0;">
            <p style="margin-bottom: 20px; font-size: 16px;">Please confirm your email address to activate your account:</p>
            
            <a href="{{ .ConfirmationURL }}" 
               style="display: inline-block; background-color: #4CAF50; color: white; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 16px; margin: 20px 0;">
                Confirm Email Address
            </a>
            
            <p style="margin-top: 30px; font-size: 14px; color: #7f8c8d;">
                Or copy and paste this link into your browser:<br>
                <a href="{{ .ConfirmationURL }}" style="color: #3498db; word-break: break-all;">{{ .ConfirmationURL }}</a>
            </p>
        </div>
        
        <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #e0e0e0;">
            <p style="font-size: 12px; color: #95a5a6; margin: 5px 0;">
                <strong>Using the mobile app?</strong><br>
                Tap the button above to open the confirmation link in your app.
            </p>
            <p style="font-size: 12px; color: #95a5a6; margin-top: 15px;">
                This link will expire in 24 hours.<br>
                If you didn't create an account, you can safely ignore this email.
            </p>
        </div>
        
        <div style="margin-top: 30px; font-size: 12px; color: #95a5a6;">
            <p>RGS Tools - HVAC Tools Management System</p>
        </div>
    </div>
</body>
</html>
```

## 📱 How It Works with Mobile Deep Links

The `{{ .ConfirmationURL }}` variable automatically:
1. Uses your configured **Site URL** (`com.rgs.app://`)
2. Includes the confirmation token
3. Redirects to your app when clicked on mobile

**Important**: Make sure you've configured:
- ✅ Site URL: `com.rgs.app://`
- ✅ Redirect URLs: `com.rgs.app://callback` (and others)

## 🎨 Customization Options

### Available Variables:
- `{{ .ConfirmationURL }}` - The confirmation link (automatically uses your redirect URLs)
- `{{ .Token }}` - The confirmation token
- `{{ .TokenHash }}` - Hashed token
- `{{ .SiteURL }}` - Your site URL
- `{{ .Email }}` - User's email address
- `{{ .Data }}` - Additional data
- `{{ .RedirectTo }}` - Redirect destination

### Color Scheme:
You can customize colors to match your app:
- Primary color: `#4CAF50` (green) - Change to your brand color
- Text color: `#333` (dark gray)
- Background: `#f8f9fa` (light gray)

## 📋 Step-by-Step: Update Email Template

1. **Go to Supabase Dashboard**
   - Navigate to **Authentication → Emails**
   - Click on **"Confirm sign up"** tab

2. **Update Subject**
   - Change to: `Confirm Your RGS Tools Account`

3. **Update Message Body**
   - Click **"<> Source"** tab
   - Replace the HTML with the template above (or customize it)
   - Click **"Preview"** to see how it looks

4. **Save Changes**
   - Click **"Save"** button

5. **Test It**
   - Sign up with a test email
   - Check the email you receive
   - Click the confirmation link
   - Verify it opens your app

## 🔄 Other Email Templates to Update

### 1. Reset Password
**Subject**: `Reset Your RGS Tools Password`

**Template**:
```html
<h2>Reset Your Password</h2>
<p>Click the link below to reset your password:</p>
<p><a href="{{ .ConfirmationURL }}">Reset Password</a></p>
<p>This link will expire in 1 hour.</p>
```

### 2. Magic Link
**Subject**: `Sign in to RGS Tools`

**Template**:
```html
<h2>Sign in to RGS Tools</h2>
<p>Click the link below to sign in:</p>
<p><a href="{{ .ConfirmationURL }}">Sign In</a></p>
<p>This link will expire in 1 hour.</p>
```

### 3. Change Email Address
**Subject**: `Confirm Your New Email Address`

**Template**:
```html
<h2>Confirm Your New Email</h2>
<p>Click the link below to confirm your new email address:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm Email</a></p>
```

## ⚠️ Important Notes

1. **Mobile Deep Links**: The `{{ .ConfirmationURL }}` automatically uses your configured redirect URLs, so mobile users will be redirected to your app.

2. **Email Confirmation Setting**: 
   - If **enabled**: Users must click the email link to confirm
   - If **disabled**: Users are auto-confirmed (no email sent)

3. **Testing**: Always test email templates with a real email address before production.

4. **Expiration**: Confirmation links expire after 24 hours by default (configurable in Supabase settings).

## 🎯 Quick Checklist

- [ ] Update "Confirm signup" email template
- [ ] Update "Reset password" email template
- [ ] Update "Magic link" email template (if using)
- [ ] Update "Change email" email template (if using)
- [ ] Test email delivery
- [ ] Test confirmation link opens app
- [ ] Verify mobile deep link works
- [ ] Check email looks good on mobile devices

## 💡 Pro Tips

1. **Keep it simple**: Don't overcomplicate the email design
2. **Mobile-first**: Most users will open emails on mobile
3. **Clear CTA**: Make the confirmation button obvious
4. **Fallback link**: Include a text link in case the button doesn't work
5. **Brand consistency**: Match your app's colors and style

---

## 🚀 Ready to Update?

1. Copy the recommended template above
2. Go to Supabase → Authentication → Emails
3. Paste it into the "Confirm sign up" template
4. Customize colors/text as needed
5. Save and test!



