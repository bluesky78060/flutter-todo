# 삼성 기기 알림 문제 심층 분석 보고서

## 요약
삼성 Galaxy 기기(특히 One UI 5.0 이상)에서 Flutter 앱의 알림이 작동하지 않는 문제는 **삼성의 공격적인 배터리 최적화 정책과 One UI의 독특한 알림 시스템** 때문입니다. 이는 단순한 권한 문제가 아니라 시스템 레벨의 제약사항입니다.

## 1. 핵심 문제점 분석

### 1.1 삼성 특유의 시스템 제약사항

#### 배터리 최적화 (가장 중요)
- **Adaptive Battery**: 머신러닝 기반으로 앱 사용 패턴 분석, 자주 사용하지 않는 앱 자동 제한
- **Sleeping Apps**: 며칠 사용하지 않으면 자동으로 절전 앱 목록 추가
- **Deep Sleeping Apps**: 거의 사용하지 않는 앱을 더욱 강력하게 제한
- **Device Care의 자동 최적화**: 매일 특정 시간에 백그라운드 앱 강제 종료

#### allowNoti 시스템 플래그 버그
특정 Galaxy 모델(A31, A51 등)에서 발견된 버그:
```bash
# 버그 확인 명령
adb shell dumpsys notification | grep "kr.bluesky.dodo" | grep "allowNoti"
# 결과가 false면 시스템 레벨에서 알림 차단됨
```

#### Doze 모드의 강화된 제한
- 삼성은 구글의 Doze 모드보다 더 공격적인 절전 정책 적용
- 화면 꺼짐 15분 후부터 네트워크 및 알람 제한 시작 (구글은 1시간)
- Light Doze와 Deep Doze 진입 시간이 더 빠름

### 1.2 One UI 버전별 특이사항

#### One UI 5.0/6.0
- 알림 카테고리 자동 비활성화 버그
- 신규 설치 앱의 알림 기본값이 "낮음"으로 설정
- 백그라운드 제한 기본 활성화

#### One UI 7.0 (최신)
- Live Notifications/Now Bar: 포그라운드 서비스 전용, 화이트리스트 필요
- 알림 우선순위 시스템 변경
- 더욱 세분화된 알림 제어 (카테고리별 개별 설정)

### 1.3 현재 코드의 한계점

```dart
// notification_service.dart 분석
const androidChannel = AndroidNotificationChannel(
  'todo_notifications_v3',  // 채널 버전 업그레이드로 캐싱 문제 해결 시도
  'Todo Reminders',
  importance: Importance.max,  // 최대 중요도 설정
  playSound: true,
  enableVibration: true,
  enableLights: true,
);
```

**문제점**:
1. 채널 생성만으로는 삼성의 시스템 제약을 우회할 수 없음
2. `exactAllowWhileIdle` 모드도 삼성의 절전 정책에 의해 무시될 수 있음
3. 권한 요청 타이밍이 Activity context와 맞지 않을 수 있음

## 2. 삼성 기기별 문제 패턴

### 2.1 플래그십 모델 (S23/S24 시리즈)
- **증상**: 알림이 늦게 오거나 배치로 한번에 표시
- **원인**: Adaptive Battery의 공격적인 학습 알고리즘
- **특징**: 앱을 자주 사용하면 점차 개선됨

### 2.2 중급 모델 (A 시리즈)
- **증상**: 알림이 전혀 오지 않음
- **원인**: allowNoti 플래그 버그, 메모리 관리 공격성
- **특징**: 시스템 업데이트 후에도 문제 지속

### 2.3 구형 모델 (Android 11 이하)
- **증상**: 재부팅 후 알림 설정 초기화
- **원인**: 권한 시스템 버그
- **특징**: 앱 재설치로 일시적 해결

## 3. 기술적 해결 방안

### 3.1 WorkManager 활용 (권장)

