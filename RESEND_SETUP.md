# Resend SMTP Setup Guide for Supabase

## 🚀 What is Resend?

Resend is a modern email API service designed for developers. It offers:
- ✅ High deliverability rates
- ✅ Simple API and SMTP support
- ✅ Free tier: 3,000 emails/month
- ✅ Great developer experience
- ✅ Fast email delivery

---

## 📝 Step 1: Create Resend Account

1. Go to [resend.com](https://resend.com)
2. Click **"Sign Up"** (or **"Log In"** if you have an account)
3. Sign up with your email or GitHub account
4. Verify your email address

---

## 🔑 Step 2: Get Resend API Key

1. After logging in, go to **API Keys** in the left sidebar
2. Click **"Create API Key"**
3. Give it a name: `RGS Tools SMTP`
4. Select permissions:
   - ✅ **Sending access** (required)
5. Click **"Add"**
6. **Copy the API key immediately** - you won't be able to see it again!
   - Format: `re_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

**Important**: Save this API key securely. You'll need it for Supabase SMTP configuration.

---

## 📧 Step 3: Verify Your Domain (Recommended for Production)

### Option A: Verify a Domain (Best for Production) ✅ DONE

**Your Domain**: `rgstools.app` (already verified in Resend)

Once a domain is verified in Resend, you can use **any email address** with that domain:
- ✅ `noreply@rgstools.app`
- ✅ `support@rgstools.app`
- ✅ `admin@rgstools.app`
- ✅ `notifications@rgstools.app`
- ✅ Any other address you want!

**Note**: You don't need to verify individual email addresses - just verify the domain once, and all email addresses on that domain work automatically.

### Step 3.1: Test the Sender Email Address (IMPORTANT!)

**Before using an email address as the sender in Supabase, test it first:**

1. **Go to Resend Dashboard** → **Emails** → **Send Email**
2. **Send a test email**:
   - **From**: `noreply@rgstools.app` (the address you want to use)
   - **To**: Your personal email address
   - **Subject**: Test Email
   - **Body**: This is a test to verify the sender email works
3. **Click "Send"**
4. **Check your inbox** (and spam folder)
5. **If you receive the email**: ✅ The sender address works, you can use it in Supabase
6. **If you don't receive the email**: 
   - Check Resend dashboard for delivery status
   - Verify domain is fully verified (not just pending)
   - Try a different email address like `support@rgstools.app`

**Why this matters**: Even though the domain is verified, it's good practice to test the specific email address you'll use as the sender to ensure it works correctly.

### Option B: Use Resend's Test Domain (For Testing)

For testing, you can use Resend's test domain:
- **Sender Email**: `onboarding@resend.dev`
- This works immediately without domain verification
- **Note**: Only for testing - use your own domain for production

---

## ⚙️ Step 4: Configure Resend SMTP in Supabase

### Step 4.1: Go to Supabase Dashboard

1. Open your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: `npgwikkvtxebzwtpzwgx`
3. Navigate to **Settings** → **Auth** → **SMTP Settings**

### Step 4.2: Enable Custom SMTP

1. Toggle **"Enable Custom SMTP"** to **ON**

### Step 4.3: Enter Resend SMTP Details

Fill in these fields with **exact values**:

```
SMTP Host: smtp.resend.com
SMTP Port: 587
SMTP User: resend
SMTP Password: re_QFStbTxg_DVBWUE5bpwSaBZzvCcBUgtmJ (your Resend API key)
Sender Email: noreply@rgstools.app (your verified domain)
Sender Name: RGS Tools
```

**Important Notes:**
- **SMTP Host**: `smtp.resend.com` (not `smtp.sendgrid.net`)
- **SMTP Port**: `587` (TLS) - this is the correct port for Resend
- **SMTP User**: `resend` (exactly this, lowercase)
- **SMTP Password**: Your full Resend API key (starts with `re_`)
- **Sender Email**: 
  - ✅ **Use**: `noreply@rgstools.app` (your verified domain)
  - You can also use: `support@rgstools.app`, `admin@rgstools.app`, or any other address with your verified domain

### Step 4.4: Test Email Configuration

**IMPORTANT**: Before testing in Supabase, make sure you've tested the sender email in Resend (Step 3.1 above).

1. Click **"Send Test Email"** button
2. Enter your email address
3. Click **"Send"**
4. Check your inbox (and spam folder) for the test email
5. **If test email is received**: ✅ SMTP configuration is correct, click **"Save"**
6. **If test email fails**: 
   - Double-check all SMTP settings
   - Verify sender email was tested in Resend first
   - Check Resend dashboard for any errors

---

## ✅ Step 5: Verify Sender Email Works

Before proceeding, ensure you've:
1. ✅ Verified your domain in Resend (`rgstools.app`)
2. ✅ Tested sending an email FROM `noreply@rgstools.app` in Resend dashboard
3. ✅ Received the test email successfully

If the test email in Resend works, then the sender email is ready to use in Supabase.

## ✅ Step 6: Verify Email Confirmation Settings

1. Go to **Authentication** → **Settings**
2. Ensure **"Enable email confirmations"** is **ON**
3. Save changes

---

## 🔗 Step 7: Configure Redirect URLs (If Not Already Done)

1. Go to **Authentication** → **URL Configuration**
2. Set **Site URL**: `com.rgs.app://`
3. Add **Redirect URLs**:
   - `com.rgs.app://`
   - `com.rgs.app://auth/callback`

---

## 📊 Step 8: Update Email Rate Limits

After setting up Resend SMTP:

1. Go to **Authentication** → **Rate Limits**
2. Click on **"Rate limit for sending emails"**
3. Increase to at least **100 emails/hour** (or higher based on your Resend plan)
   - Free tier: 3,000 emails/month = ~100 emails/hour
   - Paid plans: Higher limits available
4. Save changes

---

## 🎯 Resend SMTP Settings Summary

**Your Configuration:**
```
SMTP Host: smtp.resend.com
SMTP Port: 587
SMTP User: resend
SMTP Password: re_QFStbTxg_DVBWUE5bpwSaBZzvCcBUgtmJ
Sender Email: noreply@rgstools.app
Sender Name: RGS Tools
```

**Alternative Sender Emails** (all work with your verified domain):
- `noreply@rgstools.app` ✅ (recommended)
- `support@rgstools.app`
- `admin@rgstools.app`
- `notifications@rgstools.app`
- Any other address with `@rgstools.app`

---

## 🔒 Security Best Practices

1. ✅ **API Key Security**: 
   - Never commit your Resend API key to git
   - Store it securely (use environment variables for server-side code)
   - In Supabase, it's stored securely in their system

2. ✅ **Domain Verification**:
   - For production, always verify your domain
   - This improves deliverability and prevents spam

3. ✅ **Rate Limits**:
   - Monitor your email usage in Resend dashboard
   - Set appropriate rate limits in Supabase

---

## 🧪 Testing Email Confirmation

1. **Sign up a new user** in your app
2. **Check the email inbox** (and spam folder)
3. **Click the confirmation link** in the email
4. **Verify** the app opens and user is authenticated

---

## 📚 Additional Resources

- **Resend Documentation**: https://resend.com/docs
- **Resend SMTP Guide**: https://resend.com/docs/send-with-smtp
- **Resend Dashboard**: https://resend.com/emails
- **Supabase Auth Docs**: https://supabase.com/docs/guides/auth

---

## ❓ Troubleshooting

### Issue: Not Receiving Test Email

**Solutions:**
1. Check spam/junk folder
2. Verify SMTP settings are correct
3. Check Resend dashboard → **Emails** for delivery status
4. Verify sender email is correct (use `onboarding@resend.dev` for testing)

### Issue: "Authentication Failed" Error

**Solutions:**
1. Verify SMTP User is exactly: `resend` (lowercase)
2. Verify SMTP Password is your full API key (starts with `re_`)
3. Check that API key has "Sending access" permission

### Issue: Emails Going to Spam

**Solutions:**
1. Verify your domain in Resend (for production)
2. Use a verified sender email
3. Check Resend dashboard for delivery issues
4. Consider setting up SPF/DKIM records (Resend provides these)

---

## ✅ Checklist

- [ ] Resend account created
- [ ] API key generated and saved
- [ ] Domain verified (for production) or using test domain (for testing)
- [ ] **Sender email tested in Resend dashboard** (send test email FROM the address you'll use)
- [ ] **Test email received successfully** (verify the sender email works)
- [ ] SMTP configured in Supabase with correct settings
- [ ] Test email sent from Supabase and received successfully
- [ ] Email confirmations enabled in Supabase
- [ ] Redirect URLs configured
- [ ] Rate limits updated
- [ ] Tested email confirmation flow in app

---

**You're all set!** 🎉 Your app will now use Resend for sending email confirmations.

