-- Add position column to todos table for drag and drop sorting
-- Migration: Add position column
-- Date: 2025-11-25

-- Add position column with default value 0
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS position INTEGER NOT NULL DEFAULT 0;

-- Create index for faster ordering queries
CREATE INDEX IF NOT EXISTS idx_todos_position ON todos(position);

-- Create index for category-based sorting (position within category)
CREATE INDEX IF NOT EXISTS idx_todos_category_position ON todos(category_id, position);

-- Update existing todos with position based on created_at (older = lower position)
WITH ranked_todos AS (
  SELECT id, ROW_NUMBER() OVER (PARTITION BY COALESCE(category_id, 0) ORDER BY created_at) - 1 AS new_position
  FROM todos
)
UPDATE todos
SET position = ranked_todos.new_position
FROM ranked_todos
WHERE todos.id = ranked_todos.id;

-- Add comment to the column
COMMENT ON COLUMN todos.position IS 'Order position for drag and drop sorting (per category, 0-indexed)';
