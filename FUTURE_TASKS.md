# 향후 추가 기능 및 개선 사항

현재 버전: **1.0.11+35**
최종 업데이트: **2025-11-25**

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

### 🔴 3.2 위치 기반 알림 (Phase 3-4 남음)
**현재 상태**: Phase 1-2 완료, Phase 3 수동 작업 필요

**완료된 작업**:
- ✅ Phase 1: Infrastructure (DB, Repository, LocationService)
- ✅ Phase 2: UI Integration (LocationPickerDialog, Todo Form)
- ✅ Phase 3: Google Maps API 인프라 구축
- ✅ Phase 4: Geofencing 백그라운드 모니터링 및 클라우드 동기화 (2025-11-26)

**Phase 4 완료 항목**:
- ✅ Geofencing 백그라운드 모니터링 (WorkManager 15분 주기)
- ✅ 위치 도달 시 알림 트리거 (FlutterLocalNotifications)
- ✅ iOS 권한 설정 (Info.plist)
- ✅ 배터리 최적화 (adaptive intervals: 15-60분)
- ✅ Haversine 거리 계산 구현
- ✅ Supabase 클라우드 동기화 (location_settings table)
- ✅ 24시간 중복 알림 방지 (throttling)
- ✅ Settings UI 추가 (geofence 토글, 간격 조정)
- ✅ RLS 보안 정책 (사용자 데이터 격리)

**참고 문서**:
- `GOOGLE_MAPS_SETUP.md` - Google Maps API 상세 가이드
- `LOCATION_SETUP_GUIDE.md` - 전체 설정 가이드

---

### 🔴 14.1 업로드 키 재설정 (Google Play)
**현재 상태**: 요청 제출 완료, 승인 대기 중

**완료된 작업**:
- ✅ 원본 APK 추출 및 서명 정보 확인
- ✅ 새 업로드 키스토어 생성
- ✅ PEM 인증서 파일 생성
- ✅ Google Play Console에 재설정 요청 제출
- ✅ 새 키로 AAB 빌드 (1.0.11+35-FINAL.aab)

---

## 📋 향후 작업 (Upcoming Tasks)

### 1. 핵심 기능 추가 (Core Features)

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

#### 🟡 2.2 오프라인 모드 개선 ✅
**현재 상태**: 구현 완료 (2025-11-27)
**구현 사항**:
- [x] 오프라인 상태 감지 UI 표시 (OfflineBanner)
- [x] 동기화 상태 표시 (마지막 동기화 시간)
- [x] 동기화 실패 시 재시도 로직 (점진적 지연: 5s, 15s, 30s)
- [x] 연결 상태 위젯 (ConnectionStatusWidget)
- [ ] 동기화 충돌 해결 전략 구현 (Last-Write-Wins vs Manual Merge) - 향후 과제

**생성된 파일**:
- `lib/core/services/connectivity_service.dart` - 네트워크 상태 감지 서비스
- `lib/presentation/providers/connectivity_provider.dart` - 연결/동기화 상태 관리
- `lib/presentation/widgets/offline_banner.dart` - 오프라인 배너 및 동기화 UI

**실제 작업 시간**: 약 4시간

---

#### 🟢 2.3 데이터 내보내기 (CSV, PDF)
**설명**: Todo 목록을 CSV 또는 PDF로 내보내기
**필요 작업**:
- [ ] CSV 생성 로직 (`csv` 패키지)
- [ ] PDF 생성 로직 (`pdf` 패키지)
- [ ] 내보내기 옵션 UI (전체 vs 필터링된 항목)
- [ ] 파일 공유 기능 (`share_plus`)

**예상 작업 시간**: 4-6시간

---

### 3. 알림 및 스케줄링

#### 🟢 3.3 알림 우선순위 설정
**설명**: Todo 중요도에 따라 알림 방식 차별화
**필요 작업**:
- [ ] Todo에 `priority` 필드 추가 (High, Medium, Low)
- [ ] 우선순위별 알림 채널 설정 (소리, 진동 패턴)
- [ ] 우선순위 UI (색상 코드, 아이콘)

**예상 작업 시간**: 4-6시간

---

### 4. 사용자 경험 개선

#### ✅ 4.2 드래그 앤 드롭 정렬 (완료 - 2025-11-25)
**설명**: Todo 순서를 드래그로 변경
**완료된 작업**:
- [x] `ReorderableListView` 사용
- [x] Todo에 `position` 필드 추가
- [x] 순서 변경 시 DB 업데이트 (로컬 + Supabase)
- [x] 카테고리별 독립적 정렬
- [x] 앱 재시작 후에도 순서 유지
- [x] 반복 Todo 그룹 순서 변경 지원

---

#### 🟡 4.3 테마 커스터마이징
**현재 상태**: 다크/라이트 모드만 지원
**개선 사항**:
- [ ] 커스텀 색상 테마 선택 (블루, 그린, 퍼플 등)
- [ ] 다크/라이트 모드별 개별 색상 설정
- [ ] 폰트 크기 조절
- [ ] 설정 화면에 테마 미리보기

**예상 작업 시간**: 6-8시간

---

