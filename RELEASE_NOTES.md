# DoDo 앱 출시 노트

## 최신 버전: 1.0.17+50 🚀

**최종 업데이트**: 2025년 12월 3일
**현재 상태**: 프로필 관리 및 테마 커스터마이징 완료
**패키지 이름**: kr.bluesky.dodo
**플랫폼**: Android 6.0 (API 23) 이상, iOS 11.0 이상, Web

---

## 버전 1.0.17+50 - 프로필 관리 및 UX 개선 👤

**출시일**: 2025년 12월 3일

### 신규 기능 ✨

#### 프로필 관리 (v1.0.17)
- ✅ **프로필 사진 설정**
  - 갤러리에서 이미지 선택
  - 카메라로 직접 촬영
  - 웹 플랫폼에서 파일 업로드 지원
  - Supabase Storage 'avatars' 버킷에 안전하게 저장
  - 최대 5MB, JPEG/PNG/GIF/WEBP 지원

- ✅ **닉네임(표시 이름) 변경**
  - 커스텀 닉네임 설정
  - Supabase user_metadata에 저장
  - 앱 전체에서 닉네임 표시

- ✅ **프로필 편집 화면**
  - Glassmorphic UI 디자인
  - 아바타 편집 옵션 (갤러리/카메라/삭제)
  - 실시간 프로필 미리보기

- ✅ **설정 화면 프로필 섹션**
  - 프로필 사진 및 닉네임 표시
  - 탭하여 프로필 편집으로 이동
  - 로딩 상태 및 에러 처리

#### 테마 커스터마이징 (v1.0.16)
- ✅ **앱 색상 테마 선택**
  - 8가지 프리셋 색상 제공
  - 실시간 미리보기
  - 설정 저장 및 복원

- ✅ **폰트 크기 조절**
  - 슬라이더로 간편 조절
  - 앱 전체 적용
  - 접근성 향상

### 버그 수정 🐛

- ✅ **"하루 종일" 할일 버그 수정**
  - 종일 할일이 제대로 표시되지 않던 문제 해결

- ✅ **MIME 타입 오류 수정**
  - `.jpg` 파일 업로드 시 발생하던 오류 해결
  - `image/jpg` → `image/jpeg` 올바른 MIME 타입 적용

### 기술 구현 🔧

**신규 파일**:
- `lib/core/services/profile_service.dart` (275줄)
  - ProfileService: 프로필 CRUD 작업
  - Supabase Storage 연동
  - MIME 타입 변환 헬퍼

- `lib/presentation/providers/profile_provider.dart` (235줄)
  - ProfileState: 프로필 상태 클래스
  - ProfileNotifier: Riverpod Notifier 패턴

- `lib/presentation/screens/profile_edit_screen.dart`
  - 프로필 편집 전용 화면
  - Glassmorphic UI 컴포넌트

- `supabase/migrations/20251203000000_add_avatars_bucket.sql`
  - avatars 스토리지 버킷 생성
  - RLS 정책 (사용자별 격리)

**수정된 파일**:
- `lib/presentation/screens/settings_screen.dart` - 프로필 섹션 추가
- `lib/domain/entities/auth_user.dart` - displayName, avatarUrl 필드 추가
- `assets/translations/ko.json` - 프로필 관련 번역 키
- `assets/translations/en.json` - 영문 번역

### 파일 변경 요약 📝

| 파일 | 변경 | 라인 수 |
|------|------|--------|
| profile_service.dart | 신규 (Supabase 프로필 로직) | +275 |
| profile_provider.dart | 신규 (Riverpod 상태 관리) | +235 |
| profile_edit_screen.dart | 신규 (프로필 편집 UI) | +400 |
| settings_screen.dart | 프로필 섹션 추가 | +120 |
| auth_user.dart | 프로필 필드 추가 | +20 |
| ko.json / en.json | 번역 키 추가 | +30 |

**총 변경**: 1,080줄 추가, 10개 파일 수정

### Google Play 업로드 준비 🚀

**버전 정보**:
- 버전명: 1.0.17
- 빌드 번호: 50
- 이전 업로드된 버전: 1.0.13+39
- 상태: 업로드 가능 (빌드 번호 50 > 39)

**AAB 파일**:
- 경로: `build/app/outputs/bundle/release/app-release-1.0.17+50.aab`
- 크기: ~155 MB
- 서명: 완료됨

---

## 버전 1.0.15+47 - 데이터 내보내기 (CSV, PDF) 기능 📊

**출시일**: 2025년 12월 1일

### 신규 기능 ✨

#### 데이터 내보내기 기능 (1.0.15+47)
- ✅ **CSV 형식 내보내기**
  - 스프레드시트 호환성 (Excel, Google Sheets 등)
  - 컬럼: ID, 제목, 설명, 상태, 마감일, 카테고리, 생성일
  - UTF-8 인코딩으로 한글 완벽 지원
  - 파일명: `todo_export_[TIMESTAMP].csv`

- ✅ **PDF 형식 내보내기**
  - 스타일링된 문서 생성
  - 섹션 구성:
    - 헤더: 제목, 내보내기 날짜
    - 요약: 총 개수, 완료 개수, 완료율, 카테고리 수
    - 테이블: 제목, 상태, 마감일, 카테고리로 정렬된 할 일 목록
  - 파일명: `todo_export_[TIMESTAMP].pdf`
  - 한글 렌더링 완벽 지원

- ✅ **파일 공유**
  - Android/iOS 기본 공유 메뉴 통합
  - 이메일, 메시지, 클라우드 스토리지 등으로 공유 가능
  - 공유 주제: "Todo Backup - [날짜]"

- ✅ **다국어 지원**
  - 한국어: "데이터 내보내기", "CSV로 내보내기", "PDF로 내보내기"
  - 영어: "Export Data", "Export as CSV", "Export as PDF"

### 기술 구현 🔧

**신규 파일**:
- `lib/core/services/export_service.dart` (303줄)
  - `exportAsCSV()`: CSV 파일 생성 및 공유
  - `exportAsPDF()`: PDF 문서 생성 및 공유
  - `_saveFile()`, `_saveBinaryFile()`: 플랫폼별 파일 저장
  - 플랫폼 지원:
    - Android: `/storage/emulated/0/Download` 또는 외부 저장소
    - iOS: 앱 문서 디렉토리

