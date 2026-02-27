# Rate Limits & SMTP Configuration Guide

## 📊 Current Rate Limits

Based on your Supabase dashboard, here are your current rate limits:

### Email Rate Limit ⚠️
- **Current**: 2 emails per hour
- **Status**: Very low for production
- **Action Required**: Set up custom SMTP provider

### Other Rate Limits:
- **SMS**: 30 messages/hour
- **Token Refreshes**: 200 per 5 minutes (2400/hour) per IP
- **Token Verifications**: 30 per 5 minutes (360/hour) per IP
- **Anonymous Users**: 30 sign-ins/hour per IP
- **Sign Ups/Sign Ins**: 30 per 5 minutes (360/hour) per IP

---

## ⚠️ Email Rate Limit Issue

### The Problem:
- **2 emails per hour** is extremely low for production
- This means only 2 users can sign up per hour
- Password resets, email confirmations all count toward this limit

### The Solution:
**Set up a Custom SMTP Provider** to increase email limits.

---

## 🔧 Setting Up Custom SMTP

### Step 1: Choose an SMTP Provider

Recommended providers:

1. **SendGrid** (Recommended)
   - Free tier: 100 emails/day
   - Easy setup
   - Good deliverability

2. **Mailgun**
   - Free tier: 5,000 emails/month
   - Good for high volume

3. **Amazon SES**
   - Very cheap ($0.10 per 1,000 emails)
   - Requires AWS account

4. **Postmark**
   - Great deliverability
   - Paid service

5. **Resend**
   - Modern API
   - Good developer experience

### Step 2: Get SMTP Credentials

For **SendGrid** (example):

1. Sign up at https://sendgrid.com
2. Go to **Settings → API Keys**
3. Create an API key with "Mail Send" permissions
4. Or use SMTP credentials:
   - **SMTP Host**: `smtp.sendgrid.net`
   - **SMTP Port**: `587` (TLS) or `465` (SSL)
   - **SMTP Username**: `apikey`
   - **SMTP Password**: Your SendGrid API key

### Step 3: Configure in Supabase

1. **Go to Supabase Dashboard**
   - Navigate to **Settings → Auth → SMTP Settings**

2. **Enable Custom SMTP**
   - Toggle "Enable Custom SMTP" to ON

3. **Enter SMTP Details**:
   ```
   SMTP Host: smtp.sendgrid.net (or your provider's host)
   SMTP Port: 587
   SMTP User: apikey (or your username)
   SMTP Password: [Your API key]
   Sender Email: noreply@yourdomain.com
   Sender Name: RGS Tools
   ```

4. **Verify Email Address** (if required by provider)
   - Some providers require you to verify sender email
   - Check your email provider's documentation

5. **Test Email**
   - Click "Send Test Email"
   - Verify you receive it

6. **Save Settings**

### Step 4: Update Email Rate Limit

After setting up SMTP:
1. Go to **Authentication → Rate Limits**
2. Click on "Rate limit for sending emails"
3. You can now increase it (e.g., 100-1000 per hour)
4. Save changes

---

## 📧 Recommended SMTP Setup for Production

### For Small to Medium Apps (SendGrid):

```
SMTP Host: smtp.sendgrid.net
SMTP Port: 587
SMTP User: apikey
SMTP Password: [Your SendGrid API Key]
Sender Email: noreply@yourdomain.com
Sender Name: RGS Tools
Rate Limit: 100 emails/hour (or higher based on your plan)
```

### For High Volume Apps (Mailgun):

```
SMTP Host: smtp.mailgun.org
SMTP Port: 587
SMTP User: [Your Mailgun username]
SMTP Password: [Your Mailgun password]
Sender Email: noreply@yourdomain.com
Sender Name: RGS Tools
Rate Limit: 1000+ emails/hour
```

---

## 🎯 Recommended Rate Limits for Production

After setting up custom SMTP:

### Email Rate Limit:
- **Small app**: 100 emails/hour
- **Medium app**: 500 emails/hour
- **Large app**: 1000+ emails/hour

### Other Rate Limits (usually fine as-is):
- **Token Refreshes**: 200/5min (2400/hour) - Usually sufficient
- **Token Verifications**: 30/5min (360/hour) - Usually sufficient
- **Sign Ups/Sign Ins**: 30/5min (360/hour) - Usually sufficient
- **Anonymous Users**: 30/hour - Adjust if needed