#### 🟢 4.4 위젯 (홈 화면 위젯)
**설명**: 앱 실행 없이 홈 화면에서 Todo 확인
**필요 작업**:
- [ ] Android 위젯 구현 (`home_widget`)
- [ ] iOS 위젯 구현 (WidgetKit)
- [ ] 위젯에서 Todo 완료 토글 기능
- [ ] 위젯 사이즈 옵션 (small, medium, large)

**예상 작업 시간**: 3-5일

---

### 5. 협업 및 공유

#### 🟡 5.1 Todo 공유
**설명**: 특정 Todo를 다른 사용자와 공유
**필요 작업**:
- [ ] 공유 링크 생성 (딥링크)
- [ ] 공유된 Todo 읽기 전용 뷰
- [ ] 공유 권한 설정 (읽기 vs 편집)
- [ ] Supabase RLS 정책 수정

**예상 작업 시간**: 1-2일

---

#### 🟢 5.2 팀 협업 기능
**설명**: 여러 사용자가 같은 Todo 목록 공동 작업
**필요 작업**:
- [ ] 워크스페이스 개념 도입
- [ ] 사용자 초대 시스템
- [ ] 실시간 협업 (Supabase Realtime)
- [ ] 역할 기반 권한 (Owner, Editor, Viewer)
- [ ] 활동 로그

**예상 작업 시간**: 1-2주

---

### 6. 통계 및 분석

#### 🟡 6.1 통계 화면 개선
**현재 상태**: 기본적인 통계만 표시
**개선 사항**:
- [ ] 주간/월간/연간 완료율 추이 그래프
- [ ] 카테고리별 시간 투자 분석
- [ ] 생산성 리포트 (가장 생산적인 시간대, 요일)
- [ ] 목표 설정 및 달성률 추적

**예상 작업 시간**: 1-2일
**기술 스택**: `fl_chart` 패키지

---

#### 🟢 6.2 타임 트래킹
**설명**: Todo별 작업 시간 측정
**필요 작업**:
- [ ] 타이머 기능 (시작/일시정지/종료)
- [ ] 타임 엔트리 저장
- [ ] Todo별 총 작업 시간 표시
- [ ] 일일/주간 작업 시간 리포트

**예상 작업 시간**: 1-2일

---

### 7. 인증 및 계정 관리

#### 🟡 7.2 프로필 관리
**설명**: 사용자 프로필 사진, 이름 변경
**필요 작업**:
- [ ] 프로필 편집 화면 추가
- [ ] 프로필 사진 업로드 (Supabase Storage)
- [ ] 닉네임 변경
- [ ] Supabase Auth 메타데이터 업데이트

**예상 작업 시간**: 4-6시간

---

#### 🟢 7.3 계정 삭제
**설명**: 사용자가 계정 및 모든 데이터 삭제
**필요 작업**:
- [ ] 계정 삭제 UI (설정 화면)
- [ ] 확인 다이얼로그 (비밀번호 재입력)
- [ ] Supabase Auth 계정 삭제
- [ ] 로컬 DB 초기화

**예상 작업 시간**: 3-4시간

---

### 8. 성능 및 안정성

#### 🟡 8.2 성능 최적화
**필요 작업**:
- [ ] 이미지 캐싱 (`cached_network_image`)
- [ ] Riverpod provider 최적화 (불필요한 rebuild 방지)
- [ ] Bundle 크기 최적화

**예상 작업 시간**: 지속적

---

#### 🟡 8.3 테스트 커버리지 증가
**현재 상태**: 18-19% 커버리지 (137개 테스트)
**필요 작업**:
- [ ] 유닛 테스트 작성 (repositories, providers)
- [ ] 위젯 테스트 확대 (모든 주요 화면)
- [ ] 통합 테스트 추가
- [ ] E2E 테스트 (integration_test)

**예상 작업 시간**: 지속적

---

### 9. 접근성 및 국제화

#### 🟡 9.1 접근성 개선
**필요 작업**:
- [ ] 스크린 리더 지원 (Semantics 위젯)
- [ ] 키보드 내비게이션
- [ ] 고대비 모드
- [ ] 폰트 크기 조절 대응

**예상 작업 시간**: 1-2일

---

#### 🟡 9.2 하드코딩 한글 제거 (번역 키 사용)
**현재 상태**: 번역 키 40개 추가 완료 (2025-11-19)
**남은 작업**:
- [ ] `notification_service.dart` 수정 (알림 텍스트)
- [ ] `auth_repository_impl.dart` 수정 (에러 메시지)
- [ ] `supabase_datasource.dart` 수정 (에러 메시지)
- [ ] `register_screen.dart` 수정 (UI 레이블)
- [ ] `calendar_screen.dart` 수정 (UI 텍스트)
- [ ] `location_picker_dialog.dart` 수정 (검색 메시지)
- [ ] `web_notification_service.dart` 수정 (테스트 알림)

**예상 작업 시간**: 2-3시간

---

#### 🟡 9.3 추가 언어 지원
**현재 상태**: 한국어, 영어만 지원
**추가 언어**: 일본어, 중국어(간체/번체), 스페인어 등
**필요 작업**:
- [ ] 번역 파일 추가 (`assets/translations/`)
- [ ] 언어 선택 UI (설정 화면)
- [ ] 하드코딩 한글 제거 (9.2) 선행 필요

