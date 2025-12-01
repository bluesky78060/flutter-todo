# 향후 추가 기능 및 개선 사항

현재 버전: **1.0.15+47** (데이터 내보내기 기능 추가)
최종 업데이트: **2025-12-01**

## 우선순위 분류
- 🔴 **High**: 핵심 기능, 사용자 경험에 직접적 영향
- 🟡 **Medium**: 편의성 향상, 부가 기능
- 🟢 **Low**: Nice-to-have, 장기적 개선

---

## ✅ 완료된 작업 (Completed)

### 2025-12-01 (심야) - Phase 2: 장기 추이 분석 카드 구현 ✨
- ✅ **통계 화면 Phase 2: 월간 추이 분석 카드**
  - **목표**: 지난 12개월 완료 추이를 시각적으로 표시하는 카드 추가
  - **구현 내용**:
    - 12개월 라인 차트: 월별 완료 수 추이를 곡선 그래프로 표시
    - 통계 정보: 연간 총합, 월평균, 최고기록
    - 트렌드 인디케이터: 상반기 vs 하반기 비교로 추이 방향 표시 (↑/↓/→)
    - 컬러 코딩: 최고월 초록, 최저월 빨강, 일반 월 파랑
    - 인터렉티브 차트: 터치 시 월과 완료 수 표시
    - 평균선 표시: 월평균 라인 시각화
  - **신규 필드**:
    - `_StatisticsData.yearlyCompletions`: Map<int, int> - 12개월 완료 데이터
  - **신규 클래스**:
    - `_MonthlyAnalysisCard` - 12개월 추이 분석 위젯 (340줄)
  - **수정된 파일**:
    - `lib/presentation/screens/statistics_screen.dart` - 연간 데이터 계산 및 카드 추가 (+370줄)
    - `assets/translations/ko.json` - "월간 추이 분석", "연간 총합" 등 번역 추가
    - `assets/translations/en.json` - "12-Month Trend", "Annual Total" 등 번역 추가
  - **테스트**: ✅ Flutter analyze 통과 (기존 에러 제외)
  - **버전**: 1.0.17+49 (예정)
  - **커밋**: Phase 2 구현 완료 (미커밋)

### 2025-12-01 (심야) - Phase 1: 카테고리별 분석 카드 구현 ✨
- ✅ **통계 화면 Phase 1: 카테고리별 분석 카드**
  - **목표**: 각 카테고리별 완료율을 시각적으로 표시하는 카드 추가
  - **구현 내용**:
    - 상위 5개 카테고리를 완료율 기준으로 정렬하여 표시
    - 색상 코딩: 초록(≥75%), 주황(≥50%), 빨강(<50%)
    - 카테고리 미지정 할일도 별도로 표시
    - 진행률 및 완료/전체 카운트 표시
  - **신규 클래스**:
    - `_CategoryStats` - 카테고리별 통계 데이터 모델
    - `_CategoryAnalysisCard` - 카테고리 분석 시각화 위젯
  - **수정된 파일**:
    - `lib/presentation/screens/statistics_screen.dart` - 카테고리 데이터 페칭 및 카드 추가
    - `assets/translations/ko.json` - "카테고리별 완료율", "카테고리 미지정"
    - `assets/translations/en.json` - "Completion by Category", "Uncategorized"
  - **테스트**: ✅ Release APK v1.0.16+48 빌드 성공, 기기 설치 및 실행 완료
  - **버전**: 1.0.16+48
  - **커밋**: 673595c (feat: Phase 1 카테고리별 분석 카드 구현)

### 2025-12-01 - 데이터 내보내기 (CSV, PDF) 기능 구현 ✨
- ✅ **데이터 내보내기 (CSV, PDF) 기능**
  - **목표**: 사용자가 모든 할 일 데이터를 CSV 또는 PDF 형식으로 내보내고 공유할 수 있도록 하는 기능
  - **구현 내용**:
    - CSV 내보내기: 스프레드시트 형식 (ID, 제목, 설명, 상태, 마감일, 카테고리, 생성일)
    - PDF 내보내기: 스타일링된 문서 (헤더, 요약, 테이블)
    - 파일 공유: Android/iOS 기본 공유 메뉴 통합
    - 다국화: 한국어/영어 모두 지원
    - UTF-8 인코딩: 한글 완벽 지원
  - **신규 파일**:
    - `lib/core/services/export_service.dart` (303줄): CSV/PDF 생성 로직
    - `lib/presentation/providers/export_provider.dart` (25줄): Riverpod 상태 관리
  - **수정 파일**:
    - `lib/presentation/screens/settings_screen.dart`: 설정 UI 추가
    - `pubspec.yaml`: csv, pdf 의존성 추가
    - `assets/translations/ko.json`, `en.json`: 다국화 문자열 추가
  - **테스트**: ✅ Debug APK 빌드 성공, 모든 컴파일 에러 해결
  - **버전**: 1.0.15+47
  - **커밋**: e3b3251 (feat: 데이터 내보내기 (CSV, PDF) 기능 구현)

