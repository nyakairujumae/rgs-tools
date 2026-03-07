# Fix: Supabase Web Redirect Before App Deep Link

## The Issue

Even though you've configured `com.rgs.app://` URLs in Supabase, clicking email links takes you to a Supabase web page first (with "Continue to RGS App" banner) before opening the app.

## Why This Happens

This is **normal Supabase behavior**. The flow is:

1. **Email link**: `https://[project].supabase.co/auth/v1/verify?token=xxx&redirect_to=com.rgs.app://reset-password`
2. **Supabase web page**: Verifies the token (this is the page you see)
3. **Web page redirects**: To `com.rgs.app://reset-password` → App opens

Supabase **must** verify the token on their server first for security, so the web page is necessary.

## The Solution

### Step 1: Add Missing Redirect URL

Looking at your Supabase configuration, you have:
- ✅ `com.rgs.app://auth/callback`
- ✅ `com.rgs.app://`
- ❌ **Missing**: `com.rgs.app://reset-password`

**Add this redirect URL:**
1. Go to **Supabase Dashboard** → **Authentication** → **URL Configuration**
2. Click **"Add URL"**
3. Add: `com.rgs.app://reset-password`
4. Click **Save**

### Step 2: Verify Email Templates Use Deep Links

1. Go to **Authentication** → **Emails** → **Reset Password**
2. Make sure the template uses: `{{ .ConfirmationURL }}`
3. This will automatically use your configured redirect URLs

### Step 3: The Web Page is Normal

The Supabase verification web page is **expected behavior**. It:
- Verifies the token is valid
- Checks if it's expired
- Then redirects to your app

**You cannot skip this step** - it's required for security.

## Making It Faster

The web redirect happens very quickly (usually < 1 second). If it's slow, it might be:
- Network latency
- Supabase server response time
- Browser loading the page

## Alternative: Custom Verification Endpoint (Advanced)

If you want to skip the Supabase web page entirely, you would need to:
1. Create your own verification endpoint
2. Handle token verification yourself
3. Generate your own deep links

**But this is complex and not recommended** - the current flow is secure and works well.

## Current Flow (This is Correct)

1. User clicks email link
2. Opens Supabase verification page (web) - **This is normal**
3. Page verifies token
4. Page redirects to `com.rgs.app://reset-password`
5. App opens directly
6. User sets password

The web page is just a brief intermediate step for security verification.

## Summary

✅ **The web redirect is normal** - Supabase needs to verify tokens
✅ **Add `com.rgs.app://reset-password` to redirect URLs**
✅ **The app will open after verification** (usually very fast)
✅ **This is the secure, recommended approach**

The "Continue to RGS App" banner on the web page is Supabase's way of telling users the app will open - this is expected behavior.