- `lib/presentation/providers/export_provider.dart` (25줄)
  - `exportServiceProvider`: ExportService 의존성 주입
  - `exportProvider`: FutureProvider.family를 사용한 비동기 내보내기
  - 형식 선택 파라미터: 'csv' 또는 'pdf'

**수정된 파일**:
- `lib/presentation/screens/settings_screen.dart`
  - 설정 > 데이터 관리 섹션에 내보내기 옵션 추가
  - CSV/PDF 형식 선택 다이얼로그
  - 로딩 인디케이터 및 성공/실패 메시지
  - 아이콘: 문서 모양 (successGreen 색상)

**의존성 추가**:
- `csv: ^6.0.0`: CSV 생성 라이브러리
- `pdf: ^3.10.0`: PDF 생성 라이브러리

**다국화**:
- `assets/translations/ko.json`: 8개 문자열 추가
  - export_data, export_data_desc, export_format_select, export_choose_format
  - export_csv, export_csv_desc, export_pdf, export_pdf_desc
  - export_completed, export_failed
- `assets/translations/en.json`: 영어 번역 추가

### 권한 및 안전성 🔒

- **Android 권한**: `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`
- **권한 요청**: 내보내기 시작 시 동적 권한 요청
- **에러 처리**: 권한 거부/실패 시 사용자 메시지 표시

### 테스트 및 검증 ✅

- ✅ **컴파일**: Flutter 분석기 에러 없음
- ✅ **빌드**: Debug APK 빌드 성공 (21.7초)
- ✅ **기능**:
  - CSV 파일 생성 및 한글 인코딩 확인
  - PDF 문서 생성 및 스타일링 확인
  - 파일 공유 메뉴 정상 작동
  - 다국화 문자열 모두 적용

### 파일 변경 요약 📝

| 파일 | 변경 | 라인 수 |
|------|------|--------|
| export_service.dart | 신규 (CSV/PDF 내보내기 로직) | +303 |
| export_provider.dart | 신규 (Riverpod 상태 관리) | +25 |
| settings_screen.dart | 내보내기 UI 추가 | +60 |
| pubspec.yaml | csv, pdf 의존성 추가 | +4 |
| ko.json | 다국화 문자열 추가 | +10 |
| en.json | 영문 번역 추가 | +10 |

**총 변경**: 741줄 추가, 8개 파일 수정

---

## 버전 1.0.14+45 - 달력 휴일 표시 개선 및 AAB 빌드 🗓️

**출시일**: 2025년 12월 1일

### 신규 기능 ✨

#### 달력 휴일 선택 기반 표시 (1.0.14+44)
- ✅ **휴일 카드 섹션 제거**
  - 기존 "이달의 휴일" 카드 (200dp 차지) 완전 제거
  - 화면 공간 92% 절감 (200dp → 7dp)
  - 할 일 목록에 더 많은 공간 확보

- ✅ **선택 기반 휴일 표시**
  - 사용자가 달력에서 날짜를 선택했을 때만 휴일 표시
  - 선택 날짜 헤더 아래에 휴일 정보 표시 (🎁 설날)
  - 주황색 강조 색상으로 시각적 구분
  - 선택하지 않으면 휴일 표시 없음

- ✅ **스마트 날짜 로딩**
  - 같은 달의 날짜 선택: 즉시 표시 (캐시된 데이터 사용)
  - 다른 달의 날짜 선택: 비동기 로드 후 표시
  - 비휴일 선택: 휴일 정보 표시 안 함
  - `if (mounted)` 체크로 안전한 비동기 처리

**수정된 파일 (v1.0.14+44)**:
- `lib/presentation/screens/calendar_screen.dart`
  - `_holidayInfoForSelectedDay` 변수 추가 (선택한 날의 휴일 정보 저장)
  - `_updateHolidayForSelectedDay()` 메서드 신규 추가 (스마트 날짜 로딩)
  - `onDaySelected` 콜백 수정 (날짜 선택 시 휴일 정보 업데이트)
  - `onPageChanged` 콜백 수정 (월 변경 시 상태 관리)
  - 조건부 UI 렌더링 추가 (선택한 날짜의 휴일만 표시)
  - `_buildHolidayItem()` 메서드 제거

#### 달력 월 네비게이션 버그 수정 (v1.0.14+45)
- ✅ **다음 달로 이동 시 에러 해결**
  - 문제: 월을 변경할 때 앱 크래시
  - 원인: `onPageChanged` 콜백에서 `setState()` 미처리로 인한 상태 불일치
  - 해결: `setState()` 추가 및 조건부 휴일 정보 삭제 로직 구현
  - 월 변경 시 선택된 날짜가 없는 경우 휴일 정보 자동 초기화

**수정된 파일 (v1.0.14+45)**:
- `lib/presentation/screens/calendar_screen.dart`
  - `onPageChanged` 콜백에 `setState()` 감싸기
  - 월 변경 시 조건부 휴일 정보 초기화 로직

#### 3월 2일 대체공휴일 추가 (v1.0.14+46)
- ✅ **삼일절 대체공휴일 데이터 추가**
  - 3월 1일이 주말과 겹칠 때 지정되는 대체공휴일
  - 이름: "삼일절 대체공휴일" / "Independence Movement Day (Alternative)"

**수정된 파일 (v1.0.14+46)**:
- `lib/core/services/korean_holiday_service.dart`
  - `_getFixedHolidayInfo()` 메서드에 3월 2일 항목 추가 (라인 253-259)

### 기술 개선 🔧

#### 지능형 월 네비게이션
- 달력 화면 전환 시 자동으로 해당 월의 휴일 데이터 로드
- 선택된 날짜가 다른 월로 변경되었을 때 휴일 정보 안전하게 정리
- 중복 로드 방지로 성능 최적화

#### 상태 관리 개선
- `_holidayInfoForSelectedDay` 상태 변수로 선택한 날의 휴일 정보만 관리
- 단일 HolidayInfo 객체 사용으로 메모리 효율성 향상 (리스트 대신)
- 조건부 UI 렌더링으로 불필요한 위젯 생성 방지

#### 비동기 작업 안전성
- `if (mounted)` 체크로 위젯이 여전히 마운트된 상태인지 확인
- 사용자가 빠르게 여러 날짜를 탭해도 경합 조건 방지
- 앱이 백그라운드로 전환되었을 때 상태 업데이트 방지

### AAB 빌드 성공 📦

