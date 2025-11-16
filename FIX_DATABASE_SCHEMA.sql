-- ============================================
-- 데이터베이스 스키마 수정
-- Supabase SQL Editor에서 실행하세요
-- ============================================

-- 1. todos 테이블에 category_id 컬럼 추가
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL;

-- 2. 인덱스 생성 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_todos_category_id ON todos(category_id);

-- 3. 컬럼 확인
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'todos'
ORDER BY ordinal_position;
