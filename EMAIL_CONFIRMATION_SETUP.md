# Email Confirmation Setup: Admins vs Technicians

## Overview

This setup allows **different email confirmation requirements** for admins and technicians:

- ✅ **Admins**: Must confirm their email before they can log in (security requirement)
- ✅ **Technicians**: Email is auto-confirmed via database trigger (no email confirmation needed)

## Why This Approach?

1. **Security for Admins**: Prevents unauthorized admin registration by requiring email confirmation
2. **Ease for Technicians**: Technicians can register and log in immediately without email confirmation
3. **Domain Validation**: Admins must use `@royalgulf.ae` or `@mekar.ae` domains (enforced in app)

## Setup Steps

### Step 1: Enable Email Confirmation in Supabase

1. Go to **Supabase Dashboard** → **Authentication** → **Settings**
2. Find **"Enable email confirmations"**
3. **Turn it ON** (enable it)
4. Click **Save**

### Step 2: Run the Auto-Confirm Trigger SQL

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Open the file `AUTO_CONFIRM_TECHNICIAN_EMAILS.sql`
3. Copy and paste the SQL into the editor
4. Click **Run**

This creates a database trigger that:
- Automatically confirms technician emails after registration
- Leaves admin emails unconfirmed (requiring manual confirmation)

### Step 3: Verify the Setup

1. **Test Technician Registration**:
   - Register a new technician
   - Email should be auto-confirmed
   - User should be able to log in immediately
   - Check Supabase → Authentication → Users → The technician's email should show as "Confirmed"

2. **Test Admin Registration**:
   - Register a new admin (must use `@royalgulf.ae` or `@mekar.ae`)
   - Email should NOT be auto-confirmed
   - User should receive a confirmation email
   - User must click the confirmation link before they can log in
   - Check Supabase → Authentication → Users → The admin's email should show as "Unconfirmed" until they click the link

## How It Works

### For Technicians:
1. User registers as technician
2. Supabase creates the user account (email unconfirmed initially)
3. Database trigger detects technician role
4. Trigger automatically sets `email_confirmed_at = NOW()`
5. User can log in immediately

### For Admins:
1. User registers as admin (must use approved domain)
2. Supabase creates the user account (email unconfirmed)
3. Database trigger detects admin role and does NOT auto-confirm
4. Supabase sends confirmation email
5. User must click confirmation link
6. After confirmation, user can log in

## Security Considerations

✅ **Admin Protection**: 
- Email confirmation required
- Domain validation (`@royalgulf.ae` or `@mekar.ae`)
- Prevents unauthorized admin access

✅ **Technician Flow**:
- Email format validation (prevents invalid emails)
- Admin approval still required (separate from email confirmation)
- Technicians can't access system until admin approves

## Troubleshooting

### Issue: Technicians still need to confirm email

**Solution**: 
1. Check if the trigger was created: Run `SELECT * FROM pg_trigger WHERE tgname = 'on_technician_email_auto_confirm';`
2. Check if the function exists: Run `SELECT * FROM pg_proc WHERE proname = 'auto_confirm_technician_email';`
3. Re-run the SQL from `AUTO_CONFIRM_TECHNICIAN_EMAILS.sql`

### Issue: Admins are being auto-confirmed

**Solution**:
1. Check the trigger logic - it should only confirm if `role = 'technician'`
2. Verify the role is being set correctly in user metadata
3. Check Supabase logs for trigger execution

### Issue: Email confirmation emails not being sent

**Solution**:
1. Check Supabase → Authentication → Settings → Email templates
2. Verify email service is configured (SendGrid, etc.)
3. Check Supabase logs for email sending errors

## Alternative: Manual Admin Approval

If you prefer, you can also:
1. Disable email confirmation globally
2. Use domain validation for admins (`@royalgulf.ae` or `@mekar.ae`)
3. Require manual admin approval for all users (including admins)

This approach is simpler but less secure for admin accounts.