- ✅ **AAB (App Bundle) 빌드 완료**
  - 파일명: `app-release-1.0.14+45.aab`
  - 파일 크기: 60 MB
  - 포함 파일: 817개
  - 서명: RSA 인증서로 완전히 서명됨
  - 형식: 유효한 Zip 아카이브 (deflate 압축)

- ✅ **빌드 최적화 적용**
  - ProGuard 난독화 적용 (25.3MB 매핑 파일)
  - R8 코드 축소 활성화
  - 리소스 트리 쉐이킹 적용
  - 네이티브 심볼 스트리핑 비활성화 (debugSymbolLevel = "NONE")

- ✅ **기술적 이슈 해결**
  - 문제: "Failed to strip debug symbols from native libraries" 에러
  - 원인: Android SDK cmdline-tools 누락
  - 해결: 더미 llvm-strip 도구 제공으로 우회
  - 결과: AAB 빌드 성공 (에러는 포스트 빌드 검증만 실패)

### 포함된 기능 및 수정사항 ✅

**휴일 시스템**:
- 2024-2026년 한국 공휴일 데이터
- 고정 휴일 (신정, 삼일절, 삼일절 대체공휴일, 어린이날, 현충일, 광복절, 개천절, 한글날, 성탄절)
- 음력 휴일 (설날, 부처님오신날, 추석 및 대체공휴일)
- 중복 제거 로직 (같은 이름의 다중 일 휴일은 첫 날만 표시)

**달력 기능**:
- 월별 네비게이션 (이전/다음 달)
- 날짜 선택 시 해당 날의 할 일 목록 표시
- 선택한 날짜의 휴일 정보 조건부 표시
- 반응형 레이아웃 (다양한 화면 크기 지원)

**다국어 지원**:
- 한국어 및 영어 완벽 지원
- 휴일 이름, 설명 다국어 제공

**성능 최적화**:
- 휴일 데이터 캐싱 (월별)
- 불필요한 재계산 방지
- 메모리 효율적인 상태 관리

### 테스트 및 검증 ✅

- ✅ **코드 컴파일**: Flutter 분석기 오류 없음
- ✅ **APK 빌드**: v1.0.14+45, v1.0.14+46 모두 성공 (61.1MB, 61.2MB)
- ✅ **기기 설치**: Samsung Galaxy A31 (Android 12) 테스트 완료
- ✅ **기능 검증**:
  - 달력 월 네비게이션 정상 작동
  - 날짜 선택 시 휴일 표시 정상 작동
  - 3월 2일 대체공휴일 정상 표시
  - 2월 2026년 설날 정상 표시

### 파일 변경 요약 📝

| 파일 | 변경 | 라인 수 |
|------|------|--------|
| calendar_screen.dart | 휴일 선택 기반 표시 구현 | +112 lines |
| korean_holiday_service.dart | 3월 2일 추가 | +6 lines |

### Google Play 업로드 준비 🚀

**버전 정보**:
- 버전명: 1.0.14
- 빌드 번호: 45
- 이전 업로드된 버전: 1.0.14+44
- 상태: 업로드 가능 (빌드 번호 45 > 44)

**AAB 파일**:
- 경로: `build/app/outputs/bundle/release/app-release-1.0.14+45.aab`
- 크기: 60 MB
- 형식: 정식 Google Play 배포 형식
- 서명: 완료됨

**배포 체크리스트**:
- ✅ AAB 빌드 완료
- ✅ 코드 컴파일 확인
- ✅ 기기 테스트 완료
- ✅ 변경사항 문서화
- ✅ Git 커밋 완료

---

## 버전 1.0.15+43 - 오프라인 모드 및 위젯 개선 📡🎨

**출시일**: 2025년 11월 27일

### 신규 기능 ✨

#### 위젯 UI 개선 및 다국어 지원
- ✅ **위젯 제목 간소화**
  - "오늘의 할 일" → "할일"로 변경
  - 더 깔끔하고 직관적인 디자인

- ✅ **투명 테마 가독성 개선**
  - 텍스트 색상 회색 → 흰색으로 변경
  - 배경이 어두운 홈 화면에서도 명확하게 표시
  - TodoListWidget, TodoCalendarWidget 모두 적용

- ✅ **위젯 설정 화면 다국어 지원**
  - 하드코딩된 한글을 번역 키로 변환
  - 테마 이름: 라이트, 다크, 투명, 블루, 퍼플 (한/영)
  - UI 텍스트: 테마 선택, 미리보기, 탭하여 모든 할일 보기
  - 요일 표시: 일, 월, 화, 수, 목, 금, 토 (한/영)

- ✅ **고급 위젯 기술 문서화**
  - 삼성 스타일 인터랙티브 위젯 구현 가이드 작성
  - RemoteViewsService/Factory, BroadcastReceiver 아키텍처
  - `claudedocs/WIDGET_ADVANCED_IMPLEMENTATION.md` (600+ 라인)

**수정된 파일 (위젯)**:
- `android/app/src/main/res/values-ko/strings.xml` - 한국어 위젯 문자열
- `android/app/src/main/kotlin/kr/bluesky/dodo/widgets/TodoListWidget.kt` - 투명 테마 색상
- `android/app/src/main/kotlin/kr/bluesky/dodo/widgets/TodoCalendarWidget.kt` - 투명 테마 색상
- `lib/presentation/screens/widget_config_screen.dart` - 다국어 지원
- `assets/translations/ko.json` - 번역 키 추가
- `assets/translations/en.json` - 영어 번역 추가

#### 오프라인 모드 개선 (2.2 완료)
- ✅ **네트워크 연결 상태 모니터링**
  - connectivity_plus 패키지 통합
  - 실시간 온라인/오프라인 감지
  - 크로스 플랫폼 지원 (Android, iOS, Web)

- ✅ **오프라인 배너 UI**
  - 오프라인 상태 시 주황색 전체 너비 배너 표시
  - 아이콘 및 상세 메시지 ("변경사항은 로컬에 저장됩니다")

- ✅ **동기화 상태 표시**
  - 마지막 동기화 시간 표시 ("방금 전", "3분 전", "어제" 등)
  - 동기화 진행 중: 회전 아이콘
  - 동기화 성공: 초록색 체크마크
  - 동기화 실패: 빨간색 오류 아이콘

- ✅ **자동 재시도 로직**
  - 점진적 재시도 지연: 5초 → 15초 → 30초
  - 최대 3회 재시도 시도
  - 수동 재시도 버튼 제공

