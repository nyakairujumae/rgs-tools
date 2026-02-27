# Fix JWT Expiration Issue in Supabase

## 🔍 **Root Cause Analysis:**

The JWT tokens are expiring quickly because:

1. **Supabase default JWT expiry** is set to 1 hour
2. **No proper token refresh** mechanism in development
3. **Session persistence** issues during app restarts
4. **Development environment** configuration problems

## 🛠️ **Solutions to Implement:**

### **1. Supabase Dashboard Configuration:**

Go to your Supabase Dashboard → Authentication → Settings:

#### **JWT Settings:**
- **JWT expiry limit**: Set to `24 hours` (instead of 1 hour)
- **Refresh token expiry**: Set to `30 days`
- **Enable refresh tokens**: ✅ Yes

#### **Session Settings:**
- **Session timeout**: Set to `24 hours`
- **Enable session persistence**: ✅ Yes
- **Auto-refresh sessions**: ✅ Yes

### **2. Environment Variables (if using custom config):**

Add these to your Supabase project settings:

```env
JWT_EXPIRY=86400  # 24 hours in seconds
REFRESH_TOKEN_EXPIRY=2592000  # 30 days in seconds
```

### **3. Code-Level Fixes:**

The authentication provider now includes:
- ✅ **Automatic session refresh** when tokens expire
- ✅ **Retry mechanism** for failed role loading
- ✅ **Better error handling** for JWT issues
- ✅ **Session persistence** across app restarts

## 🚀 **Immediate Actions:**

### **Step 1: Update Supabase Settings**
1. Go to Supabase Dashboard
2. Navigate to Authentication → Settings
3. Update JWT expiry to 24 hours
4. Enable refresh tokens
5. Save changes

### **Step 2: Test the Fix**
1. Hot restart your app
2. Login as any user
3. Check console for JWT errors
4. Verify role loading works

### **Step 3: Monitor for Issues**
- Watch console logs for authentication errors
- Test with different users (admin/technician)
- Verify session persistence across app restarts

## 📱 **Expected Results:**

After implementing these fixes:
- ✅ **No more JWT expired errors**
- ✅ **Sessions last 24 hours** (not 1 hour)
- ✅ **Automatic token refresh** when needed
- ✅ **Proper role loading** for all users
- ✅ **Better user experience** with persistent sessions

## 🔧 **Technical Details:**

### **Why JWT tokens expire quickly:**
1. **Development environment** has shorter token lifetimes
2. **Supabase defaults** are conservative for security
3. **No refresh mechanism** in the original code
4. **Session management** wasn't properly configured

### **How the fix works:**
1. **Extended JWT lifetime** to 24 hours
2. **Automatic refresh** when tokens expire
3. **Retry logic** for failed authentication
4. **Better error handling** and recovery

This should resolve the JWT expiration issues for your entire HVAC tools management system!
