import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
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

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (kDebugMode) {
        print('✅ Notification service initialized: $initialized');
      }

      // Create notification channel for Android
      if (!kIsWeb && Platform.isAndroid) {
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
      'todo_notifications',
      'Todo Reminders',
      description: 'Notifications for todo items',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
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
      if (kDebugMode) {
        print('⚠️ Web platform - notification permissions handled by browser');
      }
      return true;
    }

    // For Android 13+ (API 33+)
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.notification.request();

      if (kDebugMode) {
        print('📱 Android notification permission: ${status.name}');
      }

      // Request exact alarm permission for Android 12+
      if (await Permission.scheduleExactAlarm.isDenied) {
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        if (kDebugMode) {
          print('⏰ Exact alarm permission: ${alarmStatus.name}');
        }
      }

      return status.isGranted;
    }

    // For iOS
    if (!kIsWeb && Platform.isIOS) {
      final status = await Permission.notification.request();
      if (kDebugMode) {
        print('🍎 iOS notification permission: ${status.name}');
      }
      return status.isGranted;
    }

    return true;
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

      const androidDetails = AndroidNotificationDetails(
        'todo_notifications',
        'Todo Reminders',
        channelDescription: 'Notifications for todo items',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const notificationDetails = NotificationDetails(
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

      await _notifications.zonedSchedule(
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
      final pending = await _notifications.pendingNotificationRequests();
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
    await _notifications.cancel(id);
    if (kDebugMode) {
      print('🗑️ Notification cancelled with ID: $id');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    if (kDebugMode) {
      print('🗑️ All notifications cancelled');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
