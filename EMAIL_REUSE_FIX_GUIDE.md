# Email Reuse Fix Guide

## Problem
After deleting users from both `public.users` and `auth.users`, emails still cannot be reused for registration. This happens because:

1. **Orphaned `auth.users` records** - Users deleted from `public.users` may still exist in `auth.users`
2. **Unconfirmed registrations** - Users who never confirmed their email still exist in `auth.users` and block email reuse
3. **Incomplete deletions** - Some user records may not have been fully deleted

## Solution

### Step 1: Run the Cleanup Script

Run `CLEANUP_DELETED_USERS.sql` in your Supabase SQL Editor. This script will:

1. **Identify orphaned records** - Find all `auth.users` that don't have corresponding `public.users` records
2. **Delete orphaned users** - Remove all `auth.users` records that don't have `public.users` entries
3. **Create email availability function** - Add a `check_email_available()` SQL function that properly checks both tables
4. **Show summary** - Display counts of remaining records

### Step 2: Verify Cleanup

After running the script, check the summary output. You should see:
- `orphaned_auth_users`: Should be 0 (or very low)
- `unconfirmed_users`: Should be 0 (or only very recent ones)

### Step 3: Test Email Availability

The app now uses a three-tier approach to check email availability:

1. **Primary**: Uses `check_email_available()` SQL function (most reliable)
2. **Fallback 1**: Directly queries `public.users` table
3. **Fallback 2**: Attempts sign-in with dummy password (checks `auth.users`)

### Step 4: Test Registration

Try registering with a previously deleted email. It should now work if:
- The email was properly deleted from both tables
- The cleanup script removed any orphaned records

## Important Notes

⚠️ **Backup First**: Always backup your database before running deletion scripts

⚠️ **Unconfirmed Users**: The script deletes ALL orphaned `auth.users` records. If you want to keep unconfirmed users for a grace period, you can modify the script to only delete unconfirmed users older than a certain time (e.g., 1 hour, 24 hours).

⚠️ **Active Users**: The script only deletes users that don't have `public.users` records, so active users are safe.

## Troubleshooting

### Emails Still Not Available

1. **Check for remaining orphaned records**:
   ```sql
   SELECT au.id, au.email, au.email_confirmed_at, au.created_at
   FROM auth.users au
   LEFT JOIN public.users pu ON au.id = pu.id
   WHERE pu.id IS NULL;
   ```

2. **Manually delete specific emails**:
   ```sql
   DELETE FROM auth.users WHERE email = 'user@example.com';
   ```

3. **Test the email availability function**:
   ```sql
   SELECT public.check_email_available('user@example.com');
   ```

### Function Not Found Error

If you get an error that `check_email_available` function doesn't exist:
- Make sure you ran the entire `CLEANUP_DELETED_USERS.sql` script
- Check that the function was created in the `public` schema
- Verify permissions: `GRANT EXECUTE ON FUNCTION public.check_email_available(TEXT) TO authenticated, anon;`

## Code Changes

The `isEmailAvailable()` function in `lib/providers/auth_provider.dart` has been updated to:
1. First try the SQL function `check_email_available()`
2. Fall back to direct `public.users` query
3. Last resort: sign-in attempt with dummy password

This ensures maximum reliability and proper email reuse after deletion.
