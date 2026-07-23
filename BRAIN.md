# BRAIN.md — Faith Hours System Documentation

> **Single source of truth** for any AI agent or developer working on this project.
> Last updated: 2026-06-29 (Updated after Security & Architecture Audit)

---

## 1. Project Identity

| Field | Value |
|---|---|
| **Name** | Faith Hours |
| **Purpose** | Internal office daily work reporting, approval, and compliance tracking |
| **Package name** | `faith_hours` |
| **Version** | 1.0.0+1 |
| **Platforms** | Android, iOS, Web |
| **Frontend** | Flutter (Dart ≥3.4.3 <4.0.0) |
| **Backend** | Self-hosted Supabase (PostgreSQL + GoTrue Auth + Realtime + PostgREST) |
| **Host** | VPS at `185.182.8.157`, domain `faithhours.duckdns.org` (HTTPS) |
| **Dev credit** | "Developed by ARG" (shown on login screen) |

---

## 2. High-Level Architecture

```
┌─────────────────────┐      HTTPS (Kong :8443)      ┌──────────────────────────┐
│   Flutter Mobile App │ ◄──────────────────────────► │  Self-Hosted Supabase    │
│   (Android/iOS/Web)  │                              │  (Docker Compose)        │
│                      │   supabase_flutter SDK        │                          │
│  ┌────────────────┐  │   ───────────────────►       │  ┌────────────────────┐  │
│  │ Report Service  │──┼── PostgREST (CRUD) ────────►│  │ PostgreSQL 17      │  │
│  │ Notification    │──┼── Realtime (WebSocket) ◄───►│  │ (reports, users,   │  │
│  │   Provider      │  │                              │  │  notifications,    │  │
│  │ Export Service  │  │                              │  │  projects)         │  │
│  └────────────────┘  │                              │  └────────────────────┘  │
└─────────────────────┘                              │  ┌────────────────────┐  │
                                                      │  │ GoTrue Auth (v2)   │  │
┌─────────────────────┐                              │  │ Email+Password     │  │
│  Node.js Server      │   Supabase JS SDK            │  └────────────────────┘  │
│  (Legacy/Utility)    │ ──────────────────────►      │  ┌────────────────────┐  │
│  - Cron compliance   │                              │  │ Edge Functions     │  │
│  - Email via Gmail   │                              │  │ (process-notifs)   │  │
│  - CSV import tools  │                              │  └────────────────────┘  │
└─────────────────────┘                              └──────────────────────────┘
```

### Key Insight
The Flutter app communicates **directly** with Supabase via the `supabase_flutter` SDK — it does NOT go through the Node.js server. The Node.js server exists as a **utility layer** for cron jobs and CSV imports.

---

## 3. Infrastructure — Docker Compose Services

All services run via `docker-compose.yml` under the `supabase` project name on the VPS:

| Service | Container | Image | Port | Purpose |
|---|---|---|---|---|
| **db** | supabase-db | `supabase/postgres:17.6.1.136` | 5432 (internal) | PostgreSQL database |
| **kong** | supabase-kong | `kong/kong:3.9.1` | 8000 (HTTP), 8443 (HTTPS) | API Gateway |
| **auth** | supabase-auth | `supabase/gotrue:v2.189.0` | 9999 (internal) | Authentication |
| **rest** | supabase-rest | `postgrest/postgrest:v14.12` | 3000 (internal) | REST API over Postgres |
| **realtime** | realtime-dev.supabase-realtime | `supabase/realtime:v2.102.3` | 4000 (internal) | WebSocket subscriptions |
| **storage** | supabase-storage | `supabase/storage-api:v1.60.4` | 5000 (internal) | File storage |
| **studio** | supabase-studio | `supabase/studio:2026.06.03` | 3000 (internal) | Admin dashboard UI |
| **meta** | supabase-meta | `supabase/postgres-meta:v0.96.6` | 8080 (internal) | DB metadata API |
| **functions** | supabase-edge-functions | `supabase/edge-runtime:v1.74.0` | 9000 (internal) | Deno edge functions |
| **imgproxy** | supabase-imgproxy | `darthsim/imgproxy:v3.30.1` | 5001 (internal) | Image transformation |
| **supavisor** | supabase-pooler | `supabase/supavisor:2.9.5` | 5432, 6543 | Connection pooling |

### Auth Configuration
- **Email+Password** auth enabled via GoTrue
- SMTP configured for email delivery (Gmail)
- `GOTRUE_MAILER_AUTOCONFIRM` controls whether email confirmation is needed
- Auth templates mounted at `./templates`
- JWT tokens: HS256 symmetric signing

---

## 4. Database Schema & Policies

**Row Level Security (RLS) is ENABLED** on all tables with strict role-based access policies (see `rls_policies.sql`).

