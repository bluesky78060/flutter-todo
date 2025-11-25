-- Migration: Add attachments support for todos
-- Date: 2025-11-25
-- Description: Creates attachments table, storage bucket, and RLS policies

-- Create attachments table
CREATE TABLE IF NOT EXISTS attachments (
  id BIGSERIAL PRIMARY KEY,
  todo_id BIGINT NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  storage_path TEXT NOT NULL, -- Full path in Supabase Storage
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_attachments_todo_id ON attachments(todo_id);
CREATE INDEX IF NOT EXISTS idx_attachments_user_id ON attachments(user_id);

-- Enable RLS
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own attachments
CREATE POLICY "Users can view their own attachments"
  ON attachments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own attachments"
  ON attachments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own attachments"
  ON attachments FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own attachments"
  ON attachments FOR DELETE
  USING (auth.uid() = user_id);

-- Create Storage Bucket (must be done manually in Supabase Dashboard or via SQL)
-- Bucket name: 'todo-attachments'
-- Public: false
-- File size limit: 10MB
-- Allowed MIME types: image/*, application/pdf, text/*, etc.

-- Storage RLS Policies (apply via Supabase Dashboard)
-- Policy: "Users can upload their own files"
-- INSERT: bucket_id = 'todo-attachments' AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy: "Users can view their own files"
-- SELECT: bucket_id = 'todo-attachments' AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy: "Users can update their own files"
-- UPDATE: bucket_id = 'todo-attachments' AND (storage.foldername(name))[1] = auth.uid()::text

-- Policy: "Users can delete their own files"
-- DELETE: bucket_id = 'todo-attachments' AND (storage.foldername(name))[1] = auth.uid()::text

-- Add comment to document the table
COMMENT ON TABLE attachments IS 'Stores metadata for files attached to todos. Actual files stored in Supabase Storage bucket "todo-attachments".';
COMMENT ON COLUMN attachments.storage_path IS 'Full path in Supabase Storage: {user_id}/{todo_id}/{filename}';
