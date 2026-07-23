-- ============================================================
-- Faith Hours: Row Level Security (RLS) Policies
-- Run this in Supabase Studio SQL Editor
-- ============================================================

-- 1. Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- USERS TABLE POLICIES
-- ============================================================

-- All authenticated users can read users (needed for dropdowns, TL lookups)
CREATE POLICY "users_select_authenticated"
  ON users FOR SELECT
  TO authenticated
  USING (true);

-- Only Admins can insert new users
CREATE POLICY "users_insert_admin"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = (auth.jwt() ->> 'sub')::bigint
      AND u.role = 'Admin'
    )
  );

-- Employees can update their own row; Admins/TLs can update any
CREATE POLICY "users_update_self_or_admin"
  ON users FOR UPDATE
  TO authenticated
  USING (
    employee_code = (
      SELECT u.employee_code FROM users u
      WHERE u.email = auth.jwt() ->> 'email'
    )
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.email = auth.jwt() ->> 'email'
      AND u.role IN ('Admin', 'Team Leader')
    )
  );

-- Only Admins can delete users
CREATE POLICY "users_delete_admin"
  ON users FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.email = auth.jwt() ->> 'email'
      AND u.role = 'Admin'
    )
  );

-- ============================================================
-- REPORTS TABLE POLICIES
-- ============================================================

-- Employees see own reports; TLs see reports assigned to them; Admins see all
CREATE POLICY "reports_select"
  ON reports FOR SELECT
  TO authenticated
  USING (
    employee_code = (
      SELECT u.employee_code FROM users u WHERE u.email = auth.jwt() ->> 'email'
    )
    OR team_leader_code = (
      SELECT u.employee_code FROM users u WHERE u.email = auth.jwt() ->> 'email'
    )
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.email = auth.jwt() ->> 'email'
      AND u.role = 'Admin'
    )
  );

-- Employees can insert their own reports
CREATE POLICY "reports_insert_own"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (
    employee_code = (
      SELECT u.employee_code FROM users u WHERE u.email = auth.jwt() ->> 'email'
    )
  );

-- TLs can update reports assigned to them (for review); Admins can update any
CREATE POLICY "reports_update_tl_or_admin"
  ON reports FOR UPDATE
  TO authenticated
  USING (
    team_leader_code = (
      SELECT u.employee_code FROM users u WHERE u.email = auth.jwt() ->> 'email'
    )
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.email = auth.jwt() ->> 'email'
      AND u.role = 'Admin'
    )
  );

-- ============================================================
-- NOTIFICATIONS TABLE POLICIES
-- ============================================================

-- Users can only read their own notifications
CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT
  TO authenticated
  USING (
    user_id = (
      SELECT u.employee_code FROM users u WHERE u.email = auth.jwt() ->> 'email'
    )
  );

-- Users can update their own notifications (mark as read)
CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE
  TO authenticated
  USING (
    user_id = (
      SELECT u.employee_code FROM users u WHERE u.email = auth.jwt() ->> 'email'
    )
  );

-- Notifications are inserted by triggers (SECURITY DEFINER), so we need
-- to allow the trigger function to bypass RLS. Update trigger functions:
CREATE OR REPLACE FUNCTION notify_tl_on_submission()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO notifications (user_id, message, type)
    VALUES (NEW.team_leader_code, 'New report submitted by ' || COALESCE(NEW.emp_name, NEW.employee_code), 'submission');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION notify_employee_on_review()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO notifications (user_id, message, type)
        VALUES (NEW.employee_code, 'Your report for ' || NEW.date || ' has been ' || NEW.status, 'status_update');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- PROJECTS TABLE POLICIES
-- ============================================================

-- All authenticated users can read projects
CREATE POLICY "projects_select_authenticated"
  ON projects FOR SELECT
  TO authenticated
  USING (true);

-- Only Admins can manage projects
CREATE POLICY "projects_insert_admin"
  ON projects FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.email = auth.jwt() ->> 'email'
      AND u.role = 'Admin'
    )
  );

CREATE POLICY "projects_update_admin"
  ON projects FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.email = auth.jwt() ->> 'email'
      AND u.role = 'Admin'
    )
  );

CREATE POLICY "projects_delete_admin"
  ON projects FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.email = auth.jwt() ->> 'email'
      AND u.role = 'Admin'
    )
  );
