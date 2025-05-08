-- Create a stored procedure to create a doctor with a user in a single transaction
CREATE OR REPLACE FUNCTION create_doctor_with_user(
    user_id UUID,
    specialization TEXT,
    hospital TEXT,
    license_number TEXT,
    experience INTEGER,
    is_available_for_chat BOOLEAN,
    is_available_for_video BOOLEAN,
    verification_status TEXT DEFAULT 'pending'
) RETURNS VOID AS $$
BEGIN
    -- Check if the user record exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = user_id) THEN
        RAISE EXCEPTION 'User with ID % does not exist', user_id;
    END IF;
    
    -- Update the user record to ensure user_type is 'doctor'
    UPDATE users
    SET user_type = 'doctor',
        updated_at = NOW()
    WHERE id = user_id AND user_type != 'doctor';
    
    -- Check if a doctor record already exists
    IF EXISTS (SELECT 1 FROM doctors WHERE id = user_id) THEN
        -- Update the existing doctor record
        UPDATE doctors
        SET specialization = create_doctor_with_user.specialization,
            hospital = create_doctor_with_user.hospital,
            license_number = create_doctor_with_user.license_number,
            experience = create_doctor_with_user.experience,
            is_available_for_chat = create_doctor_with_user.is_available_for_chat,
            is_available_for_video = create_doctor_with_user.is_available_for_video,
            verification_status = LOWER(create_doctor_with_user.verification_status),
            updated_at = NOW()
        WHERE id = user_id;
    ELSE
        -- Create a new doctor record
        INSERT INTO doctors (
            id,
            specialization,
            hospital,
            license_number,
            experience,
            is_available_for_chat,
            is_available_for_video,
            verification_status,
            created_at,
            updated_at
        ) VALUES (
            user_id,
            create_doctor_with_user.specialization,
            create_doctor_with_user.hospital,
            create_doctor_with_user.license_number,
            create_doctor_with_user.experience,
            create_doctor_with_user.is_available_for_chat,
            create_doctor_with_user.is_available_for_video,
            LOWER(create_doctor_with_user.verification_status),
            NOW(),
            NOW()
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
