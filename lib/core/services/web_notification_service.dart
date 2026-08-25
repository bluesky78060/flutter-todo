import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:todo_app/core/utils/app_logger.dart';

class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  final Map<int, Timer> _scheduledNotifications = {};
  bool _permissionGranted = false;

  /// Initialize web notification service
  Future<void> initialize() async {
    if (!kIsWeb) return;

    try {
      if (kDebugMode) {
        logger.d('🌐 WebNotificationService: Initializing');
      }

      // Check if Notification API is supported
      if (!_isNotificationSupported()) {
        if (kDebugMode) {
          logger.d('⚠️ WebNotificationService: Notification API not supported');
        }
        return;
      }

      // Check current permission status
      final permission = web.Notification.permission;
      _permissionGranted = permission == 'granted';

      if (kDebugMode) {
        logger.d('✅ WebNotificationService: Initialized');
        logger.d('   Permission: $permission');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('❌ WebNotificationService: Initialization failed: $e');
      }
    }
  }

  /// Check if Notification API is supported
  bool _isNotificationSupported() {
    // `package:web`에는 레거시 `Notification.supported`에 해당하는 API가 없다.
    // 브라우저가 Notification 생성자를 노출하는지로 직접 판단한다.
    return web.window.navigator.userAgent.isNotEmpty &&
        web.window.has('Notification');
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (!kIsWeb || !_isNotificationSupported()) {
      return false;
    }

    try {
      // requestPermission()은 JSPromise<JSString>을 돌려주므로 두 번 변환해야 한다.
      final permission = (await web.Notification.requestPermission().toDart).toDart;
      _permissionGranted = permission == 'granted';

      if (kDebugMode) {
        logger.d('🌐 WebNotificationService: Permission requested');
        logger.d('   Result: $permission');
      }

      return _permissionGranted;
    } catch (e) {
      if (kDebugMode) {
        logger.d('❌ WebNotificationService: Permission request failed: $e');
      }
      return false;
    }
  }

  /// Check if notifications are enabled
  bool areNotificationsEnabled() {
    if (!kIsWeb || !_isNotificationSupported()) {
      return false;
    }
    return _permissionGranted && web.Notification.permission == 'granted';
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!kIsWeb) return;

    try {
      // Cancel existing notification with same ID
      cancelNotification(id);

      final now = DateTime.now();
      final difference = scheduledDate.difference(now);

      if (difference.isNegative) {
        if (kDebugMode) {
          logger.d('⚠️ WebNotificationService: Cannot schedule notification in the past');
          logger.d('   Scheduled: $scheduledDate');
          logger.d('   Now: $now');
        }
        return;
      }

      if (!areNotificationsEnabled()) {
        if (kDebugMode) {
          logger.d('⚠️ WebNotificationService: Notifications not enabled');
        }
        // Request permission if not granted
        await requestPermission();

        if (!areNotificationsEnabled()) {
          if (kDebugMode) {
            logger.d('❌ WebNotificationService: Permission denied');
          }
          return;
        }
      }

      if (kDebugMode) {
        logger.d('🌐 WebNotificationService: Scheduling notification');
        logger.d('   ID: $id');
        logger.d('   Title: $title');
        logger.d('   Body: $body');
        logger.d('   Scheduled: $scheduledDate');
        logger.d('   Delay: ${difference.inMinutes} minutes');
      }

      // Schedule the notification
      final timer = Timer(difference, () {
        _showNotification(id, title, body);
      });

      _scheduledNotifications[id] = timer;

      if (kDebugMode) {
        logger.d('✅ WebNotificationService: Notification scheduled');
        logger.d('   Total pending: ${_scheduledNotifications.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('❌ WebNotificationService: Failed to schedule: $e');
      }
    }
  }

  /// Show a notification immediately
  void _showNotification(int id, String title, String body) {
    try {
      if (!areNotificationsEnabled()) {
        if (kDebugMode) {
          logger.d('⚠️ WebNotificationService: Cannot show notification, permission not granted');
        }
        return;
      }

      // `package:web`의 정적 타입으로 생성한다.
      // 레거시 `js.JsObject(constructor, [...])` 방식의 동적 생성자 호출은
      // `dart:js_interop`에 대응물이 없어 1:1 치환이 불가능하다.
      final notification = web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: '/icons/Icon-192.png',
          tag: 'todo-$id',
          requireInteraction: false,
          silent: false,
        ),
      );

      // Auto close after 10 seconds
      // `notification.close` 를 tear-off 로 넘기면 dart2js 가 거부한다
      // (Tear-offs of external extension type interop member are disallowed).
      Timer(const Duration(seconds: 10), () {
        try {
          notification.close();
        } catch (e) {
          if (kDebugMode) {
            logger.d('⚠️ Notification auto-close failed: $e');
          }
        }
      });

      // Handle notification click
      // 레거시 `dart:html`의 이벤트 콜백은 Zone이 자동 연결됐지만
      // `package:web` + `.toJS`에서는 보장되지 않는다. 콜백 안에서 예외가
      // 새어 나가지 않도록 try/catch로 감싼다.
      notification.onclick = (web.Event _) {
        // 콜백 본문 전체를 감싼다. 여기서 던지면 JS 경계를 넘어
        // 처리되지 않은 예외가 된다.
        try {
          web.window.focus();
          notification.close();
        } catch (e) {
          if (kDebugMode) {
            logger.d('⚠️ Notification click handling failed: $e');
          }
        }
      }.toJS;

      // Remove from scheduled list
      _scheduledNotifications.remove(id);

      if (kDebugMode) {
        logger.d('🔔 WebNotificationService: Notification shown');
        logger.d('   ID: $id');
        logger.d('   Title: $title');
      }
    } catch (e) {
      if (kDebugMode) {
        logger.d('❌ WebNotificationService: Failed to show notification: $e');
      }
    }
  }

  /// Cancel a scheduled notification
  void cancelNotification(int id) {
    final timer = _scheduledNotifications[id];
    if (timer != null) {
      timer.cancel();
      _scheduledNotifications.remove(id);

      if (kDebugMode) {
        logger.d('🗑️ WebNotificationService: Notification cancelled');
        logger.d('   ID: $id');
      }
    }
  }

  /// Cancel all scheduled notifications
  void cancelAllNotifications() {
    for (var timer in _scheduledNotifications.values) {
      timer.cancel();
    }
    _scheduledNotifications.clear();

    if (kDebugMode) {
      logger.d('🗑️ WebNotificationService: All notifications cancelled');
    }
  }

  /// Get pending notification count
  int getPendingNotificationCount() {
    return _scheduledNotifications.length;
  }

  /// Show immediate notification for testing
  Future<void> showTestNotification() async {
    if (!areNotificationsEnabled()) {
      final granted = await requestPermission();
      if (!granted) {
        if (kDebugMode) {
          logger.d('❌ WebNotificationService: Test notification cancelled - permission denied');
        }
        return;
      }
    }

    _showNotification(
      999999,
      'web_notification_test'.tr(),
      'web_notification_test_message'.tr(),
    );
  }
}
