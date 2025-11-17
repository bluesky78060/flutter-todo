-- Subtasks Table Migration for Supabase
-- This script creates the subtasks table and sets up Row Level Security (RLS) policies

-- Create subtasks table
CREATE TABLE IF NOT EXISTS subtasks (
  id BIGSERIAL PRIMARY KEY,
  todo_id BIGINT NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(title) >= 1 AND char_length(title) <= 200),
  is_completed BOOLEAN NOT NULL DEFAULT false,
  position INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,

  -- Index for faster queries
  CONSTRAINT subtasks_position_check CHECK (position >= 0)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_subtasks_todo_id ON subtasks(todo_id);
CREATE INDEX IF NOT EXISTS idx_subtasks_user_id ON subtasks(user_id);
CREATE INDEX IF NOT EXISTS idx_subtasks_position ON subtasks(todo_id, position);

-- Enable Row Level Security
ALTER TABLE subtasks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view their own subtasks" ON subtasks;
DROP POLICY IF EXISTS "Users can create their own subtasks" ON subtasks;
DROP POLICY IF EXISTS "Users can update their own subtasks" ON subtasks;
DROP POLICY IF EXISTS "Users can delete their own subtasks" ON subtasks;

-- Create RLS policies

-- 1. SELECT: Users can only see subtasks of their own todos
CREATE POLICY "Users can view their own subtasks"
  ON subtasks FOR SELECT
  USING (auth.uid() = user_id);

-- 2. INSERT: Users can only create subtasks for their own todos
CREATE POLICY "Users can create their own subtasks"
  ON subtasks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 3. UPDATE: Users can only update their own subtasks
CREATE POLICY "Users can update their own subtasks"
  ON subtasks FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4. DELETE: Users can only delete their own subtasks
CREATE POLICY "Users can delete their own subtasks"
  ON subtasks FOR DELETE
  USING (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON subtasks TO authenticated;
GRANT ALL ON subtasks TO service_role;

-- Comments for documentation
COMMENT ON TABLE subtasks IS 'Subtasks are checklist items within a todo';
COMMENT ON COLUMN subtasks.id IS 'Unique identifier for the subtask';
COMMENT ON COLUMN subtasks.todo_id IS 'Reference to parent todo';
COMMENT ON COLUMN subtasks.user_id IS 'Owner of the subtask (must match parent todo owner)';
COMMENT ON COLUMN subtasks.title IS 'Subtask title/description';
COMMENT ON COLUMN subtasks.is_completed IS 'Whether the subtask is completed';
COMMENT ON COLUMN subtasks.position IS 'Order position within the todo (0-indexed)';
COMMENT ON COLUMN subtasks.created_at IS 'Timestamp when subtask was created';
COMMENT ON COLUMN subtasks.completed_at IS 'Timestamp when subtask was completed';
