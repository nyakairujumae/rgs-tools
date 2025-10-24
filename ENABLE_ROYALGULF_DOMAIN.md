# Enable royalgulf.ae Domain for RGS HVAC Tools Management

This guide explains how to enable `royalgulf.ae` as an allowed domain for your RGS HVAC Tools Management app.

## ✅ App Configuration (Already Done)

The app configuration has been updated to include `royalgulf.ae` in the allowed email domains:

```dart
// lib/config/app_config.dart
static List<String> get allowedEmailDomains => [
  'mekar.ae',
  'royalgulf.ae',  // ✅ Added
  'gmail.com',
  'outlook.com',
  'yahoo.com',
  'hotmail.com',
];
```

## 🔧 Supabase Dashboard Configuration Required

To fully enable `royalgulf.ae` domain, you need to update your Supabase project settings:

### 1. Authentication Settings

1. **Go to Supabase Dashboard**
   - Navigate to your project: https://supabase.com/dashboard/project/npgwikkvtxebzwtpzwgx
   - Go to **Authentication** → **Settings**

2. **Update Site URL**
   - Find "Site URL" setting
   - Add: `https://royalgulf.ae`
   - Keep existing URLs if any

3. **Update Redirect URLs**
   - Find "Redirect URLs" setting
   - Add the following URLs:
     ```
     https://royalgulf.ae/**
     https://royalgulf.ae/auth/callback
     https://royalgulf.ae/dashboard
     https://royalgulf.ae/login
     https://royalgulf.ae/register
     ```

### 2. Email Domain Configuration (Optional)

If you want to restrict signups to specific domains:

1. **Go to Authentication** → **Settings**
2. **Find "Email Domains" setting**
3. **Add allowed domains:**
   ```
   mekar.ae
   royalgulf.ae
   ```

### 3. CORS Configuration (If using web version)

1. **Go to Settings** → **API**
2. **Update CORS origins:**
   ```
   https://royalgulf.ae
   https://www.royalgulf.ae
   ```

## 🚀 What This Enables

After configuration, users with `@royalgulf.ae` email addresses can:

- ✅ **Sign up** for new accounts
- ✅ **Sign in** to existing accounts  
- ✅ **Access the app** from royalgulf.ae domain
- ✅ **Receive authentication emails** (if email confirmation is enabled)
- ✅ **Use all app features** with royalgulf.ae email

## 🔍 Testing the Configuration

1. **Test Email Domain Validation:**
   ```dart
   // This should return true
   AppConfig.isEmailDomainAllowed('user@royalgulf.ae')
   ```

2. **Test User Registration:**
   - Try signing up with a `@royalgulf.ae` email
   - Should work without domain restrictions

3. **Test Authentication Flow:**
   - Sign in with royalgulf.ae email
   - Should authenticate successfully

## 📱 App Features Available

With royalgulf.ae domain enabled:

- **User Registration**: Users can sign up with @royalgulf.ae emails
- **Authentication**: Seamless login with royalgulf.ae accounts
- **Role Management**: Admin can assign roles to royalgulf.ae users
- **Tool Management**: Full access to HVAC tools management features
- **Issue Reporting**: Can report tool issues and track them
- **Profile Management**: Can update profiles and settings

## 🔒 Security Considerations

- **Domain Validation**: Only @royalgulf.ae emails are allowed for registration
- **Role-based Access**: Users get appropriate permissions based on their role
- **Session Management**: Secure authentication with JWT tokens
- **Data Protection**: All data is encrypted and secure

## 🆘 Troubleshooting

If royalgulf.ae domain doesn't work:

1. **Check Supabase Settings:**
   - Verify Site URL includes royalgulf.ae
   - Check Redirect URLs are properly configured
   - Ensure CORS origins include the domain

2. **Check App Configuration:**
   - Verify `royalgulf.ae` is in `allowedEmailDomains`
   - Test with `AppConfig.isEmailDomainAllowed('test@royalgulf.ae')`

3. **Check Network:**
   - Ensure royalgulf.ae domain is accessible
   - Verify SSL certificate is valid
   - Check DNS resolution

## 📞 Support

If you need help with the configuration:
- Check Supabase documentation: https://supabase.com/docs
- Review app logs for authentication errors
- Test with a simple @royalgulf.ae email first

---

**Status**: ✅ App configuration updated, ⏳ Supabase dashboard configuration required
