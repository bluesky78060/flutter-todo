# 향후 추가 기능 및 개선 사항

현재 버전: **1.0.14+42** (Google Play 배포됨)
최종 업데이트: **2025-11-27**

## 우선순위 분류
- 🔴 **High**: 핵심 기능, 사용자 경험에 직접적 영향
- 🟡 **Medium**: 편의성 향상, 부가 기능
- 🟢 **Low**: Nice-to-have, 장기적 개선

---

## ✅ 완료된 작업 (Completed)

### 2025-11-27
- ✅ **오프라인 모드 개선** (2.2)
  - 네트워크 연결 상태 감지 서비스 구현 (connectivity_plus)
  - 오프라인 상태 UI 배너 (OfflineBanner) 추가
  - 동기화 상태 표시 (마지막 동기화 시간, SyncStatusIndicator)
  - 동기화 실패 시 재시도 로직 구현 (점진적 지연: 5s, 15s, 30s, 최대 3회)
  - 연결 상태 위젯 (ConnectionStatusWidget) 앱바에 통합
  - TodoActions에 동기화 콜백 통합 (createTodo, updateTodo, deleteTodo, toggleCompletion)
  - 한국어/영어 번역 키 추가 (offline_mode, sync_failed 등)
  - Riverpod 3.x Notifier 패턴 적용

### 2025-11-25
- ✅ **첨부파일 시스템 완전 구현** (1.5)
  - Supabase Storage setup with `todo-attachments` bucket
  - Row-Level Security (RLS) policies for file access control
  - File upload/download functionality (images, PDFs, text files, JSON, etc.)
  - File picker integration (camera, gallery, file system)
  - Image viewer with zoom and pan (InteractiveViewer)
  - PDF viewer with Syncfusion PDF Viewer (zoom, text selection)
  - Text file viewer supporting 40+ file extensions
  - JSON file upload support (MIME type mapping workaround)
  - Attachment metadata storage (local Drift + remote Supabase)
  - Attachment display in todo detail screen (grid view with icons)
  - File size formatting and display
  - Automatic attachment deletion when todo is deleted
  - Dual Repository Pattern: Local (Drift) + Remote (Supabase)
  - Storage Path Structure: `{userId}/{todoId}/{timestamp}_{filename}`
  - 15개 파일 생성, 6개 파일 수정
  - 참고 문서: `SUPABASE_STORAGE_SETUP.md`, `TASKS.md`
- ✅ **드래그 앤 드롭 정렬 기능 구현**
  - Todo 항목 드래그로 순서 변경 가능
  - position 필드 추가 (Supabase + Drift)
  - Supabase 마이그레이션 생성 (인덱스 포함)
  - ReorderableListView 적용 (드래그 핸들 포함)
  - 카테고리별 독립 정렬 지원
  - 앱 재시작 후에도 순서 유지
  - updateTodoPositions 메서드 구현 (로컬 + 원격)
  - Todo 편집 시 position 값 보존
  - 반복 Todo 그룹 순서 변경 지원
  - 버전 1.0.13+39 AAB 빌드 및 배포
- ✅ **테스트 수정**
  - todo_repository_impl_test.dart: position 파라미터 추가 (4개 인스턴스)
  - category_repository_impl_test.dart: position 파라미터 추가 (2개 인스턴스)
  - CI/CD 테스트 통과 (128개 테스트 성공)
- ✅ **Google Play 업로드 키 재설정 및 배포** (14.1)
  - 새 업로드 키스토어 생성 및 PEM 인증서 생성
  - Google Play Console 재설정 요청 승인 완료
  - 버전 1.0.13+39까지 성공적으로 업로드
  - 드래그 앤 드롭 기능 포함된 최신 버전 배포
- ✅ **관리자 대시보드 구현** (13.1)
  - 익명화된 통계 전용 대시보드 완성
  - 5개 Supabase RPC 함수 생성 (SECURITY DEFINER)
  - Flutter 관리자 권한 체크 시스템 구현
  - Settings 화면에 관리자만 버튼 표시
  - 권한 없는 사용자 접근 차단 기능
  - 통계 데이터: 사용자, Todo, 카테고리, 시간대별 활동, 요일별 완료율
  - Pull-to-refresh 지원
  - 7개 요일 모두 표시 (데이터 없는 요일 포함)
  - Type casting 오류 수정 (int → double 변환)