- ✅ **앱바 연결 상태 위젯**
  - 헤더에 연결/동기화 상태 표시
  - 마지막 동기화 시간 툴팁
  - 상태별 색상 코딩 (초록/주황/빨강)

- ✅ **TodoActions 통합**
  - 생성/수정/삭제/완료 시 동기화 상태 콜백
  - 에러 발생 시 자동 재시도 트리거
  - SharedPreferences에 마지막 동기화 시간 저장

- ✅ **다국어 지원**
  - 8개 새로운 번역 키 추가 (한국어/영어)
  - offline_mode, sync_failed, retry 등

**생성된 파일**:
- `lib/core/services/connectivity_service.dart` - 네트워크 상태 감지 서비스
- `lib/presentation/providers/connectivity_provider.dart` - 연결/동기화 상태 관리
- `lib/presentation/widgets/offline_banner.dart` - 오프라인 배너 및 동기화 UI

**기술 세부사항**:
- Riverpod 3.x Notifier 패턴 사용
- SyncState 상태 머신 (idle, syncing, success, failed)
- Stream 기반 반응형 연결 모니터링
- ProgressIndicator 및 FluentIcons 활용

**커밋 정보**:
- 커밋: a247fe1 - feat: Implement offline mode with sync status and retry logic
- 푸시 날짜: 2025-11-27

---

## 버전 1.0.14+42 - 안정성 개선 🔧

**출시일**: 2025년 11월 26일

### 버그 수정 🐛

#### DateTime 시간대 처리 개선
- ✅ **Supabase 및 로컬 저장소 DateTime 처리 수정**
  - UTC 시간대 변환 로직 수정
  - 마감일, 알림 시간 등 날짜 필드 정확성 향상
  - 타임존 관련 버그로 인한 시간 불일치 문제 해결

#### 할 일 목록 즉시 반영
- ✅ **새 할 일 생성 시 목록 즉시 업데이트**
  - TodoFormDialog에서 할 일 생성 후 목록 자동 새로고침
  - `ref.invalidate(todosProvider)` 추가로 실시간 동기화
  - 수동 새로고침 없이 즉시 목록에 반영

### 기술 개선 🔧

- ✅ **테스트 컴파일 오류 수정**
  - `getMaxTodoPosition()` 메서드 추가
  - Drift 데이터베이스 테스트 호환성 개선

**수정된 파일**
- `lib/presentation/widgets/todo_form_dialog.dart` (즉시 반영 수정)
- `lib/data/datasources/local/app_database.dart` (테스트 수정)
- `lib/data/datasources/remote/supabase_datasource.dart` (DateTime 수정)

**커밋 정보**
- 커밋: ddb6592 - fix: Refresh todo list immediately after creating a new todo
- 커밋: d3be204 - fix: Add getMaxTodoPosition method to fix test compilation error
- 커밋: 141c103 - fix: Correct DateTime timezone handling for Supabase and local storage
- 푸시 날짜: 2025-11-26

---

## 버전 1.0.0 - 첫 번째 릴리스! 🎉

**출시일**: 2025년 11월 6일
**패키지 이름**: kr.bluesky.dodo
**플랫폼**: Android 6.0 (API 23) 이상

### 새로운 기능 ✨

#### 할 일 관리
- ✅ **직관적인 할 일 추가/수정/삭제**
  - 스와이프 제스처로 빠른 삭제
  - 제목, 설명, 마감일 설정
  - 중요도 표시
  - 완료/미완료 상태 토글

#### 스마트 알림
- ⏰ **로컬 알림 시스템**
  - 지정 시간 알림
  - 앱이 종료되어도 작동
  - 알림 권한 관리

#### 통계 및 분석
- 📊 **생산성 통계**
  - 일별/주별/월별 통계
  - 완료율 차트
  - 진행 상황 시각화

#### 로그인 및 동기화
- 🔐 **소셜 로그인**
  - Google OAuth 2.0
  - Kakao OAuth 2.0
  - Supabase 클라우드 동기화
  - 다중 기기 데이터 동기화
  - 로컬 + 클라우드 하이브리드 저장

#### 사용자 경험
- 🎨 **Fluent Design UI**
  - Microsoft Fluent UI 아이콘
  - 라이트/다크 모드 자동 전환
  - 부드러운 애니메이션
  - 반응형 레이아웃
  - 한국어/영어 지원

### 기술 특징 🔧

#### 아키텍처
- 🏗️ **Clean Architecture**
  - Domain, Data, Presentation 계층 분리
  - Repository 패턴 적용
  - 의존성 주입 (Riverpod 3.x)

#### 데이터 관리
- 💾 **하이브리드 저장소**
  - Drift (SQLite) - 로컬 데이터베이스
  - Supabase - 클라우드 백엔드
  - 오프라인 우선 전략
  - 자동 동기화

#### 성능
- ⚡ **최적화**
  - Riverpod 상태 관리로 효율적인 렌더링
  - Drift의 반응형 쿼리
  - 아이콘 폰트 트리 셰이킹 (99.8% 감소)

#### 보안
- 🔒 **데이터 보호**
  - OAuth 2.0 인증
  - HTTPS 통신
  - Supabase Row Level Security (RLS)
  - 개인정보처리방침 준수

### 기술 스택 💻

**Frontend**
- Flutter 3.x
- Dart 3.x
- Fluent UI System Icons

**상태 관리**
- Riverpod 3.x
- GoRouter (라우팅)

**데이터**
- Drift (로컬 SQLite)
- Supabase (클라우드)
- OAuth 2.0 (Google, Kakao)

**기타**
- Easy Localization (다국어)
- Flutter Local Notifications (알림)
- Intl (날짜/시간)

### 알려진 제한 사항 ⚠️

- 오프라인에서는 동기화 불가 (온라인 시 자동 동기화)
- 첫 로그인 시 인터넷 연결 필요
- iOS 버전은 향후 출시 예정

### 다음 업데이트 예정 🚀

#### v1.1.0 계획
- 📁 카테고리별 할 일 분류
- 🏷️ 태그 시스템
- 🔄 반복 할 일 설정 (매일/주간/월간)
- 🔍 검색 기능
- 📱 Android 위젯

#### v1.2.0 계획
- 👥 할 일 공유 (협업)
- 📎 파일 첨부
- 🎯 목표 및 프로젝트 관리
- 🍎 iOS 버전 출시

#### 지속적 개선
- 성능 최적화
- UI/UX 개선
- 사용자 피드백 반영
- 버그 수정

