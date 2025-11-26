# 🗺️ Supabase 위치 기반 알림 테이블 설정 가이드

**목표**: Supabase에 위치 기반 알림 데이터를 저장하는 `location_settings` 테이블 생성
**예상 시간**: 5-10분
**상태**: 구현 준비 완료 ✅

---

## 📋 테이블 구조

### location_settings 테이블

위치 기반 알림 설정을 저장하는 테이블입니다. 각 Todo 항목에 하나의 위치 설정만 가능합니다.

**필드 명세**:

| 필드명 | 타입 | 필수 | 설명 | 예시 |
|--------|------|------|------|------|
| `id` | bigint | ✅ | 기본키 (자동증가) | 1, 2, 3 |
| `user_id` | uuid | ✅ | Supabase 사용자 ID (auth.users.id 참조) | `550e8400-e29b-41d4-a716-446655440000` |
| `todo_id` | bigint | ✅ | 참조 Todo ID (todos.id 참조) | 1, 2, 3 |
| `latitude` | numeric(10,8) | ✅ | 위치 위도 (소수점 8자리) | 37.497942 |
| `longitude` | numeric(11,8) | ✅ | 위치 경도 (소수점 8자리) | 127.027621 |
| `radius` | integer | ✅ | 반경 (미터, 100-2000) | 500, 1000, 2000 |
| `location_name` | text | ❌ | 위치 이름 (선택) | "회사", "집", "학교" |
| `geofence_state` | text | ✅ | 현재 상태 (outside/entering/inside/exiting) | "inside" |
| `triggered_at` | timestamptz | ❌ | 마지막 알림 시간 (중복 방지) | 2025-11-26T10:30:00Z |
| `created_at` | timestamptz | ✅ | 생성 시간 (기본값: now()) | 2025-11-26T10:00:00Z |
| `updated_at` | timestamptz | ✅ | 수정 시간 (기본값: now()) | 2025-11-26T10:15:00Z |

---

## 🔧 SQL DDL (테이블 생성)

### 1️⃣ location_settings 테이블 생성

```sql
-- location_settings 테이블 생성
CREATE TABLE IF NOT EXISTS location_settings (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  todo_id BIGINT NOT NULL REFERENCES todos(id) ON DELETE CASCADE,
  latitude NUMERIC(10, 8) NOT NULL,
  longitude NUMERIC(11, 8) NOT NULL,
  radius INTEGER NOT NULL CHECK (radius >= 100 AND radius <= 2000),
  location_name TEXT,
  geofence_state TEXT NOT NULL DEFAULT 'outside' CHECK (geofence_state IN ('outside', 'entering', 'inside', 'exiting')),
  triggered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, todo_id)
);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX idx_location_settings_user_id ON location_settings(user_id);
CREATE INDEX idx_location_settings_todo_id ON location_settings(todo_id);
CREATE INDEX idx_location_settings_geofence_state ON location_settings(geofence_state);

-- 자동 updated_at 업데이트 함수 및 트리거
CREATE OR REPLACE FUNCTION update_location_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_location_settings_updated_at
BEFORE UPDATE ON location_settings
FOR EACH ROW
EXECUTE FUNCTION update_location_settings_updated_at();
```

---

## 🔐 Row Level Security (RLS) 정책

### 보안 규칙

사용자는 자신의 데이터만 CRUD 가능합니다.

```sql
-- RLS 활성화
ALTER TABLE location_settings ENABLE ROW LEVEL SECURITY;

-- 정책 1: SELECT - 자신의 위치 설정만 조회
CREATE POLICY "Users can SELECT their own location_settings"
  ON location_settings
  FOR SELECT
  USING (auth.uid() = user_id);

-- 정책 2: INSERT - 자신의 위치 설정만 생성
CREATE POLICY "Users can INSERT their own location_settings"
  ON location_settings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 정책 3: UPDATE - 자신의 위치 설정만 수정
CREATE POLICY "Users can UPDATE their own location_settings"
  ON location_settings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 정책 4: DELETE - 자신의 위치 설정만 삭제
CREATE POLICY "Users can DELETE their own location_settings"
  ON location_settings
  FOR DELETE
  USING (auth.uid() = user_id);
```

