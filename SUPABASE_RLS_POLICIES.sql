-- ============================================
-- Supabase RLS (Row Level Security) 정책
-- 이 SQL을 Supabase SQL Editor에서 실행하세요
-- ============================================

-- 1. Todos 테이블 RLS 활성화
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- 2. 기존 정책 삭제 (있다면)
DROP POLICY IF EXISTS "Users can view their own todos" ON todos;
DROP POLICY IF EXISTS "Users can insert their own todos" ON todos;
DROP POLICY IF EXISTS "Users can update their own todos" ON todos;
DROP POLICY IF EXISTS "Users can delete their own todos" ON todos;

-- 3. SELECT 정책: 사용자는 자신의 todos만 조회 가능
CREATE POLICY "Users can view their own todos"
ON todos FOR SELECT
USING (auth.uid()::text = user_id);

-- 4. INSERT 정책: 사용자는 자신의 todos만 생성 가능
CREATE POLICY "Users can insert their own todos"
ON todos FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- 5. UPDATE 정책: 사용자는 자신의 todos만 수정 가능
CREATE POLICY "Users can update their own todos"
ON todos FOR UPDATE
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- 6. DELETE 정책: 사용자는 자신의 todos만 삭제 가능
CREATE POLICY "Users can delete their own todos"
ON todos FOR DELETE
USING (auth.uid()::text = user_id);

-- ============================================
-- Categories 테이블 RLS 정책
-- ============================================

-- 1. Categories 테이블 RLS 활성화
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- 2. 기존 정책 삭제 (있다면)
DROP POLICY IF EXISTS "Users can view their own categories" ON categories;
DROP POLICY IF EXISTS "Users can insert their own categories" ON categories;
DROP POLICY IF EXISTS "Users can update their own categories" ON categories;
DROP POLICY IF EXISTS "Users can delete their own categories" ON categories;

-- 3. SELECT 정책
CREATE POLICY "Users can view their own categories"
ON categories FOR SELECT
USING (auth.uid()::text = user_id);

-- 4. INSERT 정책
CREATE POLICY "Users can insert their own categories"
ON categories FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- 5. UPDATE 정책
CREATE POLICY "Users can update their own categories"
ON categories FOR UPDATE
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- 6. DELETE 정책
CREATE POLICY "Users can delete their own categories"
ON categories FOR DELETE
USING (auth.uid()::text = user_id);

-- ============================================
-- 정책 확인
-- ============================================

-- Todos 테이블의 정책 확인
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'todos';

-- Categories 테이블의 정책 확인
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'categories';
