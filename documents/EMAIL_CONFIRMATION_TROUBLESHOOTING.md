# Email Confirmation Troubleshooting Guide

## Issue: Not Receiving Confirmation Emails

If you're not receiving email confirmation emails, follow these steps:

## Step 1: Test Sender Email in Resend First (CRITICAL!)

**Before configuring Supabase, you MUST test the sender email address in Resend:**

1. **Go to Resend Dashboard**: https://resend.com/emails
2. **Click "Send Email"** (or go to **Emails** → **Send Email**)
3. **Send a test email**:
   - **From**: `noreply@rgstools.app` (the address you want to use)
   - **To**: Your personal email address
   - **Subject**: Test Sender Email
   - **Body**: Testing if this sender email works
4. **Click "Send"**
5. **Check your inbox** (and spam folder)
6. **If you receive the email**: ✅ Sender email works, proceed to Step 2
7. **If you don't receive the email**: 
   - Check Resend dashboard → **Emails** for delivery status
   - Verify domain `rgstools.app` is fully verified (not pending)
   - Try a different sender like `support@rgstools.app`

**Why this matters**: Even with a verified domain, you should test the specific email address you'll use as the sender to ensure it works correctly before configuring it in Supabase.

## Step 2: Verify Supabase SMTP Configuration

1. **Go to Supabase Dashboard**
   - Navigate to: **Settings** → **Auth** → **SMTP Settings**
   - Check if **"Enable Custom SMTP"** is **ON**

2. **Verify Resend SMTP Settings**
   ```
   SMTP Host: smtp.resend.com
   SMTP Port: 587
   SMTP User: resend
   SMTP Password: re_QFStbTxg_DVBWUE5bpwSaBZzvCcBUgtmJ
   Sender Email: noreply@rgstools.app (must be tested in Resend first!)
   Sender Name: RGS Tools
   ```

3. **Test SMTP Connection**
   - Click **"Send Test Email"** button
   - Enter your email address
   - Check if you receive the test email
   - **If test email fails**: 
     - Go back to Step 1 and test the sender email in Resend first
     - Verify SMTP configuration is correct
     - Check Resend dashboard for errors

## Step 3: Check Resend Dashboard

1. **Go to Resend Dashboard**: https://resend.com/emails
2. **Check Email Logs**:
   - Look for emails sent to your address
   - Check delivery status:
     - ✅ **Delivered**: Email was sent successfully
     - ⚠️ **Pending**: Email is queued
     - ❌ **Failed**: Email failed to send (check error message)

3. **Check Domain Status**:
   - Go to **Domains** in Resend dashboard
   - Verify `rgstools.app` is **verified** (green checkmark)
   - If not verified, emails may not be delivered

## Step 4: Verify Email Confirmation is Enabled

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **Settings**
   - Find **"Enable email confirmations"**
   - Ensure it's **ON** (enabled)
   - Click **Save**

## Step 5: Check Email Templates

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **Email Templates**
   - Click on **"Confirm signup"** template
   - Verify the template is active and contains:
     - Confirmation link: `{{ .ConfirmationURL }}`
     - Proper formatting

## Step 6: Check Redirect URLs

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **URL Configuration**
   - Verify **Redirect URLs** include:
     - `com.rgs.app://`
     - `com.rgs.app://auth/callback`

## Step 7: Check Spam Folder

- **Check your spam/junk folder** - emails may be filtered
- **Check email filters** - some email providers filter automated emails
- **Try a different email provider** (Gmail, Outlook, etc.) for testing

## Step 8: Check Resend API Key

1. **Verify API Key is Active**
   - Go to Resend Dashboard → **API Keys**
   - Check that your API key is **active** (not revoked)
   - Verify it has **"Sending access"** permission

2. **Check API Key Usage**
   - Go to Resend Dashboard → **Usage**
   - Verify you haven't exceeded your monthly limit
   - Free tier: 3,000 emails/month

## Step 9: Test with Resend Test Domain

If your domain isn't working, test with Resend's test domain:

1. **Update Supabase SMTP Settings**:
   ```
   Sender Email: onboarding@resend.dev
   ```
2. **Send a test email** from Supabase
3. **If test email works**: Your domain verification may be the issue
4. **If test email fails**: SMTP configuration is incorrect

## Step 10: Check App Code

Verify the app is correctly configured:

1. **Check `emailRedirectTo` in signUp**:
   ```dart
   emailRedirectTo: 'com.rgs.app://auth/callback',
   ```

2. **Check Supabase initialization**:
   ```dart
   emailRedirectTo: 'com.rgs.app://auth/callback',
   ```

## Step 11: Check Supabase Logs

1. **Go to Supabase Dashboard**
   - Navigate to: **Logs** → **Auth Logs**
   - Look for email sending attempts
   - Check for any error messages

## Common Issues and Solutions

### Issue: "Authentication Failed" in SMTP Test

**Solution:**
- Verify SMTP User is exactly: `resend` (lowercase)
- Verify SMTP Password is your full API key (starts with `re_`)
- Check API key has "Sending access" permission

### Issue: Emails Sent but Not Received

**Solutions:**
1. Check spam folder
2. Check Resend dashboard for delivery status
3. Verify domain is verified in Resend
4. Check email provider's filters

### Issue: "Domain Not Verified" Error

**Solution:**
1. Go to Resend Dashboard → **Domains**
2. Verify `rgstools.app` is verified
3. If not verified, complete domain verification:
   - Add DNS records provided by Resend
   - Wait for verification (can take up to 48 hours)

### Issue: Rate Limit Exceeded

**Solution:**
1. Check Resend dashboard → **Usage**
2. Wait for rate limit to reset (hourly/monthly)
3. Upgrade Resend plan if needed

## Quick Checklist

- [ ] **Sender email tested in Resend dashboard first** (send test email FROM the address)
- [ ] **Test email received from Resend** (verify sender email works)
- [ ] SMTP enabled in Supabase
- [ ] Resend SMTP settings correct
- [ ] Test email sent successfully from Supabase
- [ ] Email confirmations enabled in Supabase
- [ ] Redirect URLs configured correctly
- [ ] Domain verified in Resend
- [ ] API key active and has sending permission
- [ ] Checked spam folder
- [ ] Checked Resend email logs
- [ ] Checked Supabase auth logs

## Next Steps

If emails are still not being received after checking all the above:

1. **Contact Resend Support**: https://resend.com/support
2. **Check Supabase Status**: https://status.supabase.com
3. **Review Supabase Auth Logs** for specific error messages
4. **Try using a different email provider** for testing