### 2025-11-24
- ✅ **Flutter Web OAuth 로그인 수정**
  - OAuth 401 에러 해결 (Supabase Anon Key 갱신)
  - Hash routing 지원 추가 (`#/oauth-callback`)
  - Platform-specific config 구현 (conditional imports)
  - `window.ENV` 읽기 기능 구현 (`dart:js_util`)
  - Google/Kakao OAuth 로그인 정상 작동
- ✅ **Flutter Web 주소 검색 수정** (Naver → Google Geocoding)
  - Web CORS 에러 해결 (Supabase Edge Function 사용)
  - Google Maps Geocoding API 통합
  - Edge Function: `google-geocode/index.ts` 생성
  - 주소 검색 정상 작동 ("문단길 15" 등)
  - 배포 환경(GitHub Pages) 전체 테스트 통과
- ✅ **Supabase Configuration 개선**
  - Conditional imports로 web/non-web 분리
  - `supabase_config_web.dart`: `window.ENV` 읽기
  - `supabase_config_stub.dart`: 플랫폼 stub
  - GitHub Secrets `APP_SUPABASE_*` prefix 사용
- ✅ **배포 파이프라인 수정**
  - GitHub Actions workflow 수정 (환경변수 주입)
  - `scripts/inject_env.sh` 업데이트
  - `scripts/validate_supabase_key.sh` 생성 (로컬 검증)
- ✅ **기술 문서 작성**
  - `TECHNICAL_REPORT_WEB_OAUTH_GEOCODING_FIX.md` (500+ 줄)
  - OAuth/Geocoding 문제 상세 분석
  - 솔루션 구현 가이드
  - 향후 개선 방안 제시

### 2025-11-19
- ✅ **주소 검색 API 전환** (Naver Geocoding → Google Geocoding)
  - Naver Geocoding API 모바일 앱 401 에러 해결
  - Google Geocoding (geocoding 패키지) 사용으로 전환
  - Naver Reverse Geocoding 추가 (좌표 → 한국어 주소)
  - 5단계 검색 전략 구현 (fallback 패턴)
  - 실제 디바이스 및 에뮬레이터에서 정상 작동 확인
- ✅ **위치 기반 Todo 주소 검색 완전 작동**
  - 주소 검색 ("문단길15" 등) 정상 작동 확인
  - 5단계 검색 전략:
    1. Naver Local Search - 일반 키워드 검색 (장소명, 업체명)
    2. Naver Local Search - 주소 형식 검색 (지번, 도로명 주소)
    3. Naver Local Search - 유사 주소 검색 (공백 제거)
    4. Google Geocoding - 주소 → 좌표 변환 (일반 주소)
    5. Naver Reverse Geocoding - 좌표 → 한국어 주소 변환
  - 에러 핸들링 및 로깅 완비
  - API 인증 문제 완전 해결
- ✅ **국제화(i18n) 번역 키 추가**
  - 하드코딩된 한글 텍스트용 번역 키 추가 (40개 이상)
  - 에러 메시지, UI 레이블, 알림 텍스트 등
  - 향후 완전한 다국어 지원을 위한 준비 작업

### 2025-11-18
- ✅ **Naver Maps 통합 완료** (Google Maps → Naver Maps 마이그레이션)
  - 지도 API 전환, 주소 역지오코딩, 위치 검색
- ✅ **카테고리 Supabase 동기화 구현** (앱 재설치 후 데이터 복원)
  - `getCategories()` 시 Supabase에서 자동 동기화
  - 로컬 DB 없어도 클라우드에서 복원

### 2025-11-17
- ✅ **서브태스크 기능 완전 구현** (1.4)
  - Subtask 엔티티, Repository, Provider
  - Todo 상세 화면에 서브태스크 CRUD
  - Supabase 마이그레이션 SQL
- ✅ **알림 스누즈 기능 완전 구현** (3.1)
  - SnoozeDialog, NotificationService 통합
  - 5분/10분/30분/1시간/3시간 + 커스텀
- ✅ **GitHub Actions 테스트 수정**
  - Widget test 번역 의존성 제거
  - 128개 테스트 통과
