# Push Notifications Diagnostic Guide

## Step-by-Step Verification

### Step 1: Verify FCM Tokens Are Saved ✅

**Check in Supabase:**
1. Go to **Table Editor** → `user_fcm_tokens`
2. Verify you see tokens for your user
3. Check that `platform` is set correctly (`android` or `ios`)
4. Check that `updated_at` is recent

**Or run SQL:**
```sql
SELECT * FROM user_fcm_tokens WHERE user_id = 'YOUR_USER_ID';
```

**Expected:** You should see at least one token per device

---

### Step 2: Verify Edge Function is Deployed ✅

**Check in Supabase Dashboard:**
1. Go to **Edge Functions** → `send-push-notification`
2. Verify function exists and is deployed
3. Check **Logs** for any errors
4. Verify **Secrets** are set:
   - `GOOGLE_PROJECT_ID`
   - `GOOGLE_CLIENT_EMAIL`
   - `GOOGLE_PRIVATE_KEY`

**Test Edge Function Manually:**
1. Go to **Edge Functions** → `send-push-notification` → **Invoke**
2. Use this test payload:
```json
{
  "token": "YOUR_FCM_TOKEN_FROM_DATABASE",
  "title": "Test Notification",
  "body": "This is a test push notification"
}
```
3. Check response - should return `{"success": true}`

---

### Step 3: Verify Notification Triggers in Code ✅

**Check if triggers are being called:**

1. **New Technician Registration:**
   - Location: `lib/providers/auth_provider.dart` (line ~775)
   - Should call: `PushNotificationService.sendToAdmins()`

2. **Tool Request:**
   - Location: `lib/screens/shared_tools_screen.dart` (line ~1054, 1071)
   - Should call: `PushNotificationService.sendToUser()` and `sendToAdmins()`

3. **Tool Issue:**
   - Location: `lib/providers/tool_issue_provider.dart` (line ~137)
   - Should call: `PushNotificationService.sendToAdmins()`

4. **User Approved:**
   - Location: `lib/providers/pending_approvals_provider.dart` (line ~258)
   - Should call: `PushNotificationService.sendToUser()`

**Check app logs for:**
- `📤 [Push] Sending notification to token: ...`
- `📥 [Push] Edge Function response status: ...`
- `✅ [Push] Notification sent successfully`

---

### Step 4: Check for Local Notification Conflicts ⚠️

**Issue:** Local notifications might be working, but push notifications aren't.

**How to verify:**
1. **Close the app completely** (not just background)
2. **Trigger a notification** (e.g., create a tool request)
3. **Check if notification appears** - if yes, push is working
4. **If no notification:** Check Edge Function logs

**Foreground vs Background:**
- **Foreground:** App shows local notification (this is correct behavior)
- **Background:** Should receive push notification directly
- **Terminated:** Should receive push notification directly

---

### Step 5: Verify Edge Function Response ✅

**Check Edge Function Logs:**
1. Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification` → **Logs**
2. Look for recent invocations
3. Check for errors:
   - `GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured`
   - `Invalid token`
   - `Authentication error`

**Common Issues:**
- **Secrets not set:** Function will return error about missing secrets
- **Wrong secret format:** Private key must include `\n` newlines
- **Invalid token:** Token might be expired or invalid

---

### Step 6: Test Push Notification Manually 🧪

**Create a test function in your app:**

Add this to a test screen or call it manually:

```dart
Future<void> testPushNotification() async {
  final user = SupabaseService.client.auth.currentUser;
  if (user == null) {
    print('❌ No user logged in');
    return;
  }
  
  // Get your own FCM token
  final tokens = await SupabaseService.client
      .from('user_fcm_tokens')
      .select('fcm_token, platform')
      .eq('user_id', user.id)
      .limit(1)
      .single();
  
  if (tokens == null || tokens['fcm_token'] == null) {
    print('❌ No FCM token found for user');
    return;
  }
  
  final token = tokens['fcm_token'] as String;
  print('📤 Testing push notification to token: ${token.substring(0, 20)}...');
  
  // Send test notification
  final success = await PushNotificationService.sendToToken(
    token: token,
    title: 'Test Notification',
    body: 'This is a test push notification from the app',
  );
  
  if (success) {
    print('✅ Test notification sent successfully');
  } else {
    print('❌ Test notification failed');
  }
}
```

---

### Step 7: Check Firebase Console 🔥

**Verify in Firebase Console:**
1. Go to **Firebase Console** → Your project
2. Go to **Cloud Messaging** → **Send test message**
3. Enter your FCM token (from database)
4. Send test message
5. **If this works:** Edge Function might be the issue
6. **If this doesn't work:** Firebase configuration issue

---

### Step 8: Verify Notification Permissions ✅

**Android:**
- Check app settings → Notifications → Should be enabled
- Check `AndroidManifest.xml` has `POST_NOTIFICATIONS` permission

**iOS:**
- Check app settings → Notifications → Should be enabled
- Check that permissions were requested in code

---

## Common Issues and Solutions

### Issue 1: "No FCM tokens found"
**Solution:** 
- Check if `_sendTokenToServer()` is being called
- Check RLS policies on `user_fcm_tokens` table
- Verify user is logged in when token is saved

### Issue 2: "Edge Function not found"
**Solution:**
- Deploy Edge Function: `supabase functions deploy send-push-notification`
- Check function name matches exactly: `send-push-notification`

### Issue 3: "Secrets not configured"
**Solution:**
- Go to Supabase Dashboard → Edge Functions → `send-push-notification` → Settings → Secrets
- Add: `GOOGLE_PROJECT_ID`, `GOOGLE_CLIENT_EMAIL`, `GOOGLE_PRIVATE_KEY`
- **Important:** Private key must include `\n` newlines

### Issue 4: "Notifications work in foreground but not background"
**This is expected behavior:**
- Foreground: Shows local notification (correct)
- Background: Should show push notification
- If background doesn't work: Check Edge Function logs

### Issue 5: "Local notifications work but push doesn't"
**This means:**
- FCM is working (tokens are valid)
- Local notifications are working
- But Edge Function might be failing
- **Check Edge Function logs** for errors

---

## Quick Diagnostic Checklist

- [ ] FCM tokens exist in `user_fcm_tokens` table
- [ ] Edge Function `send-push-notification` is deployed
- [ ] Edge Function secrets are configured (GOOGLE_PROJECT_ID, GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY)
- [ ] Notification permissions are granted on device
- [ ] App logs show `📤 [Push] Sending notification` messages
- [ ] Edge Function logs show successful invocations
- [ ] Test notification from Firebase Console works
- [ ] Test notification from app code works

---

## Next Steps

1. **Run `VERIFY_PUSH_NOTIFICATIONS.sql`** in Supabase SQL Editor
2. **Check Edge Function logs** for errors
3. **Test manually** using the test function above
4. **Check Firebase Console** to verify tokens are valid
5. **Review app logs** when triggering notifications

