# Edge Function Secrets Configuration Fix

## ❌ Current Issue

The Edge Function is returning:
```
GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured in Supabase secrets
```

Even though these secrets appear in your Supabase Dashboard.

## 🔍 Common Causes

### 1. **Secrets in Wrong Environment**
- You're testing in **PRODUCTION** environment
- Make sure secrets are added to **PRODUCTION**, not LOCAL or STAGING

### 2. **Private Key Format Issue**
The `GOOGLE_PRIVATE_KEY` must include the full PEM format with newlines:
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
(multiple lines of base64)
...
-----END PRIVATE KEY-----
```

**Common mistakes:**
- ❌ Missing `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`
- ❌ Newlines removed (all on one line)
- ❌ Extra spaces or characters

### 3. **Secret Names Must Match Exactly**
- ✅ `GOOGLE_CLIENT_EMAIL` (not `GOOGLE_CLIENT_EMAIL_` or `google_client_email`)
- ✅ `GOOGLE_PRIVATE_KEY` (not `GOOGLE_PRIVATE_KEY_` or `google_private_key`)
- ✅ `GOOGLE_PROJECT_ID` (not `GOOGLE_PROJECT_ID_` or `google_project_id`)

## ✅ How to Fix

### Step 1: Verify Secret Names
In Supabase Dashboard → Edge Functions → Secrets, ensure you have:
- `GOOGLE_PROJECT_ID`
- `GOOGLE_CLIENT_EMAIL`
- `GOOGLE_PRIVATE_KEY`

### Step 2: Check Private Key Format
The `GOOGLE_PRIVATE_KEY` should look like this (example):
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
(many lines of base64 encoded data)
...
-----END PRIVATE KEY-----
```

**To get the correct format:**
1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Open the JSON file
5. Copy the `private_key` value (it should include the BEGIN/END markers and newlines)
6. Paste it into Supabase Secrets as `GOOGLE_PRIVATE_KEY`

### Step 3: Verify Environment
- Make sure you're adding secrets to **PRODUCTION** environment
- The dropdown should show "PRODUCTION" when adding secrets

### Step 4: Redeploy Function (if needed)
After updating secrets:
1. Go to Edge Functions → `send-push-notification`
2. Click "Redeploy" or wait a few minutes for secrets to refresh

### Step 5: Test Again
Use the "Test" panel in Supabase Dashboard with:
```json
{
  "token": "YOUR_FCM_TOKEN",
  "title": "Test Notification",
  "body": "Testing push notifications"
}
```

## 🔍 Debugging Steps

### Check Function Logs
1. Go to Edge Functions → `send-push-notification` → Logs
2. Look for errors about missing secrets
3. Check if secrets are being read correctly

### Verify Secret Values
The function checks for secrets at lines 6-8:
```typescript
const GOOGLE_PROJECT_ID = Deno.env.get("GOOGLE_PROJECT_ID");
const GOOGLE_CLIENT_EMAIL = Deno.env.get("GOOGLE_CLIENT_EMAIL");
const GOOGLE_PRIVATE_KEY = Deno.env.get("GOOGLE_PRIVATE_KEY");
```

If any of these return `null` or `undefined`, you'll get the error.

## 📝 Quick Checklist

- [ ] Secrets are in **PRODUCTION** environment (not LOCAL/STAGING)
- [ ] Secret names match exactly: `GOOGLE_PROJECT_ID`, `GOOGLE_CLIENT_EMAIL`, `GOOGLE_PRIVATE_KEY`
- [ ] `GOOGLE_PRIVATE_KEY` includes `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`
- [ ] `GOOGLE_PRIVATE_KEY` has newlines preserved (not all on one line)
- [ ] Secrets were saved successfully (check for confirmation message)
- [ ] Function was redeployed after adding secrets (or wait 2-3 minutes)

## 🚨 Most Common Issue

**The `GOOGLE_PRIVATE_KEY` format is wrong!**

When copying from the JSON file, make sure you:
1. Copy the ENTIRE value including BEGIN/END markers
2. Preserve all newlines (don't remove `\n` characters)
3. Don't add extra quotes or escape characters

The key should look like this when pasted:
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
-----END PRIVATE KEY-----
```

NOT like this:
```
"-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----"
```