### 2025-12-01 (심야) - Phase 5 리팩토링
- ✅ **todo_list_screen.dart 리팩토링 Phase 5: 다이얼로그 헬퍼 함수 추출**
  - **목표**: 다이얼로그 구성 로직을 재사용 가능한 헬퍼 함수로 이동 (~50줄 제거)
  - **생성한 유틸리티**:
    - `showClearCompletedDialog()` in `lib/presentation/utils/dialog_helpers_utils.dart` (87줄)
      - 완료된 todos 삭제 확인 다이얼로그
      - 테마 인식 (dark/light 모드 자동 지원)
      - 삭제 버튼은 danger red 색상
    - `showRecurringDeleteDialog()` (9줄)
      - 반복 todos 삭제 시 모드 선택 다이얼로그
      - RecurringDeleteDialog 위젯 활용
    - `showConfirmationDialog()` (47줄)
      - 범용 확인 다이얼로그 헬퍼
      - 제목, 메시지, 버튼 텍스트 커스터마이징 가능
      - isDangerous 플래그로 버튼 색상 동적 제어
  - **수정된 메서드** (todo_list_screen.dart에서):
    - `_handleDelete()` - showRecurringDeleteDialog() 호출로 간소화 (18줄 → 11줄)
    - `_handleClearCompleted()` - showClearCompletedDialog() 호출로 간소화 (35줄 → 3줄)
  - **개선 사항**:
    - 다이얼로그 코드 완전 분리 (재사용 가능, 테스트 용이)
    - todo_list_screen.dart에서 ~50줄 제거 (900줄 → 869줄, 3.4% 감소)
    - 다이얼로그 UI 코드 중복 제거 (showConfirmationDialog 통일)
    - 테마 인식 다이얼로그 (어두운 모드 자동 지원)
  - **누적 감소**:
    - Phase 1-5: 1931줄 → 869줄 (1062줄 제거, 55% 감소)
    - 추출된 유틸리티/서비스: ~1000줄 (재사용 가능)
  - **테스트**: Release APK 빌드 (61.1MB) 및 기기 설치/실행 완료 ✅
  - **로그**: No Flutter errors, all dialog functions working correctly ✅

### 2025-12-01 (심야) - Phase 4 리팩토링
- ✅ **todo_list_screen.dart 리팩토링 Phase 4: 레이아웃 빌더 함수 추출**
  - **목표**: UI 구성 로직을 재사용 가능한 빌더 함수로 이동 (170줄 제거)
  - **생성한 유틸리티**:
    - `buildHeaderSection()` in `lib/presentation/utils/layout_builders_utils.dart` (86줄)
      - 제목, 부제목, 4개 액션 버튼 (새로고침, 삭제, 달력, 추가)
      - `_buildHeaderActionButton()` 헬퍼 위젯 포함
    - `buildFilterChips()` (49줄)
      - 필터 칩 (All, Pending, Completed) 렌더링
      - todo 개수 계산 및 카운트 표시
    - `buildSearchBar()` (64줄)
      - 검색 입력 필드 with 클리어 기능
      - ValueListenableBuilder로 반응형 UI
    - `buildCategoryFilter()` (52줄)
      - 가로 스크롤 가능한 카테고리 칩
      - 선택된 카테고리 표시
    - `buildQuickAddInput()` (44줄)
      - 빠른 할일 추가 입력 필드
  - **수정된 파일**:
    - `lib/presentation/screens/todo_list_screen.dart` - 빌더 함수 호출로 교체
    - `lib/presentation/utils/layout_builders_utils.dart` - 새 유틸리티 파일 (448줄)
  - **개선 사항**:
    - todo_list_screen.dart에서 335줄 제거 (1235줄 → 900줄, 27.1% 감소)
    - 누적 감소: Phase 1-4: 1931줄 → 1980줄 분산
      - todo_list_screen.dart: 1931줄 → 900줄 (1031줄 제거, 53.4%)
      - 추출된 유틸리티/서비스: 1080줄 (재사용 가능)
    - 헤더 섹션 UI 코드 완전 분리 및 재사용 가능
    - 각 UI 섹션이 독립적 함수로 테스트 가능
    - 메인 스크린 클래스의 복잡도 대폭 감소
  - **테스트**: Release APK 빌드 (61.1MB) 및 기기 설치/실행 완료 ✅
  - **로그**: No Flutter errors, all UI components rendering correctly ✅

