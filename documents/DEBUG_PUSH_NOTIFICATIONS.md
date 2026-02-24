# Debug Push Notifications - App Not Sending

## 🔍 Problem
- ✅ Firebase test messages work (tokens are valid)
- ✅ User tokens are saved in database
- ❌ App notifications don't work

This means the issue is with the **Edge Function** or how the app calls it.

---

## Step 1: Check App Logs When Triggering Notification

**Action:** Trigger a notification (e.g., create a tool request) and check app logs for:

**Expected logs:**
```
📤 [Push] Sending notification to token: ...
📤 [Push] Title: ..., Body: ...
📥 [Push] Edge Function response status: 200
📥 [Push] Edge Function response data: {...}
✅ [Push] Notification sent successfully
```

**If you see errors:**
- `Function not found` → Edge Function not deployed
- `401 Unauthorized` → Secrets not configured
- `500 Internal Server Error` → Check Edge Function logs
- `❌ [Push] Edge Function error: ...` → Check error details

---

## Step 2: Check Edge Function Deployment

**Action:** Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification`

**Check:**
- [ ] Function exists and shows "Active" status
- [ ] Function was deployed recently
- [ ] No deployment errors

**If not deployed:**
```bash
cd supabase/functions/send-push-notification
supabase functions deploy send-push-notification
```

---

## Step 3: Check Edge Function Secrets

**Action:** Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification` → **Settings** → **Secrets**

**Verify these secrets exist:**
- [ ] `GOOGLE_PROJECT_ID`
- [ ] `GOOGLE_CLIENT_EMAIL`
- [ ] `GOOGLE_PRIVATE_KEY`

**If missing:**
1. Get from Firebase Console → Project Settings → Service Accounts
2. Add to Supabase Edge Function secrets
3. **Important:** `GOOGLE_PRIVATE_KEY` must include actual newlines (`\n`), not literal `\n` text

---

## Step 4: Check Edge Function Logs

**Action:** Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification` → **Logs**

**Look for:**
- Recent invocations when you trigger notifications
- Error messages
- Success messages

**Common errors:**
- `GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured` → Secrets missing
- `Failed to get access token` → Private key format issue
- `FCM v1 API error` → Token invalid or Firebase config issue

---

## Step 5: Test Edge Function Manually

**Action:** Test the Edge Function directly from Supabase Dashboard

1. Get your FCM token from database:
```sql
SELECT fcm_token FROM user_fcm_tokens WHERE platform = 'android' LIMIT 1;
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

**Expected:** `{"success": true, "name": "projects/.../messages/..."}`

**If it fails:**
- Check response error message
- Check Edge Function logs
- Verify secrets are correct

---

## Step 6: Verify Notification Triggers Are Called

**Check if push notifications are being triggered in code:**

1. **Tool Request:**
   - Location: `lib/screens/shared_tools_screen.dart` (line ~1054, 1071)
   - Should call: `PushNotificationService.sendToUser()` and `sendToAdmins()`

2. **Tool Issue:**
   - Location: `lib/providers/tool_issue_provider.dart` (line ~137)
   - Should call: `PushNotificationService.sendToAdmins()`

3. **New Tool:**
   - Location: `lib/providers/supabase_tool_provider.dart` (line ~52)
   - Should call: `PushNotificationService.sendToAdmins()`

**Check app logs when triggering these actions** - you should see `📤 [Push]` messages.

---

## 🐛 Common Issues

### Issue 1: "Function not found" or "404"
**Solution:**
- Deploy Edge Function: `supabase functions deploy send-push-notification`
- Verify function name is exactly: `send-push-notification`

### Issue 2: "Secrets not configured"
**Solution:**
- Go to Supabase Dashboard → Edge Functions → `send-push-notification` → Settings → Secrets
- Add all 3 secrets: `GOOGLE_PROJECT_ID`, `GOOGLE_CLIENT_EMAIL`, `GOOGLE_PRIVATE_KEY`
- **Important:** Private key must include actual newlines, not literal `\n` text

### Issue 3: "Edge Function returns 500"
**Solution:**
- Check Edge Function logs for detailed error
- Verify secrets are correct
- Check if private key format is correct (must include `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)

### Issue 4: "No logs in Edge Function"
**Solution:**
- Edge Function might not be getting called
- Check app logs for `📤 [Push]` messages
- Verify notifications are being triggered in code

### Issue 5: "Edge Function works manually but not from app"
**Solution:**
- Check app logs for errors when calling Edge Function
- Verify user is authenticated (Edge Function might require auth)
- Check if there are any network/firewall issues

---

## 📋 Quick Diagnostic Checklist

- [ ] App logs show `📤 [Push] Sending notification` when triggering
- [ ] Edge Function is deployed and active
- [ ] Edge Function secrets are configured (all 3)
- [ ] Edge Function logs show invocations
- [ ] Manual Edge Function test works
- [ ] App logs show Edge Function response

---

## 🎯 Most Likely Issues (in order)

1. **Edge Function not deployed** - Check Supabase Dashboard
2. **Secrets not configured** - Check Edge Function settings
3. **Private key format wrong** - Must include newlines
4. **Edge Function returning errors** - Check logs
5. **Notifications not being triggered** - Check app logs

---

## 📝 Next Steps

1. **First:** Check Edge Function logs in Supabase Dashboard
2. **Second:** Test Edge Function manually
3. **Third:** Check app logs when triggering notifications
4. **Fourth:** Verify secrets are configured correctly

Share the results and we can pinpoint the exact issue!

