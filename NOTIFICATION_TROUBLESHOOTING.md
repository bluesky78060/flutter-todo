# 알림 문제 해결 가이드

## 현재 상황

- ✅ **v1.0.3+15**: largeIcon 버그 수정으로 크래시 문제 해결
- ✅ **테스트 앱**: test_notification.dart에서 알림 정상 작동 확인
- ❌ **메인 앱**: 실제 앱에서 알림이 표시되지 않음

## 확인된 사항

### 코드 분석 결과

1. **알림 스케줄링 로직** ✅ 정상
   - 위치: `lib/presentation/providers/todo_providers.dart:112-146`
   - TodoFormDialog에서 notificationTime을 전달
   - createTodo 시 NotificationService.scheduleNotification 호출
   - 로깅 포함 (디버그 모드)

2. **권한 요청 로직** ✅ 정상
   - 위치: `lib/presentation/screens/todo_list_screen.dart:43-110`
   - Activity context 준비 후 권한 요청 (500ms 지연)
   - 중복 요청 방지 플래그 적용
   - 다이얼로그를 통한 사용자 동의 후 권한 요청

3. **알림 서비스 초기화** ✅ 정상
   - 위치: `lib/main.dart:62-70`
   - main() 함수에서 NotificationService 초기화
   - 백그라운드 핸들러 등록 (`notificationTapBackground`)

## 가능한 문제 원인

### 1. 권한 문제 (가장 가능성 높음)

**증상**: 앱 재설치 후 권한이 초기화됨

**해결 방법**:

```bash
# 1. 현재 권한 상태 확인
~/Library/Android/sdk/platform-tools/adb shell dumpsys notification | grep kr.bluesky.dodo

# 2. POST_NOTIFICATIONS 권한 확인
~/Library/Android/sdk/platform-tools/adb shell dumpsys package kr.bluesky.dodo | grep android.permission.POST_NOTIFICATIONS

# 3. 권한 수동 부여 (테스트용)
~/Library/Android/sdk/platform-tools/adb shell pm grant kr.bluesky.dodo android.permission.POST_NOTIFICATIONS
~/Library/Android/sdk/platform-tools/adb shell pm grant kr.bluesky.dodo android.permission.SCHEDULE_EXACT_ALARM
```

**앱에서 권한 요청**:
1. 앱 최초 실행 시 "알림 권한 요청" 다이얼로그 확인
2. "허용" 선택
3. 시스템 권한 다이얼로그에서도 "허용" 선택

### 2. SharedPreferences 캐시 문제

**증상**: 앱이 이미 권한을 요청했다고 기록되어 재요청하지 않음

**해결 방법**:

```bash
# SharedPreferences 초기화
~/Library/Android/sdk/platform-tools/adb shell run-as kr.bluesky.dodo rm /data/data/kr.bluesky.dodo/shared_prefs/*.xml

# 앱 데이터 완전 삭제
~/Library/Android/sdk/platform-tools/adb shell pm clear kr.bluesky.dodo
```

### 3. Release 빌드 로깅 부재

**증상**: Release 모드에서는 logger.d() 출력이 없어 디버깅 어려움

**해결 방법**: Debug 모드로 실행하여 로그 확인

```bash
# Debug 모드로 실행
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
/opt/homebrew/share/flutter/bin/flutter run -d emulator-5554

# 로그 모니터링
~/Library/Android/sdk/platform-tools/adb logcat | grep -E "(flutter|TodoActions|NotificationService)"
```

**Debug 빌드에서 확인해야 할 로그**:

```
✅ TodoActions: Todo created with ID: X
📅 TodoActions: Scheduling notification for todo X
   Title: [할일 제목]
   Notification Time: [설정된 시간]
   Current Time: [현재 시간]
   Time until notification: X minutes
✅ TodoActions: Notification verified in pending list
   Pending notifications count: X
```

**오류 로그 예시**:

```
❌ TodoActions: Failed to schedule notification: PlatformException(...)
```

