# Email Confirmation Quick Fix - Step by Step

## ⚠️ Important: Email confirmation emails are sent on REGISTRATION, not login

If you're trying to test by logging in, you won't receive emails. Emails are only sent when:
- ✅ New user registers
- ✅ User requests password reset
- ✅ User changes email

## 🔧 Critical Checks (Do These First)

### 1. Supabase Dashboard → Authentication → Settings

**MUST CHECK:**
- [ ] **"Enable email confirmations"** is **ON** (enabled)
- [ ] Click **Save** (even if it's already on, click save to ensure it's saved)

### 2. Supabase Dashboard → Settings → Auth → SMTP Settings

**Verify ALL settings:**
```
Enable Custom SMTP: ON
SMTP Host: smtp.resend.com
SMTP Port: 587
SMTP User: resend
SMTP Password: re_... (your full Resend API key)
Sender Email: noreply@rgstools.app
Sender Name: RGS Tools
```

**CRITICAL TEST:**
- [ ] Click **"Send Test Email"** button
- [ ] Enter your email address
- [ ] **Did you receive the test email?**
  - ✅ YES → SMTP works, proceed to step 3
  - ❌ NO → SMTP is misconfigured, fix this first

### 3. Supabase Dashboard → Authentication → URL Configuration

**Redirect URLs (add these EXACTLY as shown):**
```
com.rgs.app://
com.rgs.app://auth/callback
```

**Site URL:**
```
com.rgs.app://
```

**Important:**
- [ ] Add each URL on a separate line
- [ ] No extra spaces or characters
- [ ] Click **Save**
- [ ] Refresh page and verify URLs are still there

### 4. Resend Dashboard Check

**Go to**: https://resend.com/emails

**Check:**
- [ ] Do you see ANY emails being sent to your address?
- [ ] Even if they failed, do you see attempts?
- [ ] If NO emails at all → Supabase is not connecting to Resend

### 5. Supabase Logs Check

**Go to**: Supabase Dashboard → Logs → Auth Logs

**After registering a new user, check:**
- [ ] Do you see the registration attempt?
- [ ] Do you see an email sending attempt?
- [ ] What error message appears (if any)?

**Common errors:**
- `SMTP authentication failed` → Wrong SMTP credentials
- `Connection timeout` → Wrong SMTP host/port
- `Invalid sender email` → Sender email domain not verified
- `Rate limit exceeded` → Too many emails sent

## 🧪 Test Registration Flow

1. **Register a NEW user** (not login, but register)
2. **Immediately check**:
   - Resend Dashboard → Emails (should see email attempt)
   - Supabase → Logs → Auth Logs (should see email sending attempt)
   - Your email inbox (check spam too)

## 🔍 Most Common Issues

### Issue 1: SMTP Test Email Fails

**Symptoms:**
- Test email button doesn't work
- No emails received at all

**Fix:**
1. Double-check SMTP settings (especially SMTP User = `resend`)
2. Verify Resend API key is correct and active
3. Check Resend Dashboard → API Keys → Your key is active
4. Try using `onboarding@resend.dev` as sender email for testing

### Issue 2: Emails Sent but Not Received

**Symptoms:**
- Resend Dashboard shows emails sent
- But you don't receive them

**Fix:**
1. Check spam folder
2. Check Resend Dashboard → Email delivery status
3. Try different email provider (Gmail, Outlook, etc.)
4. Check if your email provider is blocking Resend

### Issue 3: No Emails Being Sent at All

**Symptoms:**
- Resend Dashboard shows NO emails
- Supabase Logs show no email attempts

**Fix:**
1. Verify email confirmation is ENABLED
2. Check SMTP test email works
3. Check Supabase Auth Logs for errors
4. Verify Resend API key is active

### Issue 4: Email Link Doesn't Work

**Symptoms:**
- Email received
- But link doesn't open app

**Fix:**
1. Verify redirect URLs in Supabase
2. Check deep link configuration in app
3. Test deep link manually: `com.rgs.app://auth/callback`

## 📝 What to Check Right Now

**Priority 1 (Most Important):**
1. [ ] Is email confirmation **ENABLED** in Supabase?
2. [ ] Does **SMTP test email** work?
3. [ ] Are **redirect URLs** added in Supabase?

**Priority 2:**
4. [ ] Check **Resend Dashboard** - any emails being sent?
5. [ ] Check **Supabase Auth Logs** - any errors?
6. [ ] Check **spam folder** - emails might be there

**Priority 3:**
7. [ ] Verify **email template** is active
8. [ ] Check **Resend domain** is verified
9. [ ] Test with **different email provider**

## 🎯 Quick Test

**To test if everything works:**

1. **Enable email confirmation** (if not already)
2. **Send SMTP test email** (must work)
3. **Register a NEW user** with your email
4. **Check immediately**:
   - Resend Dashboard → Should see email attempt
   - Your inbox → Should receive email (check spam)
   - Supabase Logs → Should see email sending attempt

If test email works but registration email doesn't → Check email confirmation setting and redirect URLs.

## 📞 Report Back

After checking the above, tell me:

1. **Does SMTP test email work?** (YES/NO)
2. **Is email confirmation enabled?** (YES/NO)
3. **What do you see in Resend Dashboard?** (emails sent / no emails / errors)
4. **What do you see in Supabase Auth Logs?** (any errors?)
5. **Are redirect URLs added?** (YES/NO)

This will help me identify the exact issue!