- ✅ **Google Play 업로드 키 재설정 요청** (14.1)
  - AAB 빌드 1.0.11+35

### 2025-11-13
- ✅ **CI/CD 파이프라인 구축** (12.1)
  - GitHub Actions, Codecov 통합
- ✅ **통합 테스트 추가** (9.2)
  - TodoActions CRUD 통합 테스트 (9개)
  - 총 137개 테스트, 18-19% 커버리지
- ✅ **백업 및 복원 기능** (2.1)
  - JSON 백업/복원, share_plus 통합
- ✅ **검색 기능** (4.1)
  - 실시간 검색, debounce 적용
- ✅ **Apple 로그인** (7.1)
  - iOS OAuth 연동
- ✅ **에러 로깅** (8.1)
  - ErrorHandler, Failure 클래스 계층 구조

### 2025-11-10 이전
- ✅ **Todo 편집 기능** (1.1)
  - Todo 수정 다이얼로그, 로컬/Supabase 동시 업데이트
- ✅ **반복 Todo (Recurring Tasks)** (1.3)
  - RRULE 형식, 반복 설정 UI
  - RecurringTodoService, RecurrenceSettingsDialog

---

## 🚧 진행 중 작업 (In Progress)

**현재**: 없음 - 모든 주요 기능 완료됨

---

## 📋 향후 작업 (Upcoming Tasks) - Phase 3, 4

### ✅ 완료된 핵심 기능

#### ✅ 1.5 첨부파일 지원 (완료 - 2025-11-25)
**설명**: Todo에 이미지, 문서 파일 첨부
**완료된 작업**:
- ✅ Supabase Storage 버킷 생성 및 RLS 설정
- ✅ 파일 선택 UI (`image_picker`, `file_picker`)
- ✅ 파일 업로드/다운로드 로직
- ✅ 첨부파일 썸네일 표시 (그리드 뷰, 아이콘)
- ✅ Todo 삭제 시 첨부파일 자동 삭제
- ✅ 이미지/PDF/텍스트 파일 뷰어 구현

**향후 개선사항**:
- [ ] 파일 크기 제한 (10MB) 구현
- [ ] 첨부파일 개수 제한 (5-10개) 구현
- [ ] 개별 파일 삭제 UI
- [ ] 다운로드 버튼 추가
- [ ] 웹 플랫폼 파일 업로드 지원
- [ ] 비디오 뷰어
- [ ] 오디오 플레이어

**참고 문서**: `TASKS.md`, `SUPABASE_STORAGE_SETUP.md`

---

### 2. 데이터 관리 및 동기화

#### ✅ 2.2 오프라인 모드 개선 (완료 - 2025-11-27)
- [x] 오프라인 상태 감지 UI (OfflineBanner)
- [x] 동기화 상태 표시 (마지막 동기화 시간)
- [x] 자동 재시도 로직 (점진적 지연: 5s → 15s → 30s)
- [x] 앱바 연결 상태 위젯 (ConnectionStatusWidget)
- [ ] 동기화 충돌 해결 전략 (향후 과제)

**생성 파일**: connectivity_service.dart, connectivity_provider.dart, offline_banner.dart

---

#### 🟡 2.3 데이터 내보내기 (CSV, PDF) - 예정
- [ ] CSV/PDF 생성 로직
- [ ] 내보내기 옵션 UI
- [ ] 파일 공유 기능

**예상 작업**: 4-6시간

---

### 3. 알림 및 스케줄링

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **3.3 알림 우선순위** | 🟡 예정 | Priority 필드 추가, 채널 설정, UI | 4-6시간 |

### 4. 사용자 경험 개선

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **4.2 드래그 앤 드롭 정렬** | ✅ 완료 | ReorderableListView, position 필드 | 완료됨 |
| **4.3 테마 커스터마이징** | 🟡 예정 | 색상 선택, 폰트 크기, 미리보기 | 6-8시간 |
| **4.4 홈 화면 위젯** | 🟢 예정 | Android/iOS 위젯, 토글 기능 | 3-5일 |

### 5. 협업 및 공유

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **5.1 Todo 공유** | 🟡 예정 | 공유 링크, 읽기전용, 권한 설정 | 1-2일 |
| **5.2 팀 협업** | 🟢 예정 | 워크스페이스, 초대, 실시간 협업 | 1-2주 |