---

## 📱 todos 테이블 마이그레이션 (선택사항)

위치 기반 알림 활성화 여부를 todos 테이블에 추가하려면:

```sql
-- has_location_reminder 컬럼 추가 (기존 테이블에)
ALTER TABLE todos 
ADD COLUMN IF NOT EXISTS has_location_reminder BOOLEAN DEFAULT false;

-- 인덱스 생성
CREATE INDEX idx_todos_has_location_reminder ON todos(has_location_reminder);
```

---

## 🚀 Supabase Dashboard 설정 단계

### Step 1️⃣: SQL Editor 접근

1. [Supabase Dashboard](https://app.supabase.com) 열기
2. 프로젝트 선택 (`bulwfcsyqgsvmbadhlye`)
3. 좌측 메뉴 → **SQL Editor** 클릭
4. **New Query** 클릭

### Step 2️⃣: DDL 실행

1. **위의 "SQL DDL (테이블 생성)" 섹션 전체 복사**
2. SQL Editor에 붙여넣기
3. **▶️ Run** 버튼 클릭
4. 결과 확인: `success` 메시지 표시되어야 함

```
✅ Query executed successfully
Rows: 0
Duration: 45ms
```

### Step 3️⃣: RLS 정책 실행

1. **"Row Level Security (RLS) 정책" 섹션 전체 복사**
2. 새 SQL Query 만들기 (또는 기존 쿼리 clear)
3. RLS 정책 코드 붙여넣기
4. **▶️ Run** 클릭

### Step 4️⃣: 테이블 확인

1. 좌측 메뉴 → **Table Editor** 클릭
2. 테이블 목록에서 `location_settings` 확인
3. 구조 확인:
   - 열: id, user_id, todo_id, latitude, longitude, radius, location_name, geofence_state, triggered_at, created_at, updated_at
   - RLS: Enabled ✅
   - 4개 정책 활성화됨

---

## ✅ 검증 쿼리

테이블이 제대로 생성되었는지 확인하려면:

### 1️⃣ 테이블 구조 확인

```sql
-- information_schema를 이용한 테이블 구조 확인
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'location_settings'
ORDER BY ordinal_position;
```

**예상 결과**:
```
column_name       | data_type      | is_nullable | column_default
------------------+----------------+-------------+-------------------
id                | bigint         | NO          | nextval(...)
user_id           | uuid           | NO          |
todo_id           | bigint         | NO          |
latitude          | numeric        | NO          |
longitude         | numeric        | NO          |
radius            | integer        | NO          |
location_name     | text           | YES         |
geofence_state    | text           | NO          | 'outside'::text
triggered_at      | timestamptz    | YES         |
created_at        | timestamptz    | NO          | now()
updated_at        | timestamptz    | NO          | now()
```

### 2️⃣ 인덱스 확인

```sql
-- 생성된 인덱스 확인
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'location_settings'
ORDER BY indexname;
```

**예상 결과**:
```
indexname                               | indexdef
----------------------------------------+-----------------------------------
idx_location_settings_geofence_state    | CREATE INDEX idx_location_settings_geofence_state...
idx_location_settings_todo_id           | CREATE INDEX idx_location_settings_todo_id...
idx_location_settings_user_id           | CREATE INDEX idx_location_settings_user_id...
location_settings_pkey                  | CREATE UNIQUE INDEX location_settings_pkey...
location_settings_user_id_todo_id_key   | CREATE UNIQUE INDEX location_settings_user_id_todo_id_key...
```

### 3️⃣ RLS 정책 확인

```sql
-- 활성화된 RLS 정책 확인
SELECT 
  tablename,
  policyname,
  permissive,
  roles,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'location_settings'
ORDER BY policyname;
```

**예상 결과**: 4개 정책 (SELECT, INSERT, UPDATE, DELETE)

### 4️⃣ 트리거 확인

```sql
-- 생성된 트리거 확인
SELECT 
  trigger_name,
  event_manipulation,
  event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'location_settings';
```

**예상 결과**:
```
trigger_name                      | event_manipulation | event_object_table
----------------------------------+--------------------+--------------------
trigger_location_settings_updated_at | UPDATE             | location_settings
```

---

## 🧪 테스트 데이터 삽입

테이블이 정상 작동하는지 확인하려면 테스트 데이터를 삽입:

### Step 1️⃣: 테스트용 SQL 작성

```sql
-- 테스트 데이터 삽입 (실제 user_id와 todo_id 필요)
-- 아래에서 YOUR_USER_ID와 YOUR_TODO_ID를 실제 값으로 바꾸세요

INSERT INTO location_settings (
  user_id,
  todo_id,
  latitude,
  longitude,
  radius,
  location_name,
  geofence_state
) VALUES (
  'YOUR_USER_ID',     -- 실제 사용자 UUID
  1,                  -- 실제 todo id
  37.497942,          -- 예: 경복궁 위도
  127.027621,         -- 예: 경복궁 경도
  500,                -- 반경 500미터
  '경복궁',           -- 위치 이름
  'outside'           -- 초기 상태
)
RETURNING *;
```

### Step 2️⃣: 실제 user_id 찾기

```sql
-- 현재 로그인한 사용자 ID 확인
SELECT auth.uid();

-- 모든 사용자 목록 확인 (선택사항)
SELECT id, email, created_at FROM auth.users LIMIT 5;
```

### Step 3️⃣: 모든 데이터 조회

```sql
SELECT * FROM location_settings;
```

### Step 4️⃣: 특정 사용자의 위치 설정 조회

```sql
SELECT 
  id,
  todo_id,
  latitude,
  longitude,
  radius,
  location_name,
  geofence_state,
  created_at
FROM location_settings
WHERE user_id = 'YOUR_USER_ID'
ORDER BY created_at DESC;
```

---

## 🔄 데이터 동기화 전략

### 로컬 Drift ↔ 클라우드 Supabase 동기화

```dart
// Dart/Flutter에서의 사용 예시 (참고용)

// 1️⃣ 로컬에 저장 (오프라인 지원)
final locationSetting = LocationSettingsCompanion(
  todoId: Value(todoId),
  latitude: Value(latitude),
  longitude: Value(longitude),
  radius: Value(radius),
  locationName: Value(locationName),
  geofenceState: Value('outside'),
);
await _localDb.into(_localDb.locationSettings).insert(locationSetting);

// 2️⃣ 클라우드에 동기화
await _supabaseClient
  .from('location_settings')
  .insert({
    'user_id': userId,
    'todo_id': todoId,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'location_name': locationName,
    'geofence_state': 'outside',
  });

// 3️⃣ 실시간 업데이트 리슨 (Realtime 구독)
final subscription = _supabaseClient
  .from('location_settings')
  .on(RealtimeListenTypes.all, PostgresChangeFilter(
    event: '*',
    schema: 'public',
    table: 'location_settings',
    filter: 'user_id=eq.$userId',
  ))
  .subscribe((payload) {
    // 변경사항 감지 → 로컬 DB 업데이트
  });
```

---

## 📊 성능 최적화 팁

### 인덱스 사용 권장

```sql
-- 자주 사용하는 쿼리들:

-- 1️⃣ 사용자의 모든 위치 설정 조회 (매우 자주)
SELECT * FROM location_settings 
WHERE user_id = 'USER_ID'
  AND geofence_state IN ('inside', 'entering');

-- 2️⃣ 특정 Todo의 위치 설정 조회
SELECT * FROM location_settings 
WHERE todo_id = TODO_ID;

-- 3️⃣ 활성 위치 알림 조회 (백그라운드 작업용)
SELECT * FROM location_settings 
WHERE user_id = 'USER_ID' 
  AND geofence_state != 'outside'
  AND (triggered_at IS NULL OR triggered_at < NOW() - INTERVAL '24 hours');
```

**이미 생성된 인덱스**: ✅ 위 쿼리들 최적화됨

---

## ⚠️ 주의사항

### 1️⃣ Radius 제약

- 최소: 100미터
- 최대: 2,000미터 (배터리 보호)
- 위반 시: CHECK 제약으로 자동 거부

### 2️⃣ Unique 제약

- 한 Todo마다 위치 설정은 **최대 1개만** 가능
- 충돌 시: "duplicate key value violates unique constraint"
- 기존 설정 수정하려면: UPDATE 사용 (INSERT 아님)

### 3️⃣ 외래키 참조

- `user_id` 삭제 → 해당 위치 설정 모두 삭제 (CASCADE)
- `todo_id` 삭제 → 해당 위치 설정 삭제 (CASCADE)

### 4️⃣ RLS 활성화

- RLS가 활성화되면 **인증된 사용자만** 데이터 접근 가능
- 서비스 롤로 모든 데이터 조회할 수 없음
- Supabase 대시보드에서는 RLS 무시하고 모든 데이터 볼 수 있음

---

## 🐛 문제 해결

### "permission denied for schema public"

**원인**: RLS 정책이 제대로 설정되지 않음

**해결**:
```sql
-- 현재 user 확인
SELECT current_user;

-- RLS 상태 확인
SELECT * FROM pg_tables 
WHERE tablename = 'location_settings';

-- RLS 비활성화 후 다시 활성화
ALTER TABLE location_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE location_settings ENABLE ROW LEVEL SECURITY;
```

### "duplicate key value violates unique constraint"

**원인**: 같은 Todo에 위치 설정이 이미 존재함

**해결**:
```sql
-- 기존 설정 삭제 후 새로 INSERT
DELETE FROM location_settings 
WHERE user_id = 'USER_ID' AND todo_id = TODO_ID;

-- 또는 UPDATE 사용
UPDATE location_settings SET
  latitude = NEW_LAT,
  longitude = NEW_LON,
  radius = NEW_RADIUS
WHERE user_id = 'USER_ID' AND todo_id = TODO_ID;
```

### "value too long for type character varying"

**원인**: 필드 길이 초과

**해결**: 필드 길이 확인:
- `location_name`: 제한 없음 (text 타입)
- `geofence_state`: 'outside', 'entering', 'inside', 'exiting' 중 하나만

---

## 📝 체크리스트

- [ ] Step 1: SQL Editor 접근
- [ ] Step 2: DDL 실행 및 확인 (✅ success)
- [ ] Step 3: RLS 정책 실행 및 확인
- [ ] Step 4: Table Editor에서 location_settings 확인
- [ ] 검증 쿼리 1-4 실행하여 결과 확인
- [ ] 테스트 데이터 삽입 및 조회 확인
- [ ] Dart 코드에서 Supabase 클라이언트로 데이터 접근 테스트
- [ ] 오프라인 모드에서 로컬 Drift DB에 데이터 저장 확인
- [ ] 온라인 복귀 시 클라우드 동기화 확인

---

## 🎯 다음 단계

1. ✅ **Supabase location_settings 테이블 생성** (이 파일)
2. 🔄 **Flutter 앱에서 SupabaseLocationRepository 구현**
3. 🔄 **로컬/클라우드 동기화 로직 구현**
4. 🔄 **GeofenceWorkManagerService에 클라우드 업데이트 통합**
5. 🔄 **실기기 테스트 (Android + iOS)**

---

**생성**: 2025년 11월 26일
**상태**: ✅ Supabase 스키마 설정 완료, 앱 통합 대기 중

