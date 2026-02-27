# FCM v1 API Setup Guide

## ✅ Updated to Use FCM v1 API

The Edge Function has been updated to use the **FCM v1 API** instead of the legacy API.

## 🔧 Required Supabase Secrets

You need to add **TWO** secrets to Supabase:

### 1. FCM_PROJECT_ID
- **What it is**: Your Firebase Project ID
- **Where to find it**:
  - Firebase Console → Project Settings → General tab
  - Look for "Project ID" (not Project Number)
  - Example: `my-app-12345`

### 2. FCM_ACCESS_TOKEN
- **What it is**: OAuth2 access token for FCM v1 API
- **How to get it**:
  
  **Option A: Using gcloud CLI (Recommended)**
  ```bash
  # Install gcloud CLI if not already installed
  # https://cloud.google.com/sdk/docs/install
  
  # Authenticate
  gcloud auth login
  
  # Set your project
  gcloud config set project YOUR_PROJECT_ID
  
  # Get access token
  gcloud auth print-access-token
  ```
  
  **Option B: Using Service Account (For Production)**
  1. Go to Firebase Console → Project Settings → Service Accounts
  2. Click "Generate New Private Key"
  3. Download the JSON file
  4. Use the service account to generate tokens programmatically
  
  **Option C: Using Firebase Admin SDK**
  - If you have a backend service, use Firebase Admin SDK to generate tokens

## 📝 Adding Secrets to Supabase

1. Go to **Supabase Dashboard**
2. Navigate to **Settings** → **Edge Functions** → **Secrets**
3. Click **Add Secret**
4. Add both secrets:
   - **Name**: `FCM_PROJECT_ID`
     **Value**: Your Firebase Project ID
   - **Name**: `FCM_ACCESS_TOKEN`
     **Value**: Your OAuth2 access token

## ⚠️ Important Notes

### Access Token Expiration
- OAuth2 access tokens expire after **1 hour**
- For production, you should:
  - Use a service account
  - Implement token refresh logic
  - Or use a backend service that handles token refresh

### Token Refresh (Recommended for Production)
If you need automatic token refresh, you can:

1. **Use a service account** and generate tokens on-demand
2. **Create a separate Edge Function** that refreshes tokens
3. **Use Firebase Admin SDK** in a backend service

### Quick Test Token (Development Only)
For testing, you can use `gcloud auth print-access-token` to get a temporary token. This works for about 1 hour.

## 🔄 Differences from Legacy API

| Legacy API | v1 API |
|------------|--------|
| `https://fcm.googleapis.com/fcm/send` | `https://fcm.googleapis.com/v1/projects/{project-id}/messages:send` |
| Server Key | OAuth2 Access Token |
| `Authorization: key=...` | `Authorization: Bearer ...` |
| `{ to: token, ... }` | `{ message: { token: token, ... } }` |

## 🧪 Testing

After adding the secrets:

1. **Deploy the Edge Function**:
   ```bash
   supabase functions deploy send-push-notification
   ```

2. **Test from your app**:
   - Trigger any action that sends a notification
   - Check Edge Function logs in Supabase Dashboard
   - Verify notification is received on device

## 🐛 Troubleshooting

### Error: "FCM_PROJECT_ID not configured"
- Make sure you added `FCM_PROJECT_ID` secret
- Check the secret name is exactly `FCM_PROJECT_ID` (case-sensitive)

### Error: "FCM_ACCESS_TOKEN not configured"
- Make sure you added `FCM_ACCESS_TOKEN` secret
- Check the secret name is exactly `FCM_ACCESS_TOKEN` (case-sensitive)

### Error: "401 Unauthorized"
- Your access token may have expired (tokens expire after 1 hour)
- Generate a new token using `gcloud auth print-access-token`
- Update the `FCM_ACCESS_TOKEN` secret

### Error: "403 Forbidden"
- Your access token doesn't have the required permissions
- Make sure you're using a token with FCM permissions
- Check your Firebase project permissions

## 📚 Resources

- [FCM v1 API Documentation](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
- [OAuth2 Token Generation](https://cloud.google.com/docs/authentication/getting-started)
- [Service Accounts Guide](https://firebase.google.com/docs/admin/setup)



