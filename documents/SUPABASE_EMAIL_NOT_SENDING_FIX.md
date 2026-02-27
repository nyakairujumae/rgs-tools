# Supabase Email Not Sending - Troubleshooting Guide

## Issue: Supabase is not sending confirmation emails

If Supabase is not sending emails, follow these steps to diagnose and fix the issue.

## Step 1: Verify SMTP Settings in Supabase

1. **Go to Supabase Dashboard**
   - Navigate to: **Settings** → **Auth** → **SMTP Settings**

2. **Check all settings are correct:**
   ```
   ✅ Enable Custom SMTP: ON
   ✅ SMTP Host: smtp.resend.com
   ✅ SMTP Port: 587
   ✅ SMTP User: resend
   ✅ SMTP Password: re_QFStbTxg_DVBWUE5bpwSaBZzvCcBUgtmJ
   ✅ Sender Email: noreply@rgstools.app
   ✅ Sender Name: RGS Tools
   ```

3. **Click "Save"** (even if you don't see changes, make sure to save)

## Step 2: Test SMTP Connection

1. **In Supabase SMTP Settings**, look for a **"Test Connection"** or **"Send Test Email"** button
2. **If no test button exists**, proceed to Step 3 to test via actual registration

## Step 3: Check Supabase Auth Logs

1. **Go to Supabase Dashboard**
   - Navigate to: **Logs** → **Auth Logs**
   - Look for recent registration attempts
   - Check for error messages related to email sending

2. **Common errors to look for:**
   - `SMTP authentication failed`
   - `Connection timeout`
   - `Invalid credentials`
   - `Email service error`

## Step 4: Verify Resend API Key

1. **Go to Resend Dashboard**: https://resend.com/api-keys
2. **Check your API key**:
   - Verify it's **active** (not revoked)
   - Verify it has **"Sending access"** permission
   - The key should be: `re_QFStbTxg_DVBWUE5bpwSaBZzvCcBUgtmJ`

3. **If key is revoked or inactive**:
   - Create a new API key
   - Update it in Supabase SMTP settings

## Step 5: Check Resend Email Logs

1. **Go to Resend Dashboard**: https://resend.com/emails
2. **Check if emails are being sent**:
   - Look for emails to the addresses you're testing
   - Check delivery status:
     - ✅ **Delivered**: Email was sent successfully
     - ⚠️ **Pending**: Email is queued
     - ❌ **Failed**: Check error message

3. **If NO emails appear in Resend**:
   - Supabase is not successfully connecting to Resend
   - Check SMTP settings again
   - Verify API key is correct

## Step 6: Common SMTP Configuration Issues

### Issue 1: SMTP Port Wrong
- **Correct**: `587` (TLS)
- **Wrong**: `465` (SSL) or `25` (unencrypted)
- **Fix**: Use port `587` for Resend

### Issue 2: SMTP User Wrong
- **Correct**: `resend` (lowercase, exactly this)
- **Wrong**: Your email, API key, or anything else
- **Fix**: Use exactly `resend` as the SMTP user

### Issue 3: SMTP Password Wrong
- **Correct**: Your full Resend API key (starts with `re_`)
- **Wrong**: Your Resend account password
- **Fix**: Use your API key as the password, not your account password

### Issue 4: Sender Email Not Verified
- **Correct**: `noreply@rgstools.app` (your verified domain)
- **Wrong**: Any email not on your verified domain
- **Fix**: Use an email address with your verified domain `rgstools.app`

## Step 7: Verify Email Confirmations Are Enabled

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **Settings**
   - Find **"Enable email confirmations"**
   - Ensure it's **ON** (enabled)
   - Click **Save**

2. **If disabled**, Supabase won't send confirmation emails

## Step 8: Check Email Templates

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **Email Templates**
   - Click on **"Confirm signup"** template
   - Verify it's **active** and contains:
     - Confirmation link: `{{ .ConfirmationURL }}`
     - Proper formatting

2. **If template is missing or broken**, emails won't send

## Step 9: Check Rate Limits

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **Rate Limits**
   - Check **"Rate limit for sending emails"**
   - Ensure it's set to at least **100 emails/hour**

2. **If rate limit is too low**, emails may be blocked

## Step 10: Test with Resend Test Domain

If your domain isn't working, test with Resend's test domain:

1. **Update Supabase SMTP Settings**:
   ```
   Sender Email: onboarding@resend.dev
   ```
   (Keep all other settings the same)

2. **Save and test registration**

3. **If test domain works**:
   - Your domain verification may be the issue
   - Go back to Resend and verify domain is fully verified

## Step 11: Verify Redirect URLs

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **URL Configuration**
   - Verify **Redirect URLs** include:
     - `com.rgs.app://`
     - `com.rgs.app://auth/callback`

2. **If redirect URLs are wrong**, confirmation links won't work

## Step 12: Check Supabase Project Status

1. **Go to Supabase Dashboard**
   - Check project status at top of dashboard
   - Verify project is **active** (not paused or suspended)

2. **If project is paused**, emails won't send

## Diagnostic Checklist

Run through this checklist to identify the issue:

- [ ] SMTP enabled in Supabase
- [ ] SMTP Host: `smtp.resend.com`
- [ ] SMTP Port: `587`
- [ ] SMTP User: `resend` (exactly, lowercase)
- [ ] SMTP Password: Full API key (starts with `re_`)
- [ ] Sender Email: `noreply@rgstools.app` (verified domain)
- [ ] Sender Name: `RGS Tools`
- [ ] Settings saved in Supabase
- [ ] Email confirmations enabled
- [ ] Resend API key is active
- [ ] Resend API key has sending permission
- [ ] Domain verified in Resend
- [ ] Checked Resend email logs (are emails being sent?)
- [ ] Checked Supabase Auth logs (any errors?)
- [ ] Email templates are active
- [ ] Rate limits are set appropriately
- [ ] Redirect URLs configured correctly

## Most Common Issues

### 1. SMTP User is Wrong
**Problem**: Using email or API key as SMTP user  
**Solution**: Use exactly `resend` (lowercase)

### 2. API Key is Wrong
**Problem**: Using account password instead of API key  
**Solution**: Use your Resend API key (starts with `re_`)

### 3. Port is Wrong
**Problem**: Using 465 or 25 instead of 587  
**Solution**: Use port `587` for Resend

### 4. Domain Not Verified
**Problem**: Using email address from unverified domain  
**Solution**: Use email from verified domain `rgstools.app`

### 5. Email Confirmations Disabled
**Problem**: Email confirmations turned off in Supabase  
**Solution**: Enable email confirmations in Auth settings

## Next Steps

1. **Check Supabase Auth Logs** for specific error messages
2. **Check Resend Dashboard** to see if emails are being attempted
3. **Verify all SMTP settings** match exactly what's documented
4. **Test with Resend test domain** (`onboarding@resend.dev`) to isolate domain issues

## If Still Not Working

1. **Check Supabase Status**: https://status.supabase.com
2. **Check Resend Status**: https://resend.com/status
3. **Review Supabase Auth Logs** for specific error messages
4. **Contact Support**:
   - Supabase: https://supabase.com/support
   - Resend: https://resend.com/support