### 2025-12-01 (심야)
- ✅ **todo_list_screen.dart 리팩토링 Phase 3: 유틸리티 함수 추출**
  - **목표**: 그룹화 및 재정렬 로직을 유틸리티로 이동 (107줄 제거)
  - **생성한 유틸리티**:
    - `groupTodosBySeries()` in `lib/presentation/utils/todo_grouping_utils.dart` (135줄)
      - 반복 시리즈별로 todos 그룹화
      - 마감일 기준 정렬 (null dates는 마지막)
      - 단일 및 반복 todos 혼합 처리
    - `reorderTodos()` in `lib/presentation/utils/todo_reorder_utils.dart` (161줄)
      - 드래그-드롭 재정렬 로직 (그룹 무결성 유지)
      - 실제 position 계산 및 업데이트
      - ReorderResult 클래스로 타입 안전성 보장
    - 헬퍼: `flattenTodos()`, `calculateGroupStartPosition()` - 유틸리티 함수
  - **삭제된 메서드** (todo_list_screen.dart에서):
    - `_groupTodosBySeries()` (61줄)
    - `_onReorder()` (46줄 → 11줄로 간소화)
  - **개선 사항**:
    - 유틸리티 함수 완전 분리 (테스트 및 재사용 가능)
    - todo_list_screen.dart에서 107줄 제거 (1341줄 → 1235줄, 8% 감소)
    - 유틸리티 코드 완전 독립화로 메인 로직 단순화
    - 타입 안전성 향상 (ReorderResult struct 사용)
  - **누적 감소**:
    - Phase 1 + Phase 2 + Phase 3: 1931줄 → 1235줄 (696줄 제거, 36% 감소)
  - **테스트**: Release APK 빌드 (61.1MB) 및 기기 설치/실행 완료 ✅
  - **로그**: No Flutter errors, grouping and reordering working correctly ✅

- ✅ **todo_list_screen.dart 리팩토링 Phase 2: 권한 요청 로직 추출**
  - **목표**: 권한 요청 메서드들을 전용 서비스로 이동 (248줄 제거)
  - **생성한 서비스**:
    - `PermissionRequestService` in `lib/presentation/services/permission_request_service.dart` (336줄)
    - 메서드: `requestNotificationPermission()`, `requestLocationPermission()`, `requestExactAlarmPermission()`, `requestBatteryOptimization()`
    - 헬퍼: `showPermissionDialog()` - 테마 인식 다이얼로그 빌더
    - 내부 헬퍼: `_showNotificationSettingsGuide()` - 알림 설정 가이드
  - **삭제된 메서드** (todo_list_screen.dart에서):
    - `_requestNotificationPermission()` (36줄)
    - `_showNotificationSettingsGuide()` (42줄)
    - `_requestLocationPermission()` (69줄)
    - `_requestBatteryOptimization()` (42줄)
    - `_requestExactAlarmPermission()` (50줄)
    - 미사용 import 제거: geolocator, notification_service, battery_optimization_service
  - **개선 사항**:
    - 권한 로직 완전 중앙화 (재사용 가능한 서비스)
    - todo_list_screen.dart에서 248줄 제거 (1589줄 → 1341줄, 15.6% 감소)
    - 다이얼로그 코드 중복 제거 (showPermissionDialog 통일)
    - 테마 인식 다이얼로그 (어두운 모드 자동 지원)
    - 불필요한 import 제거로 컴파일 시간 단축
  - **누적 감소**:
    - Phase 1 + Phase 2: 1931줄 → 1341줄 (590줄 제거, 30.6% 감소)
  - **테스트**: Release APK 빌드 (61.1MB) 및 기기 설치/실행 완료 ✅
  - **로그**: No Flutter errors, permissions flow working correctly ✅

- ✅ **todo_list_screen.dart 리팩토링 Phase 1: 중첩 위젯 추출**
  - **목표**: 1931줄 → 1589줄 (342줄 제거, 18% 감소)
  - **추출한 위젯**:
    - `_FilterChip` → `TodoFilterChip` in `filter_chip.dart` (52줄)
    - `_NavItem` → `NavItem` in `nav_item.dart` (68줄)
    - `_CategoryChip` → `CategoryChip` in `category_chip.dart` (74줄)
    - `_RecurringTodoGroup` → `RecurringTodoGroup` in `recurring_todo_group.dart` (147줄)
  - **개선 사항**:
    - 메인 스크린 클래스 단순화 (1589줄로 감소)
    - 각 위젯이 독립 파일에서 재사용 가능
    - 코드 복잡도 감소 및 테스트 용이성 향상
    - 이름 충돌 해결 (Material FilterChip과 구분)
  - **테스트**: Release APK 빌드 (61.1MB) 및 기기 설치/실행 완료
  - **로그**: No Flutter errors, all initialization successful

