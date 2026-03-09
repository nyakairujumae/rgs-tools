# Push Notification Diagnosis: Why Console Tests Work But App Notifications Don't

## 🔍 The Key Difference

### Firebase Console Tests ✅
- **Bypasses everything**: Sends directly to FCM using the token you manually provide
- **No database involved**: Doesn't query `user_fcm_tokens` table
- **No edge function**: Doesn't use Supabase Edge Function
- **Direct FCM API**: Uses Firebase Console's own authentication

### App-Triggered Notifications ❌
- **Full flow**: App → `PushNotificationService` → Database Query → Edge Function → FCM API
- **Requires database**: Must query `user_fcm_tokens` table to get tokens
- **Requires edge function**: Must call Supabase Edge Function
- **Requires OAuth2**: Edge function must authenticate with Google

## 🚨 Common Issues & Solutions

### Issue 1: Tokens Not in Database

**Symptoms:**
- Logs show: `⚠️ [Push] No FCM tokens found for user: ...`
- `sendToAdmins()` returns 0 success count

**Causes:**
1. Token never saved after login
2. Token saved but user logged out (token deleted)
3. RLS policy blocking INSERT/UPDATE

**Diagnosis:**
Check logs for:
```
📤 [FCM] ========== SAVING TOKEN ==========
✅ [FCM] Token verified in database
```

If you see `⚠️ [FCM] Token not found in database after save`, RLS is blocking.

**Solution:**
1. Check RLS policies on `user_fcm_tokens` table:
   ```sql
   -- Should allow users to insert/update their own tokens
   CREATE POLICY "Users can insert their own tokens"
     ON user_fcm_tokens FOR INSERT
     WITH CHECK (auth.uid() = user_id);
   
   CREATE POLICY "Users can update their own tokens"
     ON user_fcm_tokens FOR UPDATE
     USING (auth.uid() = user_id);
   ```

2. Verify token is saved:
   - Check Supabase Dashboard → Table Editor → `user_fcm_tokens`
   - Look for your user_id and platform (ios/android)

### Issue 2: RLS Blocking Token Queries

**Symptoms:**
- `sendToAdmins()` finds admins but `sendToUser()` finds 0 tokens
- Logs show: `⚠️ [Push] Could not query tokens table (RLS may be blocking)`

**Causes:**
- RLS policy doesn't allow reading tokens for other users (needed for admin notifications)

**Solution:**
Add RLS policy to allow admins to read all tokens:
```sql
-- Allow admins to read all tokens (for sending notifications)
CREATE POLICY "Admins can read all tokens"
  ON user_fcm_tokens FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );
```

### Issue 3: Token Expiration/Invalid Tokens

**Symptoms:**
- Edge function returns 404 with `UNREGISTERED` error
- Logs show: `❌ [Push] FCM token is UNREGISTERED`

**Causes:**
1. App was uninstalled/reinstalled
2. Token expired and wasn't refreshed
3. App data was cleared

**Solution:**
The code already handles this by:
1. Detecting `UNREGISTERED` errors
2. Deleting invalid tokens from database
3. App will generate new token on next launch

**Verify:**
- Check if `onTokenRefresh` listener is working:
  ```
  🔄 [FCM] ========== TOKEN REFRESHED ==========
  🔄 [FCM] User is logged in, saving refreshed token...
  ```

### Issue 4: Edge Function Not Being Called

**Symptoms:**
- No logs from edge function
- `sendToToken()` completes but no notification received

**Diagnosis:**
Check logs for:
```
📤 [Push] ========== CALLING EDGE FUNCTION ==========
📤 [Push] Invoking Edge Function at: ...
📥 [Push] Edge Function call completed in ...ms
```

If you don't see these logs, `sendToToken()` isn't being called.

**Solution:**
1. Verify `sendToAdmins()` is being called:
   ```
   📤 [Push] ========== SENDING TO ADMINS ==========
   ```
2. Check if admins are found:
   ```
   ✅ [Push] Found X admin users via RPC function
   ```
3. Verify `sendToUser()` is called for each admin:
   ```
   📤 [Push] Sending to admin: email@example.com (user_id)
   ```

### Issue 5: Edge Function Errors

**Symptoms:**
- Edge function called but returns error
- Logs show: `❌ [Push] Edge Function FAILED`

**Common Errors:**

#### 401 Unauthorized
- **Cause**: Missing or invalid Google service account credentials
- **Solution**: Check Supabase Edge Function secrets:
  - `GOOGLE_PROJECT_ID`
  - `GOOGLE_CLIENT_EMAIL`
  - `GOOGLE_PRIVATE_KEY`

