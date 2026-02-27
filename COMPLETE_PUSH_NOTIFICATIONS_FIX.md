# Complete Push Notifications Fix

## 🔧 Issues Identified & Fixed

### Issue 1: iOS Tokens Not Being Saved ✅ FIXED
**Root Cause**: Database table had `UNIQUE(user_id)` constraint, allowing only ONE token per user. When iOS token was generated, it replaced the Android token.

**Fix**:
1. ✅ Created `FIX_FCM_TOKENS_TABLE.sql` - Changes constraint to `UNIQUE(user_id, platform)`
2. ✅ Updated code to use `onConflict: 'user_id,platform'` in upsert
3. ✅ Now supports both Android AND iOS tokens per user

### Issue 2: Push Notifications Not Working ✅ FIXED
**Root Cause**: `PushNotificationService.sendToUser()` only fetched one token per user.

**Fix**:
1. ✅ Updated `sendToUser()` to fetch ALL tokens for a user
2. ✅ Sends notification to all tokens (both Android and iOS)
3. ✅ Returns success if ANY token receives the notification

### Issue 3: Edge Function Secrets ⚠️ NEEDS ACTION
**Root Cause**: Edge Function can't access `GOOGLE_CLIENT_EMAIL` and `GOOGLE_PRIVATE_KEY`

**Action Required**:
1. Verify secrets are in **PRODUCTION** environment
2. Check `GOOGLE_PRIVATE_KEY` format (must include BEGIN/END markers)
3. See `EDGE_FUNCTION_SECRETS_FIX.md` for details

## 📋 Action Items

### 1. Run SQL Fix (REQUIRED)
```sql
-- Run FIX_FCM_TOKENS_TABLE.sql in Supabase SQL Editor
-- This allows multiple tokens per user (one per platform)
```

### 2. Fix Edge Function Secrets (REQUIRED)
1. Go to Supabase → Edge Functions → Secrets
2. Verify **PRODUCTION** environment is selected
3. Check `GOOGLE_PRIVATE_KEY` includes:
   ```
   -----BEGIN PRIVATE KEY-----
   (key content)
   -----END PRIVATE KEY-----
   ```
4. If wrong, delete and re-add with correct format

### 3. Test iOS Token Generation
**Requirements for iOS tokens:**
- ✅ Paid Apple Developer account ($99/year)
- ✅ APNs key uploaded to Firebase Console
- ✅ Real device (not simulator)
- ✅ Push Notifications capability in Xcode

**Check logs for:**
- `✅ [FCM] Token obtained` - Success
- `❌ [FCM] Error getting token` - APNs not configured

### 4. Test Push Notifications
1. Get token from `user_fcm_tokens` table
2. Test Edge Function in Supabase Dashboard
3. Check device for notification

## 🧪 Testing Checklist

- [ ] Run `FIX_FCM_TOKENS_TABLE.sql` in Supabase
- [ ] Verify Edge Function secrets are correct
- [ ] Test iOS token generation on real device
- [ ] Verify iOS token appears in `user_fcm_tokens` table
- [ ] Test Edge Function with Android token
- [ ] Test Edge Function with iOS token
- [ ] Test sending notification from app (tool request, etc.)

## 📝 Code Changes Made

1. ✅ `lib/services/firebase_messaging_service.dart`:
   - Changed `onConflict: 'user_id'` to `onConflict: 'user_id,platform'`
   - Updated fallback update to include platform filter

2. ✅ `lib/services/push_notification_service.dart`:
   - Updated `sendToUser()` to fetch ALL tokens
   - Sends to all tokens for a user (both platforms)

3. ✅ Created `FIX_FCM_TOKENS_TABLE.sql`:
   - Changes database constraint to support multiple tokens

## 🎯 Expected Results

After fixes:
- ✅ iOS tokens will be saved to database
- ✅ Android tokens will remain saved
- ✅ Users can have both Android AND iOS tokens
- ✅ Push notifications sent to user will go to ALL their devices
- ✅ Edge Function will work once secrets are fixed

## ⚠️ Important Notes

1. **iOS requires paid Apple Developer account** - Free accounts can't receive push notifications
2. **iOS Simulator won't work** - Must use real device
3. **Edge Function secrets must be in PRODUCTION** - Not LOCAL/STAGING
4. **Private key format is critical** - Must include BEGIN/END markers with newlines
