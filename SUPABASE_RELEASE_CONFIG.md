# Supabase Release Configuration Guide

This guide covers all the Supabase settings you need to configure for a production release build.

## 📋 Table of Contents
1. [Authentication Settings](#authentication-settings)
2. [Database & RLS Policies](#database--rls-policies)
3. [Storage Configuration](#storage-configuration)
4. [API Keys & Security](#api-keys--security)
5. [CORS & Redirect URLs](#cors--redirect-urls)
6. [Email Configuration](#email-configuration)
7. [Database Backups](#database-backups)
8. [Performance & Monitoring](#performance--monitoring)
9. [Pre-Release Checklist](#pre-release-checklist)

---

## 1. Authentication Settings

### Location: Authentication → Settings

#### Required Settings:
- ✅ **Enable email confirmations**: 
  - **For Production**: Keep ENABLED for security
  - **For Testing**: Can be DISABLED for faster testing
  - Current app supports both modes

- ✅ **Site URL**: 
  - Set to your production app URL (e.g., `https://yourdomain.com`)
  - For mobile apps, this can be a deep link scheme (e.g., `com.rgs.app://`)

- ✅ **Redirect URLs**:
  Add all your app's redirect URLs:
  ```
  com.rgs.app://
  com.rgs.app://callback
  https://yourdomain.com
  https://yourdomain.com/callback
  ```

- ✅ **JWT Expiry**: 
  - Default: 3600 seconds (1 hour)
  - Adjust based on your security requirements

- ✅ **Enable phone auth**: 
  - Configure if you plan to use phone authentication

---

## 2. Database & RLS Policies

### Location: SQL Editor

#### Verify All Tables Exist:
Run these queries to verify your tables:

```sql
-- Check if all required tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'users',
  'tools',
  'tool_issues',
  'technicians',
  'pending_user_approvals',
  'approval_workflows',
  'admin_notifications',
  'user_fcm_tokens',
  'request_chat'
);
```

#### Verify RLS is Enabled:
```sql
-- Check RLS status for all tables
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
  'users',
  'tools',
  'tool_issues',
  'technicians',
  'pending_user_approvals'
);
```

All tables should have `rowsecurity = true`.

#### Verify RLS Policies:
```sql
-- Check all RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Critical Policies to Verify:**
- ✅ Users table: Users can read/update own data
- ✅ Tools table: Admins can manage all, technicians can view all
- ✅ Tool issues: Admins can manage all, technicians can create/view
- ✅ Technicians table: Proper admin/technician access
- ✅ Pending approvals: Admin-only access

---

## 3. Storage Configuration

### Location: Storage → Buckets

#### Required Bucket: `tool-images`

**Bucket Settings:**
- ✅ **Public bucket**: `true` (for public read access)
- ✅ **File size limit**: Set appropriate limit (e.g., 10MB)
- ✅ **Allowed MIME types**: 
  ```
  image/jpeg
  image/png
  image/webp
  image/jpg
  ```

#### Storage RLS Policies:
Verify these policies exist in **Storage → Policies**:

1. **Public Access for Tool Images** (SELECT)
   ```sql
   bucket_id = 'tool-images'
   ```

2. **Authenticated Upload for Tool Images** (INSERT)
   ```sql
   bucket_id = 'tool-images' AND auth.role() = 'authenticated'
   ```

3. **Authenticated Update for Tool Images** (UPDATE)
   ```sql
   bucket_id = 'tool-images' AND auth.role() = 'authenticated'
   ```

4. **Authenticated Delete for Tool Images** (DELETE)
   ```sql
   bucket_id = 'tool-images' AND auth.role() = 'authenticated'
   ```

#### CORS Configuration:
If using web version, configure CORS in **Storage → Settings**:
- **Allowed origins**: Add your production domain
- **Allowed methods**: GET, POST, PUT, DELETE
- **Allowed headers**: `*` or specific headers

---

## 4. API Keys & Security

### Location: Settings → API

#### Production API Keys:
- ✅ **Project URL**: `https://npgwikkvtxebzwtpzwgx.supabase.co`
- ✅ **Anon/Public Key**: Use in your app (safe to expose)
- ⚠️ **Service Role Key**: **NEVER** expose in client code
  - Only use in server-side code or Edge Functions
  - Has admin privileges

#### Key Rotation:
- Consider rotating keys periodically
- Update keys in your app's `.env` file
- Test thoroughly after rotation

#### Rate Limiting:
- **Location**: Settings → API → Rate Limiting
- Configure appropriate limits for production:
  - API requests per second
  - Storage upload limits
  - Authentication request limits

---

## 5. CORS & Redirect URLs

### Location: Settings → API → CORS

#### CORS Configuration (for Web):
Add your production domains:
```
https://yourdomain.com
https://www.yourdomain.com
```

#### Redirect URLs (Authentication):
**Location**: Authentication → URL Configuration

Add all possible redirect URLs:
```
# Mobile app deep links
com.rgs.app://
com.rgs.app://callback
com.rgs.app://auth/callback

# Web URLs
https://yourdomain.com
https://yourdomain.com/callback
https://yourdomain.com/auth/callback

# Development (if needed)
http://localhost:*
```

---

## 6. Email Configuration

### Location: Authentication → Email Templates

#### Email Templates to Configure:
1. **Confirm signup** - Email verification
2. **Magic Link** - Passwordless login
3. **Change Email Address** - Email change confirmation
4. **Reset Password** - Password reset

#### SMTP Settings (Optional):
**Location**: Settings → Auth → SMTP Settings

For production, configure custom SMTP:
- Use a reliable email service (SendGrid, Mailgun, etc.)
- Update SMTP credentials
- Test email delivery

#### Email Rate Limiting:
- Configure daily email limits
- Set up email quotas to prevent abuse

---

## 7. Database Backups

### Location: Settings → Database → Backups

#### Enable Automated Backups:
- ✅ **Daily backups**: Enable for production
- ✅ **Backup retention**: Set to 7-30 days
- ✅ **Point-in-time recovery**: Enable if available

#### Manual Backup:
Before release, create a manual backup:
1. Go to **Database → Backups**
2. Click **Create Backup**
3. Download and store securely

---

## 8. Performance & Monitoring

### Database Indexes:
Verify indexes exist for performance:

```sql
-- Check indexes on critical tables
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('tools', 'tool_issues', 'users', 'technicians')
ORDER BY tablename, indexname;
```

**Required Indexes:**
- `tools`: category, status, serial_number
- `tool_issues`: tool_id, status, priority, reported_at
- `users`: id (primary key)
- `technicians`: user_id, status

### Connection Pooling:
**Location**: Settings → Database → Connection Pooling

- Enable connection pooling for production
- Configure pool size based on expected load
- Use transaction mode for most apps

### Monitoring:
**Location**: Logs & Monitoring

- Enable query logging (for debugging)
- Set up alerts for:
  - High error rates
  - Slow queries
  - Storage quota warnings
  - API rate limit breaches

---

## 9. Pre-Release Checklist

### ✅ Database
- [ ] All tables created and verified
- [ ] RLS enabled on all tables
- [ ] RLS policies tested and verified
- [ ] Indexes created for performance
- [ ] Database backup created

### ✅ Storage
- [ ] `tool-images` bucket created
- [ ] Storage RLS policies configured
- [ ] CORS configured (if web)
- [ ] File size limits set
- [ ] MIME type restrictions set

### ✅ Authentication
- [ ] Email confirmation settings configured
- [ ] Redirect URLs added
- [ ] Site URL set to production
- [ ] Email templates customized
- [ ] SMTP configured (if custom)

### ✅ Security
- [ ] API keys verified (anon key in app, service role secured)
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] RLS policies reviewed for security

### ✅ Testing
- [ ] Test user registration
- [ ] Test admin login
- [ ] Test technician login
- [ ] Test tool CRUD operations
- [ ] Test image upload/download
- [ ] Test approval workflows
- [ ] Test notifications (if applicable)

### ✅ Environment Variables
- [ ] Production Supabase URL in `.env`
- [ ] Production anon key in `.env`
- [ ] Firebase keys configured (if using)
- [ ] All sensitive keys secured

### ✅ App Configuration
- [ ] **IMPORTANT**: Your `supabase_config.dart` currently has hardcoded values
  - Consider moving to `.env` file for better security
  - Or verify the hardcoded values match your production Supabase instance
- [ ] Verify `.env` file is in `.gitignore`
- [ ] Create `.env.example` with placeholder values
- [ ] Test app with production Supabase instance
- [ ] Verify Firebase configuration (if using push notifications)

---

## 🔒 Security Best Practices

1. **Never commit API keys** to version control
2. **Use environment variables** for all sensitive data
3. **Enable RLS** on all tables
4. **Review RLS policies** regularly
5. **Rotate API keys** periodically
6. **Monitor logs** for suspicious activity
7. **Set up alerts** for security events
8. **Use HTTPS** for all connections
9. **Implement rate limiting** to prevent abuse
10. **Regular backups** and test restore procedures

---

## 📞 Support

If you encounter issues:
1. Check Supabase logs: **Logs → API Logs**
2. Check database logs: **Logs → Database Logs**
3. Review RLS policies: **Authentication → Policies**
4. Test queries in SQL Editor
5. Check Supabase status page: https://status.supabase.com

---

## 🚀 Post-Release Monitoring

After release, monitor:
- API request rates
- Database query performance
- Storage usage
- Authentication success/failure rates
- Error logs
- User registration/login patterns

Set up dashboards and alerts for these metrics.