### 6. 통계 및 분석

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **6.1 통계 개선** | 🟡 예정 | 그래프, 추이 분석, 생산성 리포트 | 1-2일 |
| **6.2 타임 트래킹** | 🟢 예정 | 타이머, 작업 시간, 리포트 | 1-2일 |

### 7. 인증 및 계정

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **7.2 프로필 관리** | 🟡 예정 | 프로필 사진, 닉네임, 메타데이터 | 4-6시간 |
| **7.3 계정 삭제** | 🟢 예정 | 삭제 UI, 확인 다이얼로그, 데이터 초기화 | 3-4시간 |

### 8. 성능 및 안정성

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **8.2 성능 최적화** | 🟡 진행 | 이미지 캐싱, Provider 최적화, Bundle 최적화 | 지속적 |
| **8.3 테스트 커버리지** | 🟡 진행 | 18-19% → 50%+ 목표 (137개 → 300+ 테스트) | 지속적 |

### 9. 접근성 및 국제화

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **9.1 접근성** | 🟡 예정 | 스크린리더, 키보드 네비게이션, 고대비 | 1-2일 |
| **9.2 하드코딩 제거** | 🟡 진행 | 7개 파일 번역 키 적용 | 2-3시간 |
| **9.3 추가 언어** | 🟢 예정 | 일본어, 중국어, 스페인어 등 | 언어당 4-6시간 |

### 10. 마케팅 및 수익화

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **10.1 프리미엄 기능** | 🟢 예정 | In-App Purchase, 페이월 UI | 1-2주 |
| **10.2 광고 통합** | 🟢 예정 | AdMob, 배너/전면 광고 | 4-6시간 |

### 11. 플랫폼별 최적화

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **11.1 태블릿 레이아웃** | 🟡 예정 | Split view, 반응형 레이아웃 | 1-2일 |
| **11.2 웹 최적화** | 🟢 예정 | 데스크톱 레이아웃, 단축키, PWA | 2-3일 |

### 12-13. 개발자 경험 및 보안

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **12.2 문서화** | 🟢 진행 | 코드 주석, dartdoc, 아키텍처 다이어그램 | 지속적 |
| **13.1 익명화 통계** | ✅ 완료 | 5개 RLS 함수, 관리자 대시보드 | 완료됨 |

---

## 📊 개발 로드맵 및 진행 상황

### ✅ Phase 1 (완료됨) - MVP 및 기본 기능
**기간**: 2025-11-06 ~ 2025-11-17

- ✅ Todo CRUD (생성, 수정, 삭제, 완료)
- ✅ 반복 Todo (RRULE 기반)
- ✅ 카테고리 관리
- ✅ 백업 및 복원 (JSON)
- ✅ 실시간 검색
- ✅ OAuth 로그인 (Google, Kakao, Apple)
- ✅ 에러 로깅 및 처리
- ✅ CI/CD 파이프라인 (GitHub Actions)

### ✅ Phase 2 (완료됨) - 사용성 및 고급 기능
**기간**: 2025-11-17 ~ 2025-11-27

- ✅ 서브태스크 기능
- ✅ 알림 스누즈 (5분 ~ 3시간 + 커스텀)
- ✅ 위치 기반 알림 (Geofencing + WorkManager)
- ✅ 첨부파일 시스템 (이미지, PDF, 텍스트, JSON)
- ✅ 드래그 앤 드롭 정렬
- ✅ 카테고리 Supabase 동기화
- ✅ 관리자 대시보드 (익명화 통계)
- ✅ 오프라인 모드 (네트워크 감지, 동기화 상태, 자동 재시도)
- ✅ 주소 검색 API 전환 (Naver → Google Geocoding)
- ✅ Flutter Web OAuth 및 Geocoding 수정

### 📋 Phase 3 (계획 중) - 데이터 관리 및 UX 개선
**예정 기간**: 2025-11-28 ~ 2025-12-31

