-- Optimize fetching an employee's history (filtered by employee_code, ordered by submitted_at)
CREATE INDEX IF NOT EXISTS idx_reports_employee_code ON reports(employee_code);
CREATE INDEX IF NOT EXISTS idx_reports_submitted_at ON reports(submitted_at DESC);

-- Optimize fetching pending reports for a Team Leader (filtered by team_leader and status)
CREATE INDEX IF NOT EXISTS idx_reports_team_leader_status ON reports(team_leader, status);

-- Optimize fetching notifications (filtered by user_id, ordered by created_at)
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);

-- Optimize checking for unread notifications (filtered by user_id and is_read)
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read);

-- Optimize user lookups for drop-downs / filtering
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_team_leader ON users(team_leader);
