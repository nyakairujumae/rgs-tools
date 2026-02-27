# FCM Token Saving Fix - Comprehensive Solution

## 🔍 Problem Identified

**Issue:** Push notifications not working because FCM tokens are not being saved to the database.

**Evidence from logs:**
```
⚠️ [Push] No FCM tokens found for user: 98a7bcec-beb6-4dc2-97a0-3b86e927ab12
⚠️ [Push] No FCM tokens found for user: a35cafe4-9f71-4b09-a3e3-6d3512121236
⚠️ [Push] No FCM tokens found for user: 239b7e3c-c80b-4f32-8415-55eea9564f42
✅ [Push] Sent to 0/3 admins
```

## ✅ Fixes Applied

### 1. Enhanced Token Saving (`lib/services/firebase_messaging_service.dart`)

**Changes:**
- ✅ Added comprehensive error handling with fallback methods (upsert → insert → update)
- ✅ Added token verification after save (queries back to confirm)
- ✅ Enhanced logging with detailed error messages
- ✅ Better handling of RLS errors, duplicate key errors, foreign key errors
- ✅ Token always saved to local storage first (even if user not logged in)
- ✅ Token synced to server after login

**Key improvements:**
```dart
// Now tries multiple methods:
1. Upsert (preferred - handles both insert and update)
2. Insert (if upsert fails)
3. Update (if insert fails)
4. Verification query (confirms token was saved)
```

### 2. Enhanced Token Retrieval Logging

**Changes:**
- ✅ Detailed logging when token is obtained
- ✅ Logs platform (iOS/Android)
- ✅ Logs token length and preview
- ✅ Handles case where user isn't logged in yet
- ✅ Token refresh listener with enhanced logging

### 3. Enhanced Push Notification Service (`lib/services/push_notification_service.dart`)

**Changes:**
- ✅ Better error messages when no tokens found
- ✅ Diagnostic queries to check if RLS is blocking
- ✅ Detailed logging for each token being sent
- ✅ Success/failure tracking per token

### 4. Diagnostic SQL Script (`DIAGNOSE_FCM_TOKENS.sql`)

**Created:** Comprehensive diagnostic script to check:
- Table structure
- Unique constraints
- RLS policies
- RLS status
- Token counts
- Admin users and their tokens
- Constraint verification

## 🔧 What to Check

### Step 1: Run Diagnostic Script

Run `DIAGNOSE_FCM_TOKENS.sql` in Supabase SQL Editor to check:
1. ✅ Table has correct structure
2. ✅ Unique constraint is `(user_id, platform)` not just `(user_id)`
3. ✅ RLS policies allow users to insert/update their own tokens
4. ✅ RLS is enabled
5. ✅ Tokens exist in database

### Step 2: Verify Table Structure

The table should have:
- `user_id` (UUID, foreign key to auth.users)
- `fcm_token` (TEXT, not null)
- `platform` (TEXT: 'android' or 'ios')
- `updated_at` (TIMESTAMPTZ)
- **Unique constraint:** `(user_id, platform)` - allows one token per platform per user

**If table has wrong constraint:**
Run `FIX_FCM_TOKENS_TABLE.sql` in Supabase SQL Editor.

### Step 3: Check RLS Policies

RLS policies should allow:
- ✅ SELECT: `auth.uid() = user_id`
- ✅ INSERT: `auth.uid() = user_id` (WITH CHECK)
- ✅ UPDATE: `auth.uid() = user_id` (USING and WITH CHECK)
- ✅ DELETE: `auth.uid() = user_id`

**If policies are wrong:**
Run `FIX_FCM_TOKENS_TABLE.sql` in Supabase SQL Editor.

### Step 4: Test Token Saving

1. **Log in to the app**
2. **Check logs for:**
   ```
   ✅ [FCM] Token obtained: ...
   📤 [FCM] Saving token for user: ...
   ✅ [FCM] Token saved to Supabase successfully
   ✅ [FCM] Token verified in database
   ```

3. **If you see errors:**
   - `RLS policy is blocking` → Check RLS policies
   - `Foreign key constraint` → User ID doesn't exist in auth.users
   - `Duplicate key` → Token already exists (this is OK)

### Step 5: Verify Tokens in Database

Run this query in Supabase SQL Editor:
```sql
SELECT 
  u.email,
  u.role,
  t.platform,
  LEFT(t.fcm_token, 30) || '...' as token_preview,
  t.updated_at
FROM public.users u
LEFT JOIN public.user_fcm_tokens t ON u.id = t.user_id
WHERE u.role = 'admin'
ORDER BY u.email;
```

**Expected:** Each admin should have at least one token (android or ios).

## 🐛 Debugging

### If tokens still aren't saving:

1. **Check logs for:**
   - `❌ [FCM] Error saving token:` - Shows the exact error
   - `⚠️ [FCM] RLS policy is blocking` - RLS issue
   - `⚠️ [FCM] User not logged in yet` - Token saved locally, will sync after login

2. **Check database:**
   - Run `DIAGNOSE_FCM_TOKENS.sql`
   - Verify table structure matches expected
   - Verify RLS policies are correct

3. **Check app flow:**
   - Firebase initializes before user logs in
   - Token is obtained and saved locally
   - After login, token should be synced to server
   - Check `auth_provider.dart` calls `saveTokenFromLocalStorage()`

### If tokens are saved but notifications don't work:

1. **Check Edge Function:**
   - Verify `send-push-notification` is deployed
   - Check Edge Function logs in Supabase
   - Verify secrets are set (GOOGLE_PROJECT_ID, GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY)

2. **Check notification sending:**
   - Logs should show: `📤 [Push] Sending to android/ios token`
   - Edge Function response should be 200
   - Check Edge Function logs for errors

## 📋 Summary

**What was fixed:**
1. ✅ Enhanced token saving with fallback methods
2. ✅ Added token verification after save
3. ✅ Better error handling and logging
4. ✅ Token always saved locally, synced after login
5. ✅ Enhanced push notification service logging

**What to do:**
1. ✅ Run `DIAGNOSE_FCM_TOKENS.sql` to check database
2. ✅ Run `FIX_FCM_TOKENS_TABLE.sql` if table structure is wrong
3. ✅ Test login and check logs for token saving
4. ✅ Verify tokens exist in database
5. ✅ Test push notifications

**Expected result:**
- Tokens are saved to database after login
- Logs show successful token save and verification
- Push notifications work because tokens are found

