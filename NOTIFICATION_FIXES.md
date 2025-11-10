# 알림 문제 해결 과정

## 🔍 웹 검색 결과 기반 문제 분석

### 발견된 주요 문제점

#### 1. ⚠️ USE_EXACT_ALARM 권한 누락 (Critical!)
**문제**: AndroidManifest.xml에 `USE_EXACT_ALARM` 권한이 없었음
- Android 12+ (API 31+)에서는 정확한 알람 스케줄링을 위해 필수
- `SCHEDULE_EXACT_ALARM`만으로는 불충분
- 웹 검색 결과: "Android 12+에서는 USE_EXACT_ALARM 권한이 필수"

**해결**:
```xml
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

#### 2. 📱 Notification Channel 설정 미흡
**문제**: Channel의 importance가 `high`였음
- Heads-up 알림(화면 상단 배너)을 표시하려면 `Importance.max` 필요
- LED 설정 누락
- 웹 검색 결과: "Importance.max + Priority.max가 헤드업 알림에 필수"

**해결**:
```dart
const androidChannel = AndroidNotificationChannel(
  'todo_notifications_v2',  // 새 채널 ID
  'Todo Reminders',
  importance: Importance.max,  // high -> max로 변경
  enableLights: true,
  ledColor: const Color.fromARGB(255, 255, 0, 0),
);
```

#### 3. 🔊 Notification Details 설정 불완전
**문제**: Priority가 high, LED/라지 아이콘 설정 누락
- 웹 검색 결과: "모든 알림 옵션을 명시적으로 설정해야 함"

**해결**:
```dart
final androidDetails = AndroidNotificationDetails(
  'todo_notifications_v2',
  'Todo Reminders',
  importance: Importance.max,
  priority: Priority.max,  // high -> max로 변경
  largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
  enableLights: true,
  ledColor: const Color.fromARGB(255, 255, 0, 0),
  ledOnMs: 1000,
  ledOffMs: 500,
  when: scheduledDate.millisecondsSinceEpoch,
  showProgress: false,
);
```

#### 4. 🔄 Notification Channel 재생성 문제
**문제**: 앱 업데이트 시 기존 채널 설정이 유지됨
- Android는 앱 업데이트 시 notification channel을 재생성하지 않음
- 웹 검색 결과: "Channel ID를 변경해야 새 설정이 적용됨"

**해결**:
```dart
// 이전: 'todo_notifications'
// 새로운: 'todo_notifications_v2'
```

## 📋 적용된 모든 변경사항

### AndroidManifest.xml
```xml
<!-- 추가된 권한 -->
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

### notification_service.dart
1. Flutter Material import 추가 (Color 사용)
2. Channel ID를 v2로 변경
3. Importance를 max로 상향
4. Priority를 max로 상향
5. LED 설정 추가
6. Large icon 추가
7. When timestamp 추가

## 🌐 참고한 웹 검색 결과

### GitHub Issues
1. **Schedule notifications not working in Android 14**
   - Issue #2185 on flutter_local_notifications
   - USE_EXACT_ALARM 권한 필요성 확인

2. **Notification sound not playing on Android**
   - Issue #1327 on flutter_local_notifications
   - Channel 설정 시 importance/priority 최대값 필요

### Stack Overflow
1. **Flutter Local Notification Sound not working**
   - Importance.max + Priority.high 필수
   - Channel 재생성을 위해 ID 변경 필요

2. **Heads up notification not showing on background**
   - fullScreenIntent: true 필요
   - Priority.max 필수

## 📱 테스트 방법

### 1. 새 APK 다운로드 및 설치
```
http://172.20.10.3:9000
```

### 2. 알림 권한 확인
- 앱 설정 → 알림 → "DoDo" → 모든 권한 허용
- 정확한 알람 권한 허용

### 3. 알림 테스트
1. + 버튼 클릭 (quick-add가 아님!)
2. 할일 제목 입력
3. "알림 시간" 설정 (예: 1분 후)
4. 저장
5. 1분 후 알림 확인:
   - 소리 ✅
   - 배너/헤드업 알림 ✅
   - 알림 트레이에 표시 ✅
   - LED 깜빡임 ✅

## 🔧 핵심 수정사항 요약

| 항목 | 이전 | 수정 후 |
|-----|------|---------|
| Channel ID | todo_notifications | todo_notifications_v2 |
| Importance | high | max |
| Priority | high | max |
| LED | ❌ | ✅ |
| Large Icon | ❌ | ✅ |
| USE_EXACT_ALARM | ❌ | ✅ |
| WAKE_LOCK | ❌ | ✅ |

## ⚠️ 주의사항

1. **앱을 완전히 삭제하고 재설치하는 것이 가장 확실함**
   - 단순 업데이트만으로는 알림 권한이 재설정되지 않을 수 있음

2. **기기별 차이**
   - Samsung, Xiaomi 등 제조사별로 알림 정책이 다를 수 있음
   - 배터리 최적화에서 앱을 제외해야 할 수 있음

3. **Android 버전별 차이**
   - Android 12 이하: SCHEDULE_EXACT_ALARM만으로 충분
   - Android 13+: USE_EXACT_ALARM 필수
   - Android 14: 추가 제한사항 있을 수 있음

## ✅ 예상 결과

이 수정으로 다음이 해결되어야 합니다:
- ✅ 알림 소리가 정상적으로 재생됨
- ✅ 알림 배너(헤드업)가 화면 상단에 표시됨
- ✅ 알림이 알림 트레이에 계속 유지됨
- ✅ LED가 깜빡임 (지원하는 기기에서)
- ✅ 정확한 시간에 알림이 발생함

## 📚 참고 자료

- [flutter_local_notifications 공식 문서](https://pub.dev/packages/flutter_local_notifications)
- [Android Notification Channels](https://developer.android.com/develop/ui/views/notifications/channels)
- [Android Exact Alarms](https://developer.android.com/about/versions/12/behavior-changes-12#exact-alarm-permission)
