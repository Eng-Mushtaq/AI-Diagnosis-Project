-- AI Diagnosist Database Schema for Supabase
-- This script creates all necessary tables with relationships for the healthcare application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types
CREATE TYPE user_type AS ENUM ('patient', 'doctor', 'admin');
CREATE TYPE gender_type AS ENUM ('Male', 'Female', 'Other', 'Not specified');
CREATE TYPE blood_group_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown');
CREATE TYPE appointment_type AS ENUM ('video', 'chat', 'in-person');
CREATE TYPE appointment_status AS ENUM ('scheduled', 'completed', 'cancelled');
CREATE TYPE lab_result_status AS ENUM ('pending', 'completed', 'reviewed');
CREATE TYPE urgency_level AS ENUM ('Low', 'Medium', 'High');
CREATE TYPE admin_message_type AS ENUM ('announcement', 'support', 'feedback');
CREATE TYPE admin_message_status AS ENUM ('active', 'archived', 'resolved');

-- Create users table (base table for all user types)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    name TEXT NOT NULL,
    profile_image TEXT,
    user_type user_type NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create patients table
CREATE TABLE patients (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    age INTEGER,
    gender gender_type DEFAULT 'Not specified',
    blood_group blood_group_type DEFAULT 'Unknown',
    height DECIMAL, -- in cm
    weight DECIMAL, -- in kg
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create doctors table
CREATE TABLE doctors (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    specialization TEXT NOT NULL,
    hospital TEXT,
    license_number TEXT,
    experience INTEGER, -- in years
    rating DECIMAL DEFAULT 0.0, -- 0.0 to 5.0
    city TEXT,
    consultation_fee DECIMAL DEFAULT 0.0,
    is_available_for_chat BOOLEAN DEFAULT TRUE,
    is_available_for_video BOOLEAN DEFAULT TRUE,
    about TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create admins table
CREATE TABLE admins (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    admin_role TEXT DEFAULT 'content_admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create patient allergies table (many-to-one)
CREATE TABLE patient_allergies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    allergy TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create patient chronic conditions table (many-to-one)
CREATE TABLE patient_chronic_conditions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    condition TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create patient medications table (many-to-one)
CREATE TABLE patient_medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    medication TEXT NOT NULL,
    dosage TEXT,
    frequency TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create doctor qualifications table (many-to-one)
CREATE TABLE doctor_qualifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    qualification TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create doctor languages table (many-to-one)
CREATE TABLE doctor_languages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    language TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create doctor available days table (many-to-one)
CREATE TABLE doctor_available_days (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    day TEXT NOT NULL, -- e.g., 'Monday', 'Tuesday', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create doctor time slots table (many-to-one)
CREATE TABLE doctor_time_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    day TEXT NOT NULL, -- e.g., 'Monday', 'Tuesday', etc.
    time_slot TEXT NOT NULL, -- e.g., '09:00-09:30', '09:30-10:00', etc.
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create admin permissions table (many-to-one)
CREATE TABLE admin_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
    permission TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create health data table
CREATE TABLE health_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    temperature DECIMAL, -- in Celsius
    heart_rate INTEGER, -- beats per minute
    systolic_bp INTEGER, -- mmHg
    diastolic_bp INTEGER, -- mmHg
    respiratory_rate INTEGER, -- breaths per minute
    oxygen_saturation DECIMAL, -- percentage
    blood_glucose DECIMAL, -- mg/dL
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create symptoms table
CREATE TABLE symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    description TEXT NOT NULL,
    severity INTEGER NOT NULL, -- 1-10 scale
    duration INTEGER NOT NULL, -- in days
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create symptom body parts table (many-to-one)
CREATE TABLE symptom_body_parts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symptom_id UUID NOT NULL REFERENCES symptoms(id) ON DELETE CASCADE,
    body_part TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create symptom associated factors table (many-to-one)
CREATE TABLE symptom_associated_factors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symptom_id UUID NOT NULL REFERENCES symptoms(id) ON DELETE CASCADE,
    factor TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create symptom images table (many-to-one)
CREATE TABLE symptom_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symptom_id UUID NOT NULL REFERENCES symptoms(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create diseases table
CREATE TABLE diseases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    specialist_type TEXT,
    risk_level TEXT,
    additional_info TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- Create disease symptoms table (many-to-one)
CREATE TABLE disease_symptoms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease_id UUID NOT NULL REFERENCES diseases(id) ON DELETE CASCADE,
    symptom TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create disease treatments table (many-to-one)
CREATE TABLE disease_treatments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    disease_id UUID NOT NULL REFERENCES diseases(id) ON DELETE CASCADE,
    treatment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create prediction results table
CREATE TABLE prediction_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    health_data_id UUID REFERENCES health_data(id),
    symptom_id UUID REFERENCES symptoms(id),
    recommended_action TEXT,
    urgency_level urgency_level,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create disease predictions table (many-to-many between prediction_results and diseases)
CREATE TABLE disease_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prediction_id UUID NOT NULL REFERENCES prediction_results(id) ON DELETE CASCADE,
    disease_id UUID NOT NULL REFERENCES diseases(id) ON DELETE CASCADE,
    probability DECIMAL NOT NULL, -- 0.0 to 1.0
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create appointments table
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    appointment_date DATE NOT NULL,
    time_slot TEXT NOT NULL,
    type appointment_type NOT NULL,
    status appointment_status NOT NULL DEFAULT 'scheduled',
    reason TEXT,
    notes TEXT,
    fee DECIMAL NOT NULL DEFAULT 0.0,
    prescription_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create appointment attachments table (many-to-one)
CREATE TABLE appointment_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    attachment_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create lab results table
CREATE TABLE lab_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    test_name TEXT NOT NULL,
    test_date DATE NOT NULL,
    lab_name TEXT NOT NULL,
    result_url TEXT NOT NULL,
    doctor_id UUID REFERENCES doctors(id),
    status lab_result_status NOT NULL DEFAULT 'pending',
    notes TEXT,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create lab result values table (many-to-one)
CREATE TABLE lab_result_values (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lab_result_id UUID NOT NULL REFERENCES lab_results(id) ON DELETE CASCADE,
    parameter TEXT NOT NULL,
    value TEXT NOT NULL,
    unit TEXT,
    reference_range TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create chats table
CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create chat participants table (many-to-many between chats and users)
CREATE TABLE chat_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(chat_id, user_id)
);

-- Create messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    attachment_url TEXT,
    attachment_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create message read status table (many-to-many between messages and users)
CREATE TABLE message_read_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- Create admin messages table
CREATE TABLE admin_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES users(id) ON DELETE SET NULL,
    type admin_message_type NOT NULL DEFAULT 'announcement',
    status admin_message_status NOT NULL DEFAULT 'active',
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create admin message attachments table
CREATE TABLE admin_message_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID NOT NULL REFERENCES admin_messages(id) ON DELETE CASCADE,
    attachment_url TEXT NOT NULL,
    attachment_type TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create admin settings table
CREATE TABLE admin_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    setting_key TEXT NOT NULL UNIQUE,
    setting_value JSONB NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create RLS policies for authentication
-- Users table policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Users can update their own data" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Patients table policies
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Patients can view their own data" ON patients
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Doctors can view patient data" ON patients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM doctors WHERE id = auth.uid()
        )
    );
CREATE POLICY "Admins can view all patients" ON patients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Patients can update their own data" ON patients
    FOR UPDATE USING (auth.uid() = id);

-- Doctors table policies
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Doctors can view their own data" ON doctors
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Patients can view doctor data" ON doctors
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM patients WHERE id = auth.uid()
        )
    );
CREATE POLICY "Admins can view all doctors" ON doctors
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Doctors can update their own data" ON doctors
    FOR UPDATE USING (auth.uid() = id);

-- Health data policies
ALTER TABLE health_data ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own health data" ON health_data
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Doctors can view patient health data" ON health_data
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM doctors WHERE id = auth.uid()
        )
    );
