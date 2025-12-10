# Push Notifications Debugging Guide

## Common Issues and Solutions

### 1. Edge Function Not Deployed
**Symptoms:**
- Error: "Function not found" or 404
- Error: "Edge Function may not be deployed"

**Solution:**
```bash
cd supabase/functions/send-push-notification
supabase functions deploy send-push-notification
```

### 2. Missing Secrets in Supabase
**Symptoms:**
- Error: "GOOGLE_PROJECT_ID not configured"
- Error: "GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured"

**Solution:**
1. Go to Supabase Dashboard → Settings → Edge Functions → Secrets
2. Add these secrets:
   - `GOOGLE_PROJECT_ID` - Your Firebase project ID
   - `GOOGLE_CLIENT_EMAIL` - Service account email (from Firebase service account JSON)
   - `GOOGLE_PRIVATE_KEY` - Service account private key (from Firebase service account JSON)

### 3. FCM Tokens Not Saved
**Symptoms:**
- No tokens in `user_fcm_tokens` table
- Error: "No FCM token found for user"

**Check:**
1. Verify Firebase is initialized: Look for `✅ [FCM] Token obtained` in logs
2. Verify user is logged in: Token is only saved when user is authenticated
3. Check `user_fcm_tokens` table in Supabase Dashboard

### 4. Invalid Service Account Credentials
**Symptoms:**
- Error: "Failed to authenticate with Google"
- Error: "Failed to get access token"

**Solution:**
1. Download service account JSON from Firebase Console
2. Extract:
   - `project_id` → `GOOGLE_PROJECT_ID`
   - `client_email` → `GOOGLE_CLIENT_EMAIL`
   - `private_key` → `GOOGLE_PRIVATE_KEY` (keep newlines as `\n`)

### 5. FCM v1 API Errors
**Symptoms:**
- Error: "Failed to send notification"
- Error: "Invalid token" or "Token not found"

**Check:**
1. Verify FCM token is valid (not expired)
2. Verify token format matches FCM v1 API requirements
3. Check Firebase Console → Cloud Messaging → Verify project settings

## Testing Steps

### Step 1: Verify FCM Token is Saved
1. Log in to the app
2. Check console logs for: `✅ [FCM] Token saved to Supabase`
3. Go to Supabase Dashboard → Table Editor → `user_fcm_tokens`
4. Verify your user_id has a token

### Step 2: Test Edge Function Directly
1. Get your FCM token from `user_fcm_tokens` table
2. Go to Supabase Dashboard → Edge Functions → `send-push-notification`
3. Click "Invoke" and use this body:
```json
{
  "token": "YOUR_FCM_TOKEN",
  "title": "Test Notification",
  "body": "This is a test"
}
```

### Step 3: Check Edge Function Logs
1. Go to Supabase Dashboard → Edge Functions → `send-push-notification` → Logs
2. Look for errors or success messages

### Step 4: Verify Secrets
1. Go to Supabase Dashboard → Settings → Edge Functions → Secrets
2. Verify all three secrets are set:
   - `GOOGLE_PROJECT_ID`
   - `GOOGLE_CLIENT_EMAIL`
   - `GOOGLE_PRIVATE_KEY`

## Debug Checklist

- [ ] Firebase initialized successfully
- [ ] FCM token obtained and logged
- [ ] FCM token saved to `user_fcm_tokens` table
- [ ] Edge Function deployed
- [ ] All three secrets configured in Supabase
- [ ] Service account has Firebase Cloud Messaging API enabled
- [ ] Test notification sent successfully from Edge Function
- [ ] App receives notification (foreground/background/terminated)