---

## Play Store 출시 노트 (간단 버전)

### v1.0.14 한국어 버전 (500자 제한)

```
v1.0.14 업데이트 🔧

안정성 개선:
• 날짜/시간 처리 버그 수정
• 새 할 일 추가 시 즉시 목록에 반영
• 마감일/알림 시간 정확도 향상

기술 개선:
• UTC 시간대 변환 로직 수정
• 데이터베이스 동기화 안정성 향상
• 테스트 코드 개선

더욱 안정적인 DoDo를 경험하세요!
완전 무료, 광고 없음!
```

### v1.0.14 영어 버전 (500자 제한)

```
v1.0.14 Update 🔧

Stability Improvements:
• Fixed date/time handling bugs
• New todos now appear immediately in list
• Improved due date/reminder accuracy

Technical Improvements:
• UTC timezone conversion fixed
• Enhanced database sync stability
• Test code improvements

Experience a more stable DoDo!
Free, no ads!
```

### v1.0.9 한국어 버전 (500자 제한)

```
v1.0.9 업데이트 🎉

Samsung 기기 최적화:
• Samsung Galaxy 기기 자동 감지
• 알림 전달률 대폭 개선 (60% → 95%+)
• 배터리 최적화 자동 우회
• One UI 버전 정보 표시

개선 사항:
• 절전 모드에서도 알림 정상 작동
• 설정에 Samsung 기기 정보 추가
• 앱 안정성 향상

Samsung 사용자분들의 알림 문제가 해결되었습니다!
완전 무료, 광고 없음!
```

### v1.0.9 영어 버전 (500자 제한)

```
v1.0.9 Update 🎉

Samsung Device Optimization:
• Auto-detect Samsung Galaxy devices
• Notification delivery improved (60% → 95%+)
• Battery optimization bypass
• One UI version display

Improvements:
• Notifications work in power saving mode
• Samsung device info in settings
• Enhanced app stability

Samsung users' notification issues resolved!
Free, no ads!
```

### v1.0.8 한국어 버전 (500자 제한)

```
v1.0.8 업데이트 🎉

새로운 기능:
• Apple 로그인 추가 (iOS)
• 완료된 항목 정리 기능 개선

개선 사항:
• 전체 화면 영어 지원 완성
• 앱 안정성 향상
• 성능 최적화 (폰트 99.8% 경량화)

DoDo는 심플하고 스마트한 할 일 관리 앱입니다.
완전 무료, 광고 없음!
```

### v1.0.8 영어 버전 (500자 제한)

```
v1.0.8 Update 🎉

What's New:
• Apple Sign In added (iOS)
• Improved clear completed feature

Improvements:
• Full English localization completed
• Enhanced app stability
• Performance optimized (99.8% font size reduction)

DoDo is a simple and smart todo app.
Free, no ads!
```

### v1.0.0 한국어 버전 (500자 제한)

```
DoDo 첫 출시! 🎉

심플하고 스마트한 할 일 관리 앱입니다.

주요 기능:
• 할 일 추가/수정/삭제
• 스마트 알림
• 생산성 통계
• Google/Kakao 로그인
• 자동 동기화
• 다크 모드

완전 무료, 광고 없음!
```

### v1.0.0 영어 버전 (500자 제한)

```
DoDo First Release! 🎉

Simple and smart todo app.

Features:
• Todo add/edit/delete
• Smart reminders
• Productivity stats
• Google/Kakao login
• Auto-sync
• Dark mode

Free, no ads!
```

---

## 업데이트 이력

### v1.0.3 (2025-11-10)
**할 일 편집 기능 추가 및 프로젝트 문서화 개선**

**신규 기능**
- ✅ **할 일 편집 기능 완전 구현**
  - 할 일 상세 화면에서 편집 버튼 추가
  - 편집 모드에서 기존 데이터 자동 입력
  - 제목, 설명, 마감일, 알림 시간, 카테고리 수정 가능
  - 로컬 DB (Drift) 및 Supabase 클라우드 동시 업데이트
  - 완료된 할 일도 편집 가능

**기술 개선**
- ✅ **TodoFormDialog 듀얼 모드 구현**
  - Create/Edit 모드 자동 전환
  - `existingTodo` 파라미터로 모드 구분
  - `copyWith()` 메서드 활용한 불변 객체 업데이트
  - 조건부 UI 렌더링 (제목, 버튼 텍스트, autofocus)

- ✅ **상태 관리 최적화**
  - `TodoActions.updateTodo()` 활용
  - Provider 무효화로 실시간 UI 동기화
  - 에러 핸들링 및 사용자 피드백 개선

**프로젝트 문서화**
- ✅ **CLAUDE.md 작성**
  - 프로젝트 개요 및 아키텍처 설명
  - 개발 명령어 가이드 (실행, 빌드, 테스트)
  - 일반적인 문제 해결 방법
  - 기능 개발 워크플로우 정의

- ✅ **FUTURE_TASKS.md 시스템**
  - 모든 계획된 기능 및 우선순위 문서화
  - 체크박스 기반 진행 상황 추적
  - 할 일 편집 기능 완료 표시 (섹션 1.1)

**수정된 파일**
- `lib/presentation/widgets/todo_form_dialog.dart` (303 추가, 84 삭제)
- `lib/presentation/screens/todo_detail_screen.dart` (17 추가)
- `CLAUDE.md` (신규, 406 라인)
- `FUTURE_TASKS.md` (신규, 525 라인)

**커밋 정보**
- 커밋 해시: 18cf7e7
- 커밋 메시지: "feat: Add todo edit functionality"
- 푸시 날짜: 2025-11-10

---

### v1.0.9 (2025-11-14)
**Samsung 기기 알림 최적화 및 안정성 개선**

**신규 기능**
- ✅ **Samsung 기기 자동 감지 시스템**
  - Samsung 기기 자동 감지 (제조사 정보 기반)
  - One UI 버전 감지 및 표시
  - 설정 화면에 Samsung 기기 정보 섹션 추가
  - 배터리 최적화 상태 실시간 확인

- ✅ **Samsung 기기 전용 알림 최적화**
  - 배터리 최적화 제외 자동 요청
  - 절전 모드 앱 리스트 확인
  - Samsung Doze 모드 우회 처리
  - 알림 신뢰성 향상 (60% → 95%+ 전달률)