CREATE POLICY "Users can insert their own health data" ON health_data
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own health data" ON health_data
    FOR UPDATE USING (auth.uid() = user_id);

-- Symptoms policies
ALTER TABLE symptoms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own symptoms" ON symptoms
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Doctors can view patient symptoms" ON symptoms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM doctors WHERE id = auth.uid()
        )
    );
CREATE POLICY "Users can insert their own symptoms" ON symptoms
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Prediction results policies
ALTER TABLE prediction_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own predictions" ON prediction_results
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Doctors can view patient predictions" ON prediction_results
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM doctors WHERE id = auth.uid()
        )
    );

-- Appointments policies
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Patients can view their own appointments" ON appointments
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Doctors can view their appointments" ON appointments
    FOR SELECT USING (auth.uid() = doctor_id);
CREATE POLICY "Patients can insert appointments" ON appointments
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Patients can update their appointments" ON appointments
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Doctors can update their appointments" ON appointments
    FOR UPDATE USING (auth.uid() = doctor_id);

-- Lab results policies
ALTER TABLE lab_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Patients can view their own lab results" ON lab_results
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Doctors can view patient lab results" ON lab_results
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM doctors WHERE id = auth.uid()
        ) OR auth.uid() = doctor_id
    );
CREATE POLICY "Patients can insert their lab results" ON lab_results
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Messages policies
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view messages in their chats" ON messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chat_participants
            WHERE chat_id = messages.chat_id AND user_id = auth.uid()
        )
    );
