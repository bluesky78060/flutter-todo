import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// WorkManager callback function - MUST be a top-level function
/// This is now a UNIFIED callback that handles both notifications and geofence checks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (kDebugMode) {
        print('🔄 WorkManager task started: $task');
      }

      // Route to appropriate handler based on task name
      if (task == 'showNotification') {
        return await _handleNotificationTask(inputData);
      } else if (task == 'geofence_check_task') {
        return await _handleGeofenceTask(inputData);
      } else {
        if (kDebugMode) {
          print('⚠️ Unknown task type: $task');
        }
        return Future.value(false);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ WorkManager task failed: $e');
        print('   Stack trace: $stackTrace');
      }
      return Future.value(false);
    }
  });
}

/// Handle notification display task
Future<bool> _handleNotificationTask(Map<String, dynamic>? inputData) async {
  try {
    // Initialize notification service for background
    final notificationService = FlutterLocalNotificationsPlugin();

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await notificationService.initialize(initSettings);

    // Create notification channel (required for Android 8+)
    final androidPlugin = notificationService
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    const androidChannel = AndroidNotificationChannel(
      'todo_notifications_v3',
      'Todo Reminders',
      description: 'Notifications for todo items',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
    );

    await androidPlugin?.createNotificationChannel(androidChannel);

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
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Notification task failed: $e');
      print('   Stack trace: $stackTrace');
    }
    return Future.value(false);
  }
}

/// Handle geofence check task
/// NOTE: This is imported from geofence_workmanager_service.dart logic
Future<bool> _handleGeofenceTask(Map<String, dynamic>? inputData) async {
  try {
    // For now, just return success
    // Geofence logic is handled separately in GeofenceWorkManagerService
    if (kDebugMode) {
      print('📍 Geofence task received - handled separately');
    }
    return Future.value(true);
  } catch (e) {
    if (kDebugMode) {
      print('❌ Geofence task failed: $e');
    }
    return Future.value(false);
  }
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