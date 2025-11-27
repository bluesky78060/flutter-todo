# Todo 앱 알림 기능 충돌 문제 분석 보고서

## 1. 문제 현상

구글 플레이 스토어에서 설치한 앱에서 할 일에 대한 알림을 설정하면, 지정된 알림 시간에 앱이 강제 종료(충돌)되고 사용자에게 알림이 표시되지 않는 문제가 발생합니다.

## 2. 핵심 원인: 백그라운드 알림 처리 로직 부재

문제의 가장 핵심적인 원인은 **앱이 종료되었거나 백그라운드 상태일 때 예약된 알림을 처리할 Dart 코드 레벨의 핸들러(Handler)가 등록되어 있지 않기 때문**입니다.

-   `flutter_local_notifications` 라이브러리는 앱이 실행 중이 아닐 때 알림이 도착하면, 이를 처리하기 위해 미리 약속된 Dart 함수를 실행시키려고 시도합니다.
-   이 함수는 반드시 클래스에 속하지 않는 **최상위 함수(Top-level function)** 또는 **정적 메소드(Static method)**여야 합니다.
-   현재 `lib/core/services/notification_service.dart`의 `initialize` 메소드에는 앱이 실행 중일 때 사용자가 알림을 '탭'하는 경우에 대한 콜백(`onDidReceiveNotificationResponse`)만 설정되어 있습니다.
-   앱이 꺼진 상태에서 알림을 수신하고 표시하는 데 필요한 **백그라운드 콜백 핸들러가 누락**되어 있습니다.

이로 인해, 안드로이드 시스템이 예약된 시간에 앱을 깨워 알림을 전달하려 할 때, 라이브러리는 실행할 Dart 함수를 찾지 못해 네이티브 코드에서 치명적인 오류가 발생하고, 이는 앱의 충돌로 이어집니다.

## 3. 분석 근거

### `notification_service.dart` 분석
-   `initialize()` 메소드 내 `_notificationsPlugin.initialize()` 호출 시, 백그라운드 처리를 위한 `onDidReceiveBackgroundNotificationResponse` 파라미터가 설정되어 있지 않음을 확인했습니다.
-   이는 앱이 종료된 상태에서의 알림 수신 시나리오를 처리할 수 없게 만듭니다.

### `android/app/src/main/AndroidManifest.xml` 분석
-   알림 표시에 필요한 권한 (`POST_NOTIFICATIONS`), 정확한 시간 알림을 위한 권한 (`SCHEDULE_EXACT_ALARM`), 그리고 재부팅 후 알림을 재등록하기 위한 권한 (`RECEIVE_BOOT_COMPLETED`) 등이 모두 정상적으로 선언되어 있습니다.
-   알림 수신을 위한 리시버(Receiver)들 또한 라이브러리 가이드에 맞게 올바르게 등록되어 있습니다.
-   이는 안드로이드 시스템 레벨의 설정에는 문제가 없으며, 문제가 순수하게 Dart 코드의 구현에 있음을 뒷받침합니다.

## 4. 결론

앱 충돌 현상은 안드로이드 설정 문제가 아닌, **Dart 코드에서 앱 종료 상태의 알림을 처리하는 로직이 부재하기 때문에 발생하는 문제**입니다. 안드로이드 시스템이 알림을 전달했지만, 이를 받아 처리할 Dart 코드가 준비되지 않아 충돌이 일어나는 것입니다.

## 5. 권장 해결 방안 (참고)

> 본 보고서는 분석 및 설명만을 제공하며, 아래 내용은 문제 해결을 위한 일반적인 가이드입니다.

1.  **백그라운드 콜백 함수 정의**: `main.dart` 또는 `notification_service.dart` 파일 내에, 클래스 외부에 최상위 함수(Top-level function)로 백그라운드 알림을 처리할 함수를 선언합니다.
2.  **콜백 함수 등록**: `NotificationService`의 `initialize` 메소드에서 `flutter_local_notifications`를 초기화할 때, 위에서 생성한 백그라운드 콜백 함수를 `onDidReceiveBackgroundNotificationResponse` 파라미터에 등록합니다.
