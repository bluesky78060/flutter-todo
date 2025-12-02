-- Migration: Add priority column to todos table
-- Date: 2025-12-02
-- Description: Adds priority field (low/medium/high) to todos for notification and sorting support

-- Add priority column to todos table
ALTER TABLE todos ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'medium';

-- Add check constraint to ensure valid priority values
ALTER TABLE todos ADD CONSTRAINT todos_priority_check
  CHECK (priority IN ('low', 'medium', 'high'));

-- Create index for faster queries by priority
CREATE INDEX IF NOT EXISTS idx_todos_priority ON todos(priority);

-- Add comment to document the column
COMMENT ON COLUMN todos.priority IS 'Priority level for notification and sorting: low, medium, high. Default: medium';
