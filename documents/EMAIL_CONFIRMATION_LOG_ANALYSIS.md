# Email Confirmation - Log Analysis Guide

## 🔍 What I See in Your Logs

The errors you're seeing:
```
500: missing destination name scopes in *models
Endpoint: /token
```

**This is NOT related to email confirmation.** This is a token refresh error, which is a separate issue.

## 📧 What to Look For in Auth Logs for Email Issues

### Filter for Email-Related Logs

1. **In the "Search events" box**, try searching for:
   - `email`
   - `smtp`
   - `confirmation`
   - `signup`
   - `registration`

2. **Filter by Endpoint:**
   - Look for `/signup` or `/signup/v1/token` endpoints
   - These are where email confirmation emails are sent

3. **Look for These Specific Messages:**
   - ✅ `Email sent successfully` → Email was sent
   - ❌ `Failed to send email` → Email sending failed
   - ❌ `SMTP authentication failed` → SMTP credentials wrong
   - ❌ `Connection timeout` → SMTP connection issue
   - ❌ `Invalid sender email` → Sender email domain issue

## 🧪 How to Test Email Confirmation

### Step 1: Register a New User

1. **Open your app**
2. **Register a NEW user** (not login - emails are only sent on registration)
3. **Use your email address** (one you can check)

### Step 2: Immediately Check Logs

**Right after registration, in Supabase Auth Logs:**

1. **Filter by time**: Select "Last 5 minutes" or "Last hour"
2. **Search for**: `signup` or `email`
3. **Look for**:
   - A `/signup` endpoint call
   - Any email-related messages
   - Any SMTP errors

### Step 3: Check Resend Dashboard

**Go to**: https://resend.com/emails

**Look for**:
- Email sent to your address
- Delivery status
- Any error messages

## 🔍 What the Current Errors Mean

The errors you're seeing (`500: missing destination name scopes in *models`) are:
- **Related to**: Token refresh operations
- **NOT related to**: Email confirmation
- **Impact**: May affect session refresh, but not email sending

## ✅ Next Steps

1. **Register a new user** with your email
2. **Immediately check**:
   - Supabase Auth Logs → Filter for "signup" or "email"
   - Resend Dashboard → Check if email was sent
   - Your email inbox (and spam)

3. **Report back**:
   - Do you see a `/signup` endpoint in the logs?
   - Do you see any email-related messages?
   - Do you see an email attempt in Resend Dashboard?

## 🎯 Quick Test

**Right now, try this:**

1. Register a new user in your app
2. Go to Supabase Auth Logs
3. In the search box, type: `signup`
4. Check what appears
5. Also check Resend Dashboard → Emails

This will tell us if emails are being sent or if there's a configuration issue.