### 4. ProGuard/R8 최적화 문제

**증상**: Release 빌드에서 알림 관련 코드가 제거됨

**확인 방법**: `android/app/proguard-rules.pro` 파일 확인

**현재 설정** (이미 적용됨):
```
# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
```

### 5. 배터리 최적화

**증상**: 백그라운드에서 앱이 종료되어 알림이 발생하지 않음

**확인**:
1. 설정 → 앱 → DoDo → 배터리
2. "제한 없음" 또는 "최적화하지 않음" 선택

**앱에서 처리**:
- `lib/presentation/screens/todo_list_screen.dart:113-154`
- 배터리 최적화 제외 요청 다이얼로그

## 디버깅 절차

### Step 1: 권한 상태 확인

```bash
# 앱 실행
~/Library/Android/sdk/platform-tools/adb shell am start -n kr.bluesky.dodo/.MainActivity

# 권한 확인
~/Library/Android/sdk/platform-tools/adb shell dumpsys notification | grep kr.bluesky.dodo
```

**예상 출력**:
```
AppSettings: kr.bluesky.dodo (xxxxx) importance=DEFAULT userSet=true
```

- `importance=NONE`: ❌ 권한 없음
- `importance=DEFAULT` or `importance=MAX`: ✅ 권한 있음

### Step 2: Debug 모드로 실행

```bash
# Debug 빌드 실행
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
/opt/homebrew/share/flutter/bin/flutter run -d emulator-5554

# 할일 생성 (알림 시간 설정)
# 1. 앱에서 + 버튼 클릭
# 2. 제목 입력
# 3. "알림 시간" 설정 (현재 시간 + 1-2분)
# 4. 저장

# 로그 확인
~/Library/Android/sdk/platform-tools/adb logcat | grep -E "(TodoActions|NotificationService)"
```

### Step 3: 예약된 알림 확인

```bash
# 로그에서 확인
# "✅ TodoActions: Notification verified in pending list" 메시지 확인
# "Pending notifications count: X" 확인
```

### Step 4: 알림 발생 대기

- 설정한 시간까지 대기 (앱은 백그라운드에 두어도 됨)
- 알림 패널 확인
- 알림이 표시되지 않으면 로그 확인

## 테스트 시나리오

### 시나리오 1: 최초 설치 후 테스트

```bash
# 1. 앱 완전 삭제
~/Library/Android/sdk/platform-tools/adb uninstall kr.bluesky.dodo

# 2. Debug APK 설치
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
/opt/homebrew/share/flutter/bin/flutter build apk --debug
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/apk/debug/app-debug.apk

# 3. 로그 모니터링 시작
~/Library/Android/sdk/platform-tools/adb logcat -c
~/Library/Android/sdk/platform-tools/adb logcat | grep -E "(flutter|TodoActions|NotificationService)" > notification_debug.log &

# 4. 앱 실행
~/Library/Android/sdk/platform-tools/adb shell am start -n kr.bluesky.dodo/.MainActivity

# 5. 앱에서 작업
# - 권한 요청 다이얼로그에서 "허용" 선택
# - 할일 생성 (알림 시간: 현재 + 2분)
# - 앱 백그라운드로 전환

# 6. 2분 후 알림 확인

# 7. 로그 분석
cat notification_debug.log
```

### 시나리오 2: 권한 없이 테스트

```bash
# 1. 권한 거부 상태로 설정
~/Library/Android/sdk/platform-tools/adb shell pm revoke kr.bluesky.dodo android.permission.POST_NOTIFICATIONS

# 2. 앱 실행 및 할일 생성
# 예상: 알림이 스케줄되지만 표시되지 않음

# 3. 권한 부여
~/Library/Android/sdk/platform-tools/adb shell pm grant kr.bluesky.dodo android.permission.POST_NOTIFICATIONS

# 4. 새 할일 생성
# 예상: 알림 정상 작동
```

### 시나리오 3: Release 빌드 테스트

