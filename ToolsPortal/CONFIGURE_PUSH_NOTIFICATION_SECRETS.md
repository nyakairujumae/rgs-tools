# Configure Push Notification Secrets in Supabase

## 🔍 Problem

The Edge Function `send-push-notification` is being called correctly, but it's failing with:
```
GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured in Supabase secrets
```

This means the Supabase Edge Function needs Firebase credentials to authenticate with FCM (Firebase Cloud Messaging).

## ✅ Solution: Add Secrets to Supabase

You need to add **3 secrets** to your Supabase Edge Function configuration.

---

## 📋 Step-by-Step Instructions

### Step 1: Get Firebase Service Account Credentials

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project (the one you're using for push notifications)

2. **Navigate to Service Accounts**
   - Click the **⚙️ Settings** icon (top left)
   - Select **Project Settings**
   - Click the **Service Accounts** tab

3. **Generate Service Account Key**
   - Click **"Generate New Private Key"** button
   - A dialog will appear warning you to keep the key secure
   - Click **"Generate Key"**
   - A JSON file will download automatically (e.g., `your-project-firebase-adminsdk-xxxxx.json`)

4. **Open the JSON file**
   - Open the downloaded JSON file in a text editor
   - You'll see something like this:
   ```json
   {
     "type": "service_account",
     "project_id": "your-project-id",
     "private_key_id": "...",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
     "client_id": "...",
     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
     "token_uri": "https://oauth2.googleapis.com/token",
     ...
   }
   ```

5. **Extract the values you need:**
   - `project_id` → This is your **GOOGLE_PROJECT_ID**
   - `client_email` → This is your **GOOGLE_CLIENT_EMAIL**
   - `private_key` → This is your **GOOGLE_PRIVATE_KEY** (keep the entire value including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)

---

### Step 2: Get Firebase Project ID (Alternative Method)

If you need to verify the Project ID:

1. **Firebase Console** → **Project Settings** → **General** tab
2. Look for **"Project ID"** (not Project Number)
3. Copy this value

---

### Step 3: Add Secrets to Supabase

1. **Go to Supabase Dashboard**
   - Visit: https://supabase.com/dashboard
   - Select your project

2. **Navigate to Edge Functions Secrets**
   - Click **Settings** (left sidebar, gear icon)
   - Click **Edge Functions** (under "Project Settings")
   - Click **Secrets** tab

3. **Add Secret 1: GOOGLE_PROJECT_ID**
   - Click **"Add Secret"** button
   - **Name**: `GOOGLE_PROJECT_ID`
   - **Value**: Paste your Firebase Project ID (from Step 1 or Step 2)
   - Click **"Save"**

4. **Add Secret 2: GOOGLE_CLIENT_EMAIL**
   - Click **"Add Secret"** button again
   - **Name**: `GOOGLE_CLIENT_EMAIL`
   - **Value**: Paste the `client_email` value from the JSON file
   - Example: `firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com`
   - Click **"Save"**

5. **Add Secret 3: GOOGLE_PRIVATE_KEY**
   - Click **"Add Secret"** button again
   - **Name**: `GOOGLE_PRIVATE_KEY`
   - **Value**: Paste the **entire** `private_key` value from the JSON file
   - **IMPORTANT**: Include the entire key, including:
     - `-----BEGIN PRIVATE KEY-----`
     - All the lines in between
     - `-----END PRIVATE KEY-----`
   - The value should look like:
     ```
     -----BEGIN PRIVATE KEY-----
     MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
     ... (many lines of base64 characters) ...
     -----END PRIVATE KEY-----
     ```
   - Click **"Save"**

---

## ⚠️ Important Notes

### Private Key Format
- The `GOOGLE_PRIVATE_KEY` must include the full key with headers and footers
- It may contain `\n` characters in the JSON - these are fine, Supabase will handle them
- If copying from JSON, make sure you get the entire value (it's usually very long)

### Security
- **Never commit the service account JSON file to git**
- **Never share these secrets publicly**
- These secrets give full access to your Firebase project
- If compromised, regenerate the service account key immediately

### Verification
After adding all 3 secrets:
1. Go back to your app
2. Click the **bug icon** (🐛) in the admin home screen
3. Run the push notification test again
4. Check the logs - you should see:
   - `✅ [Push] Notification sent successfully` instead of the 500 error
   - The Edge Function should return status 200

---

## 🔍 Troubleshooting

### Error: "GOOGLE_PROJECT_ID not configured"
- **Solution**: Make sure you added `GOOGLE_PROJECT_ID` (not `FCM_PROJECT_ID` or any other name)
- The name must be **exactly** `GOOGLE_PROJECT_ID`

### Error: "GOOGLE_CLIENT_EMAIL and GOOGLE_PRIVATE_KEY must be configured"
- **Solution**: Check that both secrets are added with exact names:
  - `GOOGLE_CLIENT_EMAIL` (not `GOOGLE_CLIENT_EMAIL_ADDRESS`)
  - `GOOGLE_PRIVATE_KEY` (not `GOOGLE_PRIVATE_KEY_JSON`)

### Error: "401 Unauthorized" or "THIRD_PARTY_AUTH_ERROR"

**CRITICAL: This is the most common issue!** The OAuth2 token is being generated successfully, but FCM API is rejecting it. This usually means:

**The Firebase Cloud Messaging API is NOT enabled in Google Cloud Console.**

**Solution - Enable FCM API:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project (`rgstools`)
3. Go to **APIs & Services** → **Library** (or **Enabled APIs**)
4. Search for **"Firebase Cloud Messaging API"**
5. If it's NOT enabled, click **"Enable"**
6. Wait a few minutes for it to activate
7. Try the test again

**Alternative: Enable via Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`rgstools`)
3. Go to **Project Settings** → **Cloud Messaging** tab
4. Look for **"Cloud Messaging API (V1)"** section
5. If it says "Not enabled", click **"Enable"**

**Verify it's enabled:**
- Go to Google Cloud Console → APIs & Services → Enabled APIs
- You should see **"Firebase Cloud Messaging API"** in the list
- Status should be **"Enabled"**

**If API is enabled but still getting 401:**
The service account needs IAM permissions. Do this:

1. **Go to Google Cloud Console** → **IAM & Admin** → **IAM**
2. **Find your service account** (the email from `GOOGLE_CLIENT_EMAIL`):
   - Look for: `firebase-adminsdk-fbsvc@rgstools.iam.gserviceaccount.com`
3. **Click the pencil icon** (Edit) next to the service account
4. **Click "ADD ANOTHER ROLE"**
5. **Add these roles:**
   - `Firebase Cloud Messaging Admin` (or `Firebase Admin SDK Administrator Service Agent`)
   - `Service Account Token Creator` (if not already present)
6. **Click "SAVE"**
7. **Wait 1-2 minutes** for permissions to propagate
8. **Test again**

**Alternative: Grant via Firebase Console:**
1. Go to **Firebase Console** → **Project Settings** → **Service Accounts**
2. Find your service account
3. Ensure it has **"Firebase Cloud Messaging Admin"** role

---

This means the secrets are set, but authentication with Google is failing. Other common causes:

1. **Private Key Format Issue**
   - The `GOOGLE_PRIVATE_KEY` must include the entire key exactly as it appears in the JSON file
   - Make sure you copied the ENTIRE value, including:
     ```
     -----BEGIN PRIVATE KEY-----
     (all the base64 lines)
     -----END PRIVATE KEY-----
     ```
   - **Common mistake**: Copying only part of the key or adding extra quotes
   - **Solution**: Copy the entire `private_key` value from the JSON file (it's usually 2000+ characters)

2. **Service Account Permissions**
   - The service account needs access to Firebase Cloud Messaging API
   - **Solution**: 
     - Go to [Google Cloud Console](https://console.cloud.google.com/)
     - Select your Firebase project
     - Go to **APIs & Services** → **Enabled APIs**
     - Make sure **Firebase Cloud Messaging API** is enabled
     - If not, click **+ ENABLE API** and search for "Firebase Cloud Messaging API"

3. **Wrong Project ID**
   - The `GOOGLE_PROJECT_ID` must match your Firebase project ID exactly
   - **Solution**: 
     - Go to Firebase Console → Project Settings → General
     - Copy the **Project ID** (not Project Number)
     - Make sure it matches exactly what you set in Supabase secrets

4. **APNs Key Environment Mismatch** (iOS only)
   - If you see "BadEnvironmentKeyInToken", your APNs key might be for the wrong environment
   - **Development key** → Use for development/testing builds
   - **Production key** → Use for App Store builds
   - **Solution**: Make sure you're using the correct APNs key for your build type

### Error: "Failed to authenticate with Google"
- **Solution**: 
  - Verify the `GOOGLE_PRIVATE_KEY` includes the full key with headers
  - Check that `GOOGLE_CLIENT_EMAIL` matches the email in your JSON file
  - Ensure the service account has the "Firebase Cloud Messaging API" enabled

### Still getting 500 errors after adding secrets
- **Solution**:
  1. Wait a few seconds for Supabase to refresh secrets
  2. Try the test again
  3. Check Supabase Edge Function logs (Dashboard → Edge Functions → send-push-notification → Logs)
  4. Look for more specific error messages in the logs

---

## ✅ Verification Checklist

After adding all secrets, verify:

- [ ] `GOOGLE_PROJECT_ID` is added (matches Firebase Project ID)
- [ ] `GOOGLE_CLIENT_EMAIL` is added (matches `client_email` from JSON)
- [ ] `GOOGLE_PRIVATE_KEY` is added (full key with BEGIN/END markers)
- [ ] All secret names are **exactly** as shown (case-sensitive)
- [ ] Test push notification works (bug icon in admin screen)
- [ ] Edge Function logs show success (not 500 errors)

---

## 📝 Quick Reference

**Secret Names (must be exact):**
1. `GOOGLE_PROJECT_ID`
2. `GOOGLE_CLIENT_EMAIL`
3. `GOOGLE_PRIVATE_KEY`

**Where to find values:**
- Firebase Console → Project Settings → Service Accounts → Generate New Private Key
- Download JSON file → Extract `project_id`, `client_email`, `private_key`

**Where to add:**
- Supabase Dashboard → Settings → Edge Functions → Secrets

---

Once all 3 secrets are configured, push notifications should work! 🎉

