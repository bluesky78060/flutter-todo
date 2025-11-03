# 설정 화면 기능 명세서

Todo 앱의 설정 화면에 포함될 기능들에 대한 상세 명세입니다.

---

## 📋 목차

1. [기본 설정](#1️⃣-기본-설정)
2. [할 일 관리 설정](#2️⃣-할-일-관리-설정)
3. [통계 및 생산성](#3️⃣-통계-및-생산성)
4. [데이터 관리](#4️⃣-데이터-관리)
5. [사용자 계정](#5️⃣-사용자-계정)
6. [앱 정보](#6️⃣-앱-정보)
7. [구현 우선순위](#💡-구현-우선순위)
8. [UI 구성안](#🎨-설정-화면-ui-구성안)

---

## 1️⃣ 기본 설정

### 🌓 테마 설정
**목적**: 사용자가 선호하는 화면 테마를 선택할 수 있도록 함

**기능**:
- ✅ 다크 모드 / 라이트 모드 전환
- ✅ 시스템 설정 따르기 (자동)
- ✅ 커스텀 색상 테마 (고급)

**구현 방법**:
```dart
// Theme Provider
enum ThemeMode { light, dark, system }

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setTheme(ThemeMode mode) {
    state = mode;
    // Save to SharedPreferences
  }
}
```

**UI 요소**:
- 세그먼트 컨트롤 또는 라디오 버튼
- 미리보기 카드

---

### 🌍 언어 설정
**목적**: 다국어 지원

**기능**:
- ✅ 한국어
- ✅ English
- ✅ 日本語 (선택)
- ✅ 中文 (선택)

**구현 방법**:
```dart
// 이미 설치된 easy_localization 활용
EasyLocalization(
  supportedLocales: [
    Locale('ko', 'KR'),
    Locale('en', 'US'),
    Locale('ja', 'JP'),
  ],
  // ...
)
```

**UI 요소**:
- 드롭다운 메뉴
- 리스트 타일

---

## 2️⃣ 할 일 관리 설정

### 🔔 알림 설정
**목적**: 사용자가 할 일을 잊지 않도록 알림 제공

**기능**:
- ✅ 마감 기한 알림 (1시간 전, 1일 전)
- ✅ 매일 아침 할 일 요약 (오전 9시)
- ✅ 미루기 알림 (3일 이상 미완료)
- ✅ 알림 활성화/비활성화 토글

**구현 방법**:
```dart
// flutter_local_notifications 패키지 사용
dependencies:
  flutter_local_notifications: ^17.0.0
```

**UI 요소**:
- 스위치 토글
- 시간 선택 다이얼로그

---

### 📅 정렬 옵션
**목적**: 할 일 목록의 기본 정렬 방식 설정

**기능**:
- ✅ 생성일 순 (최신순/오래된순)
- ✅ 마감일 순
- ✅ 중요도 순 (고급 기능 - 우선순위 추가 필요)
- ✅ 알파벳 순

**구현 방법**:
```dart
enum SortOption {
  createdDate,
  dueDate,
  priority,
  alphabetical,
}
```

**UI 요소**:
- 라디오 버튼 그룹
- 드롭다운

---

### 🗑️ 자동 정리
**목적**: 완료된 할 일을 자동으로 정리하여 목록을 깔끔하게 유지

**기능**:
- ✅ 완료된 할 일 자동 삭제 설정
  - 즉시 삭제
  - 7일 후 삭제
  - 30일 후 삭제
  - 수동 삭제만
- ✅ 휴지통 기능 (삭제 전 임시 보관)
- ✅ 휴지통 자동 비우기 (30일 후)

**구현 방법**:
```dart
class AutoCleanupService {
  Timer? _timer;

  void startAutoCleanup(Duration interval) {
    _timer = Timer.periodic(interval, (timer) {
      // Delete completed todos older than threshold
    });
  }
}
```

**UI 요소**:
- 드롭다운
- 스위치

---

## 3️⃣ 통계 및 생산성

### 📊 목표 설정
**목적**: 사용자의 생산성 향상을 위한 목표 설정

**기능**:
- ✅ 일일 목표 개수 (예: 하루 5개 완료)
- ✅ 주간 목표 (예: 주당 30개 완료)
- ✅ 완료율 목표 (예: 80% 이상)
- ✅ 목표 달성 시 축하 애니메이션

**구현 방법**:
```dart
class GoalSettings {
  final int dailyTarget;
  final int weeklyTarget;
  final double completionRateTarget;

  bool isDailyGoalMet(int completed) => completed >= dailyTarget;
}
```

**UI 요소**:
- 숫자 입력 필드
- 슬라이더 (완료율)
- 프로그레스 바

---

### 🎯 포인트/레벨 시스템
**목적**: 게이미피케이션을 통한 동기 부여

**기능**:
- ✅ 할 일 완료 시 포인트 획득
  - 일반 할 일: 10 포인트
  - 중요 할 일: 25 포인트
- ✅ 연속 달성 일수 (Streak)
- ✅ 레벨 시스템 (100포인트당 레벨업)
- ✅ 배지/업적 시스템
  - 🏆 첫 할 일 완료
  - 🔥 7일 연속 달성
  - 💯 100개 완료

**구현 방법**:
```dart
class UserProgress {
  int totalPoints;
  int currentStreak;
  int level;
  List<Achievement> unlockedAchievements;

  void addPoints(int points) {
    totalPoints += points;
    level = totalPoints ~/ 100;
  }
}
```

**UI 요소**:
- 레벨 표시 배지
- 포인트 카운터
- 업적 그리드

---

## 4️⃣ 데이터 관리

### 💾 백업 & 복원
**목적**: 데이터 손실 방지 및 기기 간 이동

**기능**:
- ✅ 로컬 백업 (JSON 파일)
- ✅ 클라우드 동기화 (Firebase/Supabase)
- ✅ 내보내기 (JSON, CSV, PDF)
- ✅ 가져오기 (JSON)
- ✅ 자동 백업 (매일 자정)

**구현 방법**:
```dart
class BackupService {
  Future<void> exportToJson() async {
    final todos = await database.getAllTodos();
    final json = jsonEncode(todos);
    // Save to file
  }

  Future<void> importFromJson(String path) async {
    final json = await File(path).readAsString();
    final todos = jsonDecode(json);
    // Import to database
  }
}
```

**UI 요소**:
- 백업/복원 버튼
- 파일 선택 다이얼로그
- 진행률 표시

---

### 🔄 동기화 설정
**목적**: 여러 기기 간 데이터 동기화

**기능**:
- ✅ 자동 동기화 활성화/비활성화
- ✅ 동기화 간격 설정 (실시간, 5분, 1시간)
- ✅ WiFi 전용 동기화
- ✅ 마지막 동기화 시간 표시

**구현 방법**:
```dart
// Firebase or Supabase 사용
class SyncService {
  Timer? _syncTimer;

  void startAutoSync(Duration interval) {
    _syncTimer = Timer.periodic(interval, (timer) async {
      if (await isWifiConnected() || !wifiOnlyMode) {
        await syncWithCloud();
      }
    });
  }
}
```

**UI 요소**:
- 스위치
- 드롭다운 (간격)
- 동기화 버튼

---

## 5️⃣ 사용자 계정

### 👤 프로필
**목적**: 사용자 정보 관리

**기능**:
- ✅ 사용자 이름 수정
- ✅ 프로필 사진 업로드
- ✅ 이메일 주소
- ✅ 가입일 표시
- ✅ 통계 요약 (총 완료 개수, 현재 레벨)

**구현 방법**:
```dart
class UserProfile {
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime joinedAt;
  final int totalCompleted;
  final int currentLevel;
}
```

**UI 요소**:
- 프로필 이미지 (원형)
- 텍스트 입력 필드
- 통계 카드

---

### 🔐 보안
**목적**: 계정 및 데이터 보안

**기능**:
- ✅ 비밀번호 변경
- ✅ 생체 인증 활성화 (지문, Face ID)
- ✅ 앱 잠금 설정
- ✅ 로그아웃

**구현 방법**:
```dart
// local_auth 패키지 사용
dependencies:
  local_auth: ^2.1.0

class BiometricAuth {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    return await auth.authenticate(
      localizedReason: '할 일 앱에 접근하려면 인증이 필요합니다',
    );
  }
}
```

**UI 요소**:
- 비밀번호 입력 다이얼로그
- 생체인증 스위치
- 로그아웃 버튼

---

## 6️⃣ 앱 정보

### ℹ️ 정보
**목적**: 앱에 대한 기본 정보 제공

**기능**:
- ✅ 앱 버전 표시
- ✅ 빌드 번호
- ✅ 개발자 정보
- ✅ 오픈소스 라이선스
- ✅ 이용약관
- ✅ 개인정보 처리방침

**구현 방법**:
```dart
// package_info_plus 사용
dependencies:
  package_info_plus: ^8.0.0

class AppInfo {
  Future<String> getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
```

**UI 요소**:
- 텍스트 표시
- 링크 버튼

---

### 📧 피드백
**목적**: 사용자 의견 수렴

**기능**:
- ✅ 버그 신고
- ✅ 기능 제안
- ✅ 앱 평가하기 (스토어 링크)
- ✅ 이메일 문의

**구현 방법**:
```dart
// url_launcher 사용 (이미 설치됨)
Future<void> sendFeedback() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'support@todoapp.com',
    queryParameters: {
      'subject': '[Todo App] 피드백',
    },
  );
  await launchUrl(emailUri);
}
```

**UI 요소**:
- 버튼 리스트
- 이메일 작성 폼

---

## 💡 구현 우선순위

### 🥇 Phase 1 - 필수 기능 (1주)
**목표**: 기본적인 설정 화면 구축

| 기능 | 중요도 | 난이도 | 예상 시간 |
|------|--------|--------|-----------|
| 사용자 프로필 (이름, 이메일) | ⭐⭐⭐⭐⭐ | 🟢 쉬움 | 2시간 |
| 테마 설정 (다크/라이트) | ⭐⭐⭐⭐⭐ | 🟡 보통 | 4시간 |
| 로그아웃 | ⭐⭐⭐⭐⭐ | 🟢 쉬움 | 1시간 |
| 앱 정보 (버전, 라이선스) | ⭐⭐⭐⭐ | 🟢 쉬움 | 2시간 |

**합계**: ~9시간

---

### 🥈 Phase 2 - 유용한 기능 (2주)
**목표**: 사용자 경험 향상

| 기능 | 중요도 | 난이도 | 예상 시간 |
|------|--------|--------|-----------|
| 언어 설정 | ⭐⭐⭐⭐ | 🟢 쉬움 | 3시간 |
| 정렬 옵션 | ⭐⭐⭐⭐ | 🟡 보통 | 4시간 |
| 자동 정리 설정 | ⭐⭐⭐⭐ | 🟡 보통 | 6시간 |
| 데이터 백업/복원 (로컬) | ⭐⭐⭐⭐ | 🟡 보통 | 8시간 |
| 비밀번호 변경 | ⭐⭐⭐ | 🟢 쉬움 | 3시간 |

**합계**: ~24시간

---

### 🥉 Phase 3 - 고급 기능 (4주)
**목표**: 차별화된 기능 제공

| 기능 | 중요도 | 난이도 | 예상 시간 |
|------|--------|--------|-----------|
| 알림 설정 | ⭐⭐⭐⭐ | 🔴 어려움 | 12시간 |
| 목표 설정 | ⭐⭐⭐ | 🟡 보통 | 8시간 |
| 포인트/레벨 시스템 | ⭐⭐⭐ | 🟡 보통 | 16시간 |
| 클라우드 동기화 | ⭐⭐⭐⭐ | 🔴 어려움 | 24시간 |
| 생체 인증 | ⭐⭐⭐ | 🟡 보통 | 6시간 |

**합계**: ~66시간

---

## 🎨 설정 화면 UI 구성안

### 레이아웃 구조

```
┌─────────────────────────────────┐
│   ⚙️ 설정                        │
├─────────────────────────────────┤
│                                 │
│ 👤 계정                          │
│ ├─ 📷 프로필 편집                 │
│ ├─ 🔑 비밀번호 변경               │
│ └─ 🚪 로그아웃                    │
│                                 │
│ ─────────────────────────       │
│                                 │
│ 🎨 테마 & 표시                   │
│ ├─ 🌓 다크 모드         [Toggle] │
│ ├─ 🌍 언어              한국어 > │
│ └─ 📅 기본 정렬         생성일 > │
│                                 │
│ ─────────────────────────       │
│                                 │
│ 🔔 알림 (선택)                   │
│ ├─ ⏰ 마감 알림         [Toggle] │
│ └─ 📬 일일 요약         [Toggle] │
│                                 │
│ ─────────────────────────       │
│                                 │
│ 💾 데이터                        │
│ ├─ ⬇️ 백업하기                   │
│ ├─ ⬆️ 복원하기                   │
│ └─ 🗑️ 데이터 초기화               │
│                                 │
│ ─────────────────────────       │
│                                 │
│ ℹ️ 정보                          │
│ ├─ 📱 버전: 1.0.0                │
│ ├─ 📄 라이선스                   │
│ └─ 📧 피드백 보내기               │
│                                 │
└─────────────────────────────────┘
```

---

### 섹션별 상세 디자인

#### 1. 계정 섹션
```dart
// Profile Section
Container(
  child: Column(
    children: [
      // Profile Image + Name
      CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(user.photoUrl),
      ),
      SizedBox(height: 12),
      Text(user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(user.email, style: TextStyle(color: Colors.grey)),

      SizedBox(height: 20),

      // Actions
      ListTile(
        leading: Icon(Icons.edit),
        title: Text('프로필 편집'),
        trailing: Icon(Icons.chevron_right),
        onTap: () => navigateToEditProfile(),
      ),
      // ...
    ],
  ),
)
```

#### 2. 테마 섹션
```dart
// Theme Toggle
SwitchListTile(
  title: Text('다크 모드'),
  subtitle: Text('어두운 화면으로 전환'),
  value: isDarkMode,
  onChanged: (value) {
    ref.read(themeProvider.notifier).toggleTheme();
  },
  secondary: Icon(Icons.dark_mode),
)
```

#### 3. 데이터 섹션
```dart
// Backup/Restore
ListTile(
  leading: Icon(Icons.backup),
  title: Text('백업하기'),
  subtitle: Text('마지막 백업: 2024-01-15 14:30'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => showBackupDialog(),
)
```

---

## 📦 필요한 패키지

### Phase 1
```yaml
dependencies:
  # 이미 설치됨
  shared_preferences: ^2.2.2  # 설정 저장
  package_info_plus: ^8.0.0   # 앱 정보
  url_launcher: ^6.2.5        # 링크 열기
```

### Phase 2
```yaml
dependencies:
  # 추가 필요
  image_picker: ^1.0.7        # 프로필 사진
  file_picker: ^8.0.0         # 백업 파일 선택
```

### Phase 3
```yaml
dependencies:
  # 추가 필요
  flutter_local_notifications: ^17.0.0  # 알림
  local_auth: ^2.1.0                    # 생체인증
  firebase_core: ^2.24.0                # Firebase
  cloud_firestore: ^4.14.0              # 클라우드 동기화
```

---

## 🎯 최종 추천

현재 Todo 앱의 상태를 고려할 때, 다음 순서로 구현하는 것을 추천합니다:

### ✅ 1단계 (즉시 구현 가능)
- 사용자 프로필 표시
- 테마 토글 (다크/라이트)
- 로그아웃
- 앱 버전 정보

### ✅ 2단계 (1주 내)
- 언어 설정
- 정렬 옵션
- 로컬 백업/복원

### ✅ 3단계 (향후)
- 알림 시스템
- 클라우드 동기화
- 게이미피케이션

---

## 📝 구현 시 고려사항

### UX/UI
- ✅ 다크 테마 일관성 유지
- ✅ 애니메이션 효과 (페이지 전환, 스위치 토글)
- ✅ 확인 다이얼로그 (위험한 작업 시)
- ✅ 로딩 인디케이터
- ✅ 에러 처리 및 사용자 피드백

### 기술적 고려사항
- ✅ Riverpod을 활용한 상태 관리
- ✅ SharedPreferences로 설정 저장
- ✅ 비동기 처리 (Future/async-await)
- ✅ 에러 핸들링 (try-catch)
- ✅ 테스트 작성 (unit test, widget test)

### 보안
- ✅ 민감한 정보 암호화
- ✅ 생체인증 구현
- ✅ 안전한 로그아웃 처리

---

**작성일**: 2024-01-15
**버전**: 1.0
**작성자**: Claude Code Assistant

