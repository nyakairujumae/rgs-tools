# Push Notifications - Complete Diagnostic Guide

## 🔍 The Problem

Push notifications are not working. We need to identify exactly where the failure is occurring.

## 🛠️ Diagnostic Tool

I've created a comprehensive diagnostic tool that will check:

1. ✅ **User Login Status** - Is user logged in?
2. ✅ **FCM Tokens in Database** - Are tokens saved?
3. ✅ **Edge Function Deployment** - Is function deployed?
4. ✅ **Edge Function Secrets** - Are secrets configured?
5. ✅ **Test Notification Send** - Can we actually send?
6. ✅ **Admin Users** - Do admins have tokens?

## 📋 How to Use

### Step 1: Add Diagnostic Button (Temporary)

Add this to any screen (e.g., admin home screen) temporarily:

```dart
import 'services/push_notification_diagnostic.dart';

// Add a button somewhere
ElevatedButton(
  onPressed: () async {
    final results = await PushNotificationDiagnostic.runDiagnostic();
    PushNotificationDiagnostic.printSummary(results);
    
    // Show results in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Push Notification Diagnostic'),
        content: SingleChildScrollView(
          child: Text(results.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  },
  child: Text('Run Push Notification Diagnostic'),
)
```

### Step 2: Run Diagnostic

1. Open the app
2. Log in as admin
3. Tap the diagnostic button
4. Check the logs and dialog

### Step 3: Check Results

The diagnostic will tell you:

#### ✅ If Edge Function is NOT Deployed:
```
❌ Edge Function NOT FOUND (404)
Action: Run: supabase functions deploy send-push-notification
```

**Fix:** Deploy the Edge Function (see below)

#### ✅ If Edge Function Secrets Missing:
```
❌ Edge Function error (500)
Error: GOOGLE_PROJECT_ID not configured
```

**Fix:** Add secrets in Supabase Dashboard (see below)

#### ✅ If No Tokens in Database:
```
🔑 Tokens: 0 token(s) for current user
```

**Fix:** Check token saving logic (see below)

#### ✅ If Tokens Exist But Not Sending:
```
🔑 Tokens: 1 token(s) ✅
⚡ Edge Function: ✅ Deployed ✅
📤 Test Send: ❌ Failed
```

**Fix:** Check Edge Function logs in Supabase Dashboard

---

## 🚀 Step-by-Step Fix Guide

### Fix 1: Deploy Edge Function

**If diagnostic shows "Edge Function NOT FOUND":**

1. **Install Supabase CLI:**
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase:**
   ```bash
   supabase login
   ```

3. **Link your project:**
   ```bash
   cd /Users/jumae/Desktop/rgstools
   supabase link --project-ref YOUR_PROJECT_REF
   ```
   (Get project ref from Supabase Dashboard URL: `https://app.supabase.com/project/YOUR_PROJECT_REF`)

4. **Deploy the function:**
   ```bash
   supabase functions deploy send-push-notification
   ```

5. **Verify deployment:**
   - Go to Supabase Dashboard → Edge Functions
   - You should see `send-push-notification` in the list

---

### Fix 2: Configure Edge Function Secrets

**If diagnostic shows "GOOGLE_PROJECT_ID not configured":**

1. **Get Firebase Service Account:**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate new private key"
   - Download the JSON file

2. **Extract values from JSON:**
   - `project_id` → `GOOGLE_PROJECT_ID`
   - `client_email` → `GOOGLE_CLIENT_EMAIL`
   - `private_key` → `GOOGLE_PRIVATE_KEY`

3. **Add secrets in Supabase:**
   - Go to Supabase Dashboard → Project Settings → Edge Functions → Secrets
   - Add each secret:
     - `GOOGLE_PROJECT_ID`: Your Firebase project ID
     - `GOOGLE_CLIENT_EMAIL`: Service account email
     - `GOOGLE_PRIVATE_KEY`: Private key (keep the `\n` characters)

4. **Verify secrets:**
   - Run diagnostic again
   - Should show "Edge Function: ✅ Working"

---

### Fix 3: Fix Token Saving

**If diagnostic shows "0 token(s) for current user":**

1. **Check if tokens are being generated:**
   - Look for logs: `✅ [FCM] Token obtained: ...`
   - If not, check Firebase initialization

