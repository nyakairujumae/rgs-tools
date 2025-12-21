# Testing Edge Function Directly

This guide shows you how to test the `send-push-notification` Edge Function directly, bypassing the app to verify if the function itself works.

## Prerequisites

1. **Get your FCM token** from the database:
   - Go to Supabase Dashboard → Table Editor → `user_fcm_tokens`
   - Find your `user_id` and copy the `fcm_token` value
   - Note the `platform` (android or ios)

2. **Get your Supabase credentials**:
   - Supabase URL: Found in Dashboard → Settings → API
   - Supabase Anon Key: Found in Dashboard → Settings → API

## Method 1: Using Supabase Dashboard (Easiest)

1. Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification`
2. Click **"Invoke"** button
3. Use one of these request bodies:

### Test with FCM Token (Direct)
```json
{
  "token": "YOUR_FCM_TOKEN_HERE",
  "title": "Test from Edge Function",
  "body": "This is a direct test from the Edge Function",
  "data": {
    "type": "test",
    "test_id": "123"
  }
}
```

### Test with User ID (Fetches token from database)
```json
{
  "user_id": "YOUR_USER_ID_HERE",
  "title": "Test from Edge Function",
  "body": "This is a direct test from the Edge Function",
  "data": {
    "type": "test",
    "test_id": "123"
  }
}
```

### Test with User ID and Platform (Specific platform)
```json
{
  "user_id": "YOUR_USER_ID_HERE",
  "platform": "android",
  "title": "Test from Edge Function",
  "body": "This is a direct test from the Edge Function",
  "data": {
    "type": "test",
    "test_id": "123"
  }
}
```

4. Click **"Invoke"** and check the response
5. Check **Logs** tab to see detailed execution logs

## Method 2: Using cURL (Command Line)

Replace the placeholders with your actual values:

```bash
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "token": "YOUR_FCM_TOKEN_HERE",
    "title": "Test from Edge Function",
    "body": "This is a direct test from the Edge Function",
    "data": {
      "type": "test",
      "test_id": "123"
    }
  }'
```

### With User ID instead of token:
```bash
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "YOUR_USER_ID_HERE",
    "title": "Test from Edge Function",
    "body": "This is a direct test from the Edge Function",
    "data": {
      "type": "test"
    }
  }'
```

## Method 3: Using JavaScript/Node.js

Create a file `test-edge-function.js`:

```javascript
const SUPABASE_URL = 'https://YOUR_PROJECT_REF.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

async function testEdgeFunction() {
  // Option 1: Test with FCM token directly
  const response = await fetch(`${SUPABASE_URL}/functions/v1/send-push-notification`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      token: 'YOUR_FCM_TOKEN_HERE',
      title: 'Test from Edge Function',
      body: 'This is a direct test from the Edge Function',
      data: {
        type: 'test',
        test_id: '123'
      }
    })
  });

  const result = await response.json();
  console.log('Response status:', response.status);
  console.log('Response data:', JSON.stringify(result, null, 2));
}

// Option 2: Test with user_id (fetches token from database)
async function testWithUserId() {
  const response = await fetch(`${SUPABASE_URL}/functions/v1/send-push-notification`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      user_id: 'YOUR_USER_ID_HERE',
      platform: 'android', // or 'ios', or omit for both
      title: 'Test from Edge Function',
      body: 'This is a direct test from the Edge Function',
      data: {
        type: 'test'
      }
    })
  });

  const result = await response.json();
  console.log('Response status:', response.status);
  console.log('Response data:', JSON.stringify(result, null, 2));
}

// Run the test
testEdgeFunction().catch(console.error);
// Or: testWithUserId().catch(console.error);
```

Run it:
```bash
node test-edge-function.js
```

## Method 4: Using Supabase CLI

```bash
# First, get your project reference
supabase link --project-ref YOUR_PROJECT_REF

# Then invoke the function
supabase functions invoke send-push-notification \
  --body '{
    "token": "YOUR_FCM_TOKEN_HERE",
    "title": "Test from Edge Function",
    "body": "This is a direct test from the Edge Function",
    "data": {"type": "test"}
  }'
```

## Method 5: Test Secrets Endpoint

The Edge Function has a built-in test endpoint to verify secrets are configured:

```bash
curl 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push-notification?test=secrets' \
  -H 'Authorization: Bearer YOUR_SUPABASE_ANON_KEY'