### 2025-12-01 (저녁)
- ✅ **태블릿 레이아웃 구현 (11.1)**
  - **마스터-디테일 분할 뷰**: 태블릿 이상 화면에서 좌측 할일 목록(40%), 우측 할일 상세(60%)
  - **반응형 레이아웃**: `ResponsiveUtils.isTabletOrLarger()` 기반으로 자동 레이아웃 선택
    - 휴대폰: 기존 단일 컬럼 레이아웃 유지 (전체 화면 목록)
    - 태블릿/데스크톱: 분할 뷰 (좌측 목록 + 우측 상세정보)
  - **TodoDetailContent 재사용 위젯**: 독립형 상세 화면과 분할 뷰 모두에서 사용 가능
    - 포함 내용: 할일 정보, 반복 설정, 서브태스크, 첨부파일, 스누즈, 미루기
  - **상태 동기화**: `_selectedTodoId` 상태로 좌우 패널 간 선택 동기화
  - **UI 개선**: 선택된 할일에 파란 테두리, 플레이스홀더 표시
  - **수정된 파일**:
    - `lib/presentation/screens/todo_list_screen.dart` - Split view 구현
    - `lib/presentation/widgets/todo_detail_content.dart` - 재사용 가능한 상세 위젯
    - `lib/core/utils/responsive_utils.dart` (이전 세션)
  - **테스트**: Release APK 빌드 (61.1MB) 및 기기 설치/실행 완료

### 2025-12-01 (오후)
- ✅ **성능 최적화 (8.2)**
  - **N+1 쿼리 패턴 수정**: `updateTodoPositions`에서 배치 업데이트 사용
    - 기존: N개 todo 각각 개별 UPDATE 쿼리 (50개면 50회 DB 호출)
    - 개선: Drift batch 작업으로 단일 트랜잭션 처리
  - **const 최적화**: `CustomTodoItem` 위젯 성능 개선
    - `Duration`, `EdgeInsets`, `BorderRadius` 등 static const 변환
    - `Icon`, `SizedBox` 위젯에 const 생성자 적용
    - 불필요한 객체 재생성 방지로 메모리 사용량 감소
  - **수정된 파일**:
    - `lib/data/datasources/local/app_database.dart` - batchUpdateTodoPositions 추가
    - `lib/data/repositories/todo_repository_impl.dart` - 배치 업데이트 사용
    - `lib/presentation/widgets/custom_todo_item.dart` - const 최적화 적용

- ✅ **통계 화면 그래프 및 추이 분석 개선 (6.1)**
  - fl_chart 라이브러리 추가 (v0.69.0)
  - **완료율 파이 차트**: 전체 진행률을 시각적으로 표시
  - **주간 바 차트**: 요일별 완료 현황 표시 (월~일)
  - **월간 라인 차트**: 최근 4주간 추이 분석
  - **연속 완료 스트릭**: 연속으로 할일을 완료한 일수 표시
  - **최고 기록 카운터**: 하루에 가장 많이 완료한 할일 수 표시
  - **다국어 지원**: 새로운 통계 텍스트 모두 번역 키로 처리
  - **수정된 파일**:
    - `pubspec.yaml` - fl_chart 의존성 추가
    - `lib/presentation/screens/statistics_screen.dart` - 전면 재작성
    - `assets/translations/en.json` - 영어 번역 키 추가
    - `assets/translations/ko.json` - 한국어 번역 키 추가
  - **추가된 번역 키**:
    - current_streak, best_day, this_week, days, tasks
    - weekly_trend, monthly_trend
    - week_4_ago, week_3_ago, week_2_ago, last_week
    - day_mon ~ day_sun

- ✅ **위젯 삭제 버튼 제거 및 완료 토글만 유지**
  - 사용자 요청으로 위젯에서 삭제 버튼 제거
  - 완료 체크박스 토글 기능만 유지
  - **수정된 파일**:
    - `android/app/src/main/res/layout/widget_todo_list.xml` - 3개 삭제 버튼 제거
    - `android/.../widgets/TodoListWidget.kt` - 삭제 버튼 핸들러 제거
    - `android/.../widgets/WidgetActionReceiver.kt` - DELETE_TODO 액션 제거

- ✅ **위젯 체크박스 토글 Supabase 동기화 수정**
  - 문제: 체크박스 토글 시 "✓ 완료!" 후 원래 상태로 되돌아감
  - 원인: 로컬 SQLite 업데이트 시도 → 데이터 없음 (Supabase가 주 저장소)
  - 해결: MethodChannel-first 방식으로 복원 (기술문서 참조)
    - PRIMARY: Flutter MethodChannel → TodoActions → Supabase 동기화
    - FALLBACK: 앱 닫힘 시 로컬 SQLite 업데이트
  - **참조 문서**: `claudedocs/2024-11-30_WIDGET_IMPROVEMENTS.md`

- ✅ **위젯 제목 한글화**
  - 하드코딩된 "Today's Tasks" → `@string/widget_today_tasks` 리소스 키 사용
  - 한국어 기기: "할일" / 영어 기기: "Tasks"
  - **수정 파일**: `widget_todo_list.xml`

