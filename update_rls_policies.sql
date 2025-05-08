-- Update RLS policies to allow data integrity fixes

-- First, let's check the current policies on the users table
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Create a function to fix data integrity issues
CREATE OR REPLACE FUNCTION fix_doctor_user_integrity()
RETURNS TRIGGER AS $$
DECLARE
  doctor_name TEXT;
BEGIN
  -- If a doctor profile is created but no user record exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = NEW.id) THEN
    -- Create a better doctor name using specialization, hospital, and city
    IF NEW.specialization IS NOT NULL AND NEW.specialization != '' THEN
      doctor_name := 'Dr. ' || NEW.specialization;

      -- Add hospital if available
      IF NEW.hospital IS NOT NULL AND NEW.hospital != '' THEN
        doctor_name := doctor_name || ' (' || NEW.hospital;

        -- Add city if available
        IF NEW.city IS NOT NULL AND NEW.city != '' THEN
          doctor_name := doctor_name || ', ' || NEW.city || ')';
        ELSE
          doctor_name := doctor_name || ')';
        END IF;
      -- Add city directly if no hospital
      ELSIF NEW.city IS NOT NULL AND NEW.city != '' THEN
        doctor_name := doctor_name || ' (' || NEW.city || ')';
      END IF;
    ELSE
      -- Fallback if no specialization
      doctor_name := 'Dr. ' || COALESCE(NEW.hospital, COALESCE(NEW.city, 'Unknown'));
    END IF;

    -- Create a user record with appropriate data
    INSERT INTO users (
      id,
      name,
      email,
      user_type,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      doctor_name,
      'doctor_' || SUBSTRING(NEW.id::text, 1, 8) || '@example.com',
      'doctor',
      NOW(),
      NOW()
    );
  ELSE
    -- Update the name in the users table to ensure it's correct
    -- Create a better doctor name using specialization, hospital, and city
    IF NEW.specialization IS NOT NULL AND NEW.specialization != '' THEN
      doctor_name := 'Dr. ' || NEW.specialization;

      -- Add hospital if available
      IF NEW.hospital IS NOT NULL AND NEW.hospital != '' THEN
        doctor_name := doctor_name || ' (' || NEW.hospital;

        -- Add city if available
        IF NEW.city IS NOT NULL AND NEW.city != '' THEN
          doctor_name := doctor_name || ', ' || NEW.city || ')';
        ELSE
          doctor_name := doctor_name || ')';
        END IF;
      -- Add city directly if no hospital
      ELSIF NEW.city IS NOT NULL AND NEW.city != '' THEN
        doctor_name := doctor_name || ' (' || NEW.city || ')';
      END IF;
    ELSE
      -- Fallback if no specialization
      doctor_name := 'Dr. ' || COALESCE(NEW.hospital, COALESCE(NEW.city, 'Unknown'));
    END IF;

    -- Update the name in the users table
    UPDATE users SET
      name = doctor_name,
      user_type = 'doctor',
      updated_at = NOW()
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger to automatically fix integrity issues
DROP TRIGGER IF EXISTS ensure_doctor_user_integrity ON doctors_profile;
CREATE TRIGGER ensure_doctor_user_integrity
AFTER INSERT OR UPDATE ON doctors_profile
FOR EACH ROW
EXECUTE FUNCTION fix_doctor_user_integrity();

-- Create a function to bypass RLS for data integrity fixes
CREATE OR REPLACE FUNCTION create_missing_user_record(
  doctor_id UUID,
  doctor_email TEXT
) RETURNS VOID AS $$
DECLARE
  doctor_record RECORD;
  doctor_name TEXT;
