# 다음 할일 목록 (Next Tasks)

최종 업데이트: **2025-12-01**
이전 정리: [FUTURE_TASKS.md](FUTURE_TASKS.md)

---

## 📊 프로젝트 진행 상황

**전체 완료율**: 약 55% (Phase 1-3 기반)

| Phase | 상태 | 완료율 | 예정 기간 |
|-------|------|--------|---------|
| **Phase 1** | ✅ 완료 | 100% | 2025-11-06 ~ 2025-11-17 |
| **Phase 2** | ✅ 완료 | 100% | 2025-11-17 ~ 2025-11-27 |
| **Phase 3** | 🔄 진행 중 | 71% (5/7) | 2025-11-28 ~ 2025-12-31 |
| **Phase 4** | 📋 계획 | 0% | 2026-01-01 이후 |

---

## 🎯 Phase 3 (현재) - 데이터 관리 및 UX 개선

**기간**: 2025-12-01 ~ 2025-12-31
**진행 상황**: 5/7 완료 (71%)

### ✅ 완료된 항목

#### 1. 데이터 내보내기 (CSV, PDF) ✅
- **완료일**: 2025-12-01
- **커밋**: e3b3251
- **구현 내용**:
  - CSV 내보내기: 스프레드시트 형식
  - PDF 내보내기: 스타일링된 문서
  - 파일 공유: Android/iOS 공유 메뉴 통합
  - 다국화: 한국어/영어 지원
- **신규 파일**: `export_service.dart`, `export_provider.dart`
- **수정 파일**: `settings_screen.dart`, `pubspec.yaml`, 번역 파일들

#### 2. 하드코딩 한글 제거 (번역 키 적용) ✅
- **완료일**: 2025-11-30
- **완료 범위**: 모든 Dart 파일 다국화 완료
- **영향 범위**: 6개 파일, 60+ 번역 키 추가

#### 3. 통계 화면 개선 (Phase 1-2) ✅
- **완료일**: 2025-12-01
- **Phase 1 - 카테고리별 분석 카드**:
  - 상위 5개 카테고리 완료율 표시
  - 색상 코딩: 초록(≥75%), 주황(≥50%), 빨강(<50%)
  - 커밋: 673595c

- **Phase 2 - 월간 추이 분석 카드**:
  - 12개월 라인 차트
  - 연간 총합, 월평균, 최고기록 표시
  - 트렌드 인디케이터 (↑/↓/→)
  - 인터렉티브 차트

- **신규 클래스**: `_CategoryAnalysisCard`, `_MonthlyAnalysisCard`, `_WeeklyPatternCard`, `_InsightsCard`
- **영향 범위**: statistics_screen.dart (+700줄), 번역 파일들

---

### 📋 진행 예정 항목

#### 4. 첨부파일 개선 (개별 삭제, 웹 플랫폼 지원) ✅
- **완료일**: 2025-12-01
- **커밋**: 웹 플랫폼 파일 업로드 지원 구현
- **우선순위**: 🟡 Medium
- **구현 내용**:
  - [x] 개별 첨부파일 삭제 UI/로직 (이전 완료)
  - [x] 웹 플랫폼 파일 업로드 지원 (kIsWeb 기반)
  - [x] 파일 바이트 처리 방식 (웹용 pickFileWithBytes, uploadFileFromBytes)
  - [x] 플랫폼별 분기 처리
- **수정 파일**:
  - `lib/core/services/attachment_service.dart` (uploadFile, uploadFileFromBytes, pickFileWithBytes 메서드 추가)
  - `lib/presentation/widgets/todo_form_dialog.dart` (_pickFile 메서드 kIsWeb 기반 대폭 재작성)
  - `assets/translations/en.json`, `assets/translations/ko.json` (번역 키 추가)
- **기술 상세**:
  - 웹 플랫폼: `FilePicker.platform.pickFiles(withData: true)` + `uploadBinary()`
  - 모바일 플랫폼: 기존 `File` 객체 + `upload()`
  - Record 타입: `(String fileName, Uint8List bytes)`
  - 플랫폼 감지: `import 'package:flutter/foundation.dart' show kIsWeb`

#### 5. 알림 우선순위 설정 ✅
- **완료일**: 2025-12-02
- **커밋**: 930a475
- **구현 내용**:
  - Priority 필드 추가 (low, medium, high): TEXT 타입
  - Drift 데이터베이스 마이그레이션 v12
  - Priority 상수 클래스 생성: `priority_constants.dart`
  - Todo 엔티티 업데이트: copyWith, updateTodoFromCompanion
  - 번역 키 추가: notification_priority, priority_low/medium/high, priority_label
- **신규 파일**: `lib/core/constants/priority_constants.dart`
- **수정 파일**: `todo.dart`, `app_database.dart`, 번역 파일들 (en.json, ko.json)
- **기술 상세**:
  - Priority: TEXT 컬럼, 기본값 'medium'
  - 우선순위 순서: high(3) > medium(2) > low(1)
  - 유틸리티 메서드: compare, toInt, fromInt, getDisplayName
- **다음 단계**:
  - [ ] 알림 채널 설정 (notification_service.dart)
  - [ ] UI에 priority 선택 위젯 추가 (todo_form_dialog.dart)
  - [ ] 우선순위 기반 정렬 (todo_list_screen.dart)

