import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/core/services/web_notification_service_stub.dart'
    if (dart.library.html) 'package:todo_app/core/services/web_notification_service.dart';
import 'package:todo_app/main.dart' show notificationTapBackground;

// Helper to check if running on Android (web-safe)
bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

// Helper to check if running on iOS (web-safe)
bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FlutterLocalNotificationsPlugin? _notifications;
  final WebNotificationService _webNotifications = WebNotificationService();

  bool _initialized = false;

  FlutterLocalNotificationsPlugin get _notificationsPlugin {
    if (kIsWeb) {
      throw UnsupportedError('FlutterLocalNotifications not supported on web');
    }
    _notifications ??= FlutterLocalNotificationsPlugin();
    return _notifications!;
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // For web platform, use WebNotificationService
      if (kIsWeb) {
        await _webNotifications.initialize();
        _initialized = true;
        if (kDebugMode) {
          print('✅ Web notification service initialized');
        }
        return;
      }

      // Initialize timezone for mobile platforms
      tz.initializeTimeZones();

      // Set local timezone
      final String timeZoneName = DateTime.now().timeZoneName;
      if (kDebugMode) {
        print('🌍 Setting timezone to: $timeZoneName');
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        // Fallback to Asia/Seoul if timezone not found
        if (kDebugMode) {
          print('⚠️ Could not set timezone $timeZoneName, using Asia/Seoul');
        }
        tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      }

      // Android initialization settings
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        // ✅ CRITICAL: Background notification handler for when app is terminated
        // Using the top-level function from main.dart
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      if (kDebugMode) {
        print('✅ Mobile notification service initialized: $initialized');
      }

      // Create notification channel for Android
      if (_isAndroid) {
        await _createNotificationChannel();
      }

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize notification service: $e');
      }
      rethrow;
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'todo_notifications_v2',  // 새 채널 ID - 업데이트 시 새 설정 적용
      'Todo Reminders',
      description: 'Notifications for todo items',
      importance: Importance.max,  // high -> max로 변경 (헤드업 알림 필수)
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    if (kDebugMode) {
      print('📱 Android notification channel created');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation or action when notification is tapped
    if (kDebugMode) {
      print('🔔 Notification tapped: ${response.payload}');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return await _webNotifications.requestPermission();
    }

    try {
      // For Android 13+ (API 33+)
      if (_isAndroid) {
        final status = await Permission.notification.request();

        if (kDebugMode) {
          print('📱 Android notification permission: ${status.name}');
        }

        // Check and request exact alarm permission for Android 12+
        // Wrap in try-catch to handle potential SecurityException
        try {
          final alarmStatus = await Permission.scheduleExactAlarm.status;
          if (kDebugMode) {
            print('⏰ Exact alarm permission status: ${alarmStatus.name}');
          }

          // Only request if not granted
          if (!alarmStatus.isGranted && alarmStatus.isDenied) {
            if (kDebugMode) {
              print('⚠️ Exact alarm permission not granted, requesting...');
            }

            // Add delay before requesting to avoid conflicts
            await Future.delayed(const Duration(milliseconds: 200));

            final newAlarmStatus = await Permission.scheduleExactAlarm.request();
            if (kDebugMode) {
              print('⏰ Exact alarm permission after request: ${newAlarmStatus.name}');
            }
          }
        } catch (alarmError) {
          if (kDebugMode) {
            print('⚠️ Exact alarm permission check failed (non-critical): $alarmError');
          }
          // Continue even if exact alarm fails - notification can still work with inexact timing
        }

        return status.isGranted;
      }

      // For iOS
      if (_isIOS) {
        final status = await Permission.notification.request();
        if (kDebugMode) {
          print('🍎 iOS notification permission: ${status.name}');
        }
        return status.isGranted;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Permission request error: $e');
      }
      return false;
    }
  }

  /// Schedule a notification for a specific date and time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // For web platform, use WebNotificationService
      if (kIsWeb) {
        await _webNotifications.scheduleNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
        );
        return;
      }

      // Check if scheduled date is in the future
      final now = DateTime.now();
      if (scheduledDate.isBefore(now)) {
        if (kDebugMode) {
          print('❌ Cannot schedule notification in the past');
          print('   Scheduled: $scheduledDate');
          print('   Now: $now');
        }
        return;
      }

      // Check permissions
      final hasPermission = await areNotificationsEnabled();
      if (!hasPermission) {
        if (kDebugMode) {
          print('⚠️ Notification permission not granted');
        }
        await requestPermissions();
      }

      final androidDetails = AndroidNotificationDetails(
        'todo_notifications_v2',  // 새 채널 ID와 일치
        'Todo Reminders',
        channelDescription: 'Notifications for todo items',
        importance: Importance.max,
        priority: Priority.max,  // high -> max로 변경
        showWhen: true,
        enableVibration: true,
        playSound: true,
        // 포그라운드에서도 알림 표시
        channelShowBadge: true,
        autoCancel: false,  // 사용자가 직접 닫을 때까지 유지
        // 헤드업 알림으로 표시 (앱이 열려있어도 위에 팝업으로 표시)
        // 일부 기기에서 풀스크린 인텐트는 별도 구성 없이는 크래시를 유발할 수 있어 비활성화
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        // 알림 스타일 설정 - body 내용을 표시
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: '할일 알림',
        ),
        // 알림바에 계속 표시
        ongoing: false,
        // 매번 알림
        onlyAlertOnce: false,
        // 화면 켜기
        visibility: NotificationVisibility.public,
        // 중요도 높이기 위한 추가 설정
        ticker: title,
        // LED 설정
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        // Android 14+ 호환성
        usesChronometer: false,
        timeoutAfter: null,
        // 추가 설정
        when: scheduledDate.millisecondsSinceEpoch,
        showProgress: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

      if (kDebugMode) {
        print('📅 Scheduling notification:');
        print('   ID: $id');
        print('   Title: $title');
        print('   Body: $body');
        print('   Scheduled (local): $scheduledDate');
        print('   Scheduled (TZ): $scheduledTZ');
        print('   Timezone: ${tz.local.name}');
      }

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );

      // Verify scheduling
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      final thisNotification = pending.where((n) => n.id == id).firstOrNull;

      if (kDebugMode) {
        if (thisNotification != null) {
          print('✅ Notification scheduled successfully');
          print('   Total pending: ${pending.length}');
        } else {
          print('⚠️ Notification may not have been scheduled');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error scheduling notification: $e');
        print('   Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      _webNotifications.cancelNotification(id);
      return;
    }

    await _notificationsPlugin.cancel(id);
    if (kDebugMode) {
      print('🗑️ Notification cancelled with ID: $id');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      _webNotifications.cancelAllNotifications();
      return;
    }

    await _notificationsPlugin.cancelAll();
    if (kDebugMode) {
      print('🗑️ All notifications cancelled');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) {
      return _webNotifications.areNotificationsEnabled();
    }

    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) {
      // For web, return empty list as we can't get structured pending notifications
      // but the count is available via WebNotificationService.getPendingNotificationCount()
      if (kDebugMode) {
        final count = _webNotifications.getPendingNotificationCount();
        print('🌐 Web pending notifications count: $count');
      }
      return [];
    }

    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