**예상 작업 시간**: 언어당 4-6시간

---

### 10. 마케팅 및 수익화

#### 🟢 10.1 프리미엄 기능 (In-App Purchase)
**설명**: 무료 + 프리미엄 모델
**프리미엄 기능**:
- 무제한 첨부파일
- 고급 통계
- 커스텀 테마
- 백업 자동화
- 광고 제거

**필요 작업**:
- [ ] `in_app_purchase` 패키지 통합
- [ ] App Store / Play Store 인앱 상품 설정
- [ ] 페이월 UI

**예상 작업 시간**: 1-2주

---

#### 🟢 10.2 광고 통합 (AdMob)
**필요 작업**:
- [ ] `google_mobile_ads` 패키지 통합
- [ ] 배너 광고, 전면 광고
- [ ] 프리미엄 사용자 광고 제거

**예상 작업 시간**: 4-6시간

---

### 11. 플랫폼별 최적화

#### 🟡 11.1 iPad / 태블릿 레이아웃
**필요 작업**:
- [ ] 반응형 레이아웃 (split view)
- [ ] 태블릿 전용 내비게이션
- [ ] 멀티 윈도우 지원

**예상 작업 시간**: 1-2일

---

#### 🟢 11.2 웹 앱 최적화
**필요 작업**:
- [ ] 데스크톱 레이아웃 개선
- [ ] 키보드 단축키
- [ ] PWA 매니페스트 최적화
- [ ] SEO 메타 태그

**예상 작업 시간**: 2-3일

---

### 12. 개발자 경험 개선

#### 🟢 12.2 문서화
**필요 작업**:
- [ ] 코드 주석 추가
- [ ] API 문서 자동 생성 (`dartdoc`)
- [ ] 아키텍처 다이어그램
- [ ] 기여 가이드라인

**예상 작업 시간**: 지속적

---

### 13. 데이터 프라이버시 및 보안

#### 🔴 13.1 관리자 데이터 접근 권한 관리
**문제**: Supabase 관리자가 사용자 개인 데이터 직접 접근 가능
**선택한 해결책**: 익명화된 통계 함수만 사용

**완료된 설계**:
- ✅ 익명화된 통계 함수 5개 설계
- ✅ SECURITY DEFINER 함수 설계
- ✅ Flutter 구현 예제 작성

**구현 필요 작업**:
- [ ] Supabase 콘솔에서 5개 SQL 함수 생성
- [ ] Flutter 관리자 대시보드 UI 구현
- [ ] 통계 데이터 시각화

**예상 작업 시간**: 4-6시간

---

## 📊 우선순위 로드맵

### Phase 1 (1-2개월) - MVP 완성 ✅ **완료됨**
- ✅ Todo 편집 기능
- ✅ 반복 Todo
- ✅ 백업 및 복원
- ✅ 검색 기능
- ✅ Apple 로그인
- ✅ 에러 로깅
- ✅ CI/CD 파이프라인
- ✅ 통합 테스트

### Phase 2 (3-4개월) - 사용성 향상 🚧
- ✅ 서브태스크 (완료)
- ✅ 스누즈 기능 (완료)
- 🚧 위치 기반 알림 (진행 중)
- 📋 통계 개선 (예정)
- 📋 프로필 관리 (예정)

### Phase 3 (5-6개월) - 고급 기능
- ✅ 첨부파일 (완료)
- 첨부파일 개선 (파일 크기/개수 제한, 개별 삭제)
- 테마 커스터마이징
- Todo 공유
- 타임 트래킹

### Phase 4 (7개월+) - 확장 및 수익화
- 팀 협업
- 홈 화면 위젯
- 프리미엄 기능
- 추가 언어 지원

---

## 🔧 기술 부채 및 리팩토링

### 현재 알려진 이슈
1. **OAuth 리다이렉트**: 웹에서 Kakao OAuth 후 자동 닫힘 필요
2. **오프라인 동기화**: 충돌 해결 전략 미흡
3. **Sentry 통합**: Kotlin 버전 충돌로 비활성화 상태

### 리팩토링 필요 영역
- `todo_list_screen.dart`: 복잡도 높음, 위젯 분리 필요
- `notification_service.dart`: 플랫폼별 분기 많음, 추상화 필요

---

## 📝 참고 사항

### 의존성 업데이트 필요
주요 패키지 업데이트 계획:
- `go_router`: 14.8.1 → 17.0.0
- `flutter_local_notifications`: 18.0.1 → 19.5.0
- `google_sign_in`: 6.3.0 → 7.2.0

**주의**: 메이저 버전 업데이트 시 breaking changes 확인 필요

---

## 🤝 기여 방법

새로운 기능을 추가하거나 개선 사항을 제안하고 싶다면:
1. 이 문서에 기능 추가 후 PR 생성
2. GitHub Issues에 Feature Request 등록
3. 우선순위 투표 참여

---

**문서 최종 업데이트**: 2025-11-25 21:30 KST
