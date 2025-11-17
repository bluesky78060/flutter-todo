# Location-Based Notification Setup Guide

**Created**: 2025-11-17
**Status**: Phase 2 완료, 수동 설정 단계 남음

## 개요

위치 기반 알림 기능의 개발이 완료되었습니다. 이제 다음의 수동 설정 단계만 완료하면 기능을 사용할 수 있습니다.

## 완료된 작업 ✅

### Phase 1: Infrastructure (완료)
- ✅ Todo 엔티티에 위치 필드 추가
- ✅ Drift 데이터베이스 스키마 업데이트 (v6)
- ✅ LocationService 구현 (권한, GPS, 주소 변환)
- ✅ LocationPickerDialog 위젯 (Google Maps 통합)

### Phase 2: UI Integration (완료)
- ✅ Todo 폼에 위치 설정 기능 추가
- ✅ Todo 상세 화면에 위치 정보 표시
- ✅ Android 권한 설정 (AndroidManifest.xml)
- ✅ Google Maps API 키 환경변수 인프라 구축

## 남은 수동 설정 단계

### 1. Google Maps API 키 설정 🔑

#### 1.1 Google Cloud Console 설정

1. **Google Cloud Console 접속**
   - https://console.cloud.google.com/ 방문
   - 프로젝트 생성 또는 기존 프로젝트 선택

2. **Maps SDK for Android 활성화**
   - 왼쪽 메뉴: "APIs & Services" > "Library"
   - "Maps SDK for Android" 검색
   - "ENABLE" 클릭

3. **API 키 생성**
   - "APIs & Services" > "Credentials"
   - "CREATE CREDENTIALS" > "API key"
   - 생성된 키 복사 (예: `AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`)

4. **API 키 제한 설정 (보안 필수)**
   - 생성된 키 클릭 > "Edit API key"
   - **Application restrictions**:
     - "Android apps" 선택
     - "ADD AN ITEM" 클릭
     - Package name: `kr.bluesky.dodo`
     - SHA-1 fingerprint 추가 (아래 1.2 참조)
   - **API restrictions**:
     - "Restrict key" 선택
     - "Maps SDK for Android" 체크
   - "SAVE" 클릭

#### 1.2 SHA-1 Fingerprint 획득

**Debug 키스토어** (개발용):
```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android | grep SHA1
```

**Release 키스토어** (배포용):
```bash
# 업로드 키스토어 경로 확인
cat android/key.properties

# SHA-1 추출
keytool -list -v -keystore /path/to/upload-keystore.jks \
  -alias upload \
  -storepass <password> | grep SHA1
```

출력 예시:
```
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

#### 1.3 local.properties 파일 생성

1. **예시 파일 복사**:
```bash
cd /Users/leechanhee/todo_app/android
cp local.properties.example local.properties
```

2. **API 키 입력**:
```bash
# android/local.properties 파일 편집
nano local.properties
```

파일 내용:
```properties
# Flutter SDK 경로 (자동 생성됨 - 건드리지 마세요)
sdk.dir=/Users/leechanhee/Library/Android/sdk
flutter.sdk=/opt/homebrew/share/flutter

# Google Maps API Key (여기에 실제 키 입력)
MAPS_API_KEY=AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

3. **저장 및 확인**:
```bash
# .gitignore에 포함되었는지 확인 (절대 커밋하면 안 됨!)
cat ../.gitignore | grep local.properties
# 출력: android/local.properties
```

#### 1.4 빌드 및 테스트

```bash
# Clean build
flutter clean
flutter pub get

# Android 빌드 (API 키가 자동으로 주입됨)
flutter build apk --debug

# 디바이스에서 실행
flutter run -d <device-id>

# 앱에서 위치 설정 테스트:
# 1. 할 일 추가/수정 화면에서 "위치 설정" 클릭
# 2. 지도가 정상적으로 표시되는지 확인
# 3. 위치 선택 및 저장 테스트
```

#### 1.5 문제 해결

**지도가 회색 화면으로 표시되는 경우**:
- API 키가 올바르게 설정되었는지 확인
- SHA-1 fingerprint가 Google Cloud Console에 추가되었는지 확인
- Maps SDK for Android가 활성화되었는지 확인
- 빌드를 clean 후 다시 시도

**"Invalid API key" 오류**:
- local.properties의 API 키 확인
- Google Cloud Console에서 키 상태 확인
- 키 제한 설정이 올바른지 확인

**상세 가이드**: [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md) 참조

---

### 2. Supabase 데이터베이스 마이그레이션 🗄️

#### 2.1 마이그레이션 실행

1. **Supabase Dashboard 접속**
   - https://supabase.com/dashboard 로그인
   - 프로젝트 선택

2. **SQL Editor 열기**
   - 왼쪽 메뉴: "SQL Editor"
   - "New query" 클릭

3. **마이그레이션 SQL 실행**
   - 아래 파일 내용을 복사하여 붙여넣기:
   - 파일: `supabase_location_migration.sql`