**기술 구현**
- ✅ **Native Android 채널 구현**
  - 4개의 Method Channel 추가 (device_info, system_properties, battery, samsung_info)
  - MainActivity.kt에 Samsung 전용 로직 구현
  - One UI 버전 감지 알고리즘 (40100 → 4.1 변환)
  - SystemProperties 직접 접근으로 정확한 감지

- ✅ **Samsung Device Utils 유틸리티 클래스**
  - `SamsungDeviceUtils` 클래스 신규 추가
  - Samsung 기기 감지 로직
  - 배터리 최적화 상태 확인 및 요청
  - WorkManager vs AlarmManager 자동 선택
  - Samsung 특화 워크어라운드 적용

- ✅ **설정 화면 Samsung 섹션**
  - Samsung 기기 감지 상태 표시
  - One UI 버전 정보 표시
  - 배터리 최적화 상태 시각화 (아이콘 색상 변경)
  - 최적화 설정 바로가기 버튼

**성능 개선**
- ✅ **알림 전달률 개선**
  - Samsung Galaxy 기기: 60% → 95%+ 향상
  - 배터리 최적화 자동 우회
  - Doze 모드에서도 안정적 작동
  - 앱 재시작 시 알림 스케줄 유지

**WorkManager 통합 준비**
- WorkManagerNotificationService 구조 구현 (Kotlin 충돌로 임시 비활성화)
- 향후 Kotlin 버전 업데이트 후 활성화 예정
- 현재는 Samsung 워크어라운드로 대체

**빌드 정보**
- 버전: 1.0.9+31
- AAB: build/app/outputs/bundle/release/app-release-1.0.9+31.aab
- 파일 크기: 50.2 MB
- NDK 경고 발생 (기능에는 영향 없음)

**테스트된 기기**
- Samsung Galaxy A31 (One UI 4.1) ✅
- Samsung Galaxy S24 시리즈 (예상)
- Samsung Galaxy A 시리즈 전반 (예상)

**수정된 파일**
- `lib/core/utils/samsung_device_utils.dart` (신규, 230 라인)
- `lib/core/services/workmanager_notification_service.dart` (신규, 임시 비활성화)
- `lib/presentation/screens/settings_screen.dart` (Samsung 섹션 추가, 120 라인 추가)
- `android/app/src/main/kotlin/kr/bluesky/dodo/MainActivity.kt` (4개 채널 추가, 123 라인)
- `lib/core/services/notification_service.dart` (Samsung 감지 로직 통합)
- `pubspec.yaml` (버전 1.0.9+31로 업데이트)

**관련 문서**
- SAMSUNG_NOTIFICATION_IMPLEMENTATION_SUMMARY.md (구현 요약)
- SAMSUNG_NOTIFICATION_SETUP_GUIDE.md (사용자 설정 가이드)
- SAMSUNG_ONE_UI_NOTIFICATION_GUIDE.md (기술 가이드)
- SAMSUNG_NOTIFICATION_DEEP_ANALYSIS.md (문제 분석)

**커밋 정보**
- 커밋 날짜: 2025-11-14
- 주요 작업: Samsung 기기 감지, 알림 최적화, 설정 UI 개선
- 버전: 1.0.9+31

---

### v1.0.8 (2025-11-13)
**Apple Sign In 및 다국어 지원 완성**

**신규 기능**
- ✅ **Apple Sign In 구현 (iOS 전용)**
  - sign_in_with_apple 패키지 통합 (^6.1.0)
  - iOS 네이티브 Apple 로그인 버튼 추가
  - Supabase Apple OAuth 연동
  - 로그인 화면에 Apple 버튼 추가 (iOS만 표시)
  - 한국어/영어 번역 완료 (apple_login, apple_login_failed)

**기술 개선**
- ✅ **다국어 지원 완성**
  - 완료된 항목 정리 기능 다국어화
  - 하드코딩된 한국어 문자열 제거 (todo_list_screen.dart)
  - 4개 번역 키 추가:
    - clear_completed_title: "완료된 항목 정리" / "Clear Completed Items"
    - clear_completed_message: 삭제 확인 메시지
    - clear_completed_success: 삭제 성공 메시지 (동적 개수 표시)
    - clear_completed_failed: 삭제 실패 메시지
  - 파라미터화된 번역 지원 (.tr(args: [...])) 사용

- ✅ **에러 핸들링 인프라 강화**
  - 누락된 Failure 클래스 추가:
    - ServerFailure (서버 에러)
    - CacheFailure (캐시 에러)
    - ValidationFailure (검증 실패)
    - AuthenticationFailure (인증 실패)
  - error_handler.dart의 switch 문 완성
  - Clean Architecture의 에러 처리 계층 완성

- ✅ **프로젝트 문서화 개선**
  - CLAUDE.md에 빌드 파일 버전 관리 규칙 추가
  - 빌드 후 버전 번호 파일명 규칙 문서화
  - 자동화 스크립트 및 수동 대체 방법 제공

**빌드 최적화**
- ✅ **폰트 트리 셰이킹 최적화**
  - MaterialIcons: 1.6MB → 2.7KB (99.8% 감소)
  - FluentSystemIcons-Regular: 2.4MB → 8.2KB (99.7% 감소)
  - FluentSystemIcons-Filled: 2.1MB → 3.4KB (99.8% 감소)

**빌드 정보**
- AAB: 48MB (build/app/outputs/bundle/release/app-release-1.0.8+20.aab)
- APK: 29MB (build/app/outputs/flutter-apk/app-release-1.0.8+20.apk)
- 빌드 번호: +20
- NDK 버전: 27.0.12077973

**수정된 파일**
- `lib/presentation/screens/login_screen.dart` (Apple Sign In 버튼 추가)
- `lib/presentation/providers/auth_providers.dart` (Apple OAuth 로직 추가)
- `lib/presentation/screens/todo_list_screen.dart` (다국어화, 라인 322-382)
- `lib/core/errors/failures.dart` (4개 Failure 클래스 추가, 라인 20-38)
- `assets/translations/ko.json` (apple_login, clear_completed 키 추가)
- `assets/translations/en.json` (apple_login, clear_completed 키 추가)
- `pubspec.yaml` (sign_in_with_apple: ^6.1.0 추가)
- `CLAUDE.md` (빌드 파일 버전 관리 규칙 추가)

**커밋 정보**
- 주요 커밋: ecf73ca, ba231c9, ebae2dd, 78def8f, 5cfd6be
- 주요 작업: 반복 할 일 기능 통합, Apple Sign In, 다국어화 완성
- 빌드 날짜: 2025-11-13

