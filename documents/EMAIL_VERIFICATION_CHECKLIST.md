# Email Verification Checklist

## ✅ Quick Fix Steps

### 1. Check Supabase Email Confirmation Setting
**Location**: Supabase Dashboard → Authentication → Settings

- [ ] **"Enable email confirmations"** is **ON**
- [ ] If OFF, turn it ON and save

### 2. Verify SMTP Configuration
**Location**: Supabase Dashboard → Settings → Auth → SMTP Settings

- [ ] **"Enable Custom SMTP"** is **ON**
- [ ] **SMTP Host**: `smtp.sendgrid.net`
- [ ] **SMTP Port**: `587`
- [ ] **SMTP User**: `apikey` (exactly this, lowercase)
- [ ] **SMTP Password**: Your SendGrid API key (starts with `SG.`)
- [ ] **Sender Email**: A verified email address
- [ ] **Sender Name**: `RGS Tools`

**Test**: Click "Send Test Email" - if it works, SMTP is configured correctly ✅

### 3. Check SendGrid Sender Verification
**Location**: SendGrid Dashboard → Settings → Sender Authentication

- [ ] Your sender email is **verified**
- [ ] If not verified, click "Verify a Single Sender" and complete verification

### 4. Check Supabase Redirect URLs
**Location**: Supabase Dashboard → Authentication → URL Configuration

Add these redirect URLs:
- [ ] `com.rgs.app://`
- [ ] `com.rgs.app://reset-password`
- [ ] `com.rgs.app://email-confirmation`

### 5. Check Email Rate Limits
**Location**: Supabase Dashboard → Authentication → Rate Limits

- [ ] **"Rate limit for sending emails"** is set to at least **100** (or higher)
- [ ] If using SendGrid, set to **1000**

### 6. Check SendGrid Activity
**Location**: SendGrid Dashboard → Activity

- [ ] Check if emails are being sent
- [ ] Look for your email address in the activity feed
- [ ] Check status: Delivered ✅, Bounced ⚠️, Blocked ⚠️, Failed ❌

### 7. Check Your Email
- [ ] Check **inbox**
- [ ] Check **spam/junk folder**
- [ ] Check for emails from your sender email address
- [ ] Mark as "Not Spam" if found in spam

## 🔧 Code Changes Made

I've updated the code to include the email redirect URL:

1. **`lib/providers/auth_provider.dart`**:
   - Added `emailRedirectTo: 'com.rgs.app://email-confirmation'` to signup

2. **`lib/main.dart`**:
   - Added email confirmation event handling in auth state listener

## 🚨 Most Common Issues

### Issue 1: Email Confirmation Disabled
**Fix**: Enable it in Supabase → Authentication → Settings

### Issue 2: SMTP Not Configured
**Fix**: Configure SendGrid SMTP in Supabase → Settings → Auth → SMTP Settings

### Issue 3: Sender Email Not Verified
**Fix**: Verify sender email in SendGrid → Settings → Sender Authentication

### Issue 4: Redirect URLs Not Configured
**Fix**: Add redirect URLs in Supabase → Authentication → URL Configuration

### Issue 5: Emails in Spam
**Fix**: Check spam folder, mark as "Not Spam", add sender to contacts

## 📝 Next Steps

1. **Verify all checklist items above**
2. **Test signup** with a new email address
3. **Check SendGrid Activity** to see if email was sent
4. **Check inbox and spam folder**
5. **Click verification link** in the email
6. **Verify app opens** and user is signed in

## 🔍 Debugging

If emails still aren't being sent:

1. **Check Supabase Logs**:
   - Go to **Logs** → **Auth Logs**
   - Look for email sending errors

2. **Check SendGrid Activity**:
   - Go to **Activity** in SendGrid
   - Filter by your email address
   - Check error messages

3. **Test SMTP**:
   - Use "Send Test Email" in Supabase SMTP settings
   - If test email works, SMTP is fine
   - If test email fails, check SMTP credentials

---

**After fixing**: Rebuild the app and test again!



