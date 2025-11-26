# 🚀 DoDo 앱 릴리즈 노트

## 최신 버전 정보

| 항목 | 내용 |
|------|------|
| **버전** | 1.0.13 (빌드 39) |
| **릴리즈 날짜** | 2025년 11월 25일 |
| **상태** | ✅ Google Play에 배포됨 |
| **패키지명** | kr.bluesky.dodo |
| **플랫폼** | Android 6.0+, iOS 11.0+, Web |
| **앱 크기** | 51.2 MB (AAB) |

---

## v1.0.13+39 (2025-11-25)
### 🎯 드래그 앤 드롭 정렬 기능 및 관리자 대시보드 완성

### ✨ 신규 기능

#### 1️⃣ 드래그 앤 드롭 정렬 기능
- Todo 항목을 드래그로 순서 변경 가능
- 카테고리별 독립적인 정렬 지원
- 앱 재시작 후에도 순서 유지
- ReorderableListView를 이용한 직관적 UI

#### 2️⃣ 관리자 대시보드 (익명화된 통계)
- 사용자, Todo, 카테고리 통계
- 시간대별 활동 분석
- 요일별 완료율 분석
- Pull-to-refresh 지원

#### 3️⃣ 첨부파일 시스템 Phase 1
- Supabase Storage 버킷 생성
- 파일 업로드/다운로드 기능
- 이미지/PDF/텍스트 파일 뷰어

### 🔧 기술 구현

#### Position 필드 추가 (Drift + Supabase)
- todos 테이블에 position 컬럼 추가
- Supabase 마이그레이션 생성 (인덱스 포함)
- updateTodoPositions 메서드 구현

#### 관리자 권한 시스템
- Supabase RPC 함수 5개 생성 (SECURITY DEFINER)
- Flutter 관리자 권한 체크
- Settings 화면에 관리자 버튼 표시

### 📊 테스트 및 빌드
- ✅ 128개 테스트 통과 (CI/CD)
- ✅ position 파라미터 추가로 모든 테스트 통과
- AAB: 51.2 MB
- Google Play에 성공적으로 업로드

### 📝 수정된 파일
- `lib/domain/entities/todo.dart` (position 필드 추가)
- `lib/data/datasources/local/drift_todo_datasource.dart` (정렬 로직)
- `lib/presentation/screens/todo_list_screen.dart` (ReorderableListView 적용)
- `lib/presentation/screens/admin_dashboard_screen.dart` (신규)
- `android/app/src/main/kotlin/kr/bluesky/dodo/MainActivity.kt` (Method Channel 추가)
- `pubspec.yaml` (버전 1.0.13+39로 업데이트)

---

## v1.0.11+35 (2025-11-19)
### 📎 첨부파일 시스템 및 서브태스크 완전 구현

### ✨ 신규 기능

#### 첨부파일 시스템 (Phase 1-2 완료)
- Supabase Storage에 파일 저장
- 다양한 파일 형식 지원 (이미지, PDF, 텍스트, JSON)
- 파일 선택 UI (카메라, 갤러리, 파일 시스템)
- 이미지 뷰어 (확대/축소, 팬)
- PDF 뷰어 (Syncfusion PDF Viewer)
- 텍스트 파일 뷰어 (40+ 확장자)

#### 서브태스크 기능
- Subtask 엔티티 및 Repository
- Todo 상세 화면에서 서브태스크 CRUD
- 서브태스크 완료 상태 추적
- Supabase 동기화

#### 알림 스누즈 기능
- 5분/10분/30분/1시간/3시간 옵션
- 커스텀 시간 설정 가능
- SnoozeDialog UI

### 🔧 기술 개선
- Dual Repository Pattern (로컬 Drift + 원격 Supabase)
- 자동 업데이트 감지 및 동기화
- CI/CD 파이프라인 구축 (GitHub Actions, Codecov)
- 128개 테스트 자동 실행

---

## v1.0.10 (2025-11-18)
### 📍 위치 기반 알림 즉시 확인 기능 추가

#### 주요 기능
- 할 일 저장 시 자동으로 즉시 위치 확인
- 설정한 위치 범위 내에 있으면 즉시 알림 발송
- 백그라운드 주기적 확인 (15분 간격)
- 이중 알림 전략으로 높은 신뢰성 보장

---

## v1.0.9 (2025-11-14)
### 📱 Samsung 기기 알림 최적화

