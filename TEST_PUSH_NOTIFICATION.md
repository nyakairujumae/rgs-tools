# Quick Test: Push Notifications from App

## 🧪 Test Steps

### Step 1: Trigger a Notification

**Option A: Create a Tool Request**
1. Login as technician
2. Go to "Shared Tools"
3. Request a tool
4. Check app logs for push notification messages

**Option B: Report a Tool Issue**
1. Login as technician
2. Report a tool issue
3. Check app logs for push notification messages

**Option C: Create a New Tool (Admin)**
1. Login as admin
2. Add a new tool
3. Check app logs for push notification messages

---

### Step 2: Check App Logs

**Look for these messages:**

**If working:**
```
📤 [Push] Sending notification to token: ...
📤 [Push] Title: ..., Body: ...
📥 [Push] Edge Function response status: 200
📥 [Push] Edge Function response data: {...}
✅ [Push] Notification sent successfully
```

**If not working:**
```
📤 [Push] Sending notification to token: ...
❌ [Push] Edge Function returned status: 500
❌ [Push] Error message: ...
```

---

### Step 3: Check Edge Function Logs

1. Go to **Supabase Dashboard** → **Edge Functions** → `send-push-notification` → **Logs**
2. Look for recent invocations (should match when you triggered notification)
3. Check for errors

---

### Step 4: Compare with Firebase Console Test

**Firebase Console test works:**
- ✅ FCM tokens are valid
- ✅ Firebase is configured correctly
- ✅ Device can receive notifications

**App notifications don't work:**
- ❌ Edge Function issue
- ❌ App not calling Edge Function correctly
- ❌ Edge Function secrets not configured

---

## 🔍 What to Check

1. **App logs** - Are push notifications being called?
2. **Edge Function logs** - Are they being received?
3. **Edge Function secrets** - Are they configured?
4. **Edge Function deployment** - Is it deployed?

---

## 📝 Share Results

When you trigger a notification, share:
1. App logs (especially `📤 [Push]` and `❌ [Push]` messages)
2. Edge Function logs (from Supabase Dashboard)
3. Any error messages

This will help identify the exact issue!

