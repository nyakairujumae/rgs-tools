# Email Flow for Admin-Created Technicians

## What Happens

When an admin adds a technician, **two emails are sent**:

### 1. Confirmation Email (Automatic from Supabase)
- **When**: Sent immediately when `signUp()` is called
- **Purpose**: Verify email address
- **Action**: Can be **ignored** - email is auto-confirmed by database trigger
- **Template**: Supabase "Confirm signup" template

### 2. Password Reset Email (Sent by our code)
- **When**: Sent after account creation (with delay for trigger)
- **Purpose**: Set initial password
- **Action**: **Use this email** to set password
- **Template**: Supabase "Reset password" template

## Why Both Emails?

This happens because:
1. Supabase automatically sends confirmation email when `signUp()` is called
2. Our code sends password reset email so technician can set password
3. The auto-confirm trigger confirms the email automatically (so confirmation email is redundant)

## What Technician Should Do

**Recommended**: Use the **password reset email** to set password. The confirmation email can be ignored since email is already auto-confirmed.

**Alternative**: Click confirmation link (harmless, already confirmed), then use password reset email.

## Is This Okay?

**Yes, this is fine!** The technician will:
1. Receive confirmation email (can ignore)
2. Receive password reset email (use this)
3. Click password reset link
4. Set password
5. Log in

The confirmation email doesn't cause any issues - it's just redundant because the trigger auto-confirms.

## Future Improvement (Optional)

If you want to avoid the confirmation email, we would need to:
- Use Supabase Admin API (requires service role key)
- Create user directly with email confirmed
- Then send password reset email

But this requires more setup and isn't necessary - the current flow works fine.
