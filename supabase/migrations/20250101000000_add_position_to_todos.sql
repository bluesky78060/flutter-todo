-- Migration: Add position column to todos table for drag-and-drop sorting
-- Date: 2025-01-01
-- Description: Adds position column with default value 0, independent sorting per category

-- Add position column to todos table
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS position INTEGER NOT NULL DEFAULT 0;

-- Create index for faster sorting queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_todos_position ON todos(position);
CREATE INDEX IF NOT EXISTS idx_todos_category_position ON todos(category_id, position);

-- Update existing todos to have sequential positions within each category
WITH numbered_todos AS (
  SELECT
    id,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(category_id, -1) ORDER BY created_at) - 1 AS new_position
  FROM todos
)
UPDATE todos
SET position = numbered_todos.new_position
FROM numbered_todos
WHERE todos.id = numbered_todos.id;

-- Add comment to document the column
COMMENT ON COLUMN todos.position IS 'Order position for drag-and-drop sorting within each category. Independent sorting per category.';
