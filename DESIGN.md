# Faith Hours - Feature Mapping & Technical Design

## 1. Project Overview
Faith Hours is a cross-platform mobile application (built with Flutter) designed for internal office management. It facilitates employee reporting, visitor tracking, and resource management using an in-house server backend.

## 2. Core Features

### 2.1 Daily Work Reporting (Primary)
Employees must submit their daily work progress.
- **Submission Form Fields:**
  - `Employee Code` (Pre-filled/Auto-detected)
  - `Date` (Default to current)
  - `Department` (Select from list)
  - `Daily Working Report 1` (Task details)
  - `Daily Working Report 2` (Task details)
  - `Daily Working Report 3` (Task details)
  - `Start Time` & `End Time`
  - `Team Leader` (Searchable dropdown)
  - `Project Number` (Searchable list)
- **Workflow & Approvals:**
  - **Submission:** On submit, the report is saved with a `Pending` status.
  - **Notification:** The selected Team Leader receives a real-time notification to review the submission.
  - **Review:** TL can `Approve` or `Reject` (with comments).
  - **Persistence:** Only `Approved` reports are finalized in the primary reporting records.
- **View History:** List of previous submissions and their current status (Pending/Approved/Rejected).
- **TL Dashboard:** Review interface for Team Leaders to monitor team progress and action pending approvals.

## 3. User Roles & Permissions
- **Employee:** Basic access to reporting, visitor invites, and room booking.
- **Team Leader:** Access to team reports and department-level visitor logs.
- **Admin / IT:** Full control over user management, project lists, and system settings.

## 4. Technical Architecture (Serverless)
- **Frontend:** Flutter (Dart) for Android and iOS.
- **Backend-as-a-Service (BaaS):** Supabase.
  - **Database:** PostgreSQL (Reports, Users, Notifications).
  - **Real-time:** Supabase Realtime for instant in-app alerts.
  - **Automation:** 
    - **Database Triggers:** Automatic notification generation on report submission/review.
    - **Edge Functions:** Scheduled "Cron" functions for daily compliance checks and email reminders.
- **Network:** Global access via Supabase cloud (no local server required).

## 5. Implementation Roadmap
1. **Phase 1: Foundation (Current)** - Feature mapping and design approval.
2. **Phase 2: Backend Development** - Setup in-house server, database schema, and Auth APIs.
3. **Phase 3: Core Reporting Feature** - Develop the Flutter form and reporting dashboard.
5. **Phase 5: Internal Testing & Deployment** - Beta testing within the office.
