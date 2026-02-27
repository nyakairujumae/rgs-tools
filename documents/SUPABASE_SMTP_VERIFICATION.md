# Supabase SMTP Configuration Verification

## ✅ Step 1: Verify SMTP Settings Are Saved

1. **Go to Supabase Dashboard**
   - Navigate to: **Settings** → **Auth** → **SMTP Settings**

2. **Verify all fields are filled correctly:**
   ```
   ✅ Enable Custom SMTP: ON
   ✅ SMTP Host: smtp.resend.com
   ✅ SMTP Port: 587
   ✅ SMTP User: resend
   ✅ SMTP Password: re_QFStbTxg_DVBWUE5bpwSaBZzvCcBUgtmJ
   ✅ Sender Email: noreply@rgstools.app
   ✅ Sender Name: RGS Tools
   ```

3. **Click "Save"** (even if you don't see a test button, make sure to save)

## ✅ Step 2: Enable Email Confirmations

1. **Go to Supabase Dashboard**
   - Navigate to: **Authentication** → **Settings**

2. **Find "Enable email confirmations"**
   - Toggle it **ON** (enabled)
   - Click **Save**

## ✅ Step 3: Test Email Confirmation (Real Test)

Since Supabase may not have a test email button, test it by registering a new user:

1. **Open your app**
2. **Register a new user** (use a real email address you can access)
3. **Check your email inbox** (and spam folder)
4. **You should receive a confirmation email** from `noreply@rgstools.app`

## ✅ Step 4: Verify Email Was Sent

1. **Check Resend Dashboard**: https://resend.com/emails
   - Look for the confirmation email
   - Check delivery status:
     - ✅ **Delivered**: Email was sent successfully
     - ⚠️ **Pending**: Email is queued (wait a moment)
     - ❌ **Failed**: Check error message

2. **Check Supabase Logs**:
   - Go to **Logs** → **Auth Logs**
   - Look for email sending attempts
   - Check for any error messages

## ✅ Step 5: Click Confirmation Link

1. **Open the confirmation email** you received
2. **Click the confirmation link**
3. **The app should open** and the user should be authenticated
4. **Verify in Supabase Dashboard**:
   - Go to **Authentication** → **Users**
   - Find the user you registered
   - Email should show as **"Confirmed"**

## Troubleshooting

### If you don't receive the confirmation email:

1. **Check spam/junk folder**
2. **Check Resend dashboard** for delivery status
3. **Verify SMTP settings are saved** (go back and check)
4. **Check Supabase Auth Logs** for errors
5. **Verify email confirmations are enabled**

### If email shows as "Failed" in Resend:

1. **Double-check SMTP settings** in Supabase
2. **Verify API key is correct** and has sending permission
3. **Check Resend dashboard** for specific error message

### If email is sent but not received:

1. **Check spam folder**
2. **Try a different email provider** (Gmail, Outlook, etc.)
3. **Check email filters** that might block automated emails

## Quick Verification Checklist

- [ ] SMTP settings saved in Supabase
- [ ] Email confirmations enabled
- [ ] Registered a test user
- [ ] Checked email inbox (and spam)
- [ ] Checked Resend dashboard for email status
- [ ] Checked Supabase Auth Logs
- [ ] Clicked confirmation link (if email received)
- [ ] Verified user email is "Confirmed" in Supabase

## Next Steps

Once email confirmation is working:
1. ✅ Users will receive confirmation emails
2. ✅ Users must click the link to confirm their email
3. ✅ After confirmation, users can log in
4. ✅ Deep linking will open the app automatically


