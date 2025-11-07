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

### 한국어 버전 (500자 제한)

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

### 영어 버전 (500자 제한)

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

### v1.0.0 (2025-11-06)
**첫 번째 공식 릴리스**

**구현된 기능**
- ✅ 할 일 CRUD (생성/읽기/수정/삭제)
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

## 라이선스

이 앱은 개인정보 보호법을 준수하며, 사용자의 데이터를 안전하게 보호합니다.

자세한 내용은 [개인정보처리방침](https://bluesky78060.github.io/flutter-todo/privacy-policy)을 참조하세요.

---

**DoDo와 함께 생산적인 하루를 만들어보세요!** 🚀
