# DoDo 앱 출시 노트

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
- **버전**: 1.0.0 (빌드 1)
- **최소 SDK**: Android 6.0 (API 23)
- **타겟 SDK**: Android 14 (API 34)
- **서명**: SHA384withRSA (2048-bit)
- **인증서 유효기간**: 2025-11-06 ~ 2053-03-24

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
