# SaaS Company Onboarding Plan

## Overview

When a new user signs up, they are treated as a **new company** (tenant). Before they can use the app, they must complete a **company setup wizard** to set company details.

---

## User Flows

### Flow A: New Company (First User)

```
Sign up (email/password) 
  → Auth user created (no org yet)
  → User lands on Company Setup Wizard
  → Step 1: Company name
  → Step 2: Company logo (optional)
  → Step 3: Address / contact (optional)
  → Create organization in DB
  → Link user to org (update users.organization_id)
  → Seed default admin positions for org
  → Redirect to app (admin home)
```

### Flow B: Invited User (Joins Existing Company)

```
Invite link (email with organization_id in metadata)
  → Sign up
  → handle_new_user creates user with organization_id
  → Skip Company Setup (org already exists)
  → Redirect to app
```

### Flow C: Existing User (Has Org)

```
Login
  → Session has organization_id
  → Redirect to app (admin or technician home)
```

---

## Database Schema Changes

### 1. Extend `organizations` table

```sql
-- Add to organizations table
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS website TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS setup_completed_at TIMESTAMP WITH TIME ZONE;
-- setup_completed_at = NULL means company setup wizard not yet completed
```

### 2. Storage bucket for logos

- Bucket: `organization-logos` (or `tool-images` with path `logos/{org_id}/logo.png`)
- RLS: Users can upload only for their org
- Public read for logo display

---

## App Logic

### 1. Detect "needs company setup"

After login/signup, check:

```dart
bool needsCompanySetup(User user) {
  // User has no organization_id
  final orgId = user.userMetadata?['organization_id'];
  if (orgId != null && orgId.isNotEmpty) return false;
  
  // Or user has org_id but org.setup_completed_at is null
  final org = await fetchOrganization(user.organizationId);
  return org?.setupCompletedAt == null;
}
```

### 2. Routing

```
main.dart / onGenerateRoute:
  if (!authenticated) → Login
  else if (needsCompanySetup) → CompanySetupWizard
  else if (isPendingApproval) → PendingApprovalScreen
  else → AdminHome / TechnicianHome
```

### 3. Company Setup Wizard (screens)

| Step | Screen | Fields |
|------|--------|--------|
| 1 | Company name | Company name, slug (auto from name) |
| 2 | Company logo | Upload image (optional, skip) |
| 3 | Company details | Address, phone, website (optional) |
| 4 | Done | "You're all set" → Continue to app |

### 4. API / Supabase operations

- **Create org**: `INSERT INTO organizations (name, slug, ...) RETURNING id`
- **Update user**: `UPDATE users SET organization_id = ? WHERE id = auth.uid()`
- **Upload logo**: Supabase Storage `organization-logos/{org_id}/logo.png`
- **Update org logo_url**: `UPDATE organizations SET logo_url = ? WHERE id = ?`
- **Mark setup complete**: `UPDATE organizations SET setup_completed_at = NOW() WHERE id = ?`
- **Seed positions**: Call `seed_default_positions_for_org(org_id)` (from V2_003)

---

## handle_new_user Trigger Changes

Current: Expects `organization_id` in metadata. If missing, user gets `organization_id = NULL`.

For SaaS: First-time signups have no org. We have two options:

**Option A (recommended):** Keep trigger as-is. User gets `organization_id = NULL`. App shows Company Setup Wizard. On completion, we `UPDATE users SET organization_id = ?` and create org.

**Option B:** Modify trigger to create org on first signup. More complex.

---

## Implementation Phases

### Phase 1: Schema & Backend

- [ ] Create migration SQL: extend `organizations` table
- [ ] Create `organization-logos` storage bucket (or use existing with RLS)
- [ ] Add RLS policy for org logo upload
- [ ] Create Edge Function or RPC: `create_organization_and_assign_user(name, slug, logo_url?, ...)` that:
  - Inserts org
  - Updates user's organization_id
  - Calls seed_default_positions_for_org
  - Sets setup_completed_at

### Phase 2: Company Setup Wizard UI

- [ ] Create `CompanySetupWizardScreen` (multi-step)
- [ ] Step 1: Company name + slug
- [ ] Step 2: Logo upload (image picker → Supabase Storage)
- [ ] Step 3: Address, phone, website (optional)
- [ ] Step 4: Success → navigate to app

### Phase 3: Auth & Routing

- [ ] Add `needsCompanySetup` check in AuthProvider
- [ ] Update main.dart routing logic
- [ ] After signup: if no org_id, redirect to CompanySetupWizard
- [ ] After company setup: update user metadata, refresh session, navigate to home

### Phase 4: App-Wide Org Branding

- [ ] Create `OrganizationProvider` or extend `AuthProvider` with `currentOrganization`
- [ ] Display org logo in app bar, login screen, etc.
- [ ] Cache org details in local storage for offline

---

## UI Considerations

- **Logo**: Square crop (e.g. 256x256), support PNG, JPG, WebP
- **Slug**: Auto-generate from company name (e.g. "Acme Corp" → "acme-corp"), editable
- **Validation**: Company name required; slug unique; logo max 2MB

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `sql scripts/V2_004_ORGANIZATION_SETUP.sql` | New – extend org table |
| `lib/screens/company_setup_wizard_screen.dart` | New |
| `lib/providers/organization_provider.dart` | New (optional) |
| `lib/main.dart` | Modify – routing |
| `lib/providers/auth_provider.dart` | Modify – needsCompanySetup |
| `supabase/functions/create-organization` | New Edge Function (optional) |

---

## Security Checklist

- [ ] RLS: Users can only update their own org (if they're admin)
- [ ] RLS: Logo upload restricted to org members
- [ ] Slug uniqueness enforced at DB level
- [ ] Rate limit org creation (e.g. 1 per 5 min per IP)