### 4.1 `users` table
```sql
id             BIGINT PK (auto-increment)
name           TEXT NOT NULL
email          TEXT UNIQUE NOT NULL
employee_code  TEXT UNIQUE NOT NULL    -- Primary business identifier
password       TEXT NOT NULL           -- LEGACY: plaintext, not used for auth
role           TEXT DEFAULT 'Employee' -- 'Employee' | 'Team Leader' | 'Admin'
department     TEXT
team_leader    TEXT                    -- Stores TL's employee_code
is_blocked     BOOLEAN DEFAULT false
contact_no     TEXT
created_at     TIMESTAMPTZ DEFAULT NOW()
```
*Policies: Employees update own row; Admins/TLs can update others; only Admins can delete.*

### 4.2 `reports` table
```sql
id               BIGINT PK (auto-increment)
employee_code    TEXT NOT NULL
date             DATE NOT NULL
department       TEXT NOT NULL
report1          TEXT                   -- Original schema, unused by app
report2          TEXT                   -- Original schema, unused by app
report3          TEXT                   -- Original schema, unused by app
working_details  TEXT                   -- App uses this instead of report1/2/3
emp_name         TEXT
contact_no       TEXT
subtitle         TEXT
hours_calculate  TEXT                   -- Format: "H:MM"
start_time       TEXT NOT NULL
end_time         TEXT NOT NULL
team_leader      TEXT NOT NULL          -- TL's name
team_leader_code TEXT                   -- TL's employee_code
project_number   TEXT NOT NULL
status           TEXT DEFAULT 'Pending' -- 'Pending' | 'Approved' | 'Rejected'
tl_comments      TEXT
submitted_at     TIMESTAMPTZ DEFAULT NOW()
reviewed_at      TIMESTAMPTZ
```
*Policies: Employees CRUD own; TLs update assigned; Admins have full access.*

### 4.3 `projects` table
```sql
id              BIGINT PK (auto-increment)
project_number  TEXT UNIQUE NOT NULL    -- e.g., "FA-241"
description     TEXT
```
*Policies: All authenticated read; Admins write.*

### 4.4 `notifications` table
```sql
id         BIGINT PK (auto-increment)
user_id    TEXT NOT NULL      -- Stores employee_code (NOT auth user ID)
message    TEXT NOT NULL
type       TEXT NOT NULL      -- 'reminder' | 'alert' | 'status_update' | 'submission'
is_read    BOOLEAN DEFAULT FALSE
created_at TIMESTAMPTZ DEFAULT NOW()
```
*Policies: Users read/update own; inserted by `SECURITY DEFINER` system triggers.*

### 4.5 Database Triggers (SECURITY DEFINER)
| Trigger | On | Function | Action |
|---|---|---|---|
| `trigger_notify_tl` | `AFTER INSERT ON reports` | `notify_tl_on_submission()` | Inserts notification for TL |
| `trigger_notify_employee` | `AFTER UPDATE ON reports` | `notify_employee_on_review()` | Inserts notification for employee |

### 4.6 Indexes
```sql
idx_reports_employee_code        ON reports(employee_code)
idx_reports_submitted_at         ON reports(submitted_at DESC)
idx_reports_team_leader_status   ON reports(team_leader, status)
idx_notifications_user_id        ON notifications(user_id)
idx_notifications_created_at     ON notifications(created_at DESC)
idx_notifications_unread         ON notifications(user_id, is_read)
idx_users_role                   ON users(role)
idx_users_team_leader            ON users(team_leader)
```

---

## 5. Flutter App Architecture

### 5.1 Directory Structure
```
mobile_app/lib/
├── main.dart                    # Entry point, auth, routing, theme
├── config/
│   └── app_config.dart          # Environment variables (--dart-define)
├── models/
│   └── report.dart              # Report data class with JSON serialization
├── providers/
│   └── notification_provider.dart # Realtime notifications via ChangeNotifier
├── screens/
│   ├── signup_screen.dart       # Login (employee_code + password)
│   ├── report_form_screen.dart  # Daily work report submission form
│   ├── report_history_screen.dart # Employee's report history list
│   ├── report_detail_screen.dart  # Full report view + TL review actions
│   ├── tl_dashboard_screen.dart   # TL's pending reports queue
│   ├── admin_dashboard_screen.dart # Admin metrics + export + management
│   ├── manage_employees_screen.dart # CRUD for employee records
│   ├── employee_profile_detail_screen.dart # Employee profile + history tabs
│   └── profile_screen.dart      # Self-profile + password change + hours
├── services/
│   ├── report_service.dart      # Supabase CRUD for reports
│   └── export_service.dart      # CSV export (web download / mobile share)
└── widgets/
    ├── design_spells.dart       # StaggeredEntry, AnimatedGlassCard, MagneticButton
    └── skeleton_loader.dart     # Shimmer loading placeholder
```

