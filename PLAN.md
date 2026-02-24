# RGS Tools - Enterprise Web Dashboard (React + Next.js)

## Overview
Standalone React web app at `/Users/jumae/Desktop/rgs-web/` connecting to the **same Supabase backend** as the Flutter mobile app. Built with Next.js 15 (App Router) + shadcn/ui + Tailwind CSS.

---

## Phase 1: Foundation (Auth + Layout + Dashboard)
**Goal:** Login, sidebar navigation, and a working dashboard with real data.

### 1.1 Project Setup
- `npx create-next-app@latest rgs-web` (TypeScript, Tailwind, App Router)
- Install: `@supabase/supabase-js`, `@supabase/ssr`, shadcn/ui init
- Configure Supabase client (same URL + anon key as Flutter app)
- Environment variables in `.env.local`

### 1.2 Auth
- `/login` page - email/password sign-in via Supabase Auth
- Middleware to protect all `/dashboard/*` routes
- Role check: only `admin` role can access web dashboard
- Session persistence via Supabase SSR helpers

### 1.3 Layout
- Collapsible sidebar with navigation:
  - Dashboard, Tools, Technicians, Issues, Approvals, Maintenance, Compliance, Reports, History, Settings
- Top bar: notifications bell (badge count), user avatar + dropdown (profile, logout)
- Dark/light mode toggle
- Breadcrumbs

### 1.4 Dashboard Page
- KPI cards (from real Supabase data):
  - Total Tools / Available / In Use / Maintenance
  - Open Issues (with critical count)
  - Pending Approvals
  - Overdue Maintenance
  - Expiring Certifications
- Recent Activity feed (from tool_history table)
- Needs Attention panel (overdue items, critical issues)
- Quick Actions: Add Tool, Assign Tool, View Reports

---

## Phase 2: Tools Management (Core Feature)
**Goal:** Full equipment CRUD with professional data tables.

### 2.1 Tools List Page (`/dashboard/tools`)
- Data table with columns: Name, Category, Brand, Serial #, Status, Condition, Assigned To, Value, Actions
- Sortable columns (click header)
- Filters: status dropdown, category dropdown, condition dropdown, search bar
- Bulk actions: select rows → Assign, Export, Delete
- Pagination (25/50/100 per page)
- Row click → tool detail page

### 2.2 Tool Detail Page (`/dashboard/tools/[id]`)
- Tool info card (image, all fields)
- Assignment history tab
- Maintenance history tab
- Issue history tab
- Certifications tab
- Full audit trail tab (from tool_history)
- Actions: Edit, Assign, Schedule Maintenance, Report Issue, Delete

### 2.3 Add/Edit Tool
- Sheet/dialog form (not a separate page)
- All fields from tools table
- Image upload to Supabase Storage
- Template quick-fill (from tool_templates table)
- Records tool_history on save

---

## Phase 3: Technicians + Issues
**Goal:** Staff management and issue tracking.

### 3.1 Technicians List (`/dashboard/technicians`)
- Data table: Name, Employee ID, Department, Phone, Status, Tools Assigned, Actions
- Click → detail page with assigned tools list
- Add/edit technician dialogs

### 3.2 Pending Approvals (`/dashboard/approvals/users`)
- List of pending user registrations
- Approve/reject with one click
- Rejection reason dialog

### 3.3 Issues (`/dashboard/issues`)
- Data table: Tool Name, Issue Type, Priority, Status, Reported By, Date, Cost
- Filter by: status, priority, issue type
- Click → issue detail with resolution form
- Status workflow: Open → In Progress → Resolved → Closed

---

## Phase 4: Approvals + Maintenance + Compliance
**Goal:** Workflow management screens.

### 4.1 Approval Workflows (`/dashboard/approvals`)
- Tabs: Pending, Approved, Rejected
- Each card shows: request type, requester, priority, due date
- Approve/reject actions with comments
- Calls existing RPC functions (approve_workflow, reject_workflow)

### 4.2 Maintenance (`/dashboard/maintenance`)
- Calendar/list view of scheduled maintenance
- Status badges: Scheduled, In Progress, Overdue, Completed
- Create new schedule dialog
- Cost tracking (estimated vs actual)

### 4.3 Compliance (`/dashboard/compliance`)
- Certification expiry dashboard
- Color-coded: Valid (green), Expiring Soon (yellow), Expired (red)
- Filter by certification type, issuing authority
- Add/renew certification dialog

---

## Phase 5: Reports + History + Notifications
**Goal:** Analytics, audit trail, and real-time updates.

