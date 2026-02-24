# OAuth Providers and Email Confirmation

## The Relationship

**OAuth providers (Apple, Google) and email confirmations are separate settings**, but they can interact in ways that cause confusion:

### How They Work Together

1. **OAuth Sign-In (Apple/Google)**:
   - Email is **already verified** by the OAuth provider
   - No email confirmation needed (email is pre-verified)
   - Users can log in immediately

2. **Email/Password Sign-Up**:
   - Email confirmation **should be required** (if enabled)
   - User must confirm email before logging in
   - SMTP must be configured to send confirmation emails

### The Problem

If OAuth providers are **enabled but misconfigured**, it might cause:
- OAuth sign-ins to fail
- But it **shouldn't** affect email/password confirmations

However, if you see `immediate_login_after_signup: true` for email/password signups, it means:
- Email confirmations are **disabled** for email/password
- OR there's an auto-confirm trigger
- OR SMTP isn't working so Supabase auto-confirms

## What to Check

### 1. Check Email Confirmation Setting

**Go to**: Authentication → Settings → "Enable email confirmations"
- **Should be**: ON (for email/password signups)
- **OAuth providers**: Don't need this (they verify email themselves)

### 2. Check OAuth Provider Configuration

**Go to**: Authentication → Providers

**For Apple Sign-In:**
- ✅ Provider enabled
- ✅ Service ID configured
- ✅ Team ID configured
- ✅ Key ID configured
- ✅ Private Key uploaded

**For Google Sign-In:**
- ✅ Provider enabled
- ✅ Client ID configured
- ✅ Client Secret configured

### 3. Check OAuth Redirect URLs

**Go to**: Authentication → URL Configuration

**Redirect URLs should include:**
- `com.rgs.app://`
- `com.rgs.app://auth/callback`
- Any OAuth callback URLs

## Why OAuth Might Be Failing

### Common OAuth Issues:

1. **Apple Sign-In**:
   - Missing or incorrect Service ID
   - Private key not uploaded correctly
   - Team ID mismatch
   - Bundle ID mismatch

2. **Google Sign-In**:
   - Client ID/Secret incorrect
   - Redirect URL not configured in Google Console
   - OAuth consent screen not configured

3. **Redirect URLs**:
   - Not configured in Supabase
   - Not matching what's in OAuth provider console

## The Real Issue

**OAuth failures shouldn't affect email/password confirmations**, but:

1. **If email confirmations are disabled**:
   - Users can log in immediately (email/password)
   - No confirmation emails sent
   - This is the main issue

2. **If OAuth is misconfigured**:
   - OAuth sign-ins fail
   - But email/password should still work (with confirmation if enabled)

## Solution

### Step 1: Fix Email Confirmations First

1. **Enable email confirmations**:
   - Authentication → Settings → "Enable email confirmations" → ON
   - Save

2. **Verify SMTP is configured**:
   - Settings → Auth → SMTP Settings
   - All fields filled correctly
   - Save

3. **Test email/password signup**:
   - Register new user
   - Should receive confirmation email
   - Should NOT be able to log in until email confirmed

### Step 2: Fix OAuth Providers (Separate Issue)

**For Apple:**
1. Check Apple Developer Console
2. Verify Service ID, Team ID, Key ID
3. Verify private key is correct
4. Check bundle ID matches

**For Google:**
1. Check Google Cloud Console
2. Verify OAuth 2.0 credentials
3. Add redirect URLs
4. Configure OAuth consent screen

## Quick Test

1. **Disable OAuth providers temporarily**:
   - Authentication → Providers
   - Turn OFF Apple and Google
   - Save

2. **Test email/password signup**:
   - Register new user
   - Check if confirmation email is sent
   - Try to log in without confirming → Should be blocked

3. **If this works**:
   - Email confirmations are working
   - OAuth issue is separate

4. **If this doesn't work**:
   - Email confirmations are still disabled
   - Need to enable them in settings

## Summary

- **OAuth and email confirmations are separate**
- **OAuth failures don't disable email confirmations**
- **If `immediate_login_after_signup: true`**, email confirmations are disabled
- **Fix email confirmations first**, then fix OAuth separately

The main issue is likely that **email confirmations are disabled** in Supabase settings, not related to OAuth.