- ✅ **위젯 설정 화면 미리보기 다국어화**
  - 할일 미리보기: "Task 1~3" → "할일 1~3" (한국어)
  - 캘린더 미리보기: "November 2025" → "2025년 12월" (현재 날짜 기준 동적)
  - **추가된 번역 키**:
    - `widget_preview_task_1~3`: Task 1~3 / 할일 1~3
    - `widget_preview_month_year`: {month} {year} / {year}년 {month}
    - `month_january~december`: January~December / 1월~12월
  - **수정된 파일**:
    - `assets/translations/en.json` - 영어 번역 키 추가
    - `assets/translations/ko.json` - 한국어 번역 키 추가
    - `lib/presentation/screens/widget_config_screen.dart` - 미리보기에서 번역 키 사용

### 2025-12-01 (오전)
- ✅ **위젯 고급 기능 완전 구현** (4.4 - 83% 완료)
  - ✅ **일자별 할일 그룹 표시**
    - 오늘, 내일, 이번 주, 다음 주, 나중에, 지남 그룹 라벨
    - 테마별 그룹 라벨 색상 적용
    - Flutter widget_service.dart에서 날짜별 정렬 및 그룹화
  - ✅ **위젯에서 직접 삭제 기능**
    - 각 할일 항목에 삭제 버튼 추가
    - WidgetActionReceiver에서 DELETE_TODO 액션 처리
    - Flutter 앱 실행 중: MethodChannel로 동기화
    - 앱 미실행 시: SQLite 직접 삭제 후 위젯 새로고침
  - ✅ **완료 진행률 표시**
    - 헤더에 "X/Y 완료" 형식으로 진행률 표시
    - 오늘 할일 기준으로 완료/전체 카운트
    - 테마별 진행률 텍스트 색상 적용
  - **수정된 파일**: 8개
    - `android/app/src/main/res/values/strings.xml` - 영어 번역
    - `android/app/src/main/res/values-ko/strings.xml` - 한국어 번역
    - `android/app/src/main/res/layout/widget_todo_list.xml` - 레이아웃
    - `android/app/src/main/res/drawable/widget_delete_icon.xml` - 삭제 아이콘
    - `android/.../widgets/TodoListWidget.kt` - 그룹/진행률 표시 로직
    - `android/.../widgets/WidgetActionReceiver.kt` - 삭제 액션 처리
    - `lib/core/widget/widget_service.dart` - Flutter 데이터 준비
    - `lib/presentation/screens/theme_preview_screen.dart` - 빌드 오류 수정

- ✅ **전체 Dart 파일 dartdoc 문서화 완료**
  - Clean Architecture 전 레이어에 dartdoc 주석 추가 (60+ 파일)
  - **Core Layer**: config/, router/, services/, theme/, utils/
  - **Data Layer**: datasources/, models/, repositories/
  - **Domain Layer**: entities/, repositories/
  - **Presentation Layer**: providers/, screens/, widgets/
  - 각 파일에 library-level dartdoc 추가 (목적, 기능, See also)
  - 코드 주석화 수준: 전문 API 문서 품질
  - 향후 `dart doc` 명령으로 HTML 문서 생성 가능

### 2025-11-30
- ✅ **전체 앱 다국어(i18n) 지원 완성**
  - 모든 하드코딩된 문자열을 번역 키로 변경
  - 디바이스 시스템 언어에 따라 자동 언어 전환 (한국어/영어)
  - Easy Localization `tr()` 함수 전면 적용
  - **수정된 Flutter 파일**: 6개
    - `lib/presentation/providers/connectivity_provider.dart` - 시간 문자열 (방금 전, 분 전, 시간 전 등)
    - `lib/core/services/notification_service.dart` - 알림 요약 텍스트
    - `lib/core/services/web_notification_service.dart` - 웹 테스트 알림 텍스트
    - `lib/presentation/screens/theme_preview_screen.dart` - 테마 미리보기 UI
    - `lib/presentation/screens/admin_dashboard_screen.dart` - 관리자 대시보드 전체
    - `lib/presentation/widgets/location_picker_dialog.dart` - 위치 검색 메시지
  - **번역 키 추가**: 60+ 개
    - 시간 표시: time_just_now, time_minutes_ago, time_hours_ago, time_days_ago
    - 알림: notification_todo_reminder, notification_location_reminder, notification_within_meters
    - 테마 미리보기: preview_category_*, preview_todo_*, preview_button_styles 등
    - 관리자 대시보드: admin_dashboard, access_denied, user_statistics, todo_statistics 등
    - 성능 등급: performance_grade_excellent, performance_rec_great 등
  - **Android 위젯 리소스 업데이트**:
    - `android/app/src/main/res/values/strings.xml` (영어)
      - widget_todo_list_description: "Displays today's todo tasks on your home screen"
      - widget_calendar_description: "Displays a monthly calendar with task indicators"
      - widget_today_tasks: "Tasks"
      - widget_task_1 ~ widget_task_5: "Task 1" ~ "Task 5"
      - widget_tap_to_view: "Tap to view all tasks"
      - widget_calendar_title: "December 2025"
      - widget_day_mon ~ widget_day_sun: "Mon" ~ "Sun"
    - `android/app/src/main/res/values-ko/strings.xml` (한국어)
      - widget_todo_list_description: "홈 화면에 오늘의 할 일을 표시합니다"
      - widget_calendar_description: "할 일이 표시된 월간 캘린더를 보여줍니다"
      - widget_today_tasks: "할일"
      - widget_task_1 ~ widget_task_5: "할 일 1" ~ "할 일 5"
      - widget_tap_to_view: "탭하여 전체 보기"
      - widget_calendar_title: "2025년 12월"
      - widget_day_mon ~ widget_day_sun: "월" ~ "일"
  - **위젯 다국어 지원 방식**:
    - Android 네이티브 위젯은 Flutter Easy Localization을 사용할 수 없음
    - Android 표준 리소스 시스템 사용 (`res/values/`, `res/values-ko/`)
    - 시스템 언어 설정에 따라 자동으로 적절한 strings.xml 로드
    - 위젯 Kotlin 코드에서 `context.getString(R.string.widget_xxx)` 호출