```dart
// 새로운 접근: WorkManager로 알림 예약
import 'package:workmanager/workmanager.dart';

// 초기화
await Workmanager().initialize(
  callbackDispatcher,
  isInDebugMode: false
);

// 알림 예약
await Workmanager().registerOneOffTask(
  "todo-notification-$id",
  "showNotification",
  initialDelay: scheduledDate.difference(DateTime.now()),
  constraints: Constraints(
    networkType: NetworkType.not_required,
    requiresBatteryNotLow: false,
    requiresCharging: false,
    requiresDeviceIdle: false,  // Doze 모드 무시
    requiresStorageNotLow: false,
  ),
  backoffPolicy: BackoffPolicy.exponential,
  backoffPolicyDelay: Duration(seconds: 10),
  inputData: {
    'title': title,
    'body': body,
    'id': id,
  },
);
```

**장점**:
- 시스템이 WorkManager 작업을 더 높은 우선순위로 처리
- 배터리 최적화 영향 최소화
- 재부팅 후에도 작업 유지
- Doze 모드 중에도 실행 가능

### 3.2 AlarmManager 직접 사용

```dart
// Android native AlarmManager 직접 호출
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

// 정확한 알람 설정
await AndroidAlarmManager.oneShotAt(
  scheduledDate,
  id,
  callback,
  exact: true,
  wakeup: true,
  rescheduleOnReboot: true,
);
```

### 3.3 Foreground Service 활용 (극단적 방법)

```dart
// 중요한 알림을 위한 포그라운드 서비스
class NotificationForegroundService {
  static Future<void> startService() async {
    // 포그라운드 서비스 시작
    // 배터리 소모 증가하지만 확실한 알림 보장
  }
}
```

### 3.4 삼성 전용 최적화

```dart
class SamsungOptimization {
  static Future<void> applySamsungWorkarounds() async {
    if (!await _isSamsungDevice()) return;

    // 1. PowerManager 화이트리스트 요청
    await _requestIgnoreBatteryOptimization();

    // 2. AutoStart 권한 요청 (One UI 전용)
    await _requestAutoStartPermission();

    // 3. 알림 채널 재생성 (캐싱 문제 해결)
    await _recreateNotificationChannels();

    // 4. 사용자 가이드 표시
    await _showSamsungSetupGuide();
  }

  static Future<bool> _isSamsungDevice() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.manufacturer?.toLowerCase() == 'samsung';
  }

  static Future<void> _requestIgnoreBatteryOptimization() async {
    // REQUEST_IGNORE_BATTERY_OPTIMIZATIONS 권한 활용
    if (Platform.isAndroid) {
      final batteryOptimization = await Permission.ignoreBatteryOptimizations;
      if (!batteryOptimization.isGranted) {
        await batteryOptimization.request();
      }
    }
  }
}
```

## 4. 사용자 교육 전략

### 4.1 첫 실행 가이드

```dart
class SamsungNotificationGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          // Step 1: 권한 설정
          _buildPermissionStep(),

          // Step 2: 배터리 최적화 해제
          _buildBatteryOptimizationStep(),

          // Step 3: 절전 앱 제외
          _buildSleepingAppsStep(),

          // Step 4: 잠금화면 알림
          _buildLockScreenStep(),

          // Step 5: 테스트 알림
          _buildTestNotificationStep(),
        ],
      ),
    );
  }
}
```

### 4.2 자동 설정 검사

```dart
class NotificationHealthCheck {
  static Future<NotificationHealth> checkHealth() async {
    final health = NotificationHealth();

    // 권한 체크
    health.hasPermission = await Permission.notification.isGranted;

    // 정확한 알람 권한
    health.hasExactAlarm = await Permission.scheduleExactAlarm.isGranted;

    // 배터리 최적화 상태
    health.batteryOptimized = await Permission.ignoreBatteryOptimizations.isDenied;

    // 알림 채널 상태
    health.channelEnabled = await _checkNotificationChannel();

    // DND 상태
    health.dndEnabled = await _checkDoNotDisturb();

    return health;
  }

  static Future<void> autoFix() async {
    final health = await checkHealth();

    if (!health.isHealthy) {
      // 문제 자동 수정 시도
      await _attemptAutoFix(health);

      // 수정 불가능한 항목 사용자 가이드
      if (!health.isHealthy) {
        await _showManualFixGuide(health);
      }
    }
  }
}
```