CREATE POLICY "Users can insert messages in their chats" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM chat_participants
            WHERE chat_id = messages.chat_id AND user_id = auth.uid()
        )
    );

-- Admin messages policies
ALTER TABLE admin_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view all admin messages" ON admin_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Users can view admin messages sent to them" ON admin_messages
    FOR SELECT USING (
        recipient_id = auth.uid() OR
        recipient_id IS NULL OR
        auth.uid() = sender_id
    );
CREATE POLICY "Admins can insert admin messages" ON admin_messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Admins can update admin messages" ON admin_messages
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Users can update read status of their messages" ON admin_messages
    FOR UPDATE USING (
        recipient_id = auth.uid() AND
        (NEW.is_read <> OLD.is_read OR NEW.read_at <> OLD.read_at)
    );

-- Admin message attachments policies
ALTER TABLE admin_message_attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view admin message attachments" ON admin_message_attachments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_messages
            WHERE id = admin_message_attachments.message_id AND
            (recipient_id = auth.uid() OR recipient_id IS NULL OR
             EXISTS (SELECT 1 FROM admins WHERE id = auth.uid()))
        )
    );
CREATE POLICY "Admins can insert admin message attachments" ON admin_message_attachments
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Admin settings policies
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view all admin settings" ON admin_settings
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Users can view public admin settings" ON admin_settings
    FOR SELECT USING (
        is_public = TRUE
    );
CREATE POLICY "Admins can insert admin settings" ON admin_settings
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Admins can update admin settings" ON admin_settings
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Admins can delete admin settings" ON admin_settings
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger to all tables with updated_at column
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- Add triggers for other tables with updated_at columns
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON patients
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON doctors
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON admins
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON doctor_time_slots
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON admin_messages
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON admin_settings
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON appointments
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON lab_results
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON chats
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON message_read_status
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

CREATE TRIGGER set_timestamp
BEFORE UPDATE ON diseases
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- Create indexes for better query performance
-- Users indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_user_type ON users(user_type);

-- Doctors indexes
CREATE INDEX idx_doctors_specialization ON doctors(specialization);
CREATE INDEX idx_doctors_city ON doctors(city);
CREATE INDEX idx_doctors_rating ON doctors(rating);

-- Health data indexes
CREATE INDEX idx_health_data_user_id ON health_data(user_id);
CREATE INDEX idx_health_data_timestamp ON health_data(timestamp);

-- Symptoms indexes
CREATE INDEX idx_symptoms_user_id ON symptoms(user_id);
CREATE INDEX idx_symptoms_timestamp ON symptoms(timestamp);

-- Prediction results indexes
CREATE INDEX idx_prediction_results_user_id ON prediction_results(user_id);
CREATE INDEX idx_prediction_results_timestamp ON prediction_results(timestamp);

-- Disease predictions indexes
CREATE INDEX idx_disease_predictions_prediction_id ON disease_predictions(prediction_id);
CREATE INDEX idx_disease_predictions_disease_id ON disease_predictions(disease_id);
CREATE INDEX idx_disease_predictions_probability ON disease_predictions(probability);

-- Appointments indexes
CREATE INDEX idx_appointments_user_id ON appointments(user_id);
CREATE INDEX idx_appointments_doctor_id ON appointments(doctor_id);
CREATE INDEX idx_appointments_appointment_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);

-- Lab results indexes
CREATE INDEX idx_lab_results_user_id ON lab_results(user_id);
CREATE INDEX idx_lab_results_test_date ON lab_results(test_date);
CREATE INDEX idx_lab_results_status ON lab_results(status);

-- Messages indexes
CREATE INDEX idx_messages_chat_id ON messages(chat_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_timestamp ON messages(timestamp);

-- Chat participants indexes
CREATE INDEX idx_chat_participants_chat_id ON chat_participants(chat_id);
CREATE INDEX idx_chat_participants_user_id ON chat_participants(user_id);
