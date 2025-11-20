# Email Verification Troubleshooting Guide

## Issue: Not Receiving Verification Email

If you're not receiving verification emails after signup, check the following:

## ✅ Step 1: Check Supabase Email Settings

### A. Verify Email Confirmation is Enabled
1. Go to **Supabase Dashboard** → **Authentication** → **Settings**
2. Check **"Enable email confirmations"** - should be **ON**
3. If it's OFF, turn it ON and save

### B. Check Email Rate Limits
1. Go to **Authentication** → **Rate Limits**
2. Check **"Rate limit for sending emails"**
3. Make sure it's set to at least **100 emails/hour** (or higher)
4. If you're using SendGrid SMTP, this should be set to 1000

### C. Verify SMTP Configuration
1. Go to **Settings** → **Auth** → **SMTP Settings**
2. Verify:
   - ✅ **Enable Custom SMTP** is **ON**
   - ✅ **SMTP Host**: `smtp.sendgrid.net`
   - ✅ **SMTP Port**: `587`
   - ✅ **SMTP User**: `apikey`
   - ✅ **SMTP Password**: Your SendGrid API key (starts with `SG.`)
   - ✅ **Sender Email**: A verified email in SendGrid
   - ✅ **Sender Name**: `RGS Tools` (or your preferred name)

3. **Test Email**:
   - Click **"Send Test Email"** button
   - Enter your email address
   - Check your inbox (and spam folder)
   - If test email works, SMTP is configured correctly

## ✅ Step 2: Check SendGrid

### A. Verify Sender Email
1. Go to **SendGrid Dashboard** → **Settings** → **Sender Authentication**
2. Make sure your sender email is **verified**
3. If not verified:
   - Click **"Verify a Single Sender"**
   - Enter the email you're using in Supabase SMTP settings
   - Check your email for verification link
   - Click the verification link

### B. Check SendGrid Activity
1. Go to **SendGrid Dashboard** → **Activity**
2. Look for recent email sends
3. Check if emails are being sent:
   - ✅ **Delivered**: Email was sent successfully
   - ⚠️ **Bounced**: Email address is invalid
   - ⚠️ **Blocked**: Email was blocked (check spam filters)
   - ❌ **Failed**: Check error message

### C. Check SendGrid Limits
1. Go to **SendGrid Dashboard** → **Settings** → **Account Details**
2. Check your plan limits:
   - **Free Tier**: 100 emails/day
   - **Essentials**: 40,000 emails/month
   - **Pro**: 100,000+ emails/month
3. Make sure you haven't exceeded your daily/monthly limit

## ✅ Step 3: Check App Configuration

### A. Verify Redirect URL
The app needs to handle the email confirmation redirect. Check:

1. **iOS URL Scheme**: Should be `com.rgs.app://` (configured in `Info.plist`)
2. **Supabase Redirect URLs**: 
   - Go to **Authentication** → **URL Configuration**
   - Add these redirect URLs:
     - `com.rgs.app://`
     - `com.rgs.app://reset-password`
     - `com.rgs.app://email-confirmation`

### B. Check Email Domain
1. Make sure you're using a valid email address
2. Check for typos in the email address
3. Some email providers block automated emails - try a different email provider (Gmail, Outlook, etc.)

## ✅ Step 4: Check Spam Folder

1. **Check Spam/Junk folder** in your email
2. **Mark as "Not Spam"** if found
3. **Add sender to contacts** to prevent future spam filtering

## ✅ Step 5: Test Email Sending

### Test 1: Send Test Email from Supabase
1. Go to **Settings** → **Auth** → **SMTP Settings**
2. Click **"Send Test Email"**
3. Enter your email address
4. Check inbox and spam folder
5. If test email works, SMTP is configured correctly

### Test 2: Check Supabase Logs
1. Go to **Supabase Dashboard** → **Logs** → **Auth Logs**
2. Look for email sending attempts
3. Check for any error messages

### Test 3: Check SendGrid Activity
1. Go to **SendGrid Dashboard** → **Activity**
2. Filter by your email address
3. Check if emails are being sent and their status

## 🔧 Common Issues and Solutions

### Issue 1: "Authentication failed" in Supabase SMTP
**Solution**:
- Verify SMTP User is exactly `apikey` (lowercase, one word)
- Verify SMTP Password is your full API key (starts with `SG.`)
- Check for extra spaces before/after the API key

### Issue 2: "Sender not verified" error
**Solution**:
- Verify sender email in SendGrid dashboard
- Complete single sender verification
- Use the verified email in Supabase SMTP settings

### Issue 3: Emails going to spam
**Solution**:
- Set up SPF/DKIM records for your domain (if using custom domain)
- Verify domain in SendGrid (if using custom domain)
- Use a professional sender name
- Add sender to contacts in your email

### Issue 4: Rate limit exceeded
**Solution**:
- Check SendGrid daily/monthly limits
- Upgrade SendGrid plan if needed
- Wait for rate limit to reset (usually resets daily)

### Issue 5: Email confirmation not working in app
**Solution**:
- Make sure redirect URLs are configured in Supabase
- Check that URL scheme is configured in `Info.plist` (iOS) or `AndroidManifest.xml` (Android)
- Test the deep link manually: `com.rgs.app://email-confirmation?token=...`

## 📋 Quick Checklist

- [ ] Email confirmation is enabled in Supabase
- [ ] SMTP is configured and test email works
- [ ] Sender email is verified in SendGrid
- [ ] Redirect URLs are configured in Supabase
- [ ] URL scheme is configured in app (Info.plist/AndroidManifest.xml)
- [ ] Email rate limit is set appropriately
- [ ] Checked spam folder
- [ ] Checked SendGrid activity for email sends
- [ ] Checked Supabase auth logs for errors

## 🚨 Still Not Working?

If emails still aren't being sent:

1. **Check Supabase Auth Logs**:
   - Go to **Logs** → **Auth Logs**
   - Look for email sending errors
   - Share error messages for debugging

2. **Check SendGrid Activity**:
   - Go to **Activity** in SendGrid
   - See if emails are being attempted
   - Check error messages

3. **Try a Different Email Provider**:
   - Some email providers block automated emails
   - Try Gmail, Outlook, or another provider

4. **Contact Support**:
   - Supabase support if SMTP test fails
   - SendGrid support if emails aren't being sent

## 📝 Next Steps

After fixing the issue:
1. Test signup with a new email address
2. Check inbox and spam folder
3. Click the verification link in the email
4. Verify the app handles the deep link correctly

---

**Last Updated**: November 20, 2025