### 5.1 Reports (`/dashboard/reports`)
- Report types: Inventory, Assignments, Issues, Financial, Comprehensive
- Date range picker
- Generate PDF/Excel (client-side using jsPDF + xlsx)
- AED currency formatting throughout

### 5.2 Audit Trail (`/dashboard/history`)
- Full tool_history table with filters
- Filter by: tool, action type, date range, performed by
- Timeline view

### 5.3 Notifications
- Real-time via Supabase subscriptions on admin_notifications table
- Bell icon with unread count
- Dropdown panel with notification list
- Mark as read

---

## Phase 6: Polish
- Shared tools management + request threads
- Locations management
- Admin positions & permissions (RBAC)
- Bulk import (CSV upload)
- Settings page
- Loading states, error boundaries, empty states
- Responsive tweaks (tablet support)

---

## File Structure
```
rgs-web/
├── .env.local                    # Supabase URL + anon key
├── src/
│   ├── app/
│   │   ├── layout.tsx            # Root layout (providers, fonts)
│   │   ├── page.tsx              # Redirect to /login or /dashboard
│   │   ├── login/
│   │   │   └── page.tsx          # Login page
│   │   └── dashboard/
│   │       ├── layout.tsx        # Sidebar + topbar layout
│   │       ├── page.tsx          # Dashboard (KPIs, activity)
│   │       ├── tools/
│   │       │   ├── page.tsx      # Tools data table
│   │       │   └── [id]/
│   │       │       └── page.tsx  # Tool detail
│   │       ├── technicians/
│   │       │   ├── page.tsx      # Technicians list
│   │       │   └── [id]/
│   │       │       └── page.tsx  # Technician detail
│   │       ├── issues/
│   │       │   └── page.tsx      # Issues management
│   │       ├── approvals/
│   │       │   ├── page.tsx      # Approval workflows
│   │       │   └── users/
│   │       │       └── page.tsx  # Pending user approvals
│   │       ├── maintenance/
│   │       │   └── page.tsx      # Maintenance schedules
│   │       ├── compliance/
│   │       │   └── page.tsx      # Certifications
│   │       ├── reports/
│   │       │   └── page.tsx      # Report generation
│   │       ├── history/
│   │       │   └── page.tsx      # Audit trail
│   │       └── settings/
│   │           └── page.tsx      # App settings
│   ├── lib/
│   │   ├── supabase/
│   │   │   ├── client.ts         # Browser Supabase client
│   │   │   ├── server.ts         # Server Supabase client
│   │   │   └── middleware.ts     # Auth middleware helper
│   │   ├── types/
│   │   │   └── database.ts       # TypeScript types matching Supabase tables
│   │   └── utils.ts              # Helpers (cn, formatAED, formatDate)
│   ├── components/
│   │   ├── ui/                   # shadcn/ui components (auto-generated)
│   │   ├── layout/
│   │   │   ├── sidebar.tsx       # Collapsible sidebar nav
│   │   │   ├── topbar.tsx        # Top bar with notifications + user menu
│   │   │   └── breadcrumbs.tsx
│   │   ├── dashboard/
│   │   │   ├── kpi-cards.tsx
│   │   │   ├── recent-activity.tsx
│   │   │   └── needs-attention.tsx
│   │   ├── tools/
│   │   │   ├── tools-table.tsx
│   │   │   ├── tool-form.tsx
│   │   │   └── tool-filters.tsx
│   │   ├── technicians/
│   │   │   ├── technicians-table.tsx
│   │   │   └── technician-form.tsx
│   │   └── shared/
│   │       ├── data-table.tsx     # Reusable data table component
│   │       ├── status-badge.tsx
│   │       ├── priority-badge.tsx
│   │       └── empty-state.tsx
│   └── hooks/
│       ├── use-tools.ts          # Fetch/mutate tools
│       ├── use-technicians.ts
│       ├── use-issues.ts
│       ├── use-approvals.ts
│       ├── use-notifications.ts  # Real-time notifications
│       └── use-auth.ts           # Auth state + role checks
└── middleware.ts                  # Next.js middleware (auth redirect)
```

---

## Implementation Order
1. **Phase 1** → You can see: login, sidebar, dashboard with live KPIs
2. **Phase 2** → Core value: tools CRUD with professional data tables
3. **Phase 3** → Team management: technicians + issue tracking
4. **Phase 4** → Operations: approvals, maintenance, compliance
5. **Phase 5** → Intelligence: reports, audit trail, real-time notifications
6. **Phase 6** → Polish: shared tools, RBAC, bulk import, settings

Each phase is independently testable and deployable.
