-- SQL functions to be added to Supabase to support admin operations
-- These functions bypass RLS policies and should be used carefully

-- Function to create a user record for a doctor
CREATE OR REPLACE FUNCTION admin_create_user_for_doctor(
    doctor_id UUID,
    user_name TEXT,
    user_email TEXT
) RETURNS VOID AS $$
BEGIN
    -- This function runs with security definer, meaning it has the permissions of the user who created it
    -- This allows it to bypass RLS policies
    INSERT INTO users (id, email, name, user_type, profile_image, created_at, updated_at)
    VALUES (
        doctor_id,
        user_email,
        user_name,
        'doctor',
        '',
        NOW(),
        NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update a user's ID (for linking auth users to existing doctor records)
CREATE OR REPLACE FUNCTION admin_update_user_id(
    old_id UUID,
    new_id UUID
) RETURNS VOID AS $$
BEGIN
    -- Update the user ID in the users table
    UPDATE users
    SET id = new_id
    WHERE id = old_id;
    
    -- You might need to update other tables that reference the user ID as well
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update a user's type
CREATE OR REPLACE FUNCTION admin_update_user_type(
    user_id UUID,
    user_type TEXT
) RETURNS VOID AS $$
BEGIN
    -- Update the user type in the users table
    UPDATE users
    SET user_type = user_type
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check data integrity between doctors and users tables
CREATE OR REPLACE FUNCTION check_doctor_user_integrity() RETURNS TABLE (
    doctor_id UUID,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to fix all doctor-user integrity issues
CREATE OR REPLACE FUNCTION fix_all_doctor_user_integrity() RETURNS TABLE (
    fixed_count INTEGER,
    total_count INTEGER
) AS $$
DECLARE
    fixed INTEGER := 0;
    total INTEGER := 0;
BEGIN
    -- Count total doctors
    SELECT COUNT(*) INTO total FROM doctors;
    
    -- Create missing user records
    INSERT INTO users (id, email, name, user_type, created_at, updated_at)
    SELECT 
        d.id,
        'doctor_' || SUBSTRING(d.id::text, 1, 8) || '@example.com' AS email,
        COALESCE(
            'Dr. ' || SPLIT_PART(d.specialization, ' ', 1),
            'Dr. Unknown'
        ) AS name,
        'doctor' AS user_type,
        NOW() AS created_at,
        NOW() AS updated_at
    FROM doctors d
    LEFT JOIN users u ON d.id = u.id
    WHERE u.id IS NULL;
    
    -- Count how many were inserted
    GET DIAGNOSTICS fixed = ROW_COUNT;
    
    -- Fix incorrect user types
    UPDATE users
    SET user_type = 'doctor'
    WHERE id IN (SELECT id FROM doctors)
    AND user_type != 'doctor';
    
    -- Add the number of updated rows to fixed count
    GET DIAGNOSTICS fixed = fixed + ROW_COUNT;
    
    RETURN QUERY SELECT fixed, total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
