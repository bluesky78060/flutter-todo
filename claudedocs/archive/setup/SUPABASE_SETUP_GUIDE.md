# Supabase 설정 가이드

**작성일**: 2024-11-12
**앱 버전**: v1.0.8+20
**패키지**: kr.bluesky.dodo

## 목차

1. [개요](#개요)
2. [필수 전제조건](#필수-전제조건)
3. [데이터베이스 스키마 설정](#데이터베이스-스키마-설정)
4. [실행 순서](#실행-순서)
5. [검증 방법](#검증-방법)
6. [OAuth 설정](#oauth-설정)
7. [문제 해결](#문제-해결)

---

## 개요

이 가이드는 DoDo Todo 앱의 Supabase 백엔드를 처음부터 설정하는 방법을 단계별로 설명합니다.

### 필요한 테이블

1. **todos** - 할 일 항목
2. **categories** - 카테고리 (현재 로컬 DB만 사용, 향후 Supabase 동기화 가능)

### 필요한 컬럼 (todos 테이블)

| 컬럼명 | 타입 | 설명 | 추가 SQL 파일 |
|--------|------|------|---------------|
| `id` | BIGSERIAL | Primary key | 기본 스키마 |
| `user_id` | TEXT | Supabase UUID (auth.uid()) | 기본 스키마 |
| `title` | TEXT | 제목 | 기본 스키마 |
| `description` | TEXT | 설명 | 기본 스키마 |
| `is_completed` | BOOLEAN | 완료 여부 | 기본 스키마 |
| `created_at` | TIMESTAMPTZ | 생성 일시 | 기본 스키마 |
| `completed_at` | TIMESTAMPTZ | 완료 일시 | 기본 스키마 |
| `category_id` | INTEGER | 카테고리 FK | ✅ `FIX_DATABASE_SCHEMA.sql` |
| `due_date` | TIMESTAMPTZ | 마감일 | ✅ `supabase_migration_add_due_date.sql` |
| `notification_time` | TIMESTAMPTZ | 알림 시간 | ⚠️ 추가 필요 (아래 참조) |
| `recurrence_rule` | TEXT | 반복 규칙 (RRULE) | ✅ `SUPABASE_RECURRING_TODO_MIGRATION.sql` |
| `parent_recurring_todo_id` | BIGINT | 부모 반복 할 일 FK | ✅ `SUPABASE_RECURRING_TODO_MIGRATION.sql` |

---

## 필수 전제조건

1. **Supabase 프로젝트 생성**: [supabase.com](https://supabase.com)에서 프로젝트 생성
2. **SQL Editor 접근**: Dashboard → SQL Editor
3. **Auth 활성화**: Dashboard → Authentication → Providers
4. **Flutter 앱 설정**: `.env` 파일에 Supabase URL/Key 설정

---

## 데이터베이스 스키마 설정

### Step 1: 기본 테이블 생성

```sql
-- ============================================
-- 기본 Todos 테이블
-- ============================================
CREATE TABLE todos (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- ============================================
-- 기본 Categories 테이블 (선택사항)
-- 현재는 로컬 DB만 사용하지만, 향후 동기화를 위해 생성
-- ============================================
CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  icon TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Step 2: 카테고리 지원 추가

**파일**: [`FIX_DATABASE_SCHEMA.sql`](FIX_DATABASE_SCHEMA.sql)

```sql
-- 1. todos 테이블에 category_id 컬럼 추가
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL;

-- 2. 인덱스 생성 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_todos_category_id ON todos(category_id);
```

### Step 3: 마감일 지원 추가

**파일**: [`supabase_migration_add_due_date.sql`](supabase_migration_add_due_date.sql)

```sql
-- Add due_date column to todos table
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS due_date TIMESTAMPTZ;

COMMENT ON COLUMN todos.due_date IS 'Optional due date and time for the todo item';
```

### Step 4: 알림 시간 추가

**⚠️ 이 SQL은 별도 파일로 제공되지 않으므로 수동 실행 필요**

```sql
-- Add notification_time column to todos table
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS notification_time TIMESTAMPTZ;

COMMENT ON COLUMN todos.notification_time IS 'Optional notification time for reminders';

-- 인덱스 생성 (알림 조회 성능 향상)
CREATE INDEX IF NOT EXISTS idx_todos_notification_time ON todos(notification_time);
```

### Step 5: 반복 할 일 지원 추가

**파일**: [`SUPABASE_RECURRING_TODO_MIGRATION.sql`](SUPABASE_RECURRING_TODO_MIGRATION.sql)

```sql
-- 1. Add recurrence_rule column (stores RRULE format string)
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS recurrence_rule TEXT;

-- 2. Add parent_recurring_todo_id column (references parent recurring todo)
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS parent_recurring_todo_id BIGINT REFERENCES todos(id) ON DELETE CASCADE;

-- 3. Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_todos_parent_recurring_todo_id
ON todos(parent_recurring_todo_id);

CREATE INDEX IF NOT EXISTS idx_todos_recurrence_rule
ON todos(recurrence_rule);

-- 4. Add comments
COMMENT ON COLUMN todos.recurrence_rule IS
'RRULE format string for recurring todos (e.g., "FREQ=DAILY;INTERVAL=1")';

COMMENT ON COLUMN todos.parent_recurring_todo_id IS
'Reference to the parent/master recurring todo. NULL for non-recurring or master todos.';
```

### Step 6: RLS (Row Level Security) 정책 설정

**파일**: [`SUPABASE_RLS_POLICIES.sql`](SUPABASE_RLS_POLICIES.sql)

```sql
-- ============================================
-- Todos 테이블 RLS 정책
-- ============================================

-- 1. RLS 활성화
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- 2. SELECT 정책: 사용자는 자신의 todos만 조회 가능
CREATE POLICY "Users can view their own todos"
ON todos FOR SELECT
USING (auth.uid()::text = user_id);

-- 3. INSERT 정책: 사용자는 자신의 todos만 생성 가능
CREATE POLICY "Users can insert their own todos"
ON todos FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- 4. UPDATE 정책: 사용자는 자신의 todos만 수정 가능
CREATE POLICY "Users can update their own todos"
ON todos FOR UPDATE
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

-- 5. DELETE 정책: 사용자는 자신의 todos만 삭제 가능
CREATE POLICY "Users can delete their own todos"
ON todos FOR DELETE
USING (auth.uid()::text = user_id);

-- ============================================
-- Categories 테이블 RLS 정책 (선택사항)
-- ============================================

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own categories"
ON categories FOR SELECT
USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert their own categories"
ON categories FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own categories"
ON categories FOR UPDATE
USING (auth.uid()::text = user_id)
WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete their own categories"
ON categories FOR DELETE
USING (auth.uid()::text = user_id);
```

---

## 실행 순서

Supabase SQL Editor에서 다음 순서대로 실행하세요:

### 1단계: 기본 스키마
```sql
-- Step 1: 기본 테이블 생성 (위의 SQL 복사)
```

### 2단계: 컬럼 추가 (순서대로)
```bash
# 1. 카테고리 지원
FIX_DATABASE_SCHEMA.sql

# 2. 마감일 지원
supabase_migration_add_due_date.sql

# 3. 알림 시간 지원 (수동 실행)
-- ALTER TABLE todos ADD COLUMN IF NOT EXISTS notification_time TIMESTAMPTZ;
-- CREATE INDEX IF NOT EXISTS idx_todos_notification_time ON todos(notification_time);

# 4. 반복 할 일 지원
SUPABASE_RECURRING_TODO_MIGRATION.sql
```

### 3단계: RLS 정책
```bash
SUPABASE_RLS_POLICIES.sql
```

---

## 검증 방법

### 1. 테이블 구조 확인

```sql
-- Todos 테이블의 모든 컬럼 확인
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'todos'
ORDER BY ordinal_position;
```

**예상 결과** (12개 컬럼):
- id, user_id, title, description, is_completed, created_at, completed_at
- category_id, due_date, notification_time ✅
- recurrence_rule, parent_recurring_todo_id ✅

### 2. 인덱스 확인

```sql
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'todos';
```

**예상 결과**:
- Primary key (id)
- idx_todos_category_id ✅
- idx_todos_notification_time ✅
- idx_todos_recurrence_rule ✅
- idx_todos_parent_recurring_todo_id ✅

### 3. RLS 정책 확인

```sql
SELECT
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies
WHERE tablename IN ('todos', 'categories')
ORDER BY tablename, policyname;
```

**예상 결과** (각 테이블당 4개 정책):
- Users can view their own todos/categories (SELECT)
- Users can insert their own todos/categories (INSERT)
- Users can update their own todos/categories (UPDATE)
- Users can delete their own todos/categories (DELETE)

### 4. 테스트 데이터 삽입

```sql
-- 인증된 사용자로 테스트 (Supabase Dashboard에서 실행)
INSERT INTO todos (
    user_id,
    title,
    description,
    due_date,
    notification_time
) VALUES (
    auth.uid()::text,
    'Test Todo',
    'Testing Supabase schema',
    NOW() + INTERVAL '1 day',
    NOW() + INTERVAL '1 day' - INTERVAL '1 hour'
);

-- 데이터 확인
SELECT * FROM todos WHERE user_id = auth.uid()::text;
```

---

## OAuth 설정

### Google OAuth

1. **Google Cloud Console**: OAuth 2.0 클라이언트 ID 생성
2. **Supabase Dashboard**:
   - Authentication → Providers → Google
   - Client ID, Client Secret 입력
   - Redirect URLs 추가:
     - Web: `https://your-project.supabase.co/auth/v1/callback`
     - Mobile: `kr.bluesky.dodo://oauth-callback`

### Kakao OAuth

1. **Kakao Developers**: 앱 생성 및 REST API 키 발급
2. **Supabase Dashboard**:
   - Authentication → Providers → Kakao (Custom)
   - REST API Key 입력
   - Redirect URL: `https://your-project.supabase.co/auth/v1/callback`

### 앱 설정 확인

**AndroidManifest.xml** (이미 설정됨 ✅):
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="kr.bluesky.dodo"/>
</intent-filter>
```

**패키지 일관성** (확인 완료 ✅):
- namespace: `kr.bluesky.dodo` ([android/app/build.gradle.kts](android/app/build.gradle.kts#L19))
- applicationId: `kr.bluesky.dodo` ([android/app/build.gradle.kts](android/app/build.gradle.kts#L34))
- MainActivity: `kr.bluesky.dodo.MainActivity` ([android/app/src/main/kotlin/kr/bluesky/dodo/MainActivity.kt](android/app/src/main/kotlin/kr/bluesky/dodo/MainActivity.kt#L1))
- Deep link scheme: `kr.bluesky.dodo` ([android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L43))

---

## 문제 해결

### 문제 1: "permission denied for table todos"

**원인**: RLS 정책이 올바르게 설정되지 않음

**해결**:
```sql
-- RLS 정책 재설정
DROP POLICY IF EXISTS "Users can view their own todos" ON todos;
CREATE POLICY "Users can view their own todos"
ON todos FOR SELECT
USING (auth.uid()::text = user_id);
```

### 문제 2: "column notification_time does not exist"

**원인**: notification_time 컬럼이 추가되지 않음

**해결**:
```sql
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS notification_time TIMESTAMPTZ;
```

### 문제 3: "null value in column user_id violates not-null constraint"

**원인**: 인증되지 않은 상태에서 데이터 삽입 시도

**해결**:
1. Supabase Dashboard에서 테스트 유저 생성
2. Flutter 앱에서 로그인 후 시도
3. SQL Editor에서 `auth.uid()`가 null이 아닌지 확인

### 문제 4: 카테고리가 동기화되지 않음

**현재 상태**: 카테고리는 로컬 DB(Drift)만 사용

**향후 개선**:
- Supabase에 categories 테이블 생성 완료 ✅
- 앱 코드에서 Supabase 동기화 로직 추가 필요 (향후 작업)

---

## 완전한 스키마 요약

### 최종 todos 테이블 구조

```sql
CREATE TABLE todos (
    -- 기본 컬럼
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,

    -- 확장 컬럼
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    due_date TIMESTAMPTZ,
    notification_time TIMESTAMPTZ,
    recurrence_rule TEXT,
    parent_recurring_todo_id BIGINT REFERENCES todos(id) ON DELETE CASCADE
);

-- 인덱스
CREATE INDEX idx_todos_category_id ON todos(category_id);
CREATE INDEX idx_todos_notification_time ON todos(notification_time);
CREATE INDEX idx_todos_recurrence_rule ON todos(recurrence_rule);
CREATE INDEX idx_todos_parent_recurring_todo_id ON todos(parent_recurring_todo_id);
```

### 최종 categories 테이블 구조

```sql
CREATE TABLE categories (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    color TEXT NOT NULL,
    icon TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 참고 자료

- [Supabase Documentation](https://supabase.com/docs)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [RRULE Specification](https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.10)
- [Flutter Supabase Client](https://pub.dev/packages/supabase_flutter)

---

**최종 업데이트**: 2024-11-12
**작성자**: Claude Code (Supabase Setup Documentation)
