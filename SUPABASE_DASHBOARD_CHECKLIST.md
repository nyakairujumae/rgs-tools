# Supabase Dashboard Settings Checklist

## 🎯 Critical Settings to Check

The "Database error granting user" error can also come from **Supabase Dashboard settings**, not just SQL triggers!

### 1. ✅ Disable Email Confirmation

**Location**: Supabase Dashboard → Authentication → Settings → Email Auth

**Setting**: "Enable email confirmations"
- ✅ **TURN THIS OFF** (uncheck it)
- This prevents the need for email verification
- Users can login immediately after signup

### 2. ✅ Disable Email Domain Restrictions

**Location**: Supabase Dashboard → Authentication → Settings → Email Auth

**Setting**: "Allowed email domains"
- ✅ **Leave this EMPTY** or add: `gmail.com, mekar.ae, outlook.com, yahoo.com, hotmail.com`
- If restricted, only those domains can signup
- Empty = all domains allowed

### 3. ✅ Enable Auto-confirm Users

**Location**: Supabase Dashboard → Authentication → Settings → Email Auth

**Setting**: "Disable email confirmations"
- ✅ **ENABLE THIS** (check the box)
- Users don't need to verify email
- Immediate access after signup

### 4. ✅ Check Database Webhooks

**Location**: Supabase Dashboard → Database → Webhooks

**Check**: Any webhooks that trigger on `auth.users` INSERT
- ✅ **Disable** or **delete** any webhooks on auth.users table
- These can cause "Database error granting user"

### 5. ✅ Check Database Triggers (in Dashboard)

**Location**: Supabase Dashboard → Database → Triggers

**Check**: Any triggers on `auth.users` table
- ✅ **Disable** or **delete** the `on_auth_user_created` trigger
- This is what's causing the error!

### 6. ✅ Check Database Functions (in Dashboard)

**Location**: Supabase Dashboard → Database → Functions

**Check**: Functions named:
- `handle_new_user()`
- `check_email_domain()`
- `validate_email_domain()`

**Action**: 
- ✅ **Delete these functions** if they exist
- Or verify they don't throw errors

### 7. ✅ Row Level Security

**Location**: Supabase Dashboard → Database → Tables → users table

**Setting**: Row Level Security (RLS)
- ✅ **Disable RLS** temporarily (toggle it OFF)
- You can re-enable later with proper policies

### 8. ✅ Table Policies

**Location**: Supabase Dashboard → Database → Tables → users → Policies

**Check**: Policies on `users`, `user_profiles`, `tools` tables
- ✅ **Delete all policies** temporarily
- Or make sure they allow `INSERT` for authenticated users

---

## 🚀 Recommended Steps (In Order)

### Step 1: Disable Email Confirmation
1. Go to **Authentication → Settings**
2. Scroll to **Email Auth**
3. **Uncheck** "Enable email confirmations"
4. Click **Save**

### Step 2: Delete the Trigger
1. Go to **Database → Triggers**
2. Find `on_auth_user_created` trigger
3. Click the **trash icon** to delete it
4. Confirm deletion

### Step 3: Disable RLS
1. Go to **Database → Tables**
2. Click on `users` table
3. Find "Row Level Security" toggle
4. **Turn it OFF**
5. Repeat for `user_profiles` and `tools` tables

### Step 4: Run ULTIMATE_FIX.sql
1. Go to **SQL Editor**
2. Copy and paste `ULTIMATE_FIX.sql`
3. Click **Run**
4. Check for success messages

### Step 5: Test Authentication
1. **Restart your Flutter app**
2. Try **signing up** with a new email
3. Try **logging in** with existing account
4. Check if it works!

---

## 🔍 If Still Failing

### Check Supabase Logs:
1. Go to **Logs → Database**
2. Look for errors around the time you tried to signup
3. Copy the error message
4. Share it with me

### Common Issues in Logs:

**"permission denied for table users"**
→ Run `ULTIMATE_FIX.sql` again (grants permissions)

**"relation users does not exist"**
→ The table is missing, run `ULTIMATE_FIX.sql` to create it

**"duplicate key value violates unique constraint"**
→ User already exists, try logging in instead of signing up

**"function handle_new_user() does not exist"**
→ Good! The trigger is deleted. But check for other triggers.

---

## 💡 Pro Tip

The **easiest way** to fix this:
1. Delete the `on_auth_user_created` trigger in Dashboard
2. Disable email confirmation
3. Disable RLS on users table
4. Test immediately

Then run SQL scripts to clean up and grant permissions.

---

## ⚠️ Security Note

These settings make authentication **permissive** for development. For production:
- Re-enable email confirmation if needed
- Re-enable RLS with proper policies
- Add proper domain restrictions
- Add back triggers with better error handling

For now, **just get it working!** 🚀






