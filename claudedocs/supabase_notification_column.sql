-- Supabase: Add notification_time column to todos table
-- Run this SQL in your Supabase SQL Editor if you get a database error

-- Check if column exists first
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'todos' 
        AND column_name = 'notification_time'
    ) THEN
        -- Add notification_time column
        ALTER TABLE todos ADD COLUMN notification_time TIMESTAMPTZ;
        
        RAISE NOTICE 'notification_time column added successfully';
    ELSE
        RAISE NOTICE 'notification_time column already exists';
    END IF;
END $$;

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'todos'
ORDER BY ordinal_position;
