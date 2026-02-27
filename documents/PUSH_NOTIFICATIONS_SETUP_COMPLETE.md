# Push Notifications Setup - Complete Implementation

## ✅ What Was Fixed

### 1. Created Push Notification Service
- **File**: `lib/services/push_notification_service.dart`
- **Functions**:
  - `sendToUser()` - Send to specific user by user_id
  - `sendToAdmins()` - Send to all admin users
  - `sendToToken()` - Send to specific FCM token

### 2. Added Push Notifications to All Actions

#### ✅ New User Registration → Admin Notification
- **Location**: When pending approval is created
- **Status**: ⚠️ **NEEDS IMPLEMENTATION** - Need to add trigger when new user registers

#### ✅ User Approved → User Notification
- **Location**: `lib/providers/pending_approvals_provider.dart`
- **Status**: ✅ **IMPLEMENTED** - Sends push notification to approved user

#### ✅ Tool Request → Admin & Holder Notifications
- **Location**: `lib/screens/shared_tools_screen.dart`
- **Status**: ✅ **IMPLEMENTED** - Sends push to admins and tool holder

#### ✅ Tool Issue Reported → Admin Notification
- **Location**: `lib/providers/tool_issue_provider.dart`
- **Status**: ✅ **IMPLEMENTED** - Sends push to admins

#### ✅ New Tool Added → Admin Notification
- **Location**: `lib/providers/supabase_tool_provider.dart`
- **Status**: ✅ **IMPLEMENTED** - Sends push to admins

#### ✅ Tool Request (from request screen) → Admin Notification
- **Location**: `lib/providers/admin_notification_provider.dart`
- **Status**: ✅ **IMPLEMENTED** - Sends push to admins when notification is created

### 3. Created Supabase Edge Function
- **File**: `supabase/functions/send-push-notification/index.ts`
- **Purpose**: Sends FCM push notifications using FCM Server Key

## 🚀 Setup Instructions

### Step 1: Deploy Edge Function

1. **Install Supabase CLI** (if not already installed):
   ```bash
   npm install -g supabase
   ```

2. **Login to Supabase**:
   ```bash
   supabase login
   ```

3. **Link your project**:
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

4. **Deploy the function**:
   ```bash
   supabase functions deploy send-push-notification
   ```

### Step 2: Add FCM Server Key to Supabase Secrets

1. **Get FCM Server Key**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to **Project Settings** → **Cloud Messaging**
   - Copy the **Server key** (under "Cloud Messaging API (Legacy)")

2. **Add to Supabase Secrets**:
   - Go to Supabase Dashboard
   - Navigate to **Settings** → **Edge Functions** → **Secrets**
   - Click **Add Secret**
   - Name: `FCM_SERVER_KEY`
   - Value: Paste your FCM Server Key
   - Click **Save**

### Step 3: Verify FCM Tokens Are Being Saved

1. **Check Database**:
   - Go to Supabase Dashboard → **Table Editor** → `user_fcm_tokens`
   - Verify users have tokens saved

2. **Test Token Retrieval**:
   - Log in to the app
   - Check console logs for: `✅ [FCM] Token saved to Supabase`

### Step 4: Test Push Notifications

1. **Test via Firebase Console**:
   - Firebase Console → **Cloud Messaging** → **Send test message**
   - Enter FCM token from `user_fcm_tokens` table
   - Send test notification
   - Should receive on device

2. **Test via App Actions**:
   - Register a new technician → Admins should get push
   - Approve a user → User should get push
   - Add a tool → Admins should get push
   - Report tool issue → Admins should get push
   - Request shared tool → Holder and admins should get push

## 📋 Checklist

- [x] Push notification service created
- [x] Edge Function code created
- [x] Push notifications added to user approval
- [x] Push notifications added to tool requests
- [x] Push notifications added to tool issues
- [x] Push notifications added to new tool creation
- [ ] **Deploy Edge Function to Supabase**
- [ ] **Add FCM_SERVER_KEY to Supabase secrets**
- [ ] **Add push notification for new user registration** (database trigger or code)
- [ ] Test all notification scenarios

## 🔧 Missing: New User Registration Push Notification

When a new user registers, we need to send a push notification to admins. This can be done in two ways:

### Option 1: Database Trigger (Recommended)
Create a database trigger that fires when a new `pending_user_approvals` record is created:

```sql
CREATE OR REPLACE FUNCTION notify_admins_on_new_registration()
RETURNS TRIGGER AS $$
BEGIN
  -- This would call the Edge Function via HTTP
  -- For now, the notification is created in the database
  -- The push notification should be sent from the app code
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_new_registration
  AFTER INSERT ON pending_user_approvals
  FOR EACH ROW
  EXECUTE FUNCTION notify_admins_on_new_registration();
```

### Option 2: App Code (Current Approach)
Add push notification sending in `registerTechnician` after pending approval is created.

**Recommended**: Add it in `lib/providers/auth_provider.dart` after pending approval is successfully created.

## 🐛 Troubleshooting

### Issue: "Edge Function not found"
**Solution**: Deploy the Edge Function using Supabase CLI

### Issue: "FCM_SERVER_KEY not configured"
**Solution**: Add FCM_SERVER_KEY to Supabase secrets

### Issue: "No FCM token found"
**Solution**: 
- Check if user is logged in
- Check if Firebase is initialized
- Check `user_fcm_tokens` table in Supabase

### Issue: "Notifications not received"
**Solution**:
- Verify FCM token is valid (test via Firebase Console)
- Check device notification permissions
- Check console logs for errors
- Verify Edge Function is deployed and working

## 📝 Next Steps

1. Deploy the Edge Function
2. Add FCM_SERVER_KEY to Supabase secrets
3. Add push notification for new user registration
4. Test all notification scenarios
5. Monitor Edge Function logs for errors



