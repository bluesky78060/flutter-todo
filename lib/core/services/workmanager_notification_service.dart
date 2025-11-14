import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// WorkManager callback function - MUST be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize notification service for background
      final notificationService = FlutterLocalNotificationsPlugin();

      // Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await notificationService.initialize(initSettings);

      // Show notification immediately
      final id = inputData?['id'] ?? DateTime.now().millisecondsSinceEpoch;
      final title = inputData?['title'] ?? 'Todo Reminder';
      final body = inputData?['body'] ?? 'You have a scheduled task';

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
        category: AndroidNotificationCategory.reminder,
        groupKey: 'kr.bluesky.dodo.TODO_REMINDERS',
        setAsGroupSummary: false,
        ongoing: false,
        onlyAlertOnce: false,
        visibility: NotificationVisibility.public,
        ticker: title,
        enableLights: true,
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await notificationService.show(
        id,
        title,
        body,
        notificationDetails,
      );

      if (kDebugMode) {
        print('✅ WorkManager notification shown: $title');
      }

      return Future.value(true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ WorkManager task failed: $e');
      }
      return Future.value(false);
    }
  });
}

/// WorkManager-based notification service for Samsung devices
class WorkManagerNotificationService {
  static final WorkManagerNotificationService _instance =
      WorkManagerNotificationService._internal();
  factory WorkManagerNotificationService() => _instance;
  WorkManagerNotificationService._internal();

  bool _initialized = false;

  /// Initialize WorkManager for notification scheduling
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      _initialized = true;

      if (kDebugMode) {
        print('✅ WorkManager initialized for notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize WorkManager: $e');
      }
      rethrow;
    }
  }

  /// Schedule a notification using WorkManager
  /// This is more reliable on Samsung devices with aggressive battery optimization
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
        }
        return;
      }

      // Calculate initial delay
      final initialDelay = scheduledDate.difference(now);

      // Create unique task name
      final taskName = 'todo-notification-$id-${scheduledDate.millisecondsSinceEpoch}';

      if (kDebugMode) {
        print('📅 Scheduling WorkManager notification:');
        print('   ID: $id');
        print('   Title: $title');
        print('   Body: $body');
        print('   Scheduled: $scheduledDate');
        print('   Initial Delay: $initialDelay');
        print('   Task Name: $taskName');
      }

      // Register one-off task
      await Workmanager().registerOneOffTask(
        taskName,
        'showNotification',
        initialDelay: initialDelay,
        constraints: Constraints(
          // Don't require network (WorkManager 0.9.0+ uses camelCase)
          networkType: NetworkType.notRequired,
          // Don't require battery to be not low
          requiresBatteryNotLow: false,
          // Don't require charging
          requiresCharging: false,
          // Don't require device to be idle (important for Samsung)
          requiresDeviceIdle: false,
          // Don't require storage to be not low
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(seconds: 10),
        inputData: {
          'id': id,
          'title': title,
          'body': body,
          'scheduledDate': scheduledDate.toIso8601String(),
        },
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      if (kDebugMode) {
        print('✅ WorkManager notification scheduled successfully');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error scheduling WorkManager notification: $e');
        print('   Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(String taskName) async {
    try {
      await Workmanager().cancelByUniqueName(taskName);

      if (kDebugMode) {
        print('🗑️ WorkManager notification cancelled: $taskName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling WorkManager notification: $e');
      }
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await Workmanager().cancelAll();

      if (kDebugMode) {
        print('🗑️ All WorkManager notifications cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelling all WorkManager notifications: $e');
      }
    }
  }
}