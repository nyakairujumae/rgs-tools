# Quick Email Diagnostic - Supabase Not Sending Emails

## Immediate Checks (Do These First)

### 1. Check Supabase Auth Logs (Most Important!)

1. **Go to Supabase Dashboard**
   - Navigate to: **Logs** → **Auth Logs**
   - Look for recent registration attempts
   - **What to look for:**
     - Error messages about SMTP
     - "Failed to send email" errors
     - Authentication errors
     - Connection timeouts

2. **Take a screenshot or copy the error message** - this will tell us exactly what's wrong

### 2. Check Resend Dashboard

1. **Go to**: https://resend.com/emails
2. **Check if ANY emails are being sent**:
   - If you see emails → Supabase IS connecting to Resend, but emails might be failing
   - If you see NO emails → Supabase is NOT connecting to Resend (SMTP config issue)

### 3. Verify SMTP Settings (Common Mistakes)

Go to **Supabase** → **Settings** → **Auth** → **SMTP Settings** and verify:

```
✅ Enable Custom SMTP: ON
✅ SMTP Host: smtp.resend.com  (NOT smtp.sendgrid.net)
✅ SMTP Port: 587              (NOT 465 or 25)
✅ SMTP User: resend           (NOT your email, NOT your API key - just "resend")
✅ SMTP Password: re_QFStbTxg_DVBWUE5bpwSaBZzvCcBUgtmJ  (Your full API key)
✅ Sender Email: noreply@rgstools.app
✅ Sender Name: RGS Tools
```

**Common Mistakes:**
- ❌ SMTP User = your email address → Should be `resend`
- ❌ SMTP Password = your account password → Should be your API key
- ❌ SMTP Port = 465 or 25 → Should be `587`
- ❌ Sender Email = email from unverified domain → Should be from `rgstools.app`

### 4. Test SMTP Connection

**Option A: Use Supabase Test Button (if available)**
- Look for "Test Connection" or "Send Test Email" button
- Click it and check if it works

**Option B: Test via Registration**
- Register a new user
- Check Supabase Auth Logs immediately after
- Check Resend dashboard to see if email was attempted

### 5. Check Email Confirmations Are Enabled

1. **Go to**: **Authentication** → **Settings**
2. **Find**: "Enable email confirmations"
3. **Must be**: **ON** (enabled)
4. **Click**: Save

## Quick Fixes Based on Error Messages

### If you see "SMTP authentication failed":
- ✅ Check SMTP User is exactly `resend` (lowercase)
- ✅ Check SMTP Password is your full API key (starts with `re_`)
- ✅ Verify API key is active in Resend dashboard

### If you see "Connection timeout":
- ✅ Check SMTP Host is `smtp.resend.com`
- ✅ Check SMTP Port is `587`
- ✅ Check your internet connection

### If you see "Invalid sender email":
- ✅ Check Sender Email is from verified domain (`rgstools.app`)
- ✅ Try using `onboarding@resend.dev` for testing

### If you see "Email service error":
- ✅ Check Resend dashboard for service status
- ✅ Check Supabase status page
- ✅ Verify API key hasn't been revoked

## What to Report Back

Please check the above and tell me:

1. **What error message do you see in Supabase Auth Logs?** (if any)
2. **Do you see ANY emails in Resend dashboard?** (even failed ones)
3. **Are all SMTP settings exactly as shown above?**
4. **Is "Enable email confirmations" turned ON?**

This will help me identify the exact issue!


