-- ============================================================
-- Faith Hours: Standardize Status Values
-- Run this in Supabase Studio SQL Editor
-- ============================================================

-- Migrate all 'Approve' status values to 'Approved' for consistency
UPDATE reports SET status = 'Approved' WHERE status = 'Approve';

-- Verify the migration
SELECT status, COUNT(*) FROM reports GROUP BY status ORDER BY status;