```bash
# 1. Release APK 빌드 및 설치
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
/opt/homebrew/share/flutter/bin/flutter build apk --release
~/Library/Android/sdk/platform-tools/adb uninstall kr.bluesky.dodo
~/Library/Android/sdk/platform-tools/adb install -r build/app/outputs/apk/release/app-release.apk

# 2. 앱 실행
~/Library/Android/sdk/platform-tools/adb shell am start -n kr.bluesky.dodo/.MainActivity

# 3. 권한 수동 부여 (자동 요청 실패 시)
~/Library/Android/sdk/platform-tools/adb shell pm grant kr.bluesky.dodo android.permission.POST_NOTIFICATIONS
~/Library/Android/sdk/platform-tools/adb shell pm grant kr.bluesky.dodo android.permission.SCHEDULE_EXACT_ALARM

# 4. 할일 생성 및 알림 테스트
```

## 알려진 문제와 해결책

### 문제 1: "permission_handler" 권한 요청 실패

**원인**: Android Activity context가 준비되지 않은 상태에서 권한 요청

**해결**: v1.0.3+14에서 이미 수정됨
- `WidgetsBinding.instance.addPostFrameCallback` 사용
- 500ms 지연 추가
- 위치: `lib/presentation/screens/todo_list_screen.dart:34-40`

### 문제 2: largeIcon 크래시

**원인**: 존재하지 않는 drawable 리소스 참조

**해결**: v1.0.3+15에서 수정됨
- `largeIcon` 속성 제거
- 위치: `lib/core/services/notification_service.dart:260`

### 문제 3: 백그라운드 핸들러 크래시

**원인**: 백그라운드 핸들러가 top-level 함수가 아님

**해결**: v1.0.3+14에서 수정됨
- `notificationTapBackground` 함수를 `main.dart`에 top-level로 정의
- `@pragma('vm:entry-point')` 어노테이션 추가
- 위치: `lib/main.dart:20-25`

## 추가 확인 사항

### 시스템 설정 확인

1. **Android 설정 → 알림**
   - DoDo 앱의 알림이 허용되어 있는지 확인
   - 중요도가 "기본" 이상인지 확인

2. **Android 설정 → 앱 → DoDo → 권한**
   - "알림" 권한이 허용되어 있는지 확인

3. **Android 설정 → 앱 → DoDo → 배터리**
   - "제한 없음" 또는 "최적화하지 않음" 선택

### 에뮬레이터 설정 확인

```bash
# 에뮬레이터 시간 확인
~/Library/Android/sdk/platform-tools/adb shell date

# 시간대 확인
~/Library/Android/sdk/platform-tools/adb shell getprop persist.sys.timezone
# 예상: Asia/Seoul
```

## 다음 단계

1. **Debug 모드 테스트 우선**
   - Release 모드는 로그가 없어 디버깅 어려움
   - Debug 모드로 전체 흐름 확인

2. **권한 상태 명확히 확인**
   - SharedPreferences 초기화
   - 권한 수동 부여 테스트

3. **단순한 케이스부터 테스트**
   - 1-2분 후 알림 설정
   - 앱 포그라운드 상태에서 테스트
   - 백그라운드 상태에서 테스트

4. **로그 수집 및 분석**
   - Debug 빌드로 상세 로그 수집
   - 문제 발생 시점 정확히 파악

## 참고 문서

- [NOTIFICATION_FIX_SUMMARY.md](NOTIFICATION_FIX_SUMMARY.md) - v1.0.3+15 버그 수정 내역
- [NOTIFICATION_FIXES.md](NOTIFICATION_FIXES.md) - 이전 수정 내역
- [NOTIFICATION_CRASH_ANALYSIS.md](NOTIFICATION_CRASH_ANALYSIS.md) - 크래시 분석
- [lib/core/services/notification_service.dart](lib/core/services/notification_service.dart) - 알림 서비스 구현
- [lib/presentation/providers/todo_providers.dart](lib/presentation/providers/todo_providers.dart) - 할일 생성 로직
