# Quick Fix Guide: Firebase, Notifications, Email Confirmation

## 🚨 Issues to Fix
1. **Firebase failed** - Initialization errors
2. **Notifications failed** - Push notifications not working
3. **Email confirmation failed** - Users can't confirm emails

---

## 1️⃣ FIREBASE FIX

### Check Current Status
Run this in terminal to see Firebase errors:
```bash
flutter run --verbose 2>&1 | grep -i firebase
```

### Common Issues & Fixes

#### Issue A: Firebase Not Initializing
**Symptoms:** `Firebase initialization failed: PlatformException`

**Fix:**
1. Verify `ios/Runner/GoogleService-Info.plist` exists
2. Verify `android/app/google-services.json` exists
3. Check Firebase SDK versions in `pubspec.yaml` match

#### Issue B: Channel Errors
**Symptoms:** `Unable to establish connection`

**Fix:** Already handled in code with delays and error handling

### Verification
After fix, you should see in logs:
```
✅ [Firebase] Initialized successfully
✅ [Firebase] FCM service initialized
```

---

## 2️⃣ PUSH NOTIFICATIONS FIX

### Step 1: Verify FCM Token is Retrieved
Check logs for:
```
✅ [FCM] Token retrieved: <token>
```

### Step 2: Verify Token is Sent to Server
Check Supabase table:
```sql
SELECT * FROM user_fcm_tokens WHERE user_id = '<your-user-id>';
```

### Step 3: Verify Edge Function is Deployed
```bash
cd "/Users/jumae/Desktop/rgs app"
supabase functions list
```

Should show: `send-push-notification`

### Step 4: Verify Edge Function Secrets
In Supabase Dashboard → Edge Functions → Secrets:
- `GOOGLE_PROJECT_ID`
- `GOOGLE_CLIENT_EMAIL`
- `GOOGLE_PRIVATE_KEY`

### Step 5: Test Push Notification
```bash
# Call Edge Function directly
curl -X POST https://<your-project>.supabase.co/functions/v1/send-push-notification \
  -H "Authorization: Bearer <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "<fcm-token>",
    "title": "Test",
    "body": "Test notification"
  }'
```

### Common Issues
- **Token not stored:** Check `_sendFCMTokenToServer` is called after login
- **Edge Function not deployed:** Run `supabase functions deploy send-push-notification`
- **Missing secrets:** Add them in Supabase Dashboard

---

## 3️⃣ EMAIL CONFIRMATION FIX

### Step 1: Run SQL Script
**CRITICAL:** Run this in Supabase SQL Editor:
```sql
-- File: FIX_EMAIL_CONFIRMATION_FLOW.sql
-- This ensures users are only created AFTER email confirmation
```

### Step 2: Verify Email Confirmation is Enabled
Supabase Dashboard → Authentication → Settings:
- ✅ **Enable email confirmations** should be ON

### Step 3: Update Email Template
Supabase Dashboard → Authentication → Email Templates → **Confirm signup**:
- Copy content from `EMAIL_TEMPLATE_FIXED.html`
- Paste into template editor
- Save

### Step 4: Verify Redirect URL
Supabase Dashboard → Authentication → URL Configuration:
- Add: `com.rgs.app://auth/callback`

### Step 5: Verify SMTP (Resend)
Supabase Dashboard → Authentication → SMTP Settings:
- Provider: Resend
- API Key: Your Resend API key
- From email: Your verified domain email

### Step 6: Test Email Confirmation
1. Register a new user
2. Check email inbox (and spam)
3. Click confirmation link
4. Should open app and confirm email
5. User record should be created in `public.users`

### Common Issues
- **No email sent:** Check Resend logs, verify SMTP settings
- **Link doesn't work:** Check redirect URL is configured
- **User created before confirmation:** SQL script not run

---

## 🔧 IMMEDIATE ACTIONS

### Action 1: Check Firebase Logs
```bash
flutter run --verbose 2>&1 | tee firebase_logs.txt
# Look for Firebase initialization messages
```

### Action 2: Check FCM Token
In app, after login, check logs for:
```
✅ [FCM] Token sent to server
```

### Action 3: Verify SQL Script
Run this query in Supabase SQL Editor:
```sql
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE event_object_table = 'users';
```

Should show: `on_auth_user_confirmed` trigger

### Action 4: Test Email
1. Register with a test email
2. Check Supabase Auth Logs (Dashboard → Authentication → Logs)
3. Check Resend Dashboard for email status
4. Check email inbox

---

## 📋 CHECKLIST

### Firebase
- [ ] `GoogleService-Info.plist` exists
- [ ] `google-services.json` exists
- [ ] Firebase initializes without errors
- [ ] FCM service initializes

### Notifications
- [ ] FCM token is retrieved
- [ ] Token is stored in `user_fcm_tokens` table
- [ ] Edge Function is deployed
- [ ] Edge Function secrets are configured
- [ ] Test notification works

### Email Confirmation
- [ ] SQL script is run
- [ ] Email confirmation is enabled
- [ ] Email template is updated
- [ ] Redirect URL is configured
- [ ] SMTP is configured
- [ ] Test email is received

---

## 🆘 If Still Not Working

1. **Share specific error messages** from logs
2. **Check Supabase Dashboard** for errors
3. **Verify all configuration** matches this guide
4. **Test each component** individually



