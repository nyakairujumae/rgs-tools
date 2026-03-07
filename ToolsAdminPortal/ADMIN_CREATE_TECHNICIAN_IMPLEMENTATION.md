# Admin-Created Technician Auth Account Implementation

## Overview

This implementation allows admins to add technicians who can immediately log in by receiving a password reset email. This is **separate from and does not interfere with** technician self-registration.

## Email Types (Different!)

### 1. **Confirmation Email** (Self-Registration)
- **When**: Technician self-registers
- **Purpose**: Verify email address
- **Template**: Supabase "Confirm signup" template
- **Action**: Click link → Email confirmed → Can log in

### 2. **Password Reset Email** (Admin-Created)
- **When**: Admin adds technician
- **Purpose**: Set initial password
- **Template**: Supabase "Reset password" template
- **Action**: Click link → Set password → Can log in

**These are completely different emails and won't conflict!**

---

## How It Works

### Admin Adds Technician Flow:
1. Admin fills out "Add Technician" form (email required)
2. System checks if email already has auth account
3. If new email:
   - Creates `auth.users` account with random secure password
   - Auto-confirms email (via trigger for technicians)
   - Creates `users` table record with role='technician'
   - Creates `pending_user_approvals` record
   - Sends **password reset email** to technician
4. Creates `technicians` table record with `user_id` linking to auth account
5. Technician receives email → clicks "Set Password" → sets password → can log in

### Self-Registration Flow (Unchanged):
1. Technician self-registers with password
2. System creates `auth.users` account
3. May send confirmation email (if enabled)
4. Creates `pending_user_approvals` record
5. Technician confirms email (if needed) → can log in

**No interference between the two flows!**

---

## Implementation Details

### Files Modified:

1. **`lib/providers/auth_provider.dart`**
   - Added `createTechnicianAuthAccount()` method
   - Creates auth account with random password
   - Auto-confirms email (via existing trigger)
   - Sends password reset email

2. **`lib/screens/add_technician_screen.dart`**
   - Calls `createTechnicianAuthAccount()` before adding technician
   - Links technician to auth account via `user_id`
   - Shows success message with email info

3. **`lib/providers/supabase_technician_provider.dart`**
   - Updated `addTechnician()` to accept optional `userId` parameter
   - Stores `user_id` in technicians table

4. **Database Schema**
   - Added `user_id` column to `technicians` table
   - Links to `auth.users(id)`

---

## Database Migration

Run this SQL in Supabase SQL Editor:

```sql
-- See ADMIN_CREATE_TECHNICIAN_AUTH.sql
```

This adds:
- `user_id` column to `technicians` table
- Index for faster lookups
- Foreign key to `auth.users`

---

## Edge Cases Handled

1. **Email Already Exists**
   - Checks if email has auth account
   - If exists, links technician to existing account
   - Shows appropriate error message

2. **Email Not Provided**
   - Technician can be added without email
   - No auth account created
   - Can be added later

3. **Password Reset Email Fails**
   - Account still created
   - Admin can resend invite later
   - Error logged but doesn't block technician creation

4. **Self-Registration Conflict**
   - Self-registration uses different flow (`registerTechnician()`)
   - Admin-created uses `createTechnicianAuthAccount()`
   - No conflict - different code paths

---

## Testing Checklist

- [ ] Admin adds technician with email → Auth account created
- [ ] Technician receives password reset email
- [ ] Technician clicks email link → Password reset screen opens
- [ ] Technician sets password → Can log in
- [ ] Technician logs in → Sees pending approval screen (if not approved)
- [ ] Self-registration still works (unchanged)
- [ ] Email already exists → Handled gracefully
- [ ] No email provided → Technician added without auth account

---

## Email Templates in Supabase

### Password Reset Template
- **Location**: Authentication → Email Templates → Reset password
- **Used for**: Admin-created technicians
- **Contains**: Link to set password

### Confirm Signup Template
- **Location**: Authentication → Email Templates → Confirm signup
- **Used for**: Self-registered technicians (if email confirmation enabled)
- **Contains**: Link to confirm email

**These are separate templates - no conflict!**

---

## Security Notes

1. **Random Password Generation**
   - Uses secure random generation
   - Password is never shown to admin
   - Technician must set their own password via email

2. **Email Verification**
   - Admin provides email (assumed verified)
   - Email auto-confirmed for technicians (via trigger)
   - Password reset email serves as additional verification

3. **Access Control**
   - Only admins can create technician auth accounts
   - RLS policies prevent unauthorized access

---

## Next Steps

1. **Run Database Migration**
   - Execute `ADMIN_CREATE_TECHNICIAN_AUTH.sql` in Supabase

2. **Test End-to-End**
   - Admin adds technician
   - Check email received
   - Test password reset flow
   - Verify login works

3. **Optional Enhancements**
   - Add "Resend Invite" button for technicians without passwords
   - Show auth account status in technician list
   - Add bulk invite feature
