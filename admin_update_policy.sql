-- Add RLS policy to allow admins to update doctor verification status
CREATE POLICY "Admins can update doctor verification status" ON doctors
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM admins WHERE id = auth.uid()
        )
    );
