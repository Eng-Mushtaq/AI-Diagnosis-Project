-- Add verification status to doctors table
ALTER TABLE doctors ADD COLUMN verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected'));
ALTER TABLE doctors ADD COLUMN rejection_reason TEXT;
ALTER TABLE doctors ADD COLUMN verification_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE doctors ADD COLUMN verified_by UUID REFERENCES users(id);

-- Create index for faster queries
CREATE INDEX idx_doctors_verification_status ON doctors(verification_status);

-- Add doctor verification documents table
CREATE TABLE doctor_verification_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL, -- e.g., 'license', 'degree', 'id'
    document_url TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add trigger for updated_at timestamp
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON doctor_verification_documents
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- Add RLS policies for doctor verification documents
ALTER TABLE doctor_verification_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Doctors can view their own verification documents" ON doctor_verification_documents
    FOR SELECT USING (auth.uid() = doctor_id);
CREATE POLICY "Admins can view all verification documents" ON doctor_verification_documents
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
CREATE POLICY "Doctors can insert their own verification documents" ON doctor_verification_documents
    FOR INSERT WITH CHECK (auth.uid() = doctor_id);
