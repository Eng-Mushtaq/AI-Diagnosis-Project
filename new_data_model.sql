-- New data model for users, patients, and doctors
-- This approach uses a single users table with separate profile tables

-- 1. First, let's create a backup of the existing tables
CREATE TABLE IF NOT EXISTS users_backup AS SELECT * FROM users;
CREATE TABLE IF NOT EXISTS doctors_backup AS SELECT * FROM doctors;
CREATE TABLE IF NOT EXISTS patients_backup AS SELECT * FROM patients;

-- 2. Modify the users table to be the primary authentication table
-- We'll keep this table simple with just authentication and basic info
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS auth_id UUID,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- 3. Create a new doctors_profile table that references users
CREATE TABLE IF NOT EXISTS doctors_profile (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  specialization TEXT,
  hospital TEXT,
  license_number TEXT,
  experience INTEGER DEFAULT 0,
  rating DECIMAL DEFAULT 0,
  consultation_fee DECIMAL DEFAULT 0,
  is_available_for_chat BOOLEAN DEFAULT false,
  is_available_for_video BOOLEAN DEFAULT false,
  verification_status TEXT DEFAULT 'pending',
  rejection_reason TEXT,
  verification_date TIMESTAMP,
  verified_by UUID REFERENCES users(id),
  about TEXT,
  city TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create a new patients_profile table that references users
CREATE TABLE IF NOT EXISTS patients_profile (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  age INTEGER,
  gender TEXT,
  blood_group TEXT,
  height DECIMAL,
  weight DECIMAL,
  medical_history TEXT,
  allergies TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create a new admins_profile table that references users
CREATE TABLE IF NOT EXISTS admins_profile (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  admin_role TEXT DEFAULT 'content_admin',
  permissions JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create a function to ensure user_type is consistent with profile tables
CREATE OR REPLACE FUNCTION ensure_user_type_consistency()
RETURNS TRIGGER AS $$
BEGIN
  -- If a doctor profile is created, ensure user_type is 'doctor'
  IF TG_TABLE_NAME = 'doctors_profile' THEN
    UPDATE users SET user_type = 'doctor' WHERE id = NEW.id;
  -- If a patient profile is created, ensure user_type is 'patient'
  ELSIF TG_TABLE_NAME = 'patients_profile' THEN
    UPDATE users SET user_type = 'patient' WHERE id = NEW.id;
  -- If an admin profile is created, ensure user_type is 'admin'
  ELSIF TG_TABLE_NAME = 'admins_profile' THEN
    UPDATE users SET user_type = 'admin' WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create triggers to maintain user_type consistency
CREATE TRIGGER ensure_doctor_user_type
AFTER INSERT ON doctors_profile
FOR EACH ROW
EXECUTE FUNCTION ensure_user_type_consistency();

CREATE TRIGGER ensure_patient_user_type
AFTER INSERT ON patients_profile
FOR EACH ROW
EXECUTE FUNCTION ensure_user_type_consistency();

CREATE TRIGGER ensure_admin_user_type
AFTER INSERT ON admins_profile
FOR EACH ROW
EXECUTE FUNCTION ensure_user_type_consistency();

-- 8. Create a function to migrate existing data
CREATE OR REPLACE FUNCTION migrate_existing_data()
RETURNS VOID AS $$
DECLARE
  doctor_record RECORD;
  patient_record RECORD;
  admin_record RECORD;
BEGIN
  -- Migrate doctors
  FOR doctor_record IN SELECT * FROM doctors LOOP
    -- Check if user exists
    IF EXISTS (SELECT 1 FROM users WHERE id = doctor_record.id) THEN
      -- Insert into doctors_profile
      INSERT INTO doctors_profile (
        id, specialization, hospital, license_number, experience,
        rating, is_available_for_chat, is_available_for_video,
        verification_status, rejection_reason, verification_date,
        verified_by, about, city, created_at, updated_at
      ) VALUES (
        doctor_record.id, doctor_record.specialization, doctor_record.hospital,
        doctor_record.license_number, doctor_record.experience, doctor_record.rating,
        doctor_record.is_available_for_chat, doctor_record.is_available_for_video,
        doctor_record.verification_status, doctor_record.rejection_reason,
        doctor_record.verification_date, doctor_record.verified_by,
        doctor_record.about, doctor_record.city, doctor_record.created_at,
        doctor_record.updated_at
      ) ON CONFLICT (id) DO NOTHING;
      
      -- Update user_type
      UPDATE users SET user_type = 'doctor' WHERE id = doctor_record.id;
    ELSE
      -- Create a new user record
      INSERT INTO users (
        id, name, email, user_type, created_at, updated_at
      ) VALUES (
        doctor_record.id,
        COALESCE('Dr. ' || SPLIT_PART(doctor_record.specialization, ' ', 1), 'Dr. Unknown'),
        'doctor_' || SUBSTRING(doctor_record.id::text, 1, 8) || '@example.com',
        'doctor',
        doctor_record.created_at,
        doctor_record.updated_at
      ) ON CONFLICT (id) DO NOTHING;
      
      -- Insert into doctors_profile
      INSERT INTO doctors_profile (
        id, specialization, hospital, license_number, experience,
        rating, is_available_for_chat, is_available_for_video,
        verification_status, rejection_reason, verification_date,
        verified_by, about, city, created_at, updated_at
      ) VALUES (
        doctor_record.id, doctor_record.specialization, doctor_record.hospital,
        doctor_record.license_number, doctor_record.experience, doctor_record.rating,
        doctor_record.is_available_for_chat, doctor_record.is_available_for_video,
        doctor_record.verification_status, doctor_record.rejection_reason,
        doctor_record.verification_date, doctor_record.verified_by,
        doctor_record.about, doctor_record.city, doctor_record.created_at,
        doctor_record.updated_at
      ) ON CONFLICT (id) DO NOTHING;
    END IF;
  END LOOP;
  
  -- Migrate patients (similar logic)
  FOR patient_record IN SELECT * FROM patients LOOP
    -- Check if user exists
    IF EXISTS (SELECT 1 FROM users WHERE id = patient_record.id) THEN
      -- Insert into patients_profile
      INSERT INTO patients_profile (
        id, age, gender, blood_group, height, weight, created_at, updated_at
      ) VALUES (
        patient_record.id, patient_record.age, patient_record.gender,
        patient_record.blood_group, patient_record.height, patient_record.weight,
        patient_record.created_at, patient_record.updated_at
      ) ON CONFLICT (id) DO NOTHING;
      
      -- Update user_type
      UPDATE users SET user_type = 'patient' WHERE id = patient_record.id;
    END IF;
  END LOOP;
  
  -- Migrate admins (similar logic)
  FOR admin_record IN SELECT * FROM admins LOOP
    -- Check if user exists
    IF EXISTS (SELECT 1 FROM users WHERE id = admin_record.id) THEN
      -- Insert into admins_profile
      INSERT INTO admins_profile (
        id, admin_role, created_at, updated_at
      ) VALUES (
        admin_record.id, admin_record.admin_role,
        admin_record.created_at, admin_record.updated_at
      ) ON CONFLICT (id) DO NOTHING;
      
      -- Update user_type
      UPDATE users SET user_type = 'admin' WHERE id = admin_record.id;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
