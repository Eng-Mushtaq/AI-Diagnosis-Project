-- Fix foreign key constraint for doctor_available_days table

-- First, let's check which tables exist and have foreign keys to the doctors table
DO $$
DECLARE
    table_exists boolean;
BEGIN
    -- Check and fix doctor_available_days table
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'doctor_available_days'
    ) INTO table_exists;

    IF table_exists THEN
        RAISE NOTICE 'Fixing constraints for doctor_available_days table';
        ALTER TABLE doctor_available_days
        DROP CONSTRAINT IF EXISTS doctor_available_days_doctor_id_fkey;

        ALTER TABLE doctor_available_days
        ADD CONSTRAINT doctor_available_days_doctor_id_fkey
        FOREIGN KEY (doctor_id) REFERENCES doctors_profile(id) ON DELETE CASCADE;
    ELSE
        RAISE NOTICE 'Table doctor_available_days does not exist, skipping';
    END IF;

    -- Check and fix doctor_qualifications table
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'doctor_qualifications'
    ) INTO table_exists;

    IF table_exists THEN
        RAISE NOTICE 'Fixing constraints for doctor_qualifications table';
        ALTER TABLE doctor_qualifications
        DROP CONSTRAINT IF EXISTS doctor_qualifications_doctor_id_fkey;

        ALTER TABLE doctor_qualifications
        ADD CONSTRAINT doctor_qualifications_doctor_id_fkey
        FOREIGN KEY (doctor_id) REFERENCES doctors_profile(id) ON DELETE CASCADE;
    ELSE
        RAISE NOTICE 'Table doctor_qualifications does not exist, skipping';
    END IF;

    -- Check and fix doctor_languages table
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'doctor_languages'
    ) INTO table_exists;

    IF table_exists THEN
        RAISE NOTICE 'Fixing constraints for doctor_languages table';
        ALTER TABLE doctor_languages
        DROP CONSTRAINT IF EXISTS doctor_languages_doctor_id_fkey;

        ALTER TABLE doctor_languages
        ADD CONSTRAINT doctor_languages_doctor_id_fkey
        FOREIGN KEY (doctor_id) REFERENCES doctors_profile(id) ON DELETE CASCADE;
    ELSE
        RAISE NOTICE 'Table doctor_languages does not exist, skipping';
    END IF;

    -- Check and fix doctor_time_slots table
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'doctor_time_slots'
    ) INTO table_exists;

    IF table_exists THEN
        RAISE NOTICE 'Fixing constraints for doctor_time_slots table';
        ALTER TABLE doctor_time_slots
        DROP CONSTRAINT IF EXISTS doctor_time_slots_doctor_id_fkey;

        ALTER TABLE doctor_time_slots
        ADD CONSTRAINT doctor_time_slots_doctor_id_fkey
        FOREIGN KEY (doctor_id) REFERENCES doctors_profile(id) ON DELETE CASCADE;
    ELSE
        RAISE NOTICE 'Table doctor_time_slots does not exist, skipping';
    END IF;

    -- Check and fix appointments table
    SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'appointments'
    ) INTO table_exists;

    IF table_exists THEN
        RAISE NOTICE 'Fixing constraints for appointments table';
        ALTER TABLE appointments
        DROP CONSTRAINT IF EXISTS appointments_doctor_id_fkey;

        ALTER TABLE appointments
        ADD CONSTRAINT appointments_doctor_id_fkey
        FOREIGN KEY (doctor_id) REFERENCES doctors_profile(id) ON DELETE CASCADE;
    ELSE
        RAISE NOTICE 'Table appointments does not exist, skipping';
    END IF;
END $$;
