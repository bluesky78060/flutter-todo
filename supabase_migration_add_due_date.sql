-- Add due_date column to todos table
-- Run this SQL in Supabase SQL Editor

ALTER TABLE todos
ADD COLUMN due_date TIMESTAMPTZ;

-- Add comment to the column
COMMENT ON COLUMN todos.due_date IS 'Optional due date and time for the todo item';
