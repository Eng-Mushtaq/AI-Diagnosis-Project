-- Create doctor_patients table to track doctor-patient relationships
CREATE TABLE doctor_patients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    relationship_type TEXT DEFAULT 'primary', -- 'primary', 'specialist', 'consultant'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(doctor_id, patient_id)
);

-- Add trigger for updated_at timestamp
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON doctor_patients
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- Add RLS policies for doctor_patients table
ALTER TABLE doctor_patients ENABLE ROW LEVEL SECURITY;

-- Doctors can view their own patients
CREATE POLICY "Doctors can view their own patients" ON doctor_patients
    FOR SELECT USING (auth.uid() = doctor_id);

-- Patients can view their own doctors
CREATE POLICY "Patients can view their own doctors" ON doctor_patients
    FOR SELECT USING (auth.uid() = patient_id);

-- Admins can view all doctor-patient relationships
CREATE POLICY "Admins can view all doctor-patient relationships" ON doctor_patients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Doctors can add patients
CREATE POLICY "Doctors can add patients" ON doctor_patients
    FOR INSERT WITH CHECK (auth.uid() = doctor_id);

-- Admins can add doctor-patient relationships
CREATE POLICY "Admins can add doctor-patient relationships" ON doctor_patients
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Doctors can update their own patient relationships
CREATE POLICY "Doctors can update their own patient relationships" ON doctor_patients
    FOR UPDATE USING (auth.uid() = doctor_id);

-- Admins can update any doctor-patient relationship
CREATE POLICY "Admins can update any doctor-patient relationship" ON doctor_patients
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Create index for faster queries
CREATE INDEX idx_doctor_patients_doctor_id ON doctor_patients(doctor_id);
CREATE INDEX idx_doctor_patients_patient_id ON doctor_patients(patient_id);
