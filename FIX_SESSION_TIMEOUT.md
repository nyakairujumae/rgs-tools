# Fix Session Timeout Issues

This guide explains how to fix the session timeout issues so users stay logged in until they explicitly log out.

## Current Issues:
- Users get logged out after 8 hours (session timeout)
- JWT tokens expire causing authentication failures
- Users have to re-login frequently

## Solutions:

### 1. App Configuration Changes
- Increase session timeout to 30 days (720 hours)
- Implement automatic token refresh
- Add persistent session storage

### 2. Supabase Dashboard Configuration
- Update JWT expiration settings
- Configure refresh token settings
- Set up proper session management

### 3. Enhanced Authentication Provider
- Add automatic session refresh
- Implement persistent login
- Better error handling for expired sessions

## Implementation Steps:

1. **Update App Config** - Increase session timeout
2. **Enhance Auth Provider** - Add automatic refresh
3. **Configure Supabase** - Update JWT settings
4. **Test Session Persistence** - Verify users stay logged in

## Expected Results:
- ✅ Users stay logged in for 30 days
- ✅ Automatic token refresh prevents logouts
- ✅ Only explicit logout clears session
- ✅ Better user experience
