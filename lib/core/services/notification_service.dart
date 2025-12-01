import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/core/services/web_notification_service_stub.dart'
    if (dart.library.html) 'package:todo_app/core/services/web_notification_service.dart';
import 'package:todo_app/core/services/workmanager_notification_service.dart';
import 'package:todo_app/core/utils/samsung_device_utils.dart';
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
  final WorkManagerNotificationService _workManagerService = WorkManagerNotificationService();

  bool _initialized = false;
  bool _isSamsungDevice = false;

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
        // CRITICAL: Show notifications even when app is in foreground
        // Without this, notifications won't appear while app is open
        defaultPresentAlert: true,
        defaultPresentSound: true,
        defaultPresentBadge: true,
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

        // Check if Samsung device and apply workarounds
        _isSamsungDevice = await SamsungDeviceUtils.isSamsungDevice();
        if (_isSamsungDevice) {
          if (kDebugMode) {
            print('📱 Samsung device detected - initializing WorkManager');
          }

          // Initialize WorkManager for Samsung devices
          await _workManagerService.initialize();

          // Apply Samsung-specific workarounds
          await SamsungDeviceUtils.applySamsungWorkarounds();
        }
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
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // 이전 채널 삭제 (v1, v2) - 캐시된 잘못된 설정 제거
    if (androidPlugin != null) {
      try {
        await androidPlugin.deleteNotificationChannel('todo_notifications');
        await androidPlugin.deleteNotificationChannel('todo_notifications_v2');
        if (kDebugMode) {
          print('🗑️ Old notification channels deleted');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Could not delete old channels (might not exist): $e');
        }
      }
    }

    const androidChannel = AndroidNotificationChannel(
      'todo_notifications_v3',  // v3로 업데이트 - 채널 캐싱 문제 해결
      'Todo Reminders',
      description: 'Notifications for todo items',
      importance: Importance.max,  // high -> max로 변경 (헤드업 알림 필수)
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    );

    await androidPlugin?.createNotificationChannel(androidChannel);

    if (kDebugMode) {
      print('📱 Android notification channel v3 created');
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

      // Use WorkManager for Samsung devices or devices with battery optimization
      final shouldUseWorkManager = await SamsungDeviceUtils.shouldUseWorkManager();
      if (shouldUseWorkManager) {
        if (kDebugMode) {
          print('📱 Using WorkManager for notification scheduling');
        }

        await _workManagerService.scheduleNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
        );

        if (kDebugMode) {
          print('✅ Notification scheduled via WorkManager');
        }
        return;
      }

      // Log Samsung device detection
      if (_isSamsungDevice) {
        if (kDebugMode) {
          print('📱 Samsung device detected - using WorkManager');
        }
        // Apply Samsung workarounds
        await SamsungDeviceUtils.applySamsungWorkarounds();
      }

      // Android 14+ (API 34+): Check if we can schedule exact alarms
      // This permission is DENIED by default for fresh installs
      if (_isAndroid) {
        try {
          final alarmStatus = await Permission.scheduleExactAlarm.status;
          if (!alarmStatus.isGranted) {
            if (kDebugMode) {
              print('❌ Cannot schedule exact alarm - permission denied');
              print('   User must grant permission in Settings');
            }
            // Don't throw - just log and let it schedule with best effort
            // The system will use inexact timing instead
          } else {
            if (kDebugMode) {
              print('✅ Exact alarm permission granted');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Exact alarm check failed: $e');
          }
        }
      }

      final androidDetails = AndroidNotificationDetails(
        'todo_notifications_v3',  // v3 채널 ID와 일치
        'Todo Reminders',
        channelDescription: 'Notifications for todo items',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        // 포그라운드에서도 알림 표시
        channelShowBadge: true,
        autoCancel: true,  // 탭하면 자동으로 사라짐
        // 헤드업 알림으로 표시 (앱이 열려있어도 위에 팝업으로 표시)
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        // 알림 그룹 설정 (여러 알림을 그룹화)
        groupKey: 'kr.bluesky.dodo.TODO_REMINDERS',
        setAsGroupSummary: false,
        // 알림 스타일 설정 - body 내용을 표시
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'notification_todo_reminder'.tr(),
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

  /// Open app notification settings
  Future<bool> openNotificationSettings() async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('⚠️ Cannot open settings on web platform');
      }
      return false;
    }

    try {
      final opened = await Permission.notification.status.isDenied
          ? await Permission.notification.request().isGranted
          : true;

      if (!opened || _isAndroid) {
        // Open app-specific notification settings
        await Permission.notification.shouldShowRequestRationale
            ? await Permission.notification.request()
            : null;

        // For Android, always try to open settings
        final settingsOpened = await openAppSettings();

        if (kDebugMode) {
          print(settingsOpened
              ? '✅ Opened app notification settings'
              : '❌ Failed to open notification settings');
        }

        return settingsOpened;
      }

      return opened;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening notification settings: $e');
      }
      return false;
    }
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

  /// Check if exact alarm permission is granted (Android 14+)
  /// Returns true if granted, false if denied or not available
  Future<bool> canScheduleExactAlarms() async {
    if (!_isAndroid) {
      return true; // iOS doesn't need this permission
    }

    try {
      final status = await Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not check exact alarm permission: $e');
      }
      return false;
    }
  }

  /// Open exact alarm settings page (Android 14+)
  /// Returns true if settings opened successfully
  Future<bool> openExactAlarmSettings() async {
    if (!_isAndroid) {
      return false;
    }

    try {
      // First try to request permission
      final status = await Permission.scheduleExactAlarm.request();

      if (!status.isGranted) {
        // If still not granted, open app settings
        final opened = await openAppSettings();
        if (kDebugMode) {
          print(opened
              ? '✅ Opened exact alarm settings'
              : '❌ Failed to open exact alarm settings');
        }
        return opened;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error opening exact alarm settings: $e');
      }
      return false;
    }
  }

  /// Snooze a notification for a specific duration
  /// Returns true if snooze was successful
  Future<bool> snoozeNotification({
    required int id,
    required String title,
    required String body,
    required Duration snoozeDuration,
  }) async {
    try {
      // Cancel existing notification
      await cancelNotification(id);

      // Calculate new notification time
      final newNotificationTime = DateTime.now().add(snoozeDuration);

      // Schedule new notification
      await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: newNotificationTime,
      );

      if (kDebugMode) {
        print('🔔 Notification snoozed for ${snoozeDuration.inMinutes} minutes');
        print('   New notification time: $newNotificationTime');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error snoozing notification: $e');
      }
      return false;
    }
  }

  /// Show location-based notification immediately
  /// Used when user enters a geofence radius
  Future<void> showLocationNotification({
    required int id,
    required String title,
    required String body,
    required double distance,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      // For web platform, use WebNotificationService
      if (kIsWeb) {
        // Web doesn't have immediate notifications, would need to schedule for "now"
        if (kDebugMode) {
          print('🌐 Location notifications not supported on web');
        }
        return;
      }

      // Format distance message
      final distanceText = distance < 1000
          ? 'notification_within_meters'.tr(namedArgs: {'distance': distance.toStringAsFixed(0)})
          : 'notification_within_km'.tr(namedArgs: {'distance': (distance / 1000).toStringAsFixed(1)});

      final androidDetails = AndroidNotificationDetails(
        'todo_notifications_v3',
        'Todo Reminders',
        channelDescription: 'Notifications for todo items',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        channelShowBadge: true,
        autoCancel: true,
        fullScreenIntent: false,
        category: AndroidNotificationCategory.reminder,
        groupKey: 'kr.bluesky.dodo.TODO_REMINDERS',
        setAsGroupSummary: false,
        styleInformation: BigTextStyleInformation(
          '$body\n\n📍 $distanceText',
          contentTitle: '📍 $title',
          summaryText: 'notification_location_reminder'.tr(),
        ),
        ongoing: false,
        onlyAlertOnce: false,
        visibility: NotificationVisibility.public,
        ticker: '📍 $title - $distanceText',
        enableLights: true,
        ledColor: const Color.fromARGB(255, 33, 150, 243), // Blue for location
        ledOnMs: 1000,
        ledOffMs: 500,
        usesChronometer: false,
        timeoutAfter: null,
        when: DateTime.now().millisecondsSinceEpoch,
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

      if (kDebugMode) {
        print('📍 Showing location notification:');
        print('   ID: $id');
        print('   Title: $title');
        print('   Body: $body');
        print('   Distance: $distanceText');
      }

      await _notificationsPlugin.show(
        id,
        '📍 $title',
        '$body\n\n📍 $distanceText',
        notificationDetails,
      );

      if (kDebugMode) {
        print('✅ Location notification shown successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error showing location notification: $e');
        print('   Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}
