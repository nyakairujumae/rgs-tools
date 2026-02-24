# Push Notifications Diagnosis - Why They're Not Working

## 🔍 Current Status

### ✅ What's Working:
1. **Firebase Initialization** - Firebase is initialized in `main.dart` with error handling
2. **FCM Token Retrieval** - Token is obtained from Firebase Messaging
3. **Token Storage** - Token is saved to Supabase `user_fcm_tokens` table
4. **Permission Handling** - Notification permissions are requested
5. **Background Handler** - Background message handler is registered

### ❌ What's Missing/Broken:

## 🚨 CRITICAL ISSUE #1: No Backend Service to Send Notifications

**The Problem:**
- FCM tokens are saved to Supabase ✅
- But there's **NO Edge Function or backend service** to actually SEND notifications ❌
- The code in `pending_approvals_provider.dart` line 266 just checks for tokens but doesn't send them

**Evidence:**
```dart
// lib/providers/pending_approvals_provider.dart:264-267
if (fcmTokenResponse != null && fcmTokenResponse['fcm_token'] != null) {
  // Send push notification via Firebase Cloud Messaging
  // This would typically be done via a Supabase Edge Function or backend service
  debugPrint('📱 FCM token found for user, push notification can be sent');
}
```

**What's Needed:**
- A Supabase Edge Function that:
  1. Listens for events (new registrations, approvals, etc.)
  2. Gets FCM tokens from `user_fcm_tokens` table
  3. Sends notifications via FCM REST API using your FCM Server Key

## 🚨 CRITICAL ISSUE #2: Token May Not Be Saved After Login

**The Problem:**
- Firebase initializes asynchronously (1.5 second delay)
- User might log in BEFORE Firebase is ready
- Token is only saved if user is logged in when `_getFCMToken()` runs

**Evidence:**
```dart
// lib/services/firebase_messaging_service.dart:151-157
static Future<void> _sendTokenToServer(String token) async {
  try {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ [FCM] No user logged in, skipping token save');
      return; // ❌ Token is NOT saved if user not logged in yet
    }
```

**What's Needed:**
- Save token when user logs in (even if Firebase initialized earlier)
- Re-send token after successful login

## 🚨 CRITICAL ISSUE #3: No FCM Server Key Configuration

**The Problem:**
- Even if we create an Edge Function, it needs your FCM Server Key
- This key must be stored as a Supabase secret
- Without it, the Edge Function can't send notifications

**What's Needed:**
1. Get FCM Server Key from Firebase Console:
   - Firebase Console → Project Settings → Cloud Messaging → Server Key
2. Add it to Supabase Secrets:
   - Supabase Dashboard → Settings → Edge Functions → Secrets
   - Add: `FCM_SERVER_KEY` = your server key

## 📋 Action Items

### Step 1: Verify Token is Being Saved
1. Log into the app
2. Check Supabase Dashboard → `user_fcm_tokens` table
3. Verify your user_id has a token saved
4. If NO token → Issue #2 is the problem

### Step 2: Create Edge Function to Send Notifications
Create: `supabase/functions/send-push-notification/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY");
const FCM_URL = "https://fcm.googleapis.com/fcm/send";

serve(async (req) => {
  try {
    const { token, title, body, data } = await req.json();
    
    const response = await fetch(FCM_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title: title,
          body: body,
        },
        data: data || {},
      }),
    });
    
    return new Response(JSON.stringify({ success: true }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
```

### Step 3: Call Edge Function When Sending Notifications
Update `pending_approvals_provider.dart` to actually call the Edge Function:

```dart
if (fcmTokenResponse != null && fcmTokenResponse['fcm_token'] != null) {
  try {
    await SupabaseService.client.functions.invoke(
      'send-push-notification',
      body: {
        'token': fcmTokenResponse['fcm_token'],
        'title': 'Account Approved',
        'body': 'Your account has been approved!',
        'data': {'type': 'account_approved'},
      },
    );
    debugPrint('✅ Push notification sent');
  } catch (e) {
    debugPrint('❌ Failed to send push notification: $e');
  }
}
```

### Step 4: Fix Token Saving After Login
Update `auth_provider.dart` to ensure token is sent after login:

```dart
// After successful login, check if FCM token exists and send it
Future<void> _ensureFCMTokenSaved() async {
  try {
    final token = FirebaseMessagingService.fcmToken;
    if (token != null && _user != null) {
      await FirebaseMessagingService.sendTokenToServer(token, _user!.id);
    }
  } catch (e) {
    debugPrint('⚠️ Could not save FCM token after login: $e');
  }
}
```

## 🧪 Testing Steps

1. **Test Token Storage:**
   - Log in to app
   - Check `user_fcm_tokens` table in Supabase
   - Should see your user_id with a token

2. **Test Notification Sending:**
   - Use Firebase Console → Cloud Messaging → Send test message
   - Enter your FCM token from `user_fcm_tokens` table
   - Send test notification
   - Should receive notification on device

3. **Test Edge Function:**
   - Call Edge Function with test token
   - Check if notification is received

## 🎯 Priority Order

1. **HIGHEST:** Create Edge Function to send notifications
2. **HIGH:** Add FCM Server Key to Supabase secrets
3. **MEDIUM:** Fix token saving after login
4. **LOW:** Add retry logic for failed token saves



