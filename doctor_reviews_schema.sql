-- Create doctor_reviews table to store doctor ratings and reviews
CREATE TABLE doctor_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_verified BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(doctor_id, patient_id, appointment_id)
);

-- Add trigger for updated_at timestamp
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON doctor_reviews
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- Add RLS policies for doctor_reviews table
ALTER TABLE doctor_reviews ENABLE ROW LEVEL SECURITY;

-- Patients can view all reviews
CREATE POLICY "Patients can view all reviews" ON doctor_reviews
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM patients WHERE id = auth.uid()
        )
    );

-- Doctors can view their own reviews
CREATE POLICY "Doctors can view their own reviews" ON doctor_reviews
    FOR SELECT USING (
        doctor_id = auth.uid()
    );

-- Patients can insert reviews
CREATE POLICY "Patients can insert reviews" ON doctor_reviews
    FOR INSERT WITH CHECK (
        auth.uid() = patient_id
    );

-- Patients can update their own reviews
CREATE POLICY "Patients can update their own reviews" ON doctor_reviews
    FOR UPDATE USING (
        auth.uid() = patient_id
    );

-- Admins can view all reviews
CREATE POLICY "Admins can view all reviews" ON doctor_reviews
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Admins can update any review
CREATE POLICY "Admins can update any review" ON doctor_reviews
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Create indexes for faster queries
CREATE INDEX idx_doctor_reviews_doctor_id ON doctor_reviews(doctor_id);
CREATE INDEX idx_doctor_reviews_patient_id ON doctor_reviews(patient_id);
CREATE INDEX idx_doctor_reviews_appointment_id ON doctor_reviews(appointment_id);
CREATE INDEX idx_doctor_reviews_rating ON doctor_reviews(rating);

-- Create function to update doctor rating
CREATE OR REPLACE FUNCTION update_doctor_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Calculate average rating for the doctor
    UPDATE doctors
    SET rating = (
        SELECT AVG(rating)::numeric(3,1)
        FROM doctor_reviews
        WHERE doctor_id = NEW.doctor_id
    )
    WHERE id = NEW.doctor_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update doctor rating on review insert/update/delete
CREATE TRIGGER update_doctor_rating_on_review_change
AFTER INSERT OR UPDATE OR DELETE ON doctor_reviews
FOR EACH ROW
EXECUTE PROCEDURE update_doctor_rating();
