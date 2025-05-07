-- Create doctor_analytics table to store doctor dashboard analytics
CREATE TABLE doctor_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    appointments_count INTEGER DEFAULT 0,
    completed_appointments_count INTEGER DEFAULT 0,
    cancelled_appointments_count INTEGER DEFAULT 0,
    new_patients_count INTEGER DEFAULT 0,
    total_patients_count INTEGER DEFAULT 0,
    video_calls_count INTEGER DEFAULT 0,
    video_calls_duration INTEGER DEFAULT 0, -- in seconds
    chat_messages_count INTEGER DEFAULT 0,
    average_rating NUMERIC(3,1),
    reviews_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(doctor_id, date)
);

-- Add trigger for updated_at timestamp
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON doctor_analytics
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- Add RLS policies for doctor_analytics table
ALTER TABLE doctor_analytics ENABLE ROW LEVEL SECURITY;

-- Doctors can view their own analytics
CREATE POLICY "Doctors can view their own analytics" ON doctor_analytics
    FOR SELECT USING (
        auth.uid() = doctor_id
    );

-- Admins can view all analytics
CREATE POLICY "Admins can view all analytics" ON doctor_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Create indexes for faster queries
CREATE INDEX idx_doctor_analytics_doctor_id ON doctor_analytics(doctor_id);
CREATE INDEX idx_doctor_analytics_date ON doctor_analytics(date);

-- Create function to update doctor analytics daily
CREATE OR REPLACE FUNCTION update_doctor_analytics()
RETURNS VOID AS $$
DECLARE
    doctor_record RECORD;
    current_date DATE := CURRENT_DATE;
BEGIN
    -- Loop through all doctors
    FOR doctor_record IN SELECT id FROM doctors LOOP
        -- Check if analytics record exists for today
        IF NOT EXISTS (
            SELECT 1 FROM doctor_analytics 
            WHERE doctor_id = doctor_record.id AND date = current_date
        ) THEN
            -- Insert new analytics record
            INSERT INTO doctor_analytics (
                doctor_id,
                date,
                appointments_count,
                completed_appointments_count,
                cancelled_appointments_count,
                new_patients_count,
                total_patients_count,
                video_calls_count,
                video_calls_duration,
                chat_messages_count,
                average_rating,
                reviews_count
            )
            VALUES (
                doctor_record.id,
                current_date,
                (SELECT COUNT(*) FROM appointments WHERE doctor_id = doctor_record.id AND DATE(appointment_date) = current_date),
                (SELECT COUNT(*) FROM appointments WHERE doctor_id = doctor_record.id AND DATE(appointment_date) = current_date AND status = 'completed'),
                (SELECT COUNT(*) FROM appointments WHERE doctor_id = doctor_record.id AND DATE(appointment_date) = current_date AND status = 'cancelled'),
                (SELECT COUNT(*) FROM doctor_patients WHERE doctor_id = doctor_record.id AND DATE(created_at) = current_date),
                (SELECT COUNT(*) FROM doctor_patients WHERE doctor_id = doctor_record.id),
                (SELECT COUNT(*) FROM video_calls WHERE (caller_id = doctor_record.id OR receiver_id = doctor_record.id) AND DATE(created_at) = current_date),
                (SELECT COALESCE(SUM(duration), 0) FROM video_calls WHERE (caller_id = doctor_record.id OR receiver_id = doctor_record.id) AND DATE(created_at) = current_date),
                (SELECT COUNT(*) FROM messages WHERE (sender_id = doctor_record.id OR receiver_id = doctor_record.id) AND DATE(created_at) = current_date),
                (SELECT rating FROM doctors WHERE id = doctor_record.id),
                (SELECT COUNT(*) FROM doctor_reviews WHERE doctor_id = doctor_record.id)
            );
        ELSE
            -- Update existing analytics record
            UPDATE doctor_analytics
            SET
                appointments_count = (SELECT COUNT(*) FROM appointments WHERE doctor_id = doctor_record.id AND DATE(appointment_date) = current_date),
                completed_appointments_count = (SELECT COUNT(*) FROM appointments WHERE doctor_id = doctor_record.id AND DATE(appointment_date) = current_date AND status = 'completed'),
                cancelled_appointments_count = (SELECT COUNT(*) FROM appointments WHERE doctor_id = doctor_record.id AND DATE(appointment_date) = current_date AND status = 'cancelled'),
                new_patients_count = (SELECT COUNT(*) FROM doctor_patients WHERE doctor_id = doctor_record.id AND DATE(created_at) = current_date),
                total_patients_count = (SELECT COUNT(*) FROM doctor_patients WHERE doctor_id = doctor_record.id),
                video_calls_count = (SELECT COUNT(*) FROM video_calls WHERE (caller_id = doctor_record.id OR receiver_id = doctor_record.id) AND DATE(created_at) = current_date),
                video_calls_duration = (SELECT COALESCE(SUM(duration), 0) FROM video_calls WHERE (caller_id = doctor_record.id OR receiver_id = doctor_record.id) AND DATE(created_at) = current_date),
                chat_messages_count = (SELECT COUNT(*) FROM messages WHERE (sender_id = doctor_record.id OR receiver_id = doctor_record.id) AND DATE(created_at) = current_date),
                average_rating = (SELECT rating FROM doctors WHERE id = doctor_record.id),
                reviews_count = (SELECT COUNT(*) FROM doctor_reviews WHERE doctor_id = doctor_record.id)
            WHERE doctor_id = doctor_record.id AND date = current_date;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
