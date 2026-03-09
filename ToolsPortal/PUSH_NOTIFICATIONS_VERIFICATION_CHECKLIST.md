# Push Notifications Verification Checklist

## ✅ Step-by-Step Verification

### Step 1: Verify FCM Tokens Are Saved ✅

**Action:** Run this SQL in Supabase SQL Editor:
```sql
SELECT * FROM user_fcm_tokens ORDER BY updated_at DESC LIMIT 10;
```

**Expected Result:**
- You should see tokens with `platform` = 'android' or 'ios'
- `fcm_token` should be a long string (not null)
- `updated_at` should be recent

**If tokens are missing:**
- Check app logs for `✅ [FCM] Token saved to Supabase successfully`
- Check RLS policies on `user_fcm_tokens` table
- Verify user is logged in when token is obtained

---

### Step 2: Verify Edge Function is Deployed ✅

**Action:** 
1. Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification`
2. Check if function exists and shows "Active" status
3. Click on **Logs** tab
4. Look for recent invocations

**Expected Result:**
- Function should be deployed and active
- Logs should show recent invocations (if notifications were triggered)

**If function is not deployed:**
```bash
supabase functions deploy send-push-notification
```

---

### Step 3: Verify Edge Function Secrets ✅

**Action:**
1. Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification` → **Settings** → **Secrets**
2. Verify these secrets exist:
   - `GOOGLE_PROJECT_ID`
   - `GOOGLE_CLIENT_EMAIL`
   - `GOOGLE_PRIVATE_KEY`

**Expected Result:**
- All 3 secrets should be present
- `GOOGLE_PRIVATE_KEY` should include `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`
- Private key should have `\n` newlines (not literal `\n` text)

**Common Issue:**
- Private key missing newlines → Edge Function will fail with authentication error
- Wrong secret names → Edge Function will return "not configured" error

---

### Step 4: Test Edge Function Manually ✅

**Action:**
1. Get your FCM token from database:
```sql
SELECT fcm_token FROM user_fcm_tokens WHERE user_id = 'YOUR_USER_ID' LIMIT 1;
```

2. Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification` → **Invoke**
3. Use this payload:
```json
{
  "token": "YOUR_FCM_TOKEN_HERE",
  "title": "Manual Test",
  "body": "Testing Edge Function manually"
}
```

4. Click **Invoke** and check response

**Expected Result:**
- Response should be: `{"success": true, "name": "projects/.../messages/..."}`
- Status should be `200`

**If it fails:**
- Check response error message
- Check Edge Function logs for details
- Verify secrets are correct

---

### Step 5: Check App Logs When Triggering Notification ✅

**Action:**
1. Trigger a notification (e.g., create a tool request, report an issue)
2. Check app logs/console for these messages:
   - `📤 [Push] Sending notification to token: ...`
   - `📥 [Push] Edge Function response status: ...`
   - `✅ [Push] Notification sent successfully` OR error messages

**Expected Result:**
- Should see `📤 [Push] Sending...` message
- Should see `📥 [Push] Edge Function response status: 200`
- Should see `✅ [Push] Notification sent successfully`

**If you see errors:**
- `Function not found` → Edge Function not deployed
- `401 Unauthorized` → Secrets not configured
- `500 Internal Server Error` → Check Edge Function logs

---

### Step 6: Check Edge Function Logs ✅

**Action:**
1. Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification` → **Logs**
2. Look for recent invocations
3. Check for errors

**Expected Result:**
- Should see log entries when notifications are triggered
- Should see `✅ Successfully obtained access token`
- Should see `Push notification sent successfully`

**Common Errors:**
- `GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured` → Secrets missing
- `Failed to get access token` → Private key format issue
- `FCM v1 API error` → Token invalid or Firebase config issue

---

### Step 7: Test with App Closed (Background/Terminated) ✅

**Action:**
1. **Close the app completely** (swipe away from recent apps)
2. Trigger a notification from another device/user
3. **Check if notification appears** on device

**Expected Result:**
- Notification should appear even when app is closed
- Tapping notification should open the app

**If notification doesn't appear:**
- Check Edge Function logs to see if it was called
- Check if notification was sent successfully
- Verify device has internet connection
- Check notification permissions in device settings

---

### Step 8: Test with App in Foreground ✅

**Action:**
1. **Open the app** (keep it in foreground)
2. Trigger a notification
3. **Check if notification appears**

**Expected Result:**
- Should see a local notification (this is correct behavior)
- App logs should show: `📱 [FCM] Foreground message received`
- Should see: `✅ [FCM] Local notification shown`

**Note:** In foreground, FCM sends the notification, but the app shows it as a local notification. This is expected behavior.

---

### Step 9: Verify Notification Permissions ✅

