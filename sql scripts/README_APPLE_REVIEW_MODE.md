# Apple Review Mode (Sign in with Apple)

Internal app with restricted access. Apple requires **Sign in with Apple** to be available when other sign-in options exist, so the button must stay visible. These scripts control who actually gets in, **without changing the app binary**.

## Before submission

1. **Run in Supabase SQL Editor:** `APPLE_REVIEW_MODE_ENABLE.sql`
2. This:
   - Sets `app_settings.apple_bypass_approval = true`
   - Adds trigger `on_apple_signin_reviewer_access` on `auth.users`: when someone signs in with **Apple** for the first time, the trigger creates a `public.users` row (role `technician`) and an **approved** `pending_user_approvals` row so they can use the app.
3. Submit the app with **Sign in with Apple** visible. Reviewers can sign in with Apple and get technician access.

## After approval

1. **Run in Supabase SQL Editor:** `APPLE_REVIEW_MODE_DISABLE.sql`
2. This:
   - Drops the trigger so **new** Apple sign-ins no longer get a user record (they are restricted).
   - Sets `app_settings.apple_bypass_approval = false`.
3. No app resubmission needed.

## Optional: revoke the reviewer account

If you want to block the specific Apple ID used during review:

```sql
-- Replace REVIEWER_AUTH_USER_ID with the auth.users id of the reviewer
DELETE FROM public.pending_user_approvals WHERE user_id = 'REVIEWER_AUTH_USER_ID';
DELETE FROM public.users WHERE id = 'REVIEWER_AUTH_USER_ID';
-- Then remove the auth user in Supabase Dashboard → Authentication → Users
```

You can find the reviewer’s `id` in Supabase **Authentication → Users** (e.g. by email or “Signed up with Apple”).