#### 주요 기능
- Samsung 기기 자동 감지 시스템
- One UI 버전 감지 및 표시
- 배터리 최적화 자동 우회
- 알림 전달률 개선 (60% → 95%+)

---

## v1.0.8 (2025-11-13)
### 🍎 Apple Sign In 및 다국어 지원 완성

#### 주요 기능
- Apple Sign In 구현 (iOS)
- 다국어 지원 완성 (한국어, 영어)
- 폰트 트리 셰이킹 최적화 (99.8% 감소)
- 에러 핸들링 인프라 강화

---

## v1.0.3 (2025-11-10)
### ✏️ 할 일 편집 기능 추가

#### 주요 기능
- TodoFormDialog 듀얼 모드 (Create/Edit)
- 기존 데이터 자동 입력
- 로컬 DB + Supabase 동시 업데이트
- 프로젝트 문서화 개선

---

## v1.0.0 (2025-11-06)
### 🎉 첫 번째 공식 릴리스

#### 구현된 기능
- ✅ 할 일 CRUD (생성/읽기/삭제/완료 토글)
- ✅ 로컬 알림 시스템
- ✅ 통계 및 차트
- ✅ Google/Kakao OAuth 로그인
- ✅ Supabase 클라우드 동기화
- ✅ 다크 모드 지원
- ✅ 한국어/영어 지원

---

## 기술 스택 🛠️

### Frontend
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **Icons**: Fluent UI System Icons

### 상태 관리 & 아키텍처
- **State Management**: Riverpod 3.x
- **Routing**: GoRouter 14.x
- **Models**: Freezed
- **Serialization**: JSON Serializable

### 데이터
- **Local DB**: Drift 2.x (SQLite)
- **Cloud**: Supabase
- **Auth**: Google OAuth, Kakao OAuth, Apple Sign In

### 부가 기능
- **Localization**: Easy Localization
- **Notifications**: Flutter Local Notifications
- **Date/Time**: Intl
- **Calendar**: Table Calendar
- **Recurrence**: RRULE

---

## 주요 특징 ⭐

### 🏗️ Clean Architecture
- Domain, Data, Presentation 계층 분리
- Repository 패턴 적용
- 의존성 주입 (Riverpod)

### 💾 하이브리드 저장소
- Drift (로컬 SQLite) - 오프라인 우선
- Supabase (클라우드) - 자동 동기화
- 다중 기기 데이터 동기화

### 🔐 보안
- OAuth 2.0 인증 (Google, Kakao, Apple)
- HTTPS 통신
- Supabase Row Level Security (RLS)
- 개인정보처리방침 준수

### 🎨 UI/UX
- Fluent Design 시스템
- 라이트/다크 모드 자동 전환
- 반응형 레이아웃
- 부드러운 애니메이션

### ⚡ 성능
- Riverpod 효율적 렌더링
- Drift 반응형 쿼리
- 99.8% 아이콘 폰트 최적화

---

## 개발자 정보

| 항목 | 내용 |
|------|------|
| 앱 이름 | DoDo (두두) |
| 개발자 | 이찬희 |
| 이메일 | bluesky78060@gmail.com |
| GitHub | https://github.com/bluesky78060 |
| 최소 SDK | Android 6.0 (API 23) |
| 타겟 SDK | Android 14 (API 34) |
| 서명 | SHA384withRSA (2048-bit) |
| 인증서 유효기간 | 2025-11-06 ~ 2053-03-24 |

---

## 라이선스

**Copyright © 2025 이찬희 (Lee Chan Hee). All rights reserved.**

DoDo 앱은 독점 소프트웨어입니다. 본 앱의 소스 코드, 디자인, 로고 및 기타 자산은 저작권법의 보호를 받습니다.

### 데이터 보안
- 모든 데이터는 HTTPS/TLS로 암호화되어 전송됩니다
- Supabase RLS로 사용자 간 데이터 격리
- 비밀번호는 해시 처리되어 저장됩니다

---

## 다음 계획 🚀

### Phase 2 (진행 중)
- 🚧 위치 기반 알림 (Phase 3-4 남음)
- 📋 통계 개선
- 👤 프로필 관리

### Phase 3 (예정)
- 테마 커스터마이징
- Todo 공유
- 타임 트래킹

### Phase 4 (향후)
- 팀 협업 기능
- 홈 화면 위젯
- 프리미엄 기능
- 추가 언어 지원

---

**DoDo와 함께 생산적인 하루를 만들어보세요!** 🎉
