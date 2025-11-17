-- Add snooze columns to todos table
-- Run this SQL in Supabase SQL Editor

ALTER TABLE todos
ADD COLUMN IF NOT EXISTS snooze_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_snooze_time TIMESTAMPTZ;

-- Add comments for documentation
COMMENT ON COLUMN todos.snooze_count IS 'Number of times the notification has been snoozed';
COMMENT ON COLUMN todos.last_snooze_time IS 'Timestamp of the last time the notification was snoozed';
