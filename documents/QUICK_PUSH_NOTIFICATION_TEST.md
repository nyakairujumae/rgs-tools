# Quick Push Notification Test

## 🚀 Fastest Way to Test

### Option 1: Add Diagnostic Button (Recommended)

Add this to your admin home screen temporarily:

```dart
// In admin_home_screen.dart, add to AppBar actions:
import 'services/push_notification_diagnostic.dart';

// Add this button in the AppBar actions or settings:
IconButton(
  icon: Icon(Icons.bug_report),
  onPressed: () async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Running Diagnostic...'),
        content: CircularProgressIndicator(),
      ),
    );
    
    final results = await PushNotificationDiagnostic.runDiagnostic();
    PushNotificationDiagnostic.printSummary(results);
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Push Notification Diagnostic'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResultRow('User Logged In', results['user_logged_in']?['has_user'] == true),
                _buildResultRow('Tokens in DB', (results['tokens_in_database']?['user_tokens_count'] ?? 0) > 0),
                _buildResultRow('Edge Function', results['edge_function']?['function_exists'] == true),
                _buildResultRow('Test Send', results['test_send']?['success'] == true),
                SizedBox(height: 16),
                Text('Check logs for detailed information', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  },
  tooltip: 'Test Push Notifications',
)
```

### Option 2: Check Logs Directly

1. **Trigger a notification** (e.g., create a tool request)
2. **Check logs** for these messages:

**If tokens are missing:**
```
⚠️ [Push] No FCM tokens found for user: ...
```

**If Edge Function not deployed:**
```
❌ [Push] Edge Function NOT FOUND (404)
⚠️ [Push] ACTION REQUIRED: Deploy Edge Function
```

**If secrets missing:**
```
❌ [Push] Edge Function error (500)
⚠️ [Push] ACTION REQUIRED: Add GOOGLE_PROJECT_ID secret
```

**If sending works:**
```
✅ [Push] Notification sent successfully
✅ [Push] FCM message name: projects/.../messages/...
```

---

## 🔍 What to Check First

### 1. Are Tokens Being Saved?

**Check logs for:**
```
✅ [FCM] Token saved to Supabase successfully
✅ [FCM] Token verified in database
```

**If you don't see this:**
- Token saving is failing
- Check RLS policies
- Run `DIAGNOSE_FCM_TOKENS.sql`

### 2. Is Edge Function Deployed?

**Check logs when sending:**
```
❌ [Push] Edge Function NOT FOUND (404)
```

**If you see this:**
- Edge Function is not deployed
- Deploy it: `supabase functions deploy send-push-notification`

### 3. Are Secrets Configured?

**Check logs when sending:**
```
❌ [Push] Edge Function error (500)
⚠️ [Push] ACTION REQUIRED: Add GOOGLE_PROJECT_ID secret
```

**If you see this:**
- Secrets are missing
- Add them in Supabase Dashboard → Settings → Edge Functions → Secrets

### 4. Is Edge Function Working?

**Check Supabase Dashboard:**
- Go to Edge Functions → `send-push-notification` → Logs
- Look for errors or successful sends

---

## 🎯 Most Likely Issues

Based on your description ("maybe we are not sending them with supabase backend"):

### Issue 1: Edge Function Not Deployed (Most Likely)
**Symptoms:**
- Logs show: `Function not found` or `404`
- No errors in app, but notifications don't send

**Fix:**
```bash
cd /Users/jumae/Desktop/rgstools
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy send-push-notification
```

### Issue 2: Secrets Not Configured
**Symptoms:**
- Logs show: `GOOGLE_PROJECT_ID not configured`
- Edge Function returns 500 error

**Fix:**
1. Get Firebase service account JSON
2. Add secrets in Supabase Dashboard
3. Redeploy function (secrets are picked up automatically)

### Issue 3: Tokens Not in Database
**Symptoms:**
- Logs show: `No FCM tokens found for user`
- Diagnostic shows 0 tokens

**Fix:**
- Check token saving logs
- Run `DIAGNOSE_FCM_TOKENS.sql`
- Fix RLS policies if needed

---

## 📋 Quick Checklist

Run through this checklist:

1. **Check if tokens exist:**
   ```sql
   SELECT COUNT(*) FROM user_fcm_tokens;
   ```
   Should be > 0

2. **Check if Edge Function exists:**
   - Go to Supabase Dashboard → Edge Functions
   - Should see `send-push-notification` in list

3. **Check if secrets are set:**
   - Go to Supabase Dashboard → Settings → Edge Functions → Secrets
   - Should see: GOOGLE_PROJECT_ID, GOOGLE_CLIENT_EMAIL, GOOGLE_PRIVATE_KEY

4. **Check Edge Function logs:**
   - Go to Edge Functions → `send-push-notification` → Logs
   - Look for errors or successful sends

5. **Test from app:**
   - Trigger a notification (create tool request)
   - Check logs for detailed error messages

---

## 🐛 If Still Not Working

1. **Run the diagnostic tool** (add button above)
2. **Check Supabase Edge Function logs** (Dashboard → Edge Functions → Logs)
3. **Check Firebase Console** (send test message directly)
4. **Check app logs** (look for `[Push]` messages)

The diagnostic tool will tell you exactly what's wrong!


