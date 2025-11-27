# 알림 문제 진단 가이드

## 알림이 작동하지 않는 경우 확인 사항

### 1. 권한 확인
```bash
# 앱 권한 상태 확인
adb -s RF9NB0146AB shell dumpsys package kr.bluesky.dodo | grep permission
```

필요한 권한:
- `android.permission.POST_NOTIFICATIONS` (Android 13+)
- `android.permission.SCHEDULE_EXACT_ALARM` (Android 12+)
- `android.permission.USE_EXACT_ALARM` (선택사항)

### 2. 알림 채널 확인
```bash
# 알림 채널 확인
adb -s RF9NB0146AB shell dumpsys notification | grep -A 20 "kr.bluesky.dodo"
```

채널 ID: `todo_notifications_v2`
중요도: MAX (헤드업 알림 표시)

### 3. 예약된 알림 확인

앱 내에서 todo를 생성한 후 로그 확인:
- "✅ TodoActions: Notification verified in pending list" 메시지 확인
- "Pending notifications count" 확인

### 4. 배터리 최적화 확인
```bash
# 배터리 최적화 상태 확인
adb -s RF9NB0146AB shell dumpsys deviceidle whitelist | grep kr.bluesky.dodo
```

삼성 기기의 경우:
1. 설정 → 앱 → DODO → 배터리
2. "백그라운드 사용 제한 없음" 선택
3. "절전 모드에서 제한 안 함" 활성화

### 5. 시스템 알림 설정 확인

Android 설정에서:
1. 설정 → 앱 → DODO → 알림
2. "알림 허용" 활성화
3. "Todo Reminders" 채널 활성화
4. 중요도: "높음" 또는 "긴급" 선택

### 6. 일정 정확한 알람 권한 (Android 12+)

```bash
# 정확한 알람 권한 확인
adb -s RF9NB0146AB shell dumpsys alarm | grep kr.bluesky.dodo
```

앱 내에서:
- 알림 권한 요청 시 "정확한 알람" 권한도 함께 요청됨
- 로그에서 "⏰ Exact alarm permission" 메시지 확인

## 일반적인 문제 및 해결 방법

### 문제 1: 알림이 전혀 표시되지 않음

**원인**:
- 알림 권한 미허용
- 배터리 최적화로 인한 백그라운드 제한

**해결**:
1. 앱 재설치 후 권한 요청 다이얼로그에서 "허용" 선택
2. 배터리 최적화 해제
3. Samsung 기기: "절전 모드에서 제한 안 함" 활성화

### 문제 2: 알림이 늦게 표시됨

**원인**:
- 정확한 알람 권한 미허용
- Android Doze 모드
- 배터리 절약 모드

**해결**:
1. "정확한 알람" 권한 허용
2. 앱을 배터리 최적화 제외 목록에 추가
3. 개발자 옵션 → "절전 모드 사용 안 함" (테스트용)

### 문제 3: 알림 소리/진동이 없음

**원인**:
- 알림 채널 설정 문제
- 방해 금지 모드 활성화

**해결**:
1. 앱 알림 설정 → Todo Reminders 채널 → 소리/진동 확인
2. 방해 금지 모드 해제 또는 앱 예외 추가

## 테스트 시나리오

### 즉시 알림 테스트
1. 새 할일 생성
2. 알림 시간을 현재 시간 + 1분으로 설정
3. 앱을 백그라운드로 이동 (홈 버튼 터치)
4. 1분 후 알림 표시 확인

### 로그 확인
```bash
# 실시간 로그 모니터링
adb -s RF9NB0146AB logcat | grep -E "(TodoActions|NotificationService|알림)"
```

확인할 로그:
- `✅ TodoActions: Todo created with ID`
- `📅 TodoActions: Scheduling notification`
- `✅ TodoActions: Notification verified in pending list`
- `🔔 Notification tapped` (알림 터치 시)

## Debug APK로 상세 로그 확인

Release APK는 로그가 최소화되어 있으므로 Debug APK로 테스트:

```bash
# Debug APK 빌드
flutter build apk --debug

# 설치
adb -s RF9NB0146AB install -r build/app/outputs/flutter-apk/app-debug.apk

# 로그 확인
adb -s RF9NB0146AB logcat | grep -E "flutter"
```

## 알림 코드 동작 흐름

1. **할일 생성** (todo_providers.dart:95-192)
   - `createTodo()` 호출
   - notificationTime이 설정되어 있으면 알림 예약
   - `scheduleNotification()` 호출

2. **알림 예약** (notification_service.dart:205-265)
   - 권한 확인
   - timezone 설정
   - Android 채널에 알림 스케줄링
   - pending 리스트에 추가 확인

3. **알림 표시** (시스템이 자동 처리)
   - 예약된 시간에 Android 시스템이 알림 표시
   - Notification Tap 시 콜백 실행

4. **알림 탭 처리** (notification_service.dart:135-140)
   - `_onNotificationTapped()` 호출
   - payload 기반 네비게이션 (현재는 로그만)

## 알려진 제한사항

### Samsung 기기
- **One UI의 강력한 배터리 최적화**
  - 기본적으로 백그라운드 앱 제한
  - "절전 모드에서 제한 안 함" 설정 필수

### Android 12+
- **정확한 알람 권한 필수**
  - `SCHEDULE_EXACT_ALARM` 권한 필요
  - 사용자가 설정에서 수동으로 허용해야 할 수도 있음

### Android 13+
- **알림 권한 명시적 요청**
  - `POST_NOTIFICATIONS` 런타임 권한 필수
  - 처음 앱 실행 시 권한 요청

## 추가 진단 도구

### 알림 상태 덤프
```bash
adb -s RF9NB0146AB shell dumpsys notification --noredact
```

### 알람 상태 확인
```bash
adb -s RF9NB0146AB shell dumpsys alarm | grep -A 50 kr.bluesky.dodo
```

### 배터리 최적화 상태
```bash
adb -s RF9NB0146AB shell dumpsys battery
adb -s RF9NB0146AB shell dumpsys deviceidle
```