BEGIN
  -- Get doctor data to create a better name
  SELECT specialization, hospital, city INTO doctor_record
  FROM doctors_profile
  WHERE id = doctor_id;

  -- Create a better doctor name using specialization, hospital, and city
  IF doctor_record.specialization IS NOT NULL AND doctor_record.specialization != '' THEN
    doctor_name := 'Dr. ' || doctor_record.specialization;

    -- Add hospital if available
    IF doctor_record.hospital IS NOT NULL AND doctor_record.hospital != '' THEN
      doctor_name := doctor_name || ' (' || doctor_record.hospital;

      -- Add city if available
      IF doctor_record.city IS NOT NULL AND doctor_record.city != '' THEN
        doctor_name := doctor_name || ', ' || doctor_record.city || ')';
      ELSE
        doctor_name := doctor_name || ')';
      END IF;
    -- Add city directly if no hospital
    ELSIF doctor_record.city IS NOT NULL AND doctor_record.city != '' THEN
      doctor_name := doctor_name || ' (' || doctor_record.city || ')';
    END IF;
  ELSE
    -- Fallback if no specialization
    doctor_name := 'Dr. ' || COALESCE(doctor_record.hospital, COALESCE(doctor_record.city, 'Unknown'));
  END IF;

  -- Insert or update the user record
  INSERT INTO users (
    id,
    name,
    email,
    user_type,
    created_at,
    updated_at
  ) VALUES (
    doctor_id,
    doctor_name,
    doctor_email,
    'doctor',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    name = doctor_name,
    user_type = 'doctor',
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Modify RLS policy on users table to allow the app to read all users
DROP POLICY IF EXISTS "Users are viewable by everyone" ON users;
CREATE POLICY "Users are viewable by everyone"
ON users FOR SELECT
USING (true);

-- Modify RLS policy on users table to allow the app to create doctor users
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON users;
CREATE POLICY "Enable insert for authenticated users only"
ON users FOR INSERT
WITH CHECK (
  -- Allow authenticated users to create their own user record
  (auth.uid() = id) OR
  -- Allow creating doctor records (for data integrity fixes)
  (user_type = 'doctor')
);

-- Modify RLS policy on users table to allow updating doctor records
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON users;
CREATE POLICY "Enable update for users based on user_id"
ON users FOR UPDATE
USING (
  -- Users can update their own records
  auth.uid() = id OR
  -- Allow updating doctor records (for data integrity fixes)
  user_type = 'doctor'
)
WITH CHECK (
  -- Users can update their own records
  auth.uid() = id OR
  -- Allow updating doctor records (for data integrity fixes)
  user_type = 'doctor'
);

-- Create a function to fix all doctor-user integrity issues at once
CREATE OR REPLACE FUNCTION fix_all_doctor_user_integrity()
RETURNS TEXT AS $$
DECLARE
  doctor_record RECORD;
  fixed_count INTEGER := 0;
  total_count INTEGER := 0;
  doctor_name TEXT;
BEGIN
  -- Get all doctors without user records
  FOR doctor_record IN
    SELECT dp.id, dp.specialization, dp.hospital, dp.city
    FROM doctors_profile dp
    LEFT JOIN users u ON dp.id = u.id
    WHERE u.id IS NULL
  LOOP
    total_count := total_count + 1;

    -- Create a better doctor name using specialization, hospital, and city
    IF doctor_record.specialization IS NOT NULL AND doctor_record.specialization != '' THEN
      doctor_name := 'Dr. ' || doctor_record.specialization;

      -- Add hospital if available
      IF doctor_record.hospital IS NOT NULL AND doctor_record.hospital != '' THEN
        doctor_name := doctor_name || ' (' || doctor_record.hospital;

        -- Add city if available
        IF doctor_record.city IS NOT NULL AND doctor_record.city != '' THEN
          doctor_name := doctor_name || ', ' || doctor_record.city || ')';
        ELSE
          doctor_name := doctor_name || ')';
        END IF;
      -- Add city directly if no hospital
      ELSIF doctor_record.city IS NOT NULL AND doctor_record.city != '' THEN
        doctor_name := doctor_name || ' (' || doctor_record.city || ')';
      END IF;
    ELSE
      -- Fallback if no specialization
      doctor_name := 'Dr. ' || COALESCE(doctor_record.hospital, COALESCE(doctor_record.city, 'Unknown'));
    END IF;

    BEGIN
      -- Create user record for this doctor with better name
      INSERT INTO users (
        id,
        name,
        email,
        user_type,
        created_at,
        updated_at
      ) VALUES (
        doctor_record.id,
        doctor_name,
        'doctor_' || SUBSTRING(doctor_record.id::text, 1, 8) || '@example.com',
        'doctor',
        NOW(),
        NOW()
      );

      fixed_count := fixed_count + 1;
    EXCEPTION WHEN OTHERS THEN
      -- Continue with next record if there's an error
      CONTINUE;
    END;
  END LOOP;

  RETURN 'Fixed ' || fixed_count || ' out of ' || total_count || ' integrity issues';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