#### 6. 테마 커스터마이징 (색상 선택, 폰트 크기)
- **예상 시간**: 6-8시간
- **우선순위**: 🟡 Medium
- **기능**:
  - [ ] 색상 선택기 UI
  - [ ] 폰트 크기 조정 슬라이더
  - [ ] 커스텀 테마 미리보기
  - [ ] 테마 저장 및 로드
- **관련 파일**: `theme_provider.dart`, `settings_screen.dart`, `app_colors.dart`

#### 7. 프로필 관리 (프로필 사진, 닉네임)
- **예상 시간**: 4-6시간
- **우선순위**: 🟡 Medium
- **기능**:
  - [ ] 프로필 사진 업로드 (Supabase Storage)
  - [ ] 닉네임 편집
  - [ ] 프로필 정보 표시
  - [ ] 사진 크롭 기능
- **관련 파일**: 신규 `profile_screen.dart`, `user_service.dart`

---

## 🚀 Phase 4 (장기) - 협업 및 고급 기능

**기간**: 2026-01-01 이후

### 진행 예정 항목

- [ ] Todo 공유 (공유 링크, 권한) - 1-2일
- [ ] 팀 협업 기능 (워크스페이스, 초대) - 1-2주
- [ ] 타임 트래킹 (타이머, 작업 시간) - 1-2일
- [ ] 홈 화면 위젯 (Android/iOS) - 3-5일 (Android 완료됨)
- [ ] 계정 삭제 기능 - 3-4시간
- [ ] 프리미엄 기능 (In-App Purchase) - 1-2주
- [ ] 광고 통합 (AdMob) - 4-6시간
- [ ] 추가 언어 지원 (일본어, 중국어, 스페인어) - 언어당 4-6시간
- [ ] iPad/태블릿 레이아웃 최적화 - 1-2일 (기본 완료)
- [ ] 웹 앱 최적화 (데스크톱 레이아웃) - 2-3일

---

## 📈 완료된 주요 마일스톤

### Phase 2 완료 (2025-11-17 ~ 2025-11-27)

✅ **서브태스크 기능** - 1.4
✅ **알림 스누즈** - 3.1
✅ **위치 기반 알림** - 3.2
✅ **첨부파일 시스템** - 1.5
✅ **드래그 앤 드롭 정렬** - 4.2
✅ **카테고리 Supabase 동기화**
✅ **관리자 대시보드** - 13.1
✅ **오프라인 모드 개선** - 2.2
✅ **주소 검색 API 전환** (Naver → Google Geocoding)
✅ **Flutter Web OAuth/Geocoding 수정**

### Phase 1 완료 (2025-11-06 ~ 2025-11-17)

✅ **Todo CRUD**
✅ **반복 Todo (RRULE)**
✅ **카테고리 관리**
✅ **백업 및 복원**
✅ **실시간 검색**
✅ **OAuth 로그인** (Google, Kakao, Apple)
✅ **에러 로깅**
✅ **CI/CD 파이프라인**

---

## 🔧 기술 부채 및 미해결 항목

| 항목 | 상태 | 우선순위 | 설명 |
|------|------|---------|------|
| 동기화 충돌 해결 | 📋 예정 | 🔴 High | Last-Write-Wins vs Manual Merge 전략 미구현 |
| 통계 Phase 3 (고급 분석) | 📋 예정 | 🟢 Low | 요일별 패턴, 타임 히트맵, AI 인사이트 |
| 다국가 휴일 지원 | 📋 설계 | 🟢 Low | Design Document 완성, 구현 대기 |
| Sentry 통합 | ⏸️ 비활성 | 🟢 Low | Kotlin 버전 충돌 (선택적) |

---

## 🎯 다음 우선순위 (추천 순서)

### Tier 1 (즉시 진행 권장)
1. **첨부파일 개선** - 웹 지원 추가 (4-6시간)
   - 기존 기능 확장이므로 위험 최소
   - 사용자 경험 향상

### Tier 2 (월말까지 완료 권장)
2. **알림 우선순위** - 알림 시스템 강화 (4-6시간)
3. **테마 커스터마이징** - 사용성 개선 (6-8시간)

### Tier 3 (연초 계획)
4. **프로필 관리** - 사용자 정보 관리 (4-6시간)
5. **Phase 4** 장기 계획 수립

---

## 📊 버전 관리

| 버전 | 날짜 | 주요 변경사항 |
|------|------|--------------|
| 1.0.17+52 | 2025-12-02 | 알림 우선순위 설정 (low/medium/high) - Phase 3 Item 5 완료 |
| 1.0.18+51 | 2025-12-01 | 웹 플랫폼 파일 업로드 지원 (kIsWeb 기반) |
| 1.0.18+50 | 2025-12-01 | 웹 플랫폼 파일 업로드 지원 (초안) |
| 1.0.17+49 | 2025-12-01 | 통계 Phase 2 (월간 추이) |
| 1.0.16+48 | 2025-12-01 | 통계 Phase 1 (카테고리 분석) |
| 1.0.15+47 | 2025-12-01 | 데이터 내보내기 (CSV, PDF) |
| 1.0.14+ | 2025-11-27 | 오프라인 모드 개선 |

---

## 🤝 기여 방법

새로운 기능을 추가하거나 개선 사항을 제안하고 싶다면:

1. 이 문서(`NEXT_TASKS.md`)에 항목 추가 후 PR 생성
2. GitHub Issues에 Feature Request 등록
3. [FUTURE_TASKS.md](FUTURE_TASKS.md) 참고하여 전체 로드맵 확인

---

**문서 최종 업데이트**: 2025-12-01 KST
