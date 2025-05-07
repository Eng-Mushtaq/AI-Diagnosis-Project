-- Create video_calls table to store video call records
CREATE TABLE video_calls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    caller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    call_token TEXT NOT NULL,
    channel_name TEXT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    duration INTEGER, -- in seconds
    status TEXT NOT NULL DEFAULT 'initiated', -- 'initiated', 'connected', 'completed', 'missed', 'declined'
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add trigger for updated_at timestamp
CREATE TRIGGER set_timestamp
BEFORE UPDATE ON video_calls
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();

-- Add RLS policies for video_calls table
ALTER TABLE video_calls ENABLE ROW LEVEL SECURITY;

-- Users can view their own calls
CREATE POLICY "Users can view their own calls" ON video_calls
    FOR SELECT USING (
        auth.uid() = caller_id OR auth.uid() = receiver_id
    );

-- Users can insert calls they initiate
CREATE POLICY "Users can insert calls they initiate" ON video_calls
    FOR INSERT WITH CHECK (
        auth.uid() = caller_id
    );

-- Users can update calls they are part of
CREATE POLICY "Users can update calls they are part of" ON video_calls
    FOR UPDATE USING (
        auth.uid() = caller_id OR auth.uid() = receiver_id
    );

-- Admins can view all calls
CREATE POLICY "Admins can view all calls" ON video_calls
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );

-- Create indexes for faster queries
CREATE INDEX idx_video_calls_caller_id ON video_calls(caller_id);
CREATE INDEX idx_video_calls_receiver_id ON video_calls(receiver_id);
CREATE INDEX idx_video_calls_appointment_id ON video_calls(appointment_id);
CREATE INDEX idx_video_calls_status ON video_calls(status);