```sql
-- Add location-based notification columns to todos table
ALTER TABLE todos
ADD COLUMN IF NOT EXISTS location_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location_name TEXT,
ADD COLUMN IF NOT EXISTS location_radius DOUBLE PRECISION;

-- Add indexes for location queries (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_todos_location ON todos(location_latitude, location_longitude)
WHERE location_latitude IS NOT NULL AND location_longitude IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN todos.location_latitude IS 'Latitude for location-based notifications';
COMMENT ON COLUMN todos.location_longitude IS 'Longitude for location-based notifications';
COMMENT ON COLUMN todos.location_name IS 'Human-readable location name (e.g., Home, Office)';
COMMENT ON COLUMN todos.location_radius IS 'Geofence radius in meters (default: 100m)';
```

4. **실행**
   - "RUN" 버튼 클릭
   - "Success. No rows returned" 메시지 확인

#### 2.2 마이그레이션 검증

**SQL Editor에서 확인**:
```sql
-- 테이블 스키마 확인
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'todos'
  AND column_name IN ('location_latitude', 'location_longitude', 'location_name', 'location_radius');
```

예상 결과:
```
location_latitude  | double precision | YES
location_longitude | double precision | YES
location_name      | text            | YES
location_radius    | double precision | YES
```

**인덱스 확인**:
```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'todos'
  AND indexname = 'idx_todos_location';
```

#### 2.3 앱에서 테스트

```bash
# 앱 실행
flutter run -d <device-id>

# 테스트 시나리오:
# 1. 위치가 설정된 할 일 생성
# 2. 앱 재시작 후 데이터 확인 (동기화 테스트)
# 3. 다른 기기에서 로그인하여 동기화 확인
```

**Supabase Dashboard에서 데이터 확인**:
- "Table Editor" > "todos" 테이블
- location_* 컬럼에 데이터가 저장되었는지 확인

---

## 설정 완료 후 기능 테스트

### 필수 테스트 체크리스트

- [ ] **Google Maps 표시**
  - [ ] 할 일 추가 시 "위치 설정" 버튼 클릭
  - [ ] 지도가 정상적으로 표시됨
  - [ ] 현재 위치 버튼(🎯)이 작동함
  - [ ] 지도 탭하여 위치 선택 가능

- [ ] **위치 정보 저장**
  - [ ] 위치 선택 후 "저장" 버튼 클릭
  - [ ] 할 일에 위치 정보가 표시됨
  - [ ] 할 일 상세 화면에 위치 이름/좌표 표시

- [ ] **Geofence 설정**
  - [ ] 반경 슬라이더 조정 (50m-1000m)
  - [ ] 지도에 원형 영역 표시됨
  - [ ] 저장 후 반경 정보 표시됨

- [ ] **클라우드 동기화**
  - [ ] 위치 정보가 Supabase에 저장됨
  - [ ] 앱 재시작 후 데이터 유지됨
  - [ ] 다른 기기에서 동기화 확인

- [ ] **권한 처리**
  - [ ] 위치 권한 요청 팝업 표시
  - [ ] 권한 거부 시 적절한 안내 메시지
  - [ ] 설정 앱으로 이동 가이드

### 디버깅 팁

**Android Logcat으로 로그 확인**:
```bash
# 위치 관련 로그 필터링
~/Library/Android/sdk/platform-tools/adb logcat | grep -E "(Location|Maps|GPS|Permission)"

# Flutter 앱 로그
~/Library/Android/sdk/platform-tools/adb logcat | grep "flutter"
```

**일반적인 문제**:
1. **지도 회색 화면**: API 키 또는 SHA-1 설정 확인
2. **권한 오류**: AndroidManifest.xml 권한 선언 확인
3. **동기화 안 됨**: Supabase 마이그레이션 실행 확인
4. **GPS 작동 안 함**: 디바이스 위치 서비스 활성화 확인

---

## 다음 단계 (향후 구현 예정)

### Phase 3: Geofencing Implementation (1-2일 소요)

현재는 UI만 구현되었으며, 실제 geofencing 백그라운드 모니터링은 아직 구현되지 않았습니다.

**예정 작업**:
- [ ] `geofence_service_flutter` 패키지 통합
- [ ] 백그라운드 위치 모니터링 서비스
- [ ] Geofence 진입/이탈 이벤트 처리
- [ ] 위치 도달 시 자동 알림 트리거
- [ ] 배터리 최적화 (geofence 수 제한, 적응형 폴링)
- [ ] iOS 위치 권한 설정 (Info.plist)

**참고**: 실제 위치 기반 알림을 받으려면 Phase 3 구현이 필요합니다.

---

## 참고 문서

- [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md) - Google Maps API 상세 가이드
- [FUTURE_TASKS.md](FUTURE_TASKS.md) - 전체 기능 로드맵
- [CLAUDE.md](CLAUDE.md) - 프로젝트 개발 가이드

## 문의 및 지원

설정 중 문제가 발생하면:
1. 이 문서의 "문제 해결" 섹션 확인
2. GOOGLE_MAPS_SETUP.md의 상세 가이드 참조
3. Android Logcat으로 오류 로그 확인
4. Supabase Dashboard에서 데이터 확인

---

**마지막 업데이트**: 2025-11-17
**작성자**: Claude Code Assistant