**Android:**
1. Go to **Device Settings** → **Apps** → **RGS** → **Notifications**
2. Verify notifications are enabled
3. Check that notification channels are enabled

**iOS:**
1. Go to **Device Settings** → **RGS** → **Notifications**
2. Verify "Allow Notifications" is ON
3. Check that "Lock Screen", "Notification Center", and "Banners" are enabled

---

### Step 10: Test Firebase Console Directly ✅

**Action:**
1. Go to **Firebase Console** → Your project → **Cloud Messaging**
2. Click **Send test message**
3. Enter your FCM token (from database)
4. Enter title and body
5. Click **Test**

**Expected Result:**
- Notification should appear on device immediately
- This tests if FCM itself is working

**If this works but app notifications don't:**
- Edge Function might be the issue
- Check Edge Function logs
- Verify Edge Function is using correct FCM token

**If this doesn't work:**
- Firebase configuration issue
- Token might be invalid
- Check Firebase project settings

---

## 🔍 Diagnostic Tools

### Use Test Service in App

Add this to any screen (e.g., settings screen) to test:

```dart
import '../services/push_notification_test_service.dart';

// Test push notification
final result = await PushNotificationTestService.testPushToCurrentUser();
print('Test result: $result');

// Get diagnostics
final diagnostics = await PushNotificationTestService.getDiagnostics();
print('Diagnostics: $diagnostics');
```

### Check Database

Run `VERIFY_PUSH_NOTIFICATIONS.sql` in Supabase SQL Editor to get comprehensive diagnostics.

---

## 🐛 Common Issues and Solutions

### Issue 1: "No FCM tokens found"
**Symptoms:** App logs show `⚠️ [Push] No FCM tokens found for user`
**Solution:**
- Check if `_sendTokenToServer()` is being called
- Verify user is logged in when token is obtained
- Check RLS policies on `user_fcm_tokens` table
- Run: `SELECT * FROM user_fcm_tokens WHERE user_id = 'YOUR_USER_ID';`

### Issue 2: "Edge Function not found"
**Symptoms:** App logs show `Function not found` or `404`
**Solution:**
- Deploy Edge Function: `supabase functions deploy send-push-notification`
- Verify function name is exactly: `send-push-notification`
- Check Supabase Dashboard → Edge Functions

### Issue 3: "Secrets not configured"
**Symptoms:** Edge Function returns `GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured`
**Solution:**
- Go to Supabase Dashboard → Edge Functions → `send-push-notification` → Settings → Secrets
- Add all 3 secrets: `GOOGLE_PROJECT_ID`, `GOOGLE_CLIENT_EMAIL`, `GOOGLE_PRIVATE_KEY`
- **Important:** Private key must include actual newlines (`\n`), not literal `\n` text
- Redeploy function after adding secrets

### Issue 4: "Notifications work in foreground but not background"
**This is CORRECT behavior:**
- **Foreground:** Shows local notification (expected)
- **Background:** Should show push notification directly
- **Terminated:** Should show push notification directly

**If background doesn't work:**
- Check Edge Function logs
- Verify notification was sent successfully
- Check device notification settings

### Issue 5: "Local notifications work but push doesn't"
**This means:**
- FCM tokens are valid (local notifications use FCM)
- But Edge Function might be failing
- **Check Edge Function logs** for errors
- Test Edge Function manually (Step 4)

### Issue 6: "Token invalid" or "Authentication error"
**Symptoms:** Edge Function logs show token or auth errors
**Solution:**
- Verify FCM token is correct (not expired)
- Check Firebase project ID matches
- Verify service account has Firebase Cloud Messaging API enabled
- Check private key format (must include newlines)

---

## 📋 Quick Test Checklist

Run through these in order:

- [ ] FCM tokens exist in database (Step 1)
- [ ] Edge Function is deployed (Step 2)
- [ ] Edge Function secrets are configured (Step 3)
- [ ] Manual Edge Function test works (Step 4)
- [ ] App logs show push notification attempts (Step 5)
- [ ] Edge Function logs show successful sends (Step 6)
- [ ] Notification appears when app is closed (Step 7)
- [ ] Notification appears when app is in foreground (Step 8)
- [ ] Notification permissions are granted (Step 9)
- [ ] Firebase Console test works (Step 10)

---

## 🎯 Next Steps

1. **Run `VERIFY_PUSH_NOTIFICATIONS.sql`** to check database state
2. **Test Edge Function manually** using Step 4
3. **Check Edge Function logs** for any errors
4. **Use test service** in app to diagnose issues
5. **Review app logs** when triggering notifications

If all steps pass but notifications still don't work, the issue might be:
- Device-specific (some Android launchers don't support badges)
- Network/firewall blocking FCM
- Token expiration (tokens can expire and need refresh)