### 5.2 State Management & Config
- **Provider**: `NotificationProvider` handles realtime subscription and badge state.
- **Config**: `AppConfig` handles `SUPABASE_URL` and `SUPABASE_ANON_KEY` injection.
- **Session**: `FlutterSecureStorage` saves user profile JSON.

### 5.3 Authentication Flow
```
1. User enters Employee ID + Password on SignupScreen
2. App queries `users` table by employee_code → gets email + is_blocked
3. If blocked → reject login
4. Supabase Auth signInWithPassword(email, password)
5. On success → fetch full user profile from `users` table
6. Profile saved to FlutterSecureStorage for session persistence
7. NotificationProvider.initNotifications(employee_code) starts realtime
8. Logout: clear secure storage + Supabase signOut + navigate to AuthWrapper
```

### 5.4 Role-Based Navigation (Resolved dynamically)
| Role | Nav Tabs |
|---|---|
| **Employee** | Report Form → History → Profile |
| **Team Leader** | My Team → History → TL Review → Profile |
| **Admin** | My Team → History → TL Review → Admin Dashboard → Profile |

*Note: The TL assigned to an employee is dynamically resolved from the database during startup to ensure accurate routing.*

---

## 6. Business Logic & Workflows

### 6.1 Report Submission Flow
Employee fills form → `ReportService.submitReport()` → INSERT into `reports` → `notify_tl_on_submission` trigger fires → INSERT `notifications` → Realtime pushes to TL.

### 6.2 Report Review Flow
TL opens TL Review tab → clicks Approve/Reject → `reviewReport()` → UPDATE `reports` → `notify_employee_on_review` trigger fires → Realtime pushes to Employee.

### 6.3 Calendar Logic
Color-codes dates: Green=submitted, Red=missing, Grey=before registration, Blue=Holiday, Yellow=On Leave, Orange=Idle. Weekends and future dates disabled.

### 6.4 Compliance Cron (Node.js)
Runs daily at 7:00 PM: checks all employees for missing reports, sends email reminders, escalates to TL if 2+ consecutive missed days.

### 6.5 Hours Calculation
Client-side: `endHour - startHour` (handles overnight with +24). Profile sums approved hours.

---

## 7. Edge Function: `process-notifications`

Location: `supabase/functions/process-notifications/index.ts`  
Runtime: Deno. Purpose: Send emails via Gmail SMTP (nodemailer).  
Types: `reminder`, `approval`, `alert`.

> **Security**: SMTP credentials are securely loaded via `Deno.env.get()`.

---

## 8. Node.js Server (Utility)

| File | Status | Purpose |
|---|---|---|
| `src/index.js` | Active | Express + Socket.IO + cron init |
| `src/config/database.js` | Active | Supabase client |
| `src/routes/reports.js` | Unused | REST API (app uses Supabase directly) |
| `src/services/notificationService.js` | Active | Cron compliance |
| `import_csv.js` | Utility | Bulk import reports |
| `import_users.js` | Utility | Extract users from CSV |

---

## 9. Security Assessment (Post-Audit)

| Area | Status | Detail |
|---|---|---|
| Auth | ✅ Good | Supabase GoTrue with JWT |
| RLS | ✅ Good | Strict role-based policies on all 4 tables |
| Password Change | ✅ Good | Uses `Supabase.auth.updateUser()` correctly |
| API Keys | ✅ Good | Passed securely via `--dart-define` build args |
| SMTP Creds | ✅ Good | Managed via Deno Edge environment variables |
| HTTPS | ✅ Good | Kong HTTPS on 8443 |
| Session | ✅ Good | Encrypted via FlutterSecureStorage |

---

## 10. Deployment

### Start Supabase
```bash
docker compose up -d
```

### Build Flutter (Production)
```bash
cd mobile_app
flutter pub get
flutter build apk --dart-define=SUPABASE_URL=https://faithhours.duckdns.org --dart-define=SUPABASE_ANON_KEY=your_key_here
```

### Run Node.js Server
```bash
cd server && npm install && node src/index.js
```

### Import Production Data
```bash
cd server
node import_users.js    # Users from CSV
node import_csv.js      # Reports from CSV
```

---

## 11. Maintenance Notes
- **Testing**: Run `flutter test` in `mobile_app` to verify `Report` model parsing.
- **SQL Updates**: Any new features requiring cross-user notifications must use `SECURITY DEFINER` in their database triggers to bypass RLS restrictions.
- **Status Value**: Always use `'Approved'` (not `'Approve'`) for status checks and writes.
