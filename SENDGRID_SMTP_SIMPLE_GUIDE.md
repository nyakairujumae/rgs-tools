# SendGrid SMTP Setup - Simple Guide

## ✅ What You Already Have

You've already created a SendGrid API key:
- **Name**: "RGS SMT API"
- **API Key ID**: `gEOEGRmHSTOFhmZdoCB4tg`
- **Full API Key**: `SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (replace with your actual API key)

**Good news**: This API key works for SMTP! You don't need to create anything else in SendGrid.

## 🎯 What You Need to Do

**You configure SMTP in Supabase, NOT in SendGrid.**

SendGrid doesn't have a separate "SMTP Settings" page. The API key you created is all you need.

## 📝 Step-by-Step: Configure SMTP in Supabase

### Step 1: Go to Supabase Dashboard

1. Open your Supabase project dashboard
2. Click on **Settings** (gear icon in the left sidebar)
3. Click on **Auth** (under Settings)
4. Scroll down and click on **SMTP Settings**

### Step 2: Enable Custom SMTP

1. Find the toggle that says **"Enable Custom SMTP"**
2. Turn it **ON**

### Step 3: Enter Your SendGrid Details

Fill in these fields with these **exact values**:

```
SMTP Host: smtp.sendgrid.net
SMTP Port: 587
SMTP User: apikey
SMTP Password: SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Important Notes:**
- **SMTP User** must be exactly: `apikey` (lowercase, one word)
- **SMTP Password** is your full API key (the long string starting with `SG.`)
- **SMTP Host** is `smtp.sendgrid.net`
- **SMTP Port** is `587`

### Step 4: Set Sender Email and Name

1. **Sender Email**: Enter an email address (you'll need to verify this in SendGrid)
   - Example: `noreply@yourdomain.com` or your personal email
   - **Note**: You'll need to verify this email in SendGrid (see Step 5)

2. **Sender Name**: Enter `RGS Tools` (or whatever you want)

### Step 5: Verify Sender Email in SendGrid

Before you can send emails, you need to verify your sender email:

1. Go back to **SendGrid Dashboard**
2. Click on **Settings** (in the left sidebar)
3. Click on **Sender Authentication**
4. Click on **Verify a Single Sender**
5. Fill in the form:
   - **From Email Address**: Enter the email you used in Step 4
   - **From Name**: Enter "RGS Tools"
   - Fill in other required fields
6. Click **Create**
7. **Check your email** for a verification link from SendGrid
8. Click the verification link in the email

### Step 6: Test Email in Supabase

1. Go back to **Supabase SMTP Settings**
2. Scroll down to find **"Send Test Email"** button
3. Enter your email address
4. Click **Send Test Email**
5. Check your inbox (and spam folder)
6. If you receive the email, click **Save** at the bottom

### Step 7: Increase Email Rate Limit

After SMTP is configured:

1. Go to **Authentication** → **Rate Limits** (in Supabase)
2. Find **"Rate limit for sending emails"**
3. Click on it and increase to **100** (or higher)
4. Click **Save**

## 🎉 That's It!

You're done! Now your app can send emails through SendGrid.

## 📋 Quick Checklist

- [x] API key created in SendGrid ✅ (You already did this!)
- [ ] SMTP enabled in Supabase
- [ ] SMTP credentials entered in Supabase
- [ ] Sender email verified in SendGrid
- [ ] Test email sent successfully
- [ ] Email rate limit increased

## 🚨 Common Issues

### "Authentication failed" error
- Make sure **SMTP User** is exactly `apikey` (not your SendGrid username)
- Make sure **SMTP Password** is your full API key (starts with `SG.`)
- Check for extra spaces before/after the API key

### "Sender not verified" error
- You need to verify your sender email in SendGrid first
- Go to SendGrid → Settings → Sender Authentication
- Verify the email address you're using

### Can't find SMTP Settings in Supabase
- Make sure you're in the correct project
- Go to: Settings → Auth → SMTP Settings
- Scroll down if you don't see it immediately

### Test email not received
- Check spam folder
- Make sure sender email is verified in SendGrid
- Check SendGrid Activity feed to see if email was sent

## 💡 Key Points to Remember

1. ✅ **You don't need SMTP settings in SendGrid** - just the API key
2. ✅ **SMTP configuration is in Supabase**, not SendGrid
3. ✅ **Your existing API key works for SMTP** - no need to create a new one
4. ✅ **Verify your sender email** in SendGrid before sending emails

## 🔗 Where to Find Things

**In SendGrid:**
- API Keys: Settings → API Keys (you already have one!)
- Verify Sender: Settings → Sender Authentication

**In Supabase:**
- SMTP Settings: Settings → Auth → SMTP Settings
- Rate Limits: Authentication → Rate Limits

---

**You're almost there!** Just configure SMTP in Supabase using your existing API key. 🚀


