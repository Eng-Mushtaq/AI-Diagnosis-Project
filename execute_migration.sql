-- Execute the migration to the new data model

-- 1. First, let's create backups of the existing data
SELECT 'Creating backups of existing tables...';
CREATE TABLE IF NOT EXISTS users_backup AS SELECT * FROM users;
CREATE TABLE IF NOT EXISTS doctors_backup AS SELECT * FROM doctors;
CREATE TABLE IF NOT EXISTS patients_backup AS SELECT * FROM patients;
CREATE TABLE IF NOT EXISTS admins_backup AS SELECT * FROM admins;

-- 2. Check the current state of the database
SELECT 'Checking current state of the database...';
SELECT COUNT(*) AS total_users FROM users;
SELECT COUNT(*) AS total_doctors FROM doctors;
SELECT COUNT(*) AS total_patients FROM patients;
SELECT COUNT(*) AS total_admins FROM admins;

-- 3. Check for data integrity issues
SELECT 'Checking for data integrity issues...';
SELECT 'Doctors without user records:';
SELECT d.id, d.verification_status 
FROM doctors d 
LEFT JOIN users u ON d.id = u.id 
WHERE u.id IS NULL;

SELECT 'Users with doctor records but wrong user_type:';
SELECT u.id, u.user_type 
FROM users u 
JOIN doctors d ON u.id = d.id 
WHERE u.user_type != 'doctor';

-- 4. Create the new profile tables
SELECT 'Creating new profile tables...';
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

CREATE TABLE IF NOT EXISTS admins_profile (
  id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  admin_role TEXT DEFAULT 'content_admin',
  permissions JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create consistency triggers
SELECT 'Creating consistency triggers...';
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

-- 6. Migrate existing data
SELECT 'Migrating existing data...';

-- 6.1 First, create missing user records for doctors
INSERT INTO users (id, name, email, user_type, created_at, updated_at)
SELECT 
    d.id,
    COALESCE('Dr. ' || SPLIT_PART(d.specialization, ' ', 1), 'Dr. Unknown'),
    'doctor_' || SUBSTRING(d.id::text, 1, 8) || '@example.com',
    'doctor',
    d.created_at,
    d.updated_at
FROM doctors d
LEFT JOIN users u ON d.id = u.id
WHERE u.id IS NULL;

-- 6.2 Migrate doctors to doctors_profile
INSERT INTO doctors_profile (
  id, specialization, hospital, license_number, experience,
  rating, is_available_for_chat, is_available_for_video,
  verification_status, rejection_reason, verification_date,
  verified_by, about, city, created_at, updated_at
)
SELECT 
  id, specialization, hospital, license_number, experience,
  rating, is_available_for_chat, is_available_for_video,
  verification_status, rejection_reason, verification_date,
  verified_by, about, city, created_at, updated_at
FROM doctors
ON CONFLICT (id) DO NOTHING;

-- 6.3 Migrate patients to patients_profile
INSERT INTO patients_profile (
  id, age, gender, blood_group, height, weight, created_at, updated_at
)
SELECT 
  id, age, gender, blood_group, height, weight, created_at, updated_at
FROM patients
ON CONFLICT (id) DO NOTHING;

-- 6.4 Migrate admins to admins_profile
INSERT INTO admins_profile (
  id, admin_role, created_at, updated_at
)
SELECT 
  id, admin_role, created_at, updated_at
FROM admins
ON CONFLICT (id) DO NOTHING;

-- 6.5 Ensure all user_types are consistent
UPDATE users u
SET user_type = 'doctor'
FROM doctors_profile dp
WHERE u.id = dp.id AND u.user_type != 'doctor';

UPDATE users u
SET user_type = 'patient'
FROM patients_profile pp
WHERE u.id = pp.id AND u.user_type != 'patient';

UPDATE users u
SET user_type = 'admin'
FROM admins_profile ap
WHERE u.id = ap.id AND u.user_type != 'admin';

-- 7. Verify the migration
SELECT 'Verifying migration...';
SELECT COUNT(*) AS total_users FROM users;
SELECT COUNT(*) AS total_doctors_profile FROM doctors_profile;
SELECT COUNT(*) AS total_patients_profile FROM patients_profile;
SELECT COUNT(*) AS total_admins_profile FROM admins_profile;

-- 8. Check for any remaining data integrity issues
SELECT 'Checking for remaining data integrity issues...';
SELECT 'Doctors_profile without user records:';
SELECT dp.id, dp.verification_status 
FROM doctors_profile dp 
LEFT JOIN users u ON dp.id = u.id 
WHERE u.id IS NULL;

SELECT 'Users with doctor_profile records but wrong user_type:';
SELECT u.id, u.user_type 
FROM users u 
JOIN doctors_profile dp ON u.id = dp.id 
WHERE u.user_type != 'doctor';
