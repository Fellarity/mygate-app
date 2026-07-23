-- ============================================================
-- Faith Hours: Migrate team_leader from Name → Employee Code
-- Run this in Supabase Studio SQL Editor
-- ============================================================

-- STEP 1: Preview what will change (run this first to verify)
SELECT 
  u.employee_code AS employee,
  u.name AS employee_name,
  u.team_leader AS current_tl_value,
  tl.employee_code AS resolved_tl_code,
  tl.name AS tl_name
FROM users u
LEFT JOIN users tl ON LOWER(TRIM(tl.name)) = LOWER(TRIM(u.team_leader))
WHERE u.team_leader IS NOT NULL AND u.team_leader != '';

-- STEP 2: Perform the migration (uncomment and run after verifying step 1)
-- UPDATE users u
-- SET team_leader = tl.employee_code
-- FROM users tl
-- WHERE LOWER(TRIM(tl.name)) = LOWER(TRIM(u.team_leader))
--   AND u.team_leader IS NOT NULL
--   AND u.team_leader != '';

-- STEP 3: Verify results
-- SELECT employee_code, name, team_leader FROM users ORDER BY name;
