# How to Delete Users from auth.users

## 🔒 Why You Can't Delete from auth.users Directly

The `auth.users` table in Supabase is **protected** and has special security restrictions:

1. **RLS (Row Level Security)**: The `auth` schema has strict security policies
2. **Admin-only access**: Only service_role or admin users can delete from `auth.users`
3. **Cascade restrictions**: Foreign keys might prevent deletion if not handled properly

## ✅ Solutions

### Option 1: Use Supabase Dashboard (Easiest)

1. Go to **Supabase Dashboard** → **Authentication** → **Users**
2. Find the user you want to delete
3. Click the **three dots (⋮)** next to the user
4. Click **Delete user**
5. Confirm deletion

**This is the recommended method** - it handles all cascades and permissions correctly.

### Option 2: Use SQL with Service Role (Advanced)

If you need to delete programmatically, you must use the **service_role** key (not the anon key):

```sql
-- This requires service_role permissions
-- Run in Supabase SQL Editor (which uses service_role)
DELETE FROM auth.users WHERE email = 'user@example.com';
```

**Note**: The SQL Editor in Supabase Dashboard uses service_role, so this should work there.

### Option 3: Use the Delete Function We Created

We created `delete_user_completely()` function that handles everything:

```sql
-- This function deletes from both public.users AND auth.users
SELECT public.delete_user_completely('user@example.com');
```

**File**: `FIX_EMAIL_REUSE_ISSUE.sql`

This function:
1. Handles all foreign key constraints
2. Deletes from `public.users`
3. Deletes from `auth.users`
4. Cleans up related data

## ⚠️ Common Errors

### Error: "permission denied for table auth.users"
**Cause**: You're using the `anon` or `authenticated` role, not `service_role`

**Solution**: 
- Use Supabase Dashboard (uses service_role automatically)
- Or use SQL Editor in Dashboard (also uses service_role)

### Error: "violates foreign key constraint"
**Cause**: User is referenced by other tables

**Solution**: Use `delete_user_completely()` function which handles all foreign keys

### Error: "cannot delete user"
**Cause**: User might be the last admin or has special permissions

**Solution**: Check if user has special roles or is the only admin

## 🔧 Using the Delete Function

The `delete_user_completely()` function we created handles everything:

```sql
-- Delete a user completely
SELECT public.delete_user_completely('user@example.com');

-- Returns:
-- true = Success
-- false = User not found or error occurred
```

**What it does**:
1. ✅ Sets `reviewed_by` to NULL in `pending_user_approvals`
2. ✅ Deletes pending approvals where user is requester
3. ✅ Handles all foreign key references
4. ✅ Deletes from `public.users`
5. ✅ Deletes from `auth.users` (the critical part for email reuse)

## 📋 Step-by-Step: Delete User via Dashboard

1. **Open Supabase Dashboard**
2. **Navigate to**: Authentication → Users
3. **Find the user** by email or ID
4. **Click the three dots (⋮)** menu
5. **Click "Delete user"**
6. **Confirm deletion**

This is the **safest and easiest** method.

## 🎯 Quick Fix for Email Reuse

If you're trying to delete a user to reuse their email:

1. **Use Dashboard method** (easiest)
2. **Or use the function**:
   ```sql
   SELECT public.delete_user_completely('user@example.com');
   ```

Both methods will:
- ✅ Delete from `auth.users` (allows email reuse)
- ✅ Delete from `public.users`
- ✅ Clean up all related data

## ⚠️ Important Notes

1. **Deletion is permanent** - User will need to register again
2. **Cascade deletes** - Related data in `public.users` will be deleted automatically
3. **Email reuse** - After deletion, the email can be used again for registration
4. **Backup first** - If you need the data, export it before deleting