```

This will return:
```json
{
  "message": "Secrets status check",
  "secrets": {
    "GOOGLE_PROJECT_ID": "✅ Set (your-project-id)",
    "GOOGLE_CLIENT_EMAIL": "✅ Set (your-service-account@...)",
    "GOOGLE_PRIVATE_KEY": "✅ Set (2048 chars, starts with: -----BEGIN...)",
    "privateKeyHasBegin": "✅ Yes",
    "privateKeyHasEnd": "✅ Yes"
  },
  "allSecretsSet": true
}
```

## Expected Responses

### Success Response (200)
```json
{
  "success": true,
  "results": [
    {
      "token": "fcm_token_here...",
      "platform": "android",
      "success": true,
      "name": "projects/YOUR_PROJECT_ID/messages/0:1234567890"
    }
  ]
}
```

### Error Response (400/500)
```json
{
  "error": "Error message here",
  "details": {
    "error": "Specific error details"
  }
}
```

### No Token Found (404)
```json
{
  "error": "No active FCM token found for user/platform"
}
```

## Troubleshooting

### 1. Check Edge Function Logs
- Go to Supabase Dashboard → Edge Functions → `send-push-notification` → **Logs**
- Look for detailed execution logs including:
  - OAuth2 token generation
  - FCM API calls
  - Error messages

### 2. Verify Secrets
Use the secrets test endpoint (Method 5) to verify all secrets are configured correctly.

### 3. Check FCM Token Validity
- Make sure the token is not expired
- Verify the token is from the correct Firebase project
- Check if the token was saved correctly in `user_fcm_tokens` table

### 4. Verify User ID
If using `user_id`, verify:
- The user exists in the `users` table
- The user has a valid token in `user_fcm_tokens` table
- The token's `updated_at` is recent (not older than 90 days)

### 5. Common Errors

**"GOOGLE_PROJECT_ID not configured"**
- Go to Supabase Dashboard → Settings → Edge Functions → Secrets
- Add `GOOGLE_PROJECT_ID` with your Firebase project ID

**"Failed to authenticate with Google"**
- Check `GOOGLE_CLIENT_EMAIL` and `GOOGLE_PRIVATE_KEY` are set correctly
- Verify the private key includes `BEGIN PRIVATE KEY` and `END PRIVATE KEY` markers
- Ensure newlines are preserved (use `\n` in the secret)

**"No active FCM token found for user/platform"**
- Verify the user has a token in `user_fcm_tokens` table
- Check the `platform` matches (android/ios)
- Ensure the token is not expired (check `updated_at`)

**"UNREGISTERED" or "INVALID_ARGUMENT"**
- The FCM token is invalid or expired
- The token will be automatically deleted from the database
- User needs to re-login to get a new token

## Next Steps

1. **If Edge Function works**: The issue is in the app's integration. Check:
   - How the app calls the Edge Function
   - Token registration flow
   - Message handling in the app

2. **If Edge Function fails**: Check:
   - Secrets configuration
   - Firebase service account permissions
   - FCM v1 API is enabled in Google Cloud Console

## Quick Test Script

Save this as `quick-test.sh`:

```bash
#!/bin/bash

# Configuration
SUPABASE_URL="https://YOUR_PROJECT_REF.supabase.co"
SUPABASE_ANON_KEY="YOUR_SUPABASE_ANON_KEY"
FCM_TOKEN="YOUR_FCM_TOKEN_HERE"

echo "🧪 Testing Edge Function..."
echo ""

# Test 1: Check secrets
echo "1️⃣ Testing secrets configuration..."
curl -s "${SUPABASE_URL}/functions/v1/send-push-notification?test=secrets" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" | jq '.'

echo ""
echo "2️⃣ Sending test notification..."
curl -X POST "${SUPABASE_URL}/functions/v1/send-push-notification" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"token\": \"${FCM_TOKEN}\",
    \"title\": \"Test Notification\",
    \"body\": \"This is a test from Edge Function\",
    \"data\": {\"type\": \"test\"}
  }" | jq '.'

echo ""
echo "✅ Test complete! Check your device for the notification."
```

Make it executable and run:
```bash
chmod +x quick-test.sh
./quick-test.sh
```



