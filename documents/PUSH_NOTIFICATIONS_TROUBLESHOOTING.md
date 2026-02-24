# Push Notifications Troubleshooting Guide

## 🔍 Understanding the Flow

### How Push Notifications Work

1. **App gets FCM token** → Saved to `user_fcm_tokens` table
2. **Event triggers notification** → Code calls `PushNotificationService.sendToUser()` or `sendToAdmins()`
3. **Service gets FCM tokens** → Queries `user_fcm_tokens` table
4. **Calls Edge Function** → `send-push-notification` function
5. **Edge Function sends to FCM** → Uses FCM v1 API
6. **FCM delivers to device** → Device receives notification
7. **App handles notification** → Shows local notification (foreground) or system notification (background)

---

## ⚠️ Important: Local vs Push Notifications

### Foreground (App Open)
- **Push notification arrives** → FCM delivers to app
- **App shows local notification** → This is CORRECT behavior
- **You'll see:** Local notification appears
- **This means:** Push notification IS working!

### Background (App Minimized)
- **Push notification arrives** → FCM delivers to device
- **System shows notification** → Android/iOS shows it
- **You'll see:** Notification in notification tray
- **This means:** Push notification IS working!

### Terminated (App Closed)
- **Push notification arrives** → FCM delivers to device
- **System shows notification** → Android/iOS shows it
- **Tapping opens app** → App handles the notification
- **This means:** Push notification IS working!

---

## 🐛 Common Confusion

**"Local notifications work but push doesn't"**

This is usually a misunderstanding:
- **If local notifications work** → FCM tokens are valid
- **If you see notifications in foreground** → Push notifications ARE working (they're just shown as local)
- **The issue might be:** Notifications not appearing in background/terminated state

**To verify push is working:**
1. Close the app completely
2. Trigger a notification
3. Check if notification appears → If yes, push is working!

---

## 🔧 Step-by-Step Diagnosis

### Step 1: Check FCM Tokens ✅

**SQL Query:**
```sql
SELECT user_id, platform, LEFT(fcm_token, 30) || '...' as token_preview, updated_at
FROM user_fcm_tokens
ORDER BY updated_at DESC;
```

**What to check:**
- Tokens exist for your user
- `platform` is correct (`android` or `ios`)
- `updated_at` is recent

**If no tokens:**
- Check app logs for `✅ [FCM] Token saved to Supabase successfully`
- Check RLS policies on `user_fcm_tokens` table
- Verify user is logged in

---

### Step 2: Check Edge Function ✅

**In Supabase Dashboard:**
1. Go to **Edge Functions** → `send-push-notification`
2. Check **Logs** tab
3. Look for recent invocations

**What to check:**
- Function is deployed and active
- Logs show invocations when notifications are triggered
- No errors in logs

**If function not deployed:**
```bash
cd supabase/functions/send-push-notification
supabase functions deploy send-push-notification
```

---

### Step 3: Check Edge Function Secrets ✅

**In Supabase Dashboard:**
1. Go to **Edge Functions** → `send-push-notification` → **Settings** → **Secrets**
2. Verify these exist:
   - `GOOGLE_PROJECT_ID`
   - `GOOGLE_CLIENT_EMAIL`
   - `GOOGLE_PRIVATE_KEY`

**Critical:** `GOOGLE_PRIVATE_KEY` must include actual newlines:
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
(multiple lines)
...
-----END PRIVATE KEY-----
```

**Not:**
```
-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----
```

---

### Step 4: Test Edge Function Manually ✅

**Get your FCM token:**
```sql
SELECT fcm_token FROM user_fcm_tokens WHERE user_id = 'YOUR_USER_ID' LIMIT 1;
```

**Test in Supabase Dashboard:**
1. Go to **Edge Functions** → `send-push-notification` → **Invoke**
2. Use payload:
```json
{
  "token": "YOUR_FCM_TOKEN",
  "title": "Test",
  "body": "Testing Edge Function"
}
```

**Expected Response:**
```json
{
  "success": true,
  "name": "projects/.../messages/..."
}
```

**If it fails:**
- Check response error message
- Check Edge Function logs
- Verify secrets are correct

---

### Step 5: Check App Logs ✅

**When triggering a notification, look for:**

```
📤 [Push] Sending notification to token: ...
📤 [Push] Title: ..., Body: ...
📥 [Push] Edge Function response status: 200
📥 [Push] Edge Function response data: {...}
✅ [Push] Notification sent successfully
```

**If you see errors:**
- `Function not found` → Deploy Edge Function
- `401 Unauthorized` → Check secrets
- `500 Internal Server Error` → Check Edge Function logs

---

### Step 6: Test with App Closed ✅

**This is the REAL test:**

1. **Close app completely** (swipe away from recent apps)
2. **Trigger notification** from another device/user
3. **Check if notification appears**

**If notification appears:**
- ✅ Push notifications ARE working!
- The issue might be with foreground handling (showing local notifications)

**If notification doesn't appear:**
- Check Edge Function logs
- Verify notification was sent
- Check device notification settings
- Test with Firebase Console directly

---

### Step 7: Test with Firebase Console ✅

**This bypasses your app and Edge Function:**

1. Go to **Firebase Console** → **Cloud Messaging** → **Send test message**
2. Enter your FCM token
3. Enter title and body
4. Click **Test**

**If this works:**
- ✅ FCM tokens are valid
- ✅ Firebase is configured correctly
- Issue is likely with Edge Function or app code

**If this doesn't work:**
- ❌ Firebase configuration issue
- ❌ Token might be invalid/expired
- Check Firebase project settings

---

## 🎯 Quick Diagnostic

### Run This SQL:
```sql
-- Get comprehensive status
SELECT 
  'FCM Tokens' as check_type,
  COUNT(*) as count,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(CASE WHEN platform = 'android' THEN 1 END) as android,
  COUNT(CASE WHEN platform = 'ios' THEN 1 END) as ios
FROM user_fcm_tokens;

-- Get your tokens
SELECT user_id, platform, LEFT(fcm_token, 30) || '...' as token, updated_at
FROM user_fcm_tokens
WHERE user_id = 'YOUR_USER_ID';
```

### Check Edge Function Logs:
1. Supabase Dashboard → Edge Functions → `send-push-notification` → Logs
2. Look for recent invocations
3. Check for errors

### Test Notification:
1. Close app completely
2. Trigger a notification (create tool request, report issue, etc.)
3. Check if notification appears
4. Check Edge Function logs to see if it was called

---

## 📝 What to Check Next

Based on your situation (tokens exist, permissions granted):

1. **Check Edge Function logs** - Are notifications being sent?
2. **Test Edge Function manually** - Does it work when invoked directly?
3. **Test with app closed** - Do notifications appear when app is terminated?
4. **Check Firebase Console** - Can you send test messages?

**Most likely issues:**
- Edge Function secrets not configured correctly
- Edge Function returning errors (check logs)
- Notifications being sent but not received (device/network issue)
- Local notifications working but confusion about foreground behavior

---

## 🚀 Next Steps

1. Run `VERIFY_PUSH_NOTIFICATIONS.sql` in Supabase
2. Check Edge Function logs for errors
3. Test Edge Function manually (Step 4)
4. Test with app closed (Step 6)
5. Test with Firebase Console (Step 7)

Share the results and we can pinpoint the exact issue!