### 2025-11-27
- ✅ **위젯 UI 개선 및 다국어 지원**
  - 위젯 제목 변경: "오늘의 할 일" → "할일" (strings.xml, ko.json)
  - 투명 테마 가독성 개선: 회색 텍스트 → 흰색 텍스트 (TodoListWidget.kt, TodoCalendarWidget.kt)
  - 위젯 설정 화면 다국어 지원 (widget_config_screen.dart)
    - 하드코딩된 한글을 번역 키로 변경 (`tr()` 함수 사용)
    - 테마 이름: 라이트, 다크, 투명, 블루, 퍼플
    - UI 텍스트: 테마 선택, 미리보기, 탭하여 모든 할일 보기
  - 영어 번역 키 추가 (en.json): theme_light, theme_dark, theme_transparent 등
  - 요일 번역 키 추가: day_sun, day_mon, day_tue, day_wed, day_thu, day_fri, day_sat
  - **수정된 파일**: 6개
    - `android/app/src/main/res/values-ko/strings.xml`
    - `android/app/src/main/kotlin/kr/bluesky/dodo/widgets/TodoListWidget.kt`
    - `android/app/src/main/kotlin/kr/bluesky/dodo/widgets/TodoCalendarWidget.kt`
    - `lib/presentation/screens/widget_config_screen.dart`
    - `assets/translations/ko.json`
    - `assets/translations/en.json`

- ✅ **고급 위젯 기술 문서화**
  - FUTURE_TASKS.md에 섹션 4.4 추가 (삼성 스타일 인터랙티브 위젯)
  - 상세 기술 가이드 생성: `claudedocs/WIDGET_ADVANCED_IMPLEMENTATION.md` (600+ 라인)
    - RemoteViewsService/RemoteViewsFactory 아키텍처
    - BroadcastReceiver 위젯 액션 처리
    - PendingIntent 개별 아이템 클릭
    - Flutter MethodChannel 연동
    - 레이아웃 XML 예시
    - 단계별 구현 계획 (1-2주)

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

### 📅 다국가 휴일 지원 아키텍처 설계 (Design Phase)
**상태**: 🟡 Design Document 완료, 구현 대기
**우선순위**: Medium
**예상 기간**: 5-7일 (5개 Phase)

**개요**:
- 사용자가 Settings에서 휴일 표시 국가 선택 가능
- 선택된 국가의 휴일만 달력에 표시
- Factory 패턴으로 새 국가 쉽게 추가 가능

**설계 내용**:
- ✅ `HolidayService` 추상 인터페이스 설계
- ✅ `HolidayRegion` Enum (한국, 미국, 일본, 영국)
- ✅ Factory 패턴 구현 계획
- ✅ Riverpod Provider 상태 관리 설계
- ✅ Settings UI 및 Calendar 통합 설계
- ✅ SharedPreferences 영속성 설계

**기술 문서**: `claudedocs/MULTI_COUNTRY_HOLIDAY_SUPPORT.md` (작성 완료)

**구현 Phase**:
1. **Phase 1** (1-2일): 기초 구조
   - [ ] `holiday_service.dart` - 추상 인터페이스
   - [ ] `holiday_region.dart` - Enum 정의
   - [ ] `holiday_service_factory.dart` - Factory 패턴
   - [ ] 기존 `KoreanHolidayService` 인터페이스 상속

2. **Phase 2** (1-2일): 추가 국가 구현
   - [ ] `us_holiday_service.dart` - 미국 휴일
   - [ ] `japan_holiday_service.dart` - 일본 휴일
   - [ ] `uk_holiday_service.dart` - 영국 휴일

3. **Phase 3** (1일): Riverpod 통합
   - [ ] `settings_providers.dart` - Provider 추가
   - [ ] SharedPreferences 영속성
   - [ ] 앱 시작 시 설정 로드

4. **Phase 4** (1-2일): UI 구현
   - [ ] Settings 화면 - 국가 선택 UI
   - [ ] Calendar 화면 - 동적 휴일 표시
   - [ ] 다국화 문자열 추가 (en.json, ko.json)

