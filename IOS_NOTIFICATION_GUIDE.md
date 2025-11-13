# iOS 알림 가이드

## 개요

iOS에서 DODO Todo 앱의 알림이 정상적으로 작동하도록 하는 사용자 및 개발자 가이드입니다.

## iOS 알림 시스템 특징

### Android와의 주요 차이점

| 항목 | Android | iOS |
|------|---------|-----|
| **권한 요청 시점** | 런타임 (Android 13+) | 런타임 (iOS 10+) |
| **포그라운드 알림** | 기본 표시 | **기본 숨김** (설정 필요) |
| **알림 중요도** | 5단계 (채널별) | 4단계 (앱 전체) |
| **정확한 시간** | 권한 필요 (Android 14+) | 기본 지원 |
| **배터리 최적화** | 수동 제외 필요 | 자동 관리 |
| **백그라운드 제한** | Doze 모드 | Background App Refresh |

### iOS 알림 우선순위

1. **Time Sensitive** (시간 민감) - 중단 화면에도 표시
2. **Active** (활성) - 일반 알림, 소리/진동 포함
3. **Passive** (수동) - 소리 없이 알림 센터에만 표시
4. **Critical** (긴급) - 방해 금지 모드 무시 (특별 권한 필요)

## 현재 구현된 설정

### 1. 초기화 설정

```dart
const iosSettings = DarwinInitializationSettings(
  requestAlertPermission: true,    // 배너/알림 표시 권한
  requestBadgePermission: true,    // 앱 아이콘 배지 권한
  requestSoundPermission: true,    // 소리 권한
  // ✅ 포그라운드 알림 표시 (매우 중요!)
  defaultPresentAlert: true,       // 앱 실행 중에도 알림 표시
  defaultPresentSound: true,       // 앱 실행 중에도 소리 재생
  defaultPresentBadge: true,       // 배지 업데이트
);
```

**⚠️ 중요**: `defaultPresentAlert: true` 없으면 **앱이 열려있을 때 알림이 표시되지 않습니다!**

### 2. 알림 우선순위 설정

```dart
const iosDetails = DarwinNotificationDetails(
  presentAlert: true,              // 알림 배너 표시
  presentBadge: true,              // 배지 업데이트
  presentSound: true,              // 소리 재생
  badgeNumber: 1,                  // 배지 숫자
  interruptionLevel: InterruptionLevel.timeSensitive,  // 시간 민감 알림
);
```

**Time Sensitive 알림**:
- Focus 모드에서도 표시
- 알림 요약에 포함되지 않고 즉시 표시
- 사용자가 명시적으로 차단하지 않는 한 항상 표시

## 사용자 설정 가이드

### 필수 확인 사항

#### 1. 알림 권한
- **경로**: 설정 → DODO → 알림
- **확인**: "알림 허용" 토글이 켜져 있는지
- **세부 설정**:
  - ✅ 잠금 화면
  - ✅ 알림 센터
  - ✅ 배너

#### 2. 알림 스타일
- **경로**: 설정 → DODO → 알림
- **권장**: "배너" 스타일 선택
- **배너 스타일 옵션**:
  - **임시**: 몇 초 후 자동으로 사라짐 (권장)
  - **지속**: 사용자가 수동으로 닫아야 함

#### 3. Focus 모드 (집중 모드)
- **경로**: 설정 → 집중 모드
- **확인**: DODO 앱이 "Time Sensitive Notifications 허용" 목록에 있는지
- **중요**: Focus 모드 활성화 시 Time Sensitive 알림만 표시됨

#### 4. Background App Refresh (백그라운드 앱 새로고침)
- **경로**: 설정 → 일반 → 백그라운드 앱 새로고침 → DODO
- **설정**: **켜짐** 권장
- **이유**: 앱이 백그라운드에서 알림을 준비하는 데 도움

#### 5. 알림 요약 (Notification Summary)
- **경로**: 설정 → 알림 → 예약된 요약
- **확인**: DODO가 **요약에 포함되지 않도록** 설정
- **이유**: Time Sensitive 알림은 자동으로 제외되지만, 이중 확인 권장

## 자주 발생하는 문제

### 문제 1: 앱이 열려있을 때 알림이 표시되지 않음

**원인**:
- iOS 기본 동작: 포그라운드 알림 숨김
- `defaultPresentAlert` 설정 누락

**해결**:
- ✅ 현재 구현에 `defaultPresentAlert: true` 포함됨
- 앱 업데이트 후 재시작 필요

### 문제 2: Focus 모드에서 알림이 오지 않음

**원인**:
- Focus 모드가 Time Sensitive 알림만 허용
- DODO가 허용 목록에 없음

**해결**:
1. 설정 → 집중 모드 → [활성 모드] → 앱
2. "Time Sensitive Notifications 허용" 활성화
3. DODO 추가

### 문제 3: 알림이 늦게 표시됨

**원인**:
- Background App Refresh 비활성화
- Low Power Mode (저전력 모드) 활성화
- 네트워크 연결 문제

**해결**:
1. Background App Refresh 활성화
2. 저전력 모드 해제 (임시)
3. Wi-Fi/셀룰러 연결 확인

