# 알림 시스템 분석

## 알림 작동 방식

### 1. 알림 생성 시점
**파일**: `lib/presentation/providers/todo_providers.dart`
**함수**: `TodoActions.createTodo()` (59-101번 줄)

할일을 생성할 때 알림 시간(notificationTime)이 설정되어 있으면 자동으로 알림을 예약합니다.

```dart
await notificationService.scheduleNotification(
  id: todoId,              // 할일 ID
  title: '할일 알림',       // 알림 제목 (한글)
  body: title,             // 할일 제목
  scheduledDate: notificationTime,  // 알림 시간
);
```

### 2. 알림 서비스 (NotificationService)
**파일**: `lib/core/services/notification_service.dart`

**주요 기능**:
- 타임존 설정 (Asia/Seoul)
- Android 알림 채널 생성
- 알림 권한 요청
- 알림 예약 및 취소

**알림 채널 정보** (Android):
- ID: `todo_notifications`
- 이름: `Todo Reminders`
- 중요도: High
- 소리: 켜짐
- 진동: 켜짐

### 3. 알림 권한
**Android** (Android 13+):
- `Permission.notification` - 알림 표시 권한
- `Permission.scheduleExactAlarm` - 정확한 알람 권한 (Android 12+)

**iOS**:
- `Permission.notification` - 알림 권한
- UIBackgroundModes 설정 (fetch, remote-notification)

### 4. 알림 예약 방식
- 라이브러리: `flutter_local_notifications`
- 타임존: `timezone` 패키지
- 스케줄 모드: `AndroidScheduleMode.exactAllowWhileIdle`
  - 절전 모드에서도 정확한 시간에 알림 발송

## 알림 테스트 방법

### 1단계: 할일 생성 with 알림
1. 앱 실행
2. "+" 버튼 클릭
3. 할일 제목 입력 (예: "테스트")
4. 알림 시간 설정 (현재 시간 + 1-2분)
5. 저장 버튼 클릭

### 2단계: 로그 확인
디버그 콘솔에서 다음 로그 확인:
```
📅 TodoActions: Scheduling notification for todo X
   Title: 테스트
   Time: 2025-11-05 10:41:00.000
✅ TodoActions: Notification scheduled successfully
   Total pending: 1
```

### 3단계: 알림 수신 대기
설정한 시간이 되면 다음과 같은 알림이 표시됩니다:
```
제목: 할일 알림
내용: 테스트
```

## 알림 표시 예시

**Android 알림**:
- 제목: "할일 알림"
- 내용: [할일 제목]
- 아이콘: 앱 아이콘
- 소리 및 진동 있음

**iOS 알림**:
- 제목: "할일 알림"
- 내용: [할일 제목]
- 배지 표시
- 기본 알림음

## 알림 디버깅

### 예약된 알림 확인
```dart
final pending = await notificationService.getPendingNotifications();
print('예약된 알림 수: ${pending.length}');
for (var n in pending) {
  print('ID: ${n.id}, Title: ${n.title}');
}
```

### 권한 상태 확인
```dart
final hasPermission = await notificationService.areNotificationsEnabled();
print('알림 권한: $hasPermission');
```

## 알림이 작동하지 않는 경우

1. **권한 거부**: 앱 설정에서 알림 권한 확인
2. **과거 시간**: 알림 시간이 현재보다 과거면 예약 안됨
3. **절전 모드**: Android 배터리 최적화 해제 필요
4. **정확한 알람 권한**: Android 12+ 에서 추가 권한 필요

## 현재 구현 상태
✅ 알림 서비스 초기화  
✅ 권한 요청 (Android/iOS)  
✅ 알림 스케줄링  
✅ 알림 취소 (할일 삭제 시)  
✅ 한글 알림 제목  
✅ 타임존 설정 (Asia/Seoul)  
✅ 절전 모드 대응 (exactAllowWhileIdle)  