- [ ] 데이터 내보내기 (CSV, PDF) - 4-6시간
- [ ] 첨부파일 개선 (크기/개수 제한, 개별 삭제) - 4-6시간
- [ ] 알림 우선순위 설정 - 4-6시간
- [ ] 테마 커스터마이징 (색상 선택, 폰트 크기) - 6-8시간
- [ ] 통계 화면 개선 (그래프, 추이 분석) - 1-2일
- [ ] 하드코딩 한글 제거 (번역 키 적용) - 2-3시간
- [ ] 프로필 관리 (프로필 사진, 닉네임) - 4-6시간

### 🚀 Phase 4 (장기) - 협업 및 고급 기능
**예정 기간**: 2026-01-01 이후

- [ ] Todo 공유 (공유 링크, 권한) - 1-2일
- [ ] 팀 협업 기능 (워크스페이스, 초대) - 1-2주
- [ ] 타임 트래킹 (타이머, 작업 시간) - 1-2일
- [ ] 홈 화면 위젯 (Android/iOS) - 3-5일
- [ ] 계정 삭제 기능 - 3-4시간
- [ ] 프리미엄 기능 (In-App Purchase) - 1-2주
- [ ] 광고 통합 (AdMob) - 4-6시간
- [ ] 추가 언어 지원 (일본어, 중국어, 스페인어) - 언어당 4-6시간
- [ ] iPad/태블릿 레이아웃 최적화 - 1-2일
- [ ] 웹 앱 최적화 (데스크톱 레이아웃) - 2-3일

---

## 🔧 기술 부채 및 알려진 이슈

### 현재 알려진 이슈
1. **OAuth 리다이렉트**: 웹에서 Kakao OAuth 팝업 자동 닫힘 개선 필요
2. **오프라인 동기화 충돌**: Last-Write-Wins vs Manual Merge 전략 미구현 (향후 과제)
3. **Sentry 통합**: Kotlin 버전 충돌로 비활성화 상태 (선택적)

### 리팩토링 권장 사항
| 파일 | 현황 | 개선 사항 | 우선순위 |
|------|------|---------|---------|
| `todo_list_screen.dart` | 복잡도 높음 (1000+ 줄) | 위젯 분리, 상태 분리 | 🟡 중간 |
| `notification_service.dart` | 플랫폼별 분기 많음 | 추상화, 인터페이스 정의 | 🟡 중간 |
| `todo_providers.dart` | TodoActions 복잡함 | 로직 분리, 헬퍼 메서드 | 🟡 중간 |
| 테스트 커버리지 | 18-19% (137개 테스트) | 50%+ 목표 | 🟢 낮음 |

---

## 📝 참고 사항 및 중요 문서

### 주요 기술 문서
| 문서 | 설명 | 용도 |
|------|------|------|
| `CLAUDE.md` | 프로젝트 개발 가이드 (명령어, 아키텍처) | 일일 개발 참고 |
| `GOOGLE_MAPS_SETUP.md` | Google Maps API 설정 상세 가이드 | 위치 기반 기능 구현 |
| `LOCATION_SETUP_GUIDE.md` | 위치 기반 알림 전체 설정 가이드 | 위치 알림 구현 |
| `SUPABASE_STORAGE_SETUP.md` | Supabase Storage 설정 및 RLS | 첨부파일 시스템 구현 |
| `TASKS.md` | 첨부파일 시스템 완성 태스크 | 첨부파일 개선 |
| `TECHNICAL_REPORT_WEB_OAUTH_GEOCODING_FIX.md` | Web OAuth/Geocoding 수정 상세 분석 | Web 플랫폼 이해 |

### 의존성 업데이트 계획
**현재 버전**:
- `flutter_riverpod`: 3.0.0 ✅
- `flutter_local_notifications`: 18.0.1 ✅
- `go_router`: 14.8.1 ✅
- `connectivity_plus`: 6.0.3 ✅

**향후 업데이트** (선택적):
- `go_router`: 17.0.0+ (breaking changes 확인 필요)
- `flutter_local_notifications`: 19.5.0+ (API 변경 가능)
- `google_sign_in`: 7.2.0+ (권한 처리 변경)

---

## 🤝 기여 방법

새로운 기능을 추가하거나 개선 사항을 제안하고 싶다면:
1. 이 문서에 기능 추가 후 PR 생성
2. GitHub Issues에 Feature Request 등록
3. 우선순위 투표 참여

---

**문서 최종 업데이트**: 2025-11-27 09:30 KST
