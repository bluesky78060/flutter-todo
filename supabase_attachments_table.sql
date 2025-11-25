-- Create attachments table for todo file attachments
CREATE TABLE IF NOT EXISTS public.attachments (
  id BIGSERIAL PRIMARY KEY,
  todo_id BIGINT NOT NULL REFERENCES public.todos(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  mime_type TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS attachments_todo_id_idx ON public.attachments(todo_id);
CREATE INDEX IF NOT EXISTS attachments_user_id_idx ON public.attachments(user_id);

-- Enable Row Level Security
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for attachments
-- Users can view their own attachments
CREATE POLICY "Users can view their own attachments" ON public.attachments
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own attachments
CREATE POLICY "Users can insert their own attachments" ON public.attachments
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own attachments
CREATE POLICY "Users can update their own attachments" ON public.attachments
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own attachments
CREATE POLICY "Users can delete their own attachments" ON public.attachments
  FOR DELETE
  USING (auth.uid() = user_id);
