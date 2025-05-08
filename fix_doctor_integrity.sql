-- SQL script to fix data integrity issues between doctors and users tables

-- 1. First, let's check the current state of the tables
-- Get all doctors
SELECT id, verification_status FROM doctors;

-- Get all users with user_type = 'doctor'
SELECT id, user_type, email, name FROM users WHERE user_type = 'doctor';

-- 2. Identify doctors without corresponding user records
WITH doctor_ids AS (
    SELECT id FROM doctors
),
user_ids AS (
    SELECT id FROM users
)
SELECT d.id AS missing_user_id
FROM doctor_ids d
LEFT JOIN user_ids u ON d.id = u.id
WHERE u.id IS NULL;

-- 3. Create missing user records for doctors
-- This will insert user records for any doctor that doesn't have a corresponding user record
INSERT INTO users (id, email, name, user_type, created_at, updated_at)
SELECT 
    d.id,
    'doctor_' || SUBSTRING(d.id::text, 1, 8) || '@example.com' AS email,
    'Dr. Unknown' AS name,
    'doctor' AS user_type,
    NOW() AS created_at,
    NOW() AS updated_at
FROM doctors d
LEFT JOIN users u ON d.id = u.id
WHERE u.id IS NULL;

-- 4. Check for users with doctor IDs but incorrect user_type
SELECT id, user_type, email, name 
FROM users 
WHERE id IN (SELECT id FROM doctors) 
AND user_type != 'doctor';

-- 5. Fix users with incorrect user_type
UPDATE users
SET user_type = 'doctor'
WHERE id IN (SELECT id FROM doctors)
AND user_type != 'doctor';

-- 6. Verify the fix
-- Check if all doctors now have corresponding user records
WITH doctor_ids AS (
    SELECT id FROM doctors
),
user_ids AS (
    SELECT id FROM users WHERE user_type = 'doctor'
)
SELECT d.id AS doctor_id, 
       CASE WHEN u.id IS NULL THEN 'Missing user record' ELSE 'OK' END AS status
FROM doctor_ids d
LEFT JOIN user_ids u ON d.id = u.id;

-- 7. Check specifically for approved doctors
WITH approved_doctor_ids AS (
    SELECT id FROM doctors WHERE verification_status = 'approved'
),
doctor_user_ids AS (
    SELECT id FROM users WHERE user_type = 'doctor'
)
SELECT d.id AS approved_doctor_id, 
       CASE WHEN u.id IS NULL THEN 'Missing user record' ELSE 'OK' END AS status
FROM approved_doctor_ids d
LEFT JOIN doctor_user_ids u ON d.id = u.id;