#### 404 Not Found
- **Cause**: Edge function not deployed or FCM token invalid
- **Solution**: 
  1. Deploy edge function: `supabase functions deploy send-push-notification`
  2. Check if token is valid (see Issue 3)

#### 500 Internal Server Error
- **Cause**: Edge function code error or missing secrets
- **Solution**: Check Supabase Dashboard → Edge Functions → Logs

### Issue 6: Silent Failures

**Symptoms:**
- No errors in logs but notifications not received
- `sendToAdmins()` returns success count > 0 but no notifications

**Causes:**
1. Errors caught but not logged
2. Async operations not awaited
3. Exceptions swallowed

**Solution:**
The code now has extensive logging. Check for:
```
✅ [Push] ========== ADMIN NOTIFICATION SUMMARY ==========
✅ [Push] Total admins: X
✅ [Push] Success: Y
✅ [Push] Failed: Z
```

If Success > 0 but no notifications, check Edge Function logs.

## 🔧 Step-by-Step Diagnosis

### Step 1: Verify Tokens Are Saved
1. Open app and log in
2. Check logs for: `✅ [FCM] Token verified in database`
3. Check Supabase Dashboard → `user_fcm_tokens` table
4. Verify your user_id and platform exist

### Step 2: Trigger a Notification
1. Create a tool request or report an issue
2. Watch logs for:
   ```
   📤 [Push] ========== SENDING TO ADMINS ==========
   ✅ [Push] Found X admin users
   📤 [Push] Sending to admin: ...
   ```

### Step 3: Check Token Queries
1. Look for: `📊 [Push] Found X token(s) for user`
2. If 0 tokens found, see Issue 1 or 2

### Step 4: Check Edge Function Calls
1. Look for: `📤 [Push] ========== CALLING EDGE FUNCTION ==========`
2. Check response: `📥 [Push] Edge Function response status: 200`
3. If not 200, see Issue 5

### Step 5: Check Edge Function Logs
1. Go to Supabase Dashboard → Edge Functions → `send-push-notification` → Logs
2. Look for:
   - `✅ OAuth2 access token obtained successfully`
   - `✅ Final FCM payload`
   - `📥 FCM API response status: 200`

### Step 6: Verify FCM API Response
1. Edge function logs should show: `Push notification sent successfully`
2. Response should include: `"name": "projects/.../messages/..."`

## 🎯 Quick Fixes

### Fix 1: Force Token Refresh
```dart
// In app, call:
await FirebaseMessagingService.refreshToken();
```

### Fix 2: Manually Save Token
```dart
// After login, ensure token is saved:
final token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await FirebaseMessagingService.sendTokenToServer(token, userId);
}
```

### Fix 3: Test Edge Function Directly
```bash
# Test edge function with curl:
curl -X POST \
  https://YOUR_PROJECT.supabase.co/functions/v1/send-push-notification \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "YOUR_FCM_TOKEN",
    "title": "Test",
    "body": "Test notification"
  }'
```

## 📊 Expected Log Flow (Success)

```
1. Token Saved:
   ✅ [FCM] Token verified in database

2. Notification Triggered:
   📤 [Push] ========== SENDING TO ADMINS ==========
   ✅ [Push] Found 2 admin users via RPC function

3. For Each Admin:
   📤 [Push] Sending to admin: admin@example.com (user_id)
   📊 [Push] Found 1 token(s) for user
   📤 [Push] ========== CALLING EDGE FUNCTION ==========
   📥 [Push] Edge Function call completed in 500ms
   📥 [Push] Edge Function response status: 200
   ✅ [Push] Notification sent successfully

4. Summary:
   ✅ [Push] ========== ADMIN NOTIFICATION SUMMARY ==========
   ✅ [Push] Total admins: 2
   ✅ [Push] Success: 2
   ✅ [Push] Failed: 0
```

## 🚨 If Console Tests Work But App Doesn't

This means:
- ✅ FCM tokens are valid
- ✅ Device can receive notifications
- ✅ Firebase is configured correctly
- ❌ **Problem is in the app → edge function → FCM flow**

**Most likely causes:**
1. Tokens not in database (Issue 1)
2. RLS blocking queries (Issue 2)
3. Edge function errors (Issue 5)

**Action:**
1. Check Supabase Dashboard → `user_fcm_tokens` table
2. Check Edge Function logs
3. Verify RLS policies
4. Check app logs for the flow above