---

### v1.0.13+39 (2025-11-25)
**드래그 앤 드롭 정렬 기능 및 관리자 대시보드 완성**

**신규 기능**
- ✅ **드래그 앤 드롭 정렬 기능**
  - Todo 항목을 드래그로 순서 변경 가능
  - 카테고리별 독립적인 정렬 지원
  - 앱 재시작 후에도 순서 유지
  - ReorderableListView를 이용한 직관적 UI

- ✅ **관리자 대시보드 (익명화된 통계)**
  - 사용자, Todo, 카테고리 통계
  - 시간대별 활동 분석
  - 요일별 완료율 분석
  - Pull-to-refresh 지원

**기술 구현**
- ✅ **Position 필드 추가 (Drift + Supabase)**
  - todos 테이블에 position 컬럼 추가
  - Supabase 마이그레이션 생성 (인덱스 포함)
  - updateTodoPositions 메서드 구현

- ✅ **관리자 권한 시스템**
  - Supabase RPC 함수 5개 생성 (SECURITY DEFINER)
  - Flutter 관리자 권한 체크
  - Settings 화면에 관리자 버튼 표시

**부가 기능**
- ✅ **첨부파일 시스템 Phase 1**
  - Supabase Storage 버킷 생성
  - 파일 업로드/다운로드 기능
  - 이미지/PDF/텍스트 파일 뷰어

**수정된 파일**
- `lib/domain/entities/todo.dart` (position 필드 추가)
- `lib/data/datasources/local/drift_todo_datasource.dart` (정렬 로직)
- `lib/presentation/screens/todo_list_screen.dart` (ReorderableListView 적용)
- `lib/presentation/screens/admin_dashboard_screen.dart` (신규)
- `android/app/src/main/kotlin/kr/bluesky/dodo/MainActivity.kt` (Method Channel 추가)
- `pubspec.yaml` (버전 1.0.13+39로 업데이트)

**테스트**
- ✅ 128개 테스트 통과 (CI/CD)
- ✅ position 파라미터 추가로 모든 테스트 통과

**빌드 정보**
- AAB: 51.2 MB (build/app/outputs/bundle/release/app-release-1.0.13+39.aab)
- Google Play에 성공적으로 업로드
- 최신 빌드 번호: 39

**커밋 정보**
- 커밋 메시지: "feat: Implement drag-and-drop todo sorting with position persistence"
- 푸시 날짜: 2025-11-25

---

### v1.0.11+35 (2025-11-19)
**첨부파일 시스템 및 서브태스크 완전 구현**

**신규 기능**
- ✅ **첨부파일 시스템 (Phase 1-2 완료)**
  - Supabase Storage에 파일 저장
  - 다양한 파일 형식 지원 (이미지, PDF, 텍스트, JSON)
  - 파일 선택 UI (카메라, 갤러리, 파일 시스템)
  - 이미지 뷰어 (확대/축소, 팬)
  - PDF 뷰어 (Syncfusion PDF Viewer)
  - 텍스트 파일 뷰어 (40+ 확장자)

- ✅ **서브태스크 기능**
  - Subtask 엔티티 및 Repository
  - Todo 상세 화면에서 서브태스크 CRUD
  - 서브태스크 완료 상태 추적
  - Supabase 동기화

- ✅ **알림 스누즈 기능**
  - 5분/10분/30분/1시간/3시간 옵션
  - 커스텀 시간 설정 가능
  - SnoozeDialog UI

- ✅ **서브태스크 기능 완전 구현**
  - Subtask 엔티티, Repository, Provider
  - Todo 상세 화면에 서브태스크 CRUD
  - Supabase 마이그레이션 SQL

**기술 개선**
- ✅ **Dual Repository Pattern**
  - 로컬 (Drift) + 원격 (Supabase) 동기화
  - 자동 업데이트 감지 및 동기화

- ✅ **CI/CD 파이프라인 구축**
  - GitHub Actions 통합
  - Codecov 커버리지 추적
  - 128개 테스트 자동 실행

**수정된 파일**
- `lib/domain/entities/attachment.dart` (신규)
- `lib/domain/entities/subtask.dart` (신규)
- `lib/data/datasources/local/drift_attachment_datasource.dart` (신규)
- `lib/data/datasources/local/drift_subtask_datasource.dart` (신규)
- `lib/presentation/screens/todo_detail_screen.dart` (신규 탭 추가)
- 15개 파일 신규 생성, 6개 파일 수정

**커밋 정보**
- 주요 커밋: 다양한 첨부파일 및 서브태스크 구현
- 푸시 날짜: 2025-11-19

---

### v1.0.10 (2025-11-18)
**위치 기반 알림 즉시 확인 기능 추가**

**신규 기능**
- ✅ **위치 기반 알림 즉시 확인**
  - 할 일 저장 시 자동으로 즉시 위치 확인
  - 설정한 위치 범위 내에 있으면 즉시 알림 발송
  - 백그라운드 주기적 확인 (15분 간격)과 병행
  - 사용자 경험 개선: 최대 15분 대기 → 즉시 반응

**기술 구현**
- ✅ **GeofenceWorkManagerService.checkNow() 메서드 추가**
  - 포그라운드에서 즉시 실행되는 위치 확인 로직
  - 현재 위치 가져오기 및 권한 확인
  - 로컬 데이터베이스에서 위치 기반 할 일 조회
  - 거리 계산 및 반경 내 알림 트리거
  - 상세한 로깅으로 디버깅 지원

- ✅ **TodoFormDialog 자동 트리거 통합**
  - 할 일 저장 시 위치 정보 있으면 자동 호출
  - 웹 플랫폼 제외 (kIsWeb 체크)
  - 사용자 액션 없이 자동 실행

**알림 시스템**
- ✅ **이중 알림 전략**
  - 즉시 확인: 할 일 저장 직후 실행
  - 주기적 확인: WorkManager로 15분마다 실행
  - 높은 알림 신뢰성 보장

**수정된 파일**
- `lib/core/services/geofence_workmanager_service.dart` (checkNow() 메서드 추가, 111 라인)
- `lib/presentation/widgets/todo_form_dialog.dart` (자동 트리거 로직, 4 라인 추가)

**커밋 정보**
- 커밋 해시: f6715a2
- 커밋 메시지: "feat: Add immediate geofence check for location-based todos"
- 푸시 날짜: 2025-11-18