## 5. 추가 디버깅 도구

### 5.1 알림 상태 실시간 모니터링

```dart
class NotificationMonitor {
  static Stream<NotificationStatus> monitor() {
    return Stream.periodic(Duration(seconds: 30), (_) async {
      final pending = await NotificationService().getPendingNotifications();
      final health = await NotificationHealthCheck.checkHealth();

      return NotificationStatus(
        pendingCount: pending.length,
        isHealthy: health.isHealthy,
        lastCheck: DateTime.now(),
        issues: health.issues,
      );
    });
  }
}
```

### 5.2 삼성 전용 로깅

```dart
class SamsungLogger {
  static Future<void> logSamsungSpecifics() async {
    if (!await _isSamsungDevice()) return;

    final logs = <String>[];

    // One UI 버전
    logs.add('One UI Version: ${await _getOneUIVersion()}');

    // 배터리 상태
    logs.add('Battery Optimization: ${await _getBatteryOptimizationStatus()}');

    // 절전 앱 상태
    logs.add('Sleeping Apps: ${await _getSleepingAppsStatus()}');

    // allowNoti 플래그
    logs.add('AllowNoti Flag: ${await _getAllowNotiFlag()}');

    // Doze 모드 상태
    logs.add('Doze Mode: ${await _getDozeStatus()}');

    // 로그 전송 또는 표시
    await _sendLogs(logs);
  }
}
```

## 6. 대안적 접근 방법

### 6.1 서버 기반 푸시 알림 (FCM)
- 로컬 알림 대신 FCM 사용
- 서버에서 예약 관리
- 삼성 기기도 FCM은 높은 우선순위로 처리

### 6.2 위젯 알림
- 홈 화면 위젯으로 할일 표시
- 알림 없이도 시각적 리마인더 제공
- 배터리 최적화 영향 없음

### 6.3 In-App 알림
- 앱 실행 시 놓친 알림 표시
- 로컬 데이터베이스에 알림 이력 저장
- 사용자가 앱 열 때마다 확인

## 7. 결론 및 권장사항

### 즉시 적용 가능한 개선사항
1. **WorkManager 도입**: 현재 AlarmManager 대신 WorkManager 사용
2. **배터리 최적화 요청**: 앱 설치 시 자동으로 화이트리스트 요청
3. **삼성 기기 감지**: 제조사 확인 후 전용 가이드 표시
4. **채널 버전 관리**: 업데이트마다 채널 ID 변경으로 캐싱 문제 회피

### 중장기 개선 방향
1. **FCM 통합**: 서버 기반 알림 시스템 구축
2. **위젯 개발**: Android 홈 화면 위젯 제공
3. **사용자 교육**: 인앱 튜토리얼 강화
4. **A/B 테스트**: 다양한 알림 전략 효과 측정

### 테스트 필요 사항
1. Galaxy S24, S23, A54, A34 등 주요 모델별 테스트
2. One UI 5.0, 6.0, 7.0 버전별 동작 확인
3. 배터리 최적화 상태별 알림 동작 검증
4. 장기간(1주일 이상) 실사용 테스트

## 8. 참고 자료
- [Don't kill my app! - Samsung](https://dontkillmyapp.com/samsung)
- [Samsung Knox SDK Documentation](https://docs.samsungknox.com/)
- [Android Developers - WorkManager](https://developer.android.com/topic/libraries/architecture/workmanager)
- [Flutter WorkManager Plugin](https://pub.dev/packages/workmanager)

---
작성일: 2025-11-14
버전: 1.0.0