---

## ⚙️ Other Rate Limit Settings

### Token Refreshes (200 per 5 minutes)
- **What it does**: Limits how often users can refresh their session
- **Default is usually fine**: 2400 requests/hour is plenty
- **Adjust if**: You have very active users or long sessions

### Token Verifications (30 per 5 minutes)
- **What it does**: Limits OTP/Magic link verification attempts
- **Default is usually fine**: 360/hour is sufficient
- **Adjust if**: You use magic links frequently

### Sign Ups/Sign Ins (30 per 5 minutes)
- **What it does**: Prevents brute force attacks
- **Default is usually fine**: 360/hour is reasonable
- **Adjust if**: You expect high signup volume

### Anonymous Users (30 per hour)
- **What it does**: Limits anonymous sign-ins
- **Default is usually fine**: Unless you use anonymous auth heavily

---

## 🔒 Security Considerations

### Rate Limiting Best Practices:

1. **Don't disable rate limits** - They protect against abuse
2. **Monitor your limits** - Check Supabase logs regularly
3. **Set appropriate limits** - Balance between usability and security
4. **Use Attack Protection** - Enable in Authentication → Attack Protection

### Attack Protection Settings:

Go to **Authentication → Attack Protection**:

- ✅ **Enable rate limiting** (already enabled via rate limits)
- ✅ **Enable CAPTCHA** (optional, for signup/login)
- ✅ **IP blocking** (optional, for known bad IPs)

---

## 📋 Quick Setup Checklist

### SMTP Setup:
- [ ] Choose SMTP provider (SendGrid recommended)
- [ ] Create account and get credentials
- [ ] Go to Supabase → Settings → Auth → SMTP Settings
- [ ] Enable Custom SMTP
- [ ] Enter SMTP credentials
- [ ] Set sender email and name
- [ ] Send test email
- [ ] Verify email received
- [ ] Save settings

### Rate Limits:
- [ ] Set up SMTP first (required to change email limit)
- [ ] Go to Authentication → Rate Limits
- [ ] Increase email rate limit (e.g., 100/hour)
- [ ] Review other rate limits (usually fine as-is)
- [ ] Save changes

### Testing:
- [ ] Test email sending (signup confirmation)
- [ ] Test password reset email
- [ ] Verify emails are delivered
- [ ] Check email deliverability (not in spam)

---

## 💡 Pro Tips

1. **Start with SendGrid**: Easiest to set up, good free tier
2. **Use a custom domain**: Better deliverability (e.g., `noreply@yourdomain.com`)
3. **Verify your domain**: Most providers require domain verification
4. **Monitor email delivery**: Check spam rates and delivery rates
5. **Set up SPF/DKIM records**: Improves email deliverability

### Domain Verification (Recommended):

For better deliverability, verify your domain:

1. **Get DNS records** from your SMTP provider
2. **Add to your domain DNS**:
   - SPF record
   - DKIM record
   - DMARC record (optional)
3. **Verify in SMTP provider dashboard**

---

## 🚨 Important Notes

1. **Email limit can't be changed without SMTP**: The popup you saw is correct - you MUST set up custom SMTP to increase email limits.

2. **2 emails/hour is too low**: This will cause issues in production. Set up SMTP before release.

3. **Free tier limits**: Most SMTP providers have free tiers that are sufficient for small apps.

4. **Test before production**: Always test email delivery before going live.

---

## 🎯 Action Items

**Before Production Release:**

1. ✅ **Set up Custom SMTP** (Required)
   - Choose provider (SendGrid recommended)
   - Configure in Supabase
   - Test email delivery

2. ✅ **Increase Email Rate Limit**
   - Set to at least 100/hour
   - Adjust based on expected volume

3. ✅ **Review Other Rate Limits**
   - Usually fine as-is
   - Adjust if you have specific needs

4. ✅ **Enable Attack Protection**
   - Go to Authentication → Attack Protection
   - Enable recommended settings

5. ✅ **Test Everything**
   - Test signup emails
   - Test password reset
   - Verify deliverability

---

## 📞 Need Help?

If you need help setting up SMTP:
1. Check your SMTP provider's documentation
2. Verify DNS records are correct
3. Check Supabase logs for errors
4. Test with a simple email first

**You MUST set up SMTP before production** - 2 emails/hour is not sufficient! 🚨



