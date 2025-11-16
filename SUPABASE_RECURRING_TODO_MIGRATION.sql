-- ============================================
-- Supabase Migration: Add Recurring Todo Support
-- Created: 2025-11-10
-- This SQL adds recurrence_rule and parent_recurring_todo_id columns
-- to enable recurring todo functionality
-- ============================================

-- 1. Add recurrence_rule column (stores RRULE format string)
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS recurrence_rule TEXT;

-- 2. Add parent_recurring_todo_id column (references parent recurring todo)
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS parent_recurring_todo_id BIGINT REFERENCES todos(id) ON DELETE CASCADE;

-- 3. Create index for performance optimization
CREATE INDEX IF NOT EXISTS idx_todos_parent_recurring_todo_id
ON todos(parent_recurring_todo_id);

CREATE INDEX IF NOT EXISTS idx_todos_recurrence_rule
ON todos(recurrence_rule);

-- 4. Add comment to explain columns
COMMENT ON COLUMN todos.recurrence_rule IS
'RRULE format string for recurring todos (e.g., "FREQ=DAILY;INTERVAL=1")';

COMMENT ON COLUMN todos.parent_recurring_todo_id IS
'Reference to the parent/master recurring todo. NULL for non-recurring or master todos.';

-- ============================================
-- RLS Policies Update
-- The existing RLS policies automatically apply to new columns
-- No additional policy changes needed as they use user_id for authorization
-- ============================================

-- Verify existing RLS policies still work with new columns
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'todos';

-- ============================================
-- Verification Queries
-- ============================================

-- 1. Verify columns were added successfully
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'todos'
AND column_name IN ('recurrence_rule', 'parent_recurring_todo_id')
ORDER BY ordinal_position;

-- 2. Verify indexes were created
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'todos'
AND indexname LIKE '%recurring%';

-- 3. Check for any existing data (should be empty before first use)
SELECT
    COUNT(*) as total_todos,
    COUNT(recurrence_rule) as todos_with_recurrence,
    COUNT(parent_recurring_todo_id) as todos_with_parent
FROM todos;

-- ============================================
-- Example Usage (for testing)
-- ============================================

-- Example 1: Create a daily recurring todo (master)
-- INSERT INTO todos (title, description, user_id, recurrence_rule, created_at)
-- VALUES (
--     'Daily standup meeting',
--     'Check team progress',
--     auth.uid()::text,
--     'FREQ=DAILY;INTERVAL=1',
--     NOW()
-- );

-- Example 2: Create a recurring todo instance (child)
-- INSERT INTO todos (title, description, user_id, parent_recurring_todo_id, due_date, created_at)
-- VALUES (
--     'Daily standup meeting',
--     'Check team progress',
--     auth.uid()::text,
--     <parent_todo_id>,
--     NOW() + INTERVAL '1 day',
--     NOW()
-- );

-- Example 3: Query all recurring todos
-- SELECT
--     id,
--     title,
--     recurrence_rule,
--     parent_recurring_todo_id,
--     created_at
-- FROM todos
-- WHERE recurrence_rule IS NOT NULL OR parent_recurring_todo_id IS NOT NULL;

-- ============================================
-- Rollback Instructions (if needed)
-- ============================================

-- CAUTION: This will delete all recurring todo data!
-- Only run if you need to completely remove recurring todo support

-- DROP INDEX IF EXISTS idx_todos_recurrence_rule;
-- DROP INDEX IF EXISTS idx_todos_parent_recurring_todo_id;
-- ALTER TABLE todos DROP COLUMN IF EXISTS parent_recurring_todo_id;
-- ALTER TABLE todos DROP COLUMN IF EXISTS recurrence_rule;
