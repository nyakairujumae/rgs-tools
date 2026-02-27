# OAuth User Role Handling

## Problem

When users sign in with Apple or Google OAuth for the first time, they don't have a role in the database. The current code signs them out with an error message.

## Solution Options

### Option 1: Redirect to Role Selection (Recommended)
- OAuth users without a role are redirected to role selection screen
- They choose admin or technician
- Account is created with selected role

### Option 2: Default Role Assignment
- OAuth users get a default role (e.g., technician)
- They go through normal approval flow if technician

### Option 3: Database Trigger
- Create a trigger that assigns a default role when OAuth user is created
- Requires database migration

## Recommended Implementation

We'll implement **Option 1** - redirect OAuth users to role selection if they don't have a role.

### Code Changes Needed

1. **Update `_loadUserRole()` in AuthProvider**:
   - Check if user is from OAuth (has `provider` in metadata)
   - If OAuth user and no role, don't sign them out
   - Return a flag indicating "needs role selection"

2. **Update deep link handler in main.dart**:
   - Detect OAuth callback
   - Check if user needs role selection
   - Redirect to role selection screen if needed

3. **Create OAuth role selection flow**:
   - Similar to registration but for existing OAuth users
   - Assign role and create user record