### 문제 4: 알림 소리가 나지 않음

**원인**:
- 방해금지 모드 활성화
- 벨소리/알림 볼륨이 0
- 알림 소리 권한 거부

**해결**:
1. 방해금지 모드 해제
2. 설정 → 사운드 및 촉각 → 벨소리 및 알림 볼륨 조정
3. 설정 → DODO → 알림 → 소리 활성화

## 개발자를 위한 추가 정보

### 권장 설정 체크리스트

- [x] `DarwinInitializationSettings`에 포그라운드 표시 설정
- [x] `InterruptionLevel.timeSensitive` 사용
- [x] 권한 요청 시 사용자에게 이유 설명
- [x] Background notification handler 구현
- [ ] Critical 알림 필요 시 Apple 승인 신청

### Info.plist 설정 확인

iOS 알림을 위해 `ios/Runner/Info.plist`에 다음 설정이 필요합니다:

```xml
<!-- 백그라운드 모드 -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<!-- 알림 사용 설명 (선택사항, 권장) -->
<key>NSUserNotificationsUsageDescription</key>
<string>할 일 알림을 받으려면 알림 권한이 필요합니다.</string>
```

### 디버깅 명령어

#### Xcode Console에서 확인
```bash
# 알림 권한 상태 확인
po UNUserNotificationCenter.current().getNotificationSettings()

# 대기 중인 알림 확인
po UNUserNotificationCenter.current().getPendingNotificationRequests()

# 전달된 알림 확인
po UNUserNotificationCenter.current().getDeliveredNotifications()
```

#### Flutter DevTools에서 확인
```dart
// notification_service.dart에 이미 구현된 디버그 로그 활용
// kDebugMode에서 자동으로 출력됨:
// ✅ iOS notification service initialized
// 🍎 iOS notification permission: granted
// 📅 Notification scheduled for: [시간]
```

### 테스트 시나리오

1. **포그라운드 알림 테스트**:
   - 앱을 열어둔 상태에서 1분 후 알림 설정
   - 앱을 계속 사용하면서 알림이 배너로 표시되는지 확인

2. **백그라운드 알림 테스트**:
   - 알림 설정 후 홈 화면으로 이동
   - 알림이 정확한 시간에 표시되는지 확인

3. **Focus 모드 테스트**:
   - Focus 모드 활성화
   - Time Sensitive 알림이 표시되는지 확인

4. **배지 업데이트 테스트**:
   - 여러 알림 설정
   - 앱 아이콘의 배지 숫자가 증가하는지 확인

## iOS 버전별 차이점

### iOS 15+
- **알림 요약** 기능 도입
- Focus 모드 개선
- Time Sensitive 알림 도입

### iOS 16+
- Focus 모드 필터 추가
- 잠금 화면 위젯과 알림 통합

### iOS 17+
- 라이브 액티비티 개선
- 알림 상호작용 향상

## 참고 자료

- [Apple Human Interface Guidelines - Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications)
- [UNNotificationRequest - Apple Developer](https://developer.apple.com/documentation/usernotifications/unnotificationrequest)
- [Managing Your App's Notification Support](https://developer.apple.com/documentation/usernotifications/managing-your-apps-notification-support)
- [flutter_local_notifications - iOS Setup](https://pub.dev/packages/flutter_local_notifications#-ios-integration-optional)

## 버전 히스토리

### v1.0.6 (2024-11-12)
- 포그라운드 알림 표시 설정 추가 (`defaultPresentAlert`)
- Time Sensitive 우선순위 적용
- iOS 전용 가이드 문서 작성

### v1.0.5
- 기본 iOS 알림 지원
- 권한 요청 로직 구현

## Android vs iOS 비교표

| 기능 | Android | iOS | 비고 |
|------|---------|-----|------|
| **포그라운드 알림** | 기본 표시 | 설정 필요 | iOS: defaultPresentAlert |
| **정확한 시간** | 권한 필요 (14+) | 기본 지원 | Android: SCHEDULE_EXACT_ALARM |
| **배터리 관리** | 수동 제외 필요 | 자동 관리 | iOS가 더 간단 |
| **Focus/DND** | DND 모드 | Focus 모드 | iOS가 더 세밀한 제어 |
| **알림 그룹화** | 채널 기반 | 앱 기반 | Android가 더 유연 |
| **우선순위 단계** | 5단계 (채널별) | 4단계 (앱 전체) | Android가 더 세밀 |
| **백그라운드 제한** | Doze 모드 | Background Refresh | 둘 다 영향 있음 |

## 요약

iOS 알림은 Android보다 **간단하지만 포그라운드 표시 설정이 필수**입니다. 현재 구현에는 이 설정이 포함되어 있으므로, 사용자는 다음만 확인하면 됩니다:

1. ✅ 알림 권한 허용
2. ✅ Focus 모드에서 Time Sensitive 알림 허용
3. ✅ Background App Refresh 활성화 (권장)
4. ✅ 알림 요약에서 제외

이 설정들만 확인하면 DODO의 할 일 알림이 정상적으로 작동합니다!