5. **Phase 5** (1일): 완성 및 검증
   - [ ] 모든 국가별 휴일 테스트
   - [ ] 성능 검증 (캐싱)
   - [ ] Release APK 빌드 및 기기 테스트

**성능 최적화**:
- 월별 캐시: ~3KB (7년)
- 싱글톤 서비스 인스턴스
- 국가 변경 시에만 새로운 호출

**확장성**:
- 새 국가 추가: 새 Service 클래스 생성 + Factory 수정만 필요
- API 기반 방식으로 나중에 전환 가능 (Nager.Date 등)

**테스트 난이도**: 낮음 (모의 데이터 사용)

---

## 📊 통계 화면 개선 - Phase 2, 3 (계획)

### Phase 2: 장기 추이 분석 카드 구현 (예정)
**목표**: 월간/연간 패턴 분석 추가

**구현 내용**:
1. 월간 통계 확장
   - 기존: 4주 (최근 한 달)
   - 추가: 12개월 데이터 (연간 추이)

2. 새로운 카드: `_MonthlyAnalysisCard`
   - 월별 완료 수 라인 차트
   - 평균선 표시 (전체 평균과 비교)
   - 최고/최저 달 강조

3. 생산성 지표 추가
   - 월간 평균 완료 수
   - 최고 생산성 월
   - 추이 방향 (↑/↓/→)

**수정 파일**:
- `lib/presentation/screens/statistics_screen.dart` (약 +120줄)

**사용 라이브러리**: 기존 fl_chart 활용

**예상 기간**: 30분

---

### Phase 3: 고급 분석 및 인사이트 카드 구현 (예정)
**목표**: 사용자 패턴 분석 및 추천

**구현 내용**:
1. 요일별 패턴 분석
   - 새로운 카드: `_WeeklyPatternCard`
   - 각 요일별 평균 완료 수 표시
   - 최고 생산성 요일 강조
   - 선택 가능한 필터 (이번주/지난주/전체)

2. 타임 히트맵 (선택사항)
   - 시간대별 완료 분포 (24시간)
   - 히트맵으로 시각화
   - 최고 활동 시간대 표시

3. 인사이트 섹션
   - 새로운 카드: `_InsightsCard`
   - 자동 생성되는 분석 문구:
     - "월요일에 가장 생산적입니다 💪"
     - "평균 3.2시간 내에 작업을 완료합니다 ⏱️"
     - "지난달 대비 15% 향상했습니다 📈"
     - "최고 기록: 한 날에 12개 완료 🔥"

**수정 파일**:
- `lib/presentation/screens/statistics_screen.dart` (약 +200줄)

**새로운 가능 의존성**: 선택사항 (현재 라이브러리로 구현 가능)

**예상 기간**: 30분

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

**완료된 개선사항**:
- ✅ 파일 크기 제한 (10MB) 구현
- ✅ 첨부파일 개수 제한 (10개) 구현

**향후 개선사항**:
- [x] 개별 파일 삭제 UI
- [x] 다운로드 버튼 추가
- [x] 웹 플랫폼 파일 업로드 지원

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

#### ✅ 2.3 데이터 내보내기 (CSV, PDF) - 완료 (2025-12-01)
- ✅ CSV/PDF 생성 로직
- ✅ 내보내기 옵션 UI
- ✅ 파일 공유 기능

**완료됨**: 2025-12-01 | **커밋**: e3b3251

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
| **4.4 홈 화면 위젯 고급 기능** | ✅ 완료 | 삼성 스타일 인터랙티브 위젯 (6/6 완료) | 완료됨 |

#### ✅ 4.4 홈 화면 위젯 고급 기능 (Samsung Style Interactive Widget) - 83% 완료
**우선순위**: High - 사용자 경험 대폭 향상
**완료 상태**: 5/6 기능 구현 (2025-12-01)

**현재 상태**:
- 기본 위젯 구현됨 (할일 리스트, 캘린더)
- 테마 지원 (light, dark, transparent, blue, purple)
- 월 네비게이션 (캘린더 위젯)

