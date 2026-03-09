# Email Confirmation User Creation Fix

## Problem
After registering and confirming email, users were redirected to role selection, but when trying to login, they got an error saying "account not available" even though they were authenticated in `auth.users` but not in `public.users`.

## Root Cause
The database trigger `handle_email_confirmed_user` was updated to require explicit roles (no default to 'technician'), but there were two issues:

1. **Timing Issue**: When email confirmation happens via deep link, the app tries to auto-login immediately, but the database trigger might not have finished creating the user record yet.

2. **Role Reading**: The trigger might not be reading the role from metadata correctly, or there could be a delay in the trigger execution.

3. **No Retry Logic**: The login code checked for user record once, and if it didn't exist, it immediately failed without waiting for the trigger to complete.

## Solution

### 1. Database Fix (`FIX_EMAIL_CONFIRMATION_USER_CREATION.sql`)
- **Improved trigger**: Enhanced `handle_email_confirmed_user` to better read role from metadata
- **Better logging**: Added RAISE NOTICE statements to debug trigger execution
- **Backfill**: Automatically creates user records for any confirmed users who don't have records yet (if they have a role in metadata)
- **Verification**: Includes queries to check trigger status and find users needing records

### 2. Code Fixes

#### `lib/main.dart`
- **Added delay**: Wait 2 seconds after email confirmation to allow database trigger to complete
- **Better logging**: Log user metadata and role to help debug issues

#### `lib/providers/auth_provider.dart`
- **Retry logic**: After checking for user record, wait 1 second and retry (in case trigger is still processing)
- **Fallback creation**: If user record still doesn't exist after retry, create it from metadata (if role exists)
- **Pending approval**: If creating technician user record, also create pending approval
- **Better error messages**: More specific error messages explaining what went wrong

## How to Fix

### Step 1: Run SQL Script
Run `FIX_EMAIL_CONFIRMATION_USER_CREATION.sql` in your Supabase SQL Editor. This will:
- Update the trigger to be more robust
- Backfill any existing users who confirmed email but don't have records
- Verify the trigger is working

### Step 2: Test Registration Flow
1. Register a new user with explicit role (technician or admin)
2. Confirm email via the confirmation link
3. Should automatically log in and redirect to appropriate screen
4. If it doesn't work, check logs for role in metadata

## What Changed

### Before
- Trigger might not create user record if role reading failed
- No retry logic in login code
- Immediate failure if user record doesn't exist

### After
- Trigger is more robust at reading role from metadata
- Login code waits and retries before failing
- Fallback creation if trigger didn't run
- Better error messages

## Verification

After running the SQL script, check:

1. **Trigger exists**:
   ```sql
   SELECT tgname, tgenabled FROM pg_trigger WHERE tgname = 'on_email_confirmed';
   ```

2. **Function exists**:
   ```sql
   SELECT proname FROM pg_proc WHERE proname = 'handle_email_confirmed_user';
   ```

3. **Users needing records** (should be 0 after backfill):
   ```sql
   SELECT COUNT(*) FROM auth.users au
   WHERE au.email_confirmed_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.id = au.id)
     AND (au.raw_user_meta_data->>'role' IS NOT NULL 
          AND au.raw_user_meta_data->>'role' != ''
          AND au.raw_user_meta_data->>'role' != 'null');
   ```

## Notes

- The trigger requires explicit role in metadata - no defaults
- If role is missing, user record won't be created (by design)
- The code now handles timing issues better with retries and delays
- Users who already confirmed but don't have records will be backfilled automatically



