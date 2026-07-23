-- SQL to create a test user for login verification
-- Run this in your Supabase SQL Editor

INSERT INTO users (name, email, employee_code, password, contact_no, role, department, team_leader)
VALUES (
    'Test Employee', 
    'test@faithhours.com', 
    'E1001', 
    'pass123', 
    '9876543210', 
    'Employee', 
    'Engineering', 
    'TL-John'
)
ON CONFLICT (employee_code) DO UPDATE 
SET password = EXCLUDED.password, 
    name = EXCLUDED.name;