**요청된 기능** (삼성 리마인더/캘린더 스타일):
- [x] 일자별 할일 그룹 표시 (오늘, 내일, 이번 주 등) ✅ (2025-12-01)
- [x] 위젯에서 직접 완료 체크박스 토글 ✅ (WidgetActionReceiver + SQLite 직접 업데이트)
- [x] 위젯에서 직접 할일 삭제 (삭제 버튼) ✅ (2025-12-01, SQLite + MethodChannel)
- [x] + 버튼으로 DoDo 앱 할일 추가 화면 바로 열기 ✅ (dodo://add-todo URI)
- [x] 완료 진행률 표시 ("X/Y 완료" 형식) ✅ (2025-12-01)
- [x] 다가오는 이벤트 섹션 (캘린더 위젯) ✅ (updateEventsSection 구현 완료)

**기술 요구사항**:
- `RemoteViewsService` + `RemoteViewsFactory` (동적 ListView)
- `PendingIntent` per item (개별 아이템 클릭 처리)
- `BroadcastReceiver` (위젯 버튼 액션 처리)
- `MethodChannel` (Flutter ↔ Native 데이터 동기화)
- Configuration Activity (위젯 추가 시 설정)

**참고 문서**: `claudedocs/WIDGET_ADVANCED_IMPLEMENTATION.md`

### 5. 협업 및 공유

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **5.1 Todo 공유** | 🟡 예정 | 공유 링크, 읽기전용, 권한 설정 | 1-2일 |
| **5.2 팀 협업** | 🟢 예정 | 워크스페이스, 초대, 실시간 협업 | 1-2주 |

### 6. 통계 및 분석

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **6.1 통계 개선** | ✅ 완료 | 그래프, 추이 분석, 생산성 리포트 | 완료 |
| **6.2 타임 트래킹** | 🟢 예정 | 타이머, 작업 시간, 리포트 | 1-2일 |

### 7. 인증 및 계정

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **7.2 프로필 관리** | 🟡 예정 | 프로필 사진, 닉네임, 메타데이터 | 4-6시간 |
| **7.3 계정 삭제** | 🟢 예정 | 삭제 UI, 확인 다이얼로그, 데이터 초기화 | 3-4시간 |

### 8. 성능 및 안정성

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **8.2 성능 최적화** | ✅ 완료 | N+1 쿼리 수정, const 최적화 적용 (2025-12-01) | 완료됨 |
| **8.3 테스트 커버리지** | 🟡 진행 | 18-19% → 50%+ 목표 (137개 → 300+ 테스트) | 지속적 |

### 9. 접근성 및 국제화

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **9.1 접근성** | 🟡 예정 | 스크린리더, 키보드 네비게이션, 고대비 | 1-2일 |
| **9.2 하드코딩 제거** | ✅ 완료 | 모든 파일 번역 키 적용 완료 | 완료됨 |
| **9.3 추가 언어** | 🟢 예정 | 일본어, 중국어, 스페인어 등 | 언어당 4-6시간 |

### 10. 마케팅 및 수익화

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **10.1 프리미엄 기능** | 🟢 예정 | In-App Purchase, 페이월 UI | 1-2주 |
| **10.2 광고 통합** | 🟢 예정 | AdMob, 배너/전면 광고 | 4-6시간 |

### 11. 플랫폼별 최적화

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **11.1 태블릿 레이아웃** | ✅ 완료 | Split view, 반응형 레이아웃 | 완료 (2025-12-01) |
| **11.2 웹 최적화** | 🟢 예정 | 데스크톱 레이아웃, 단축키, PWA | 2-3일 |

### 12-13. 개발자 경험 및 보안

| 기능 | 상태 | 세부사항 | 예상시간 |
|------|------|---------|---------|
| **12.2 문서화** | ✅ 완료 | dartdoc 완료 (60+ 파일), 아키텍처 다이어그램 향후 | 완료됨 |
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
- [x] 하드코딩 한글 제거 (번역 키 적용) - ✅ 완료 (2025-11-30)
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
| `todo_list_screen.dart` | ✅ 리팩토링 완료 (869줄) | 5 Phase 완료 (1931→869, 55% 감소) | ✅ |
| `notification_service.dart` | 플랫폼별 분기 많음 | 추상화, 인터페이스 정의 | 🟡 중간 |
| `todo_providers.dart` | TodoActions 복잡함 | 로직 분리, 헬퍼 메서드 | 🟡 중간 |
| 테스트 커버리지 | 18-19% (137개 테스트) | 50%+ 목표 | 🟢 낮음 |

### 완료된 Phase 5 리팩토링 요약
**전체 진행율**: Phase 1-5 완료 (100%)
- **최초**: 1931줄 (단일 파일, 높은 복잡도)
- **현재**: 869줄 + 재사용 유틸리티 1000줄 분산
- **개선**: 55% 감소 (1062줄 제거)

**추출된 모듈**:
1. **Phase 1**: 중첩 위젯 추출 (342줄 제거)
2. **Phase 2**: 권한 요청 로직 추출 (248줄 제거)
3. **Phase 3**: 유틸리티 함수 추출 (107줄 제거)
4. **Phase 4**: UI 빌더 함수 추출 (335줄 제거)
5. **Phase 5**: 다이얼로그 헬퍼 추출 (~50줄 제거)

**메인 스크린 복잡도 평가**:
- ✅ 관리 가능한 크기로 축소 (869줄)
- ✅ 각 UI 섹션이 독립 함수로 재사용 가능
- ✅ 권한 및 다이얼로그 로직 완전 분리
- ✅ 테스트 용이성 대폭 향상

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

**문서 최종 업데이트**: 2025-12-01 KST