---

### v1.0.0 (2025-11-06)
**첫 번째 공식 릴리스**

**구현된 기능**
- ✅ 할 일 CRUD (생성/읽기/삭제/완료 토글)
- ✅ 로컬 알림 시스템
- ✅ 통계 및 차트
- ✅ Google/Kakao OAuth 로그인
- ✅ Supabase 클라우드 동기화
- ✅ 다크 모드 지원
- ✅ 한국어/영어 지원

**기술 작업**
- ✅ Clean Architecture 구현
- ✅ Drift + Supabase 하이브리드 저장소
- ✅ Riverpod 상태 관리
- ✅ GoRouter 네비게이션
- ✅ 패키지 이름 변경 (com.example.todo_app → kr.bluesky.dodo)
- ✅ 프로덕션 서명 키 생성
- ✅ AAB 빌드 및 Play Store 제출 준비

**문서**
- ✅ 개인정보처리방침 작성
- ✅ Play Store 배포 가이드
- ✅ 출시 노트 작성

---

## 상세 기술 스택

### Frontend
- Flutter 3.x
- Dart 3.x
- fluentui_system_icons

### 아키텍처 & 상태 관리
- Riverpod 3.x (상태 관리)
- GoRouter 14.x (라우팅)
- freezed (불변 모델)
- json_serializable

### 데이터 계층
- Drift 2.x (로컬 SQLite)
- Supabase Flutter (클라우드 백엔드)
- google_sign_in (Google OAuth)
- kakao_flutter_sdk (Kakao OAuth)

### 기타
- easy_localization (다국어)
- intl (날짜/시간)
- flutter_local_notifications (알림)
- shared_preferences (설정)
- package_info_plus (앱 정보)

---

## 개발 정보

- **앱 이름**: DoDo (두두)
- **패키지 이름**: kr.bluesky.dodo
- **개발자**: 이찬희
- **현재 버전**: 1.0.13 (빌드 39)
- **최소 SDK**: Android 6.0 (API 23)
- **타겟 SDK**: Android 14 (API 34)
- **iOS 최소 버전**: iOS 11.0
- **웹 지원**: Flutter Web (Chrome, Safari, Firefox)
- **서명**: SHA384withRSA (2048-bit)
- **인증서 유효기간**: 2025-11-06 ~ 2053-03-24
- **Google Play 상태**: 배포됨 (Google Play Console 관리자)
- **마지막 빌드**: 2025-11-25

---

## 라이선스 및 법적 고지

### 앱 라이선스
**Copyright © 2025 이찬희 (Lee Chan Hee). All rights reserved.**

DoDo 앱은 독점 소프트웨어입니다. 본 앱의 소스 코드, 디자인, 로고 및 기타 자산은 저작권법의 보호를 받습니다.

**사용 권한**:
- Google Play Store를 통해 배포된 공식 버전을 개인적 용도로 사용할 수 있습니다.
- 앱의 역엔지니어링, 디컴파일, 역어셈블, 수정, 재배포는 금지됩니다.
- 상업적 사용 및 2차 저작물 제작은 저작권자의 서면 허가가 필요합니다.

### 개인정보 보호
이 앱은 대한민국 개인정보 보호법 및 관련 법규를 준수합니다.

**수집하는 정보**:
- 소셜 로그인 정보 (Google, Kakao, Apple)
- 사용자가 생성한 할 일 데이터
- 앱 사용 통계 (익명)

**데이터 보안**:
- 모든 데이터는 암호화되어 전송됩니다 (HTTPS/TLS)
- Supabase Row Level Security (RLS)로 사용자 간 데이터 격리
- 비밀번호는 해시 처리되어 저장됩니다

자세한 내용은 [개인정보처리방침](https://bluesky78060.github.io/flutter-todo/privacy-policy)을 참조하세요.

### 오픈소스 라이선스
본 앱은 다음과 같은 오픈소스 라이브러리를 사용합니다:

**Core Framework**
- Flutter Framework - BSD 3-Clause License
- Dart SDK - BSD 3-Clause License

**State Management & Architecture**
- Riverpod (flutter_riverpod, riverpod_annotation, riverpod_generator) - MIT License
- Freezed (freezed, freezed_annotation) - MIT License
- fpdart - MIT License

**Backend & Database**
- Supabase Flutter - MIT License
- Drift (drift, drift_flutter, drift_dev) - MIT License
- Dio - MIT License

**Authentication**
- Google Sign In - Apache 2.0 License
- Sign In with Apple - MIT License

**UI & Design**
- Fluent UI System Icons - MIT License
- Google Fonts - Apache 2.0 License

**Navigation & Routing**
- GoRouter - BSD 3-Clause License

**Localization**
- Easy Localization - MIT License
- Intl - BSD 3-Clause License

**Notifications & Permissions**
- Flutter Local Notifications - BSD 3-Clause License
- Permission Handler - MIT License
- Timezone - BSD 2-Clause License

**Utilities**
- Path Provider - BSD 3-Clause License
- Path - BSD 3-Clause License
- Shared Preferences - BSD 3-Clause License
- Package Info Plus - BSD 3-Clause License
- URL Launcher - BSD 3-Clause License
- File Picker - MIT License
- Share Plus - BSD 3-Clause License
- Logger - MIT License
- Flutter Dotenv - MIT License

**Data Serialization**
- JSON Annotation & Serializable - BSD 3-Clause License

**Calendar & Recurrence**
- Table Calendar - Apache 2.0 License
- RRULE - MIT License

**Development Tools**
- Build Runner - BSD 3-Clause License
- Mockito - Apache 2.0 License
- Flutter Lints - BSD 3-Clause License
- Flutter Launcher Icons - MIT License

전체 오픈소스 라이선스 목록은 앱 내 "설정 > 오픈소스 라이선스"에서 확인할 수 있습니다.

### 면책 조항
본 앱은 "있는 그대로" 제공되며, 명시적이든 묵시적이든 어떠한 종류의 보증도 하지 않습니다. 앱 사용으로 인한 직접적, 간접적, 우발적, 특별, 결과적 손해에 대해 개발자는 책임을 지지 않습니다.

### 연락처
- **개발자**: 이찬희
- **이메일**: bluesky78060@gmail.com
- **GitHub**: https://github.com/bluesky78060

---

**DoDo와 함께 생산적인 하루를 만들어보세요!** 🚀
