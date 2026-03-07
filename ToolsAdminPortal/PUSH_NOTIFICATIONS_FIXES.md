# Push Notifications Fixes - Complete Guide

## 🔧 Issues Fixed

### 1. **iOS Tokens Not Being Saved** ✅ FIXED
**Problem**: The `user_fcm_tokens` table had a UNIQUE constraint on `user_id` only, which meant only ONE token per user could exist. When a user logged in on iOS after having an Android token, the iOS token would replace the Android token (or vice versa).

**Fix Applied**:
- ✅ Changed unique constraint from `(user_id)` to `(user_id, platform)`
- ✅ Updated `upsert` to use `onConflict: 'user_id,platform'`
- ✅ Now users can have both Android AND iOS tokens saved

**SQL File**: `FIX_FCM_TOKENS_TABLE.sql` - Run this in Supabase SQL Editor

### 2. **Push Notifications Not Working** ✅ FIXED
**Problem**: `PushNotificationService.sendToUser()` only sent to one token per user.

**Fix Applied**:
- ✅ Updated `sendToUser()` to fetch ALL tokens for a user (both Android and iOS)
- ✅ Sends notification to all tokens, ensuring delivery on all user's devices

### 3. **Edge Function Secrets** ⚠️ NEEDS VERIFICATION
**Problem**: Edge Function can't access `GOOGLE_CLIENT_EMAIL` and `GOOGLE_PRIVATE_KEY`

**Solution**: 
- Check that secrets are in **PRODUCTION** environment (not LOCAL/STAGING)
- Verify `GOOGLE_PRIVATE_KEY` includes full PEM format with BEGIN/END markers
- See `EDGE_FUNCTION_SECRETS_FIX.md` for detailed instructions

## 📋 Steps to Fix Everything

### Step 1: Fix Database Table (REQUIRED)
Run `FIX_FCM_TOKENS_TABLE.sql` in Supabase SQL Editor:
```sql
-- This changes the unique constraint to allow multiple tokens per user
-- One token per platform (Android and iOS)
```

### Step 2: Fix Edge Function Secrets (REQUIRED)
1. Go to Supabase Dashboard → Edge Functions → Secrets
2. Verify you're in **PRODUCTION** environment
3. Check `GOOGLE_PRIVATE_KEY` format:
   - Must include `-----BEGIN PRIVATE KEY-----`
   - Must include `-----END PRIVATE KEY-----`
   - Must preserve newlines
4. If wrong, delete and re-add with correct format

### Step 3: Test iOS Token Generation
**For iOS tokens to be generated, you need:**
1. ✅ APNs configured in Firebase Console
2. ✅ APNs key uploaded to Firebase
3. ✅ Paid Apple Developer account ($99/year)
4. ✅ Real device (not simulator)
5. ✅ Push Notifications capability enabled in Xcode

**Check iOS logs for:**
- `✅ [FCM] Token obtained` - Token was generated
- `✅ [FCM] Token saved to Supabase successfully` - Token was saved
- If you see `❌ [FCM] Error getting token` - APNs not configured

### Step 4: Test Push Notifications
1. **Get a test token** from `user_fcm_tokens` table
2. **Test Edge Function** in Supabase Dashboard:
   ```json
   {
     "token": "YOUR_TOKEN_HERE",
     "title": "Test",
     "body": "Testing push notifications"
   }
   ```
3. **Check Edge Function logs** for errors
4. **Check device** for notification

## 🐛 Troubleshooting

### iOS Tokens Still Not Saving
1. Check iOS logs for `❌ [FCM] Error getting token`
2. Verify APNs is configured in Firebase
3. Check if running on simulator (won't work - use real device)
4. Verify Apple Developer account is paid (not free)

### Push Notifications Still Not Working
1. **Verify Edge Function secrets**:
   - Test function in Supabase Dashboard
   - Check for "GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured" error
   
2. **Check Edge Function logs**:
   - Supabase Dashboard → Edge Functions → `send-push-notification` → Logs
   - Look for authentication errors or FCM API errors

3. **Verify tokens are valid**:
   - Test token from Firebase Console → Cloud Messaging
   - If Firebase Console works but Edge Function doesn't → Edge Function issue
   - If neither works → Token or device issue

4. **Check device permissions**:
   - iOS: Settings → RGS → Notifications (should be enabled)
   - Android: Settings → Apps → RGS → Notifications (should be enabled)

## ✅ What's Fixed

- ✅ Database table now supports multiple tokens per user
- ✅ Code updated to save tokens with platform
- ✅ Code updated to send to all user's tokens
- ✅ Error handling improved

## ⏳ What You Need to Do

1. **Run `FIX_FCM_TOKENS_TABLE.sql`** in Supabase SQL Editor
2. **Fix Edge Function secrets** (see `EDGE_FUNCTION_SECRETS_FIX.md`)
3. **Test on real iOS device** (not simulator)
4. **Verify APNs is configured** in Firebase Console
5. **Test push notifications** from Edge Function

## 📝 Summary

**Database Issue**: ✅ Fixed (SQL file created)
**Code Issue**: ✅ Fixed (multiple tokens support)
**Edge Function Secrets**: ⚠️ Needs verification
**iOS APNs**: ⚠️ Needs verification (requires paid Apple Developer account)
