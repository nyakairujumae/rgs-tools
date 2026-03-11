# Multi-Tenant Migration Guide

## Goal

- **Original product**: Stays unchanged, continues using the existing Supabase project (`npgwikkvtxebzwtpzwgx.supabase.co`)
- **This project (ToolsApp)**: Becomes multi-tenant by using a **new** Supabase project with the V2 schema

---

## Current Architecture

| Component | Purpose | Shared? |
|-----------|---------|---------|
| **Supabase** (cloud) | Auth, storage, Postgres tables | Likely shared with original product |
| **Local SQLite** (`hvac_tools.db`) | Offline cache for mobile sync | Per-device, not shared |
| **Config** | `.env` or `--dart-define` | Per-project |

---

## Safe Disconnection Strategy

**Do NOT run the V2 multi-tenant scripts on the existing Supabase project.**  
The V2 scripts (`V2_002_SCHEMA_WITH_TENANCY.sql`) **DROP** existing tables. That would break the original product.

### Recommended Approach: New Supabase Project

1. **Create a new Supabase project** (e.g. `rgs-tools-multitenant` or `toolsapp-mt`)
2. **Run the V2 scripts on the new project only** (in order: V2_001 → V2_002 → V2_003)
3. **Point this ToolsApp to the new project** via `.env` or build args
4. **Leave the original product** pointing at the old Supabase URL

Result:
- Original product → unchanged, same Supabase
- This project → new Supabase, multi-tenant schema

---

## Step-by-Step Migration

### Step 1: Create New Supabase Project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Create a new project (e.g. `rgs-tools-multitenant`)
3. Note the new **Project URL** and **anon key**

### Step 2: Run Multi-Tenant Schema on New Project

In the new project’s SQL Editor, run in order:

1. `sql scripts/V2_001_MULTI_TENANT_FOUNDATION.sql` – organizations table, helpers
2. `sql scripts/V2_002_SCHEMA_WITH_TENANCY.sql` – users, technicians, tools, assignments
3. `sql scripts/V2_003_TENANT_TABLES.sql` – approval workflows, notifications, etc.

### Step 3: Point This App to the New Supabase

**Option A: Local development (`.env`)**

Create or update `.env` in the project root:

```env
SUPABASE_URL=https://YOUR_NEW_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=your_new_anon_key_here
```

**Option B: CI / production (Codemagic, etc.)**

Set environment variables:

- `SUPABASE_URL` = new project URL  
- `SUPABASE_ANON_KEY` = new anon key  

And pass them at build time:

```bash
--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Step 4: Remove Hardcoded Defaults (Optional but Recommended)

In `lib/config/supabase_config.dart`, the fallback is the **original** Supabase URL. To avoid accidentally using the old project:

- Either remove the hardcoded defaults and require `.env` / `--dart-define`
- Or change the defaults to the new project URL (only if this app will never use the old project)

### Step 5: Local SQLite (Offline Cache)

- **No change needed.**  
- `hvac_tools.db` is a local offline cache that syncs with whatever Supabase URL the app uses.
- After switching to the new project, the cache will sync with the new backend.
- Consider bumping the DB version in `database_helper.dart` and adding `organization_id` to local tables if you want tenant-aware offline sync (optional, for later).

---

## App Code Changes for Multi-Tenancy

The V2 schema expects `organization_id` on users and all tenant tables. The app already has some `organization_id` handling in `main.dart` and `login_screen.dart`. You’ll need to ensure:

### 1. User Signup / Invite Flow

- Pass `organization_id` in `raw_user_meta_data` when creating users (invite links, registration).
- The `handle_new_user` trigger in V2_002 reads `organization_id` from metadata.

### 2. Data Operations

- All inserts into `tools`, `technicians`, `assignments`, etc. must include `organization_id`.
- RLS policies use `current_organization_id()` (from `users.organization_id`), so the user must have `organization_id` set.

### 3. Organization Selection

- If users can belong to multiple orgs, add an org switcher and store the active org (e.g. in `AuthProvider` or a `TenantProvider`).
- If users belong to a single org, ensure `organization_id` is set on the user profile and used consistently.

### 4. Bootstrap First Organization

- Create the first organization (e.g. via Supabase dashboard or a migration):

```sql
INSERT INTO organizations (name, slug)
VALUES ('Default Organization', 'default')
ON CONFLICT (slug) DO NOTHING;
```

- Assign new users to this org via invite metadata or a post-signup flow.

---

## Summary

| Action | Where | Effect |
|--------|-------|--------|
| Create new Supabase project | Supabase Dashboard | New backend for multi-tenant app |
| Run V2_001, V2_002, V2_003 | New project SQL Editor | Multi-tenant schema |
| Set `SUPABASE_URL` + `SUPABASE_ANON_KEY` | `.env` or CI | This app uses new project |
| Leave original product config | Original project | Original product unchanged |
| Update app code | This repo | Pass `organization_id`, org selection, etc. |

---

## Checklist

- [ ] Create new Supabase project
- [ ] Run V2_001, V2_002, V2_003 on new project
- [ ] Create first organization (e.g. `default`)
- [ ] Update `.env` or CI with new Supabase URL and anon key
- [ ] (Optional) Remove or change hardcoded defaults in `supabase_config.dart`
- [ ] Update signup/invite flows to pass `organization_id`
- [ ] Ensure all data providers pass `organization_id` on inserts
- [ ] Test auth, tools, technicians, and offline sync
- [ ] Verify original product still works with old Supabase
