-- Create admin_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.admin_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key TEXT NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add RLS policies
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

-- Policy for admins to read all settings
CREATE POLICY admin_read_all_settings ON public.admin_settings
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

-- Policy for non-admins to read only public settings
CREATE POLICY public_read_public_settings ON public.admin_settings
    FOR SELECT
    USING (
        is_public = TRUE
    );

-- Policy for admins to insert settings
CREATE POLICY admin_insert_settings ON public.admin_settings
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

-- Policy for admins to update settings
CREATE POLICY admin_update_settings ON public.admin_settings
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

-- Policy for admins to delete settings
CREATE POLICY admin_delete_settings ON public.admin_settings
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND user_type = 'admin'
        )
    );

-- Create function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_admin_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update the updated_at timestamp
CREATE TRIGGER update_admin_settings_updated_at
BEFORE UPDATE ON public.admin_settings
FOR EACH ROW
EXECUTE FUNCTION update_admin_settings_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_settings TO authenticated;
