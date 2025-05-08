-- SQL script to prevent doctor-user data integrity issues
-- This script adds triggers and functions to ensure that:
-- 1. Every doctor has a corresponding user record
-- 2. When a doctor is created, a user record is automatically created if it doesn't exist
-- 3. When a user is deleted, the corresponding doctor record is also deleted (already handled by ON DELETE CASCADE)

-- First, let's create a function to ensure a user record exists for a doctor
CREATE OR REPLACE FUNCTION ensure_doctor_user_exists()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if a user record exists for this doctor
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = NEW.id) THEN
        -- Create a user record with the doctor's ID
        INSERT INTO users (
            id, 
            email, 
            name, 
            user_type, 
            created_at, 
            updated_at
        ) VALUES (
            NEW.id,
            'doctor_' || SUBSTRING(NEW.id::text, 1, 8) || '@example.com',
            COALESCE('Dr. ' || SPLIT_PART(NEW.specialization, ' ', 1), 'Dr. Unknown'),
            'doctor',
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Created missing user record for doctor ID: %', NEW.id;
    ELSE
        -- Ensure the user type is set to 'doctor'
        UPDATE users 
        SET user_type = 'doctor' 
        WHERE id = NEW.id AND user_type != 'doctor';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger to run the function before inserting a new doctor
CREATE OR REPLACE TRIGGER ensure_doctor_user_trigger
BEFORE INSERT ON doctors
FOR EACH ROW
EXECUTE FUNCTION ensure_doctor_user_exists();

-- Create a function to validate doctor-user relationship
CREATE OR REPLACE FUNCTION validate_doctor_user_relationship()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the user record exists and has user_type = 'doctor'
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = NEW.id AND user_type = 'doctor'
    ) THEN
        RAISE EXCEPTION 'Doctor ID % must have a corresponding user record with user_type = doctor', NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to validate the relationship after the user record is created
CREATE OR REPLACE TRIGGER validate_doctor_user_trigger
AFTER INSERT ON doctors
FOR EACH ROW
EXECUTE FUNCTION validate_doctor_user_relationship();

-- Create a function to update user record when doctor is updated
CREATE OR REPLACE FUNCTION sync_doctor_user_updates()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the user's name if the specialization changed
    IF NEW.specialization != OLD.specialization THEN
        UPDATE users 
        SET name = 'Dr. ' || SPLIT_PART(NEW.specialization, ' ', 1)
        WHERE id = NEW.id AND name LIKE 'Dr. %';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to sync updates
CREATE OR REPLACE TRIGGER sync_doctor_user_updates_trigger
AFTER UPDATE ON doctors
FOR EACH ROW
WHEN (NEW.specialization IS DISTINCT FROM OLD.specialization)
EXECUTE FUNCTION sync_doctor_user_updates();

-- Create a function to ensure user_type is 'doctor' for users in the doctors table
CREATE OR REPLACE FUNCTION ensure_user_type_is_doctor()
RETURNS TRIGGER AS $$
BEGIN
    -- If this user is in the doctors table, ensure user_type is 'doctor'
    IF EXISTS (SELECT 1 FROM doctors WHERE id = NEW.id) AND NEW.user_type != 'doctor' THEN
        NEW.user_type := 'doctor';
        RAISE NOTICE 'Automatically set user_type to doctor for user ID: %', NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to ensure user_type is 'doctor' for users in the doctors table
CREATE OR REPLACE TRIGGER ensure_user_type_is_doctor_trigger
BEFORE INSERT OR UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION ensure_user_type_is_doctor();

-- Add a check constraint to the doctors table to ensure verification_status is lowercase
ALTER TABLE doctors ADD CONSTRAINT check_verification_status_lowercase
CHECK (verification_status = lower(verification_status));

-- Create a function to automatically convert verification_status to lowercase
CREATE OR REPLACE FUNCTION normalize_verification_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Convert verification_status to lowercase
    IF NEW.verification_status IS NOT NULL THEN
        NEW.verification_status := lower(NEW.verification_status);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to normalize verification_status
CREATE OR REPLACE TRIGGER normalize_verification_status_trigger
BEFORE INSERT OR UPDATE ON doctors
FOR EACH ROW
EXECUTE FUNCTION normalize_verification_status();