2. **Check if tokens are being saved:**
   - Look for logs: `✅ [FCM] Token saved to Supabase successfully`
   - If not, check RLS policies

3. **Run SQL diagnostic:**
   - Run `DIAGNOSE_FCM_TOKENS.sql` in Supabase SQL Editor
   - Check if tokens exist in database
   - Check RLS policies

4. **Fix RLS if needed:**
   - Run `FIX_FCM_TOKENS_TABLE.sql` if table structure is wrong

---

### Fix 4: Check Edge Function Logs

**If tokens exist but sending fails:**

1. **Go to Supabase Dashboard:**
   - Edge Functions → `send-push-notification` → Logs

2. **Check for errors:**
   - Look for authentication errors
   - Look for FCM API errors
   - Look for secret configuration errors

3. **Common errors:**
   - `GOOGLE_PROJECT_ID not configured` → Add secret
   - `Failed to authenticate with Google` → Check private key format
   - `FCM v1 API error` → Check token validity

---

## 🔍 Manual Testing

### Test 1: Check Tokens in Database

Run in Supabase SQL Editor:
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

**Expected:** Each admin should have at least one token.

### Test 2: Test Edge Function Directly

Run in Supabase SQL Editor (or use Supabase Dashboard → Edge Functions → Invoke):
```sql
-- This will test the Edge Function
-- Replace TOKEN with an actual FCM token
SELECT net.http_post(
  url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push-notification',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer YOUR_ANON_KEY'
  ),
  body := jsonb_build_object(
    'token', 'YOUR_FCM_TOKEN',
    'title', 'Test',
    'body', 'Test notification'
  )
);
```

### Test 3: Check Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Send a test message to a specific FCM token
3. If this works → Edge Function issue
4. If this doesn't work → Firebase configuration issue

---

## 📊 Diagnostic Results Interpretation

### ✅ All Green:
```
👤 User: ✅ Logged in
🔑 Tokens: 1 token(s) ✅
⚡ Edge Function: ✅ Deployed ✅
📤 Test Send: ✅ Success
```
**Status:** Everything is working! Check app-side notification handling.

### ❌ Edge Function Not Deployed:
```
⚡ Edge Function: ❌ NOT DEPLOYED
```
**Action:** Deploy Edge Function (Fix 1)

### ❌ No Tokens:
```
🔑 Tokens: 0 token(s)
```
**Action:** Fix token saving (Fix 3)

### ❌ Edge Function Error:
```
⚡ Edge Function: ✅ Deployed
   Status: ❌ Error (500)
   Error: GOOGLE_PROJECT_ID not configured
```
**Action:** Configure secrets (Fix 2)

### ❌ Test Send Failed:
```
📤 Test Send: ❌ Failed
```
**Action:** Check Edge Function logs (Fix 4)

---

## 🎯 Quick Checklist

- [ ] Edge Function deployed (`supabase functions deploy send-push-notification`)
- [ ] Secrets configured (GOOGLE_PROJECT_ID, GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY)
- [ ] FCM tokens saved in database (check `user_fcm_tokens` table)
- [ ] Admin users have tokens (run SQL query)
- [ ] Edge Function logs show no errors
- [ ] Test notification from Firebase Console works
- [ ] Diagnostic tool shows all green

---

## 🐛 Common Issues

### Issue 1: "Function not found"
**Cause:** Edge Function not deployed
**Fix:** Deploy it (Fix 1)

### Issue 2: "GOOGLE_PROJECT_ID not configured"
**Cause:** Secrets not set
**Fix:** Add secrets (Fix 2)

### Issue 3: "No FCM tokens found"
**Cause:** Tokens not being saved
**Fix:** Check token saving logic and RLS policies (Fix 3)

### Issue 4: "Failed to authenticate with Google"
**Cause:** Private key format wrong
**Fix:** Ensure private key has `\n` characters preserved

### Issue 5: "FCM v1 API error: Invalid token"
**Cause:** Token is invalid or expired
**Fix:** Regenerate token (user needs to re-login)

---

## ✅ Next Steps

1. **Run the diagnostic tool** to identify the exact issue
2. **Follow the appropriate fix** based on diagnostic results
3. **Test again** with the diagnostic tool
4. **Check logs** in both app and Supabase Dashboard
5. **Verify** notifications work end-to-end

The diagnostic tool will tell you exactly what's wrong!


