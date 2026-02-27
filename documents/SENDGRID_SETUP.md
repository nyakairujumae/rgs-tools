# SendGrid Setup Guide

## 🔑 API Key Information

Your SendGrid API key has been saved to `.env` file (not committed to git for security).

**API Key Format**: `SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## 📝 .env File Configuration

Add the following to your `.env` file in the project root:

```env
# SendGrid API Key
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# SendGrid Recovery Code (if you have one)
# SENDGRID_RECOVERY_CODE=
```

## ⚙️ Supabase SMTP Configuration

### Step 1: Go to Supabase Dashboard
1. Navigate to **Settings** → **Auth** → **SMTP Settings**

### Step 2: Enable Custom SMTP
- Toggle **"Enable Custom SMTP"** to **ON**

### Step 3: Enter SendGrid SMTP Details

Use these exact settings:

```
SMTP Host: smtp.sendgrid.net
SMTP Port: 587
SMTP User: apikey
SMTP Password: SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Sender Email: noreply@yourdomain.com (or your verified sender email)
Sender Name: RGS Tools
```

**Important Notes:**
- **SMTP User** must be exactly: `apikey` (not your SendGrid username)
- **SMTP Password** is your full API key: `SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- **Sender Email** must be a verified sender in SendGrid

### Step 4: Verify Sender Email in SendGrid

1. Go to **SendGrid Dashboard** → **Settings** → **Sender Authentication**
2. Verify your sender email address (or domain)
3. Use that verified email as the **Sender Email** in Supabase

### Step 5: Test Email

1. Click **"Send Test Email"** in Supabase SMTP settings
2. Enter your email address
3. Check your inbox for the test email
4. If successful, click **Save**

## 📧 Update Email Rate Limit

After setting up SMTP:

1. Go to **Authentication** → **Rate Limits**
2. Click on **"Rate limit for sending emails"**
3. Increase to at least **100 emails/hour** (or higher based on your SendGrid plan)
4. Save changes

## 🔒 Security Best Practices

1. ✅ **API Key is in .env** (not committed to git)
2. ✅ **Never share your API key** publicly
3. ✅ **Rotate API keys** periodically
4. ✅ **Use restricted API keys** if possible (only Mail Send permissions)
5. ✅ **Monitor SendGrid usage** for unusual activity

## 🧪 Testing

### Test Password Reset Email:
1. Go to login screen
2. Click "Forgot Password?"
3. Enter your email
4. Check inbox for reset email
5. Verify email is delivered (not in spam)

### Test Signup Confirmation Email:
1. Register a new account
2. Check inbox for confirmation email
3. Verify email styling and links work

## 📊 SendGrid Plan Limits

Check your SendGrid plan for email limits:
- **Free Tier**: 100 emails/day
- **Essentials**: 40,000 emails/month
- **Pro**: 100,000+ emails/month

## 🚨 Troubleshooting

### Issue: "Authentication failed"
- Verify SMTP User is exactly `apikey`
- Verify API key is correct (no extra spaces)
- Check API key has "Mail Send" permissions

### Issue: "Sender not verified"
- Verify sender email in SendGrid dashboard
- Use a verified sender email address
- Complete domain authentication if using custom domain

### Issue: Emails going to spam
- Set up SPF/DKIM records for your domain
- Verify domain in SendGrid
- Use a professional sender name

### Issue: Rate limit still low
- Make sure SMTP is enabled and saved
- Refresh the Rate Limits page
- Contact Supabase support if issue persists

## 📋 Quick Checklist

- [ ] API key added to `.env` file
- [ ] SMTP enabled in Supabase
- [ ] SMTP credentials entered correctly
- [ ] Sender email verified in SendGrid
- [ ] Test email sent successfully
- [ ] Email rate limit increased
- [ ] Password reset email tested
- [ ] Signup confirmation email tested

## 🔗 Useful Links

- [SendGrid Dashboard](https://app.sendgrid.com/)
- [SendGrid API Keys](https://app.sendgrid.com/settings/api_keys)
- [SendGrid SMTP Settings](https://app.sendgrid.com/guide)
- [Supabase SMTP Settings](https://supabase.com/dashboard/project/_/settings/auth)

---

**Note**: Keep your API key secure! Never commit it to version control. The `.env` file is already in `.gitignore`.


