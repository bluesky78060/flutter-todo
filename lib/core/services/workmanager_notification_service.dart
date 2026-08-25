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
      } else if (task == 'geofence_check_task' ||
          task == 'geofence_check_unique_id') {
        // DTA-4-5: 두 문자열을 모두 받아야 한다. 플랫폼마다 넘어오는 값이 다르다.
        //   Android — registerPeriodicTask(uniqueName, taskName)의 **taskName**
        //              ('geofence_check_task')
        //   iOS     — BGTaskScheduler **identifier** ('geofence_check_unique_id').
        //              workmanager_apple의 BackgroundWorker.onResultSendArguments가
        //              .backgroundPeriodicTask(identifier)를 그대로 DART_TASK에 담는다.
        // iOS 값을 빠뜨리면 여기서 'Unknown task type'으로 빠져 지오펜스 핸들러가
        // **아예 호출되지 않는다.** 그것이 이 분기의 이유 전부다.
        //
        // (초안 주석은 "false를 반환하면 플러그인이 setTaskCompleted(success: false)로
        //  보고해 iOS가 백그라운드 예산을 깎는다"고 적었으나 사실이 아니다. 플러그인은
        //  setTaskCompleted(success: !operation.isCancelled)로 **취소 여부만** 보고하고
        //  (WorkmanagerPlugin.swift:30,55), Dart 반환값은 performBackgroundRequest { _ in }
        //  에서 버려진다(BackgroundTaskOperation.swift:41). 반환값을 OS에 전달하는 경로는
        //  iOS 12의 performFetchWithCompletionHandler뿐이고 이 앱은 그 경로를 쓰지 않는다.)
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

  /// DTA-4-5: 진행 중인 초기화를 캐싱한다.
  ///
  /// `_initialized` 플래그만으로는 **순차 호출만** 막힌다. main.dart 는
  /// _initNotificationService() 와 _initGeofenceService() 를 Future.wait 로 **동시** 실행하고,
  /// 후자가 DTA-4-5 에서 이 initialize() 를 호출하게 됐다. 삼성 Android 에서는 두 경로가
  /// 모두 여기 도달하므로, 플래그가 세워지기 전에 둘 다 통과해 Workmanager().initialize() 가
  /// 두 번 불릴 수 있다. 진행 중인 Future 를 공유해 그것을 막는다.
  Future<void>? _initFuture;

  /// Initialize WorkManager for notification scheduling
  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initFuture ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
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
      // 실패한 Future 를 캐시에 남기면 이후 호출이 영구히 같은 실패를 돌려받는다.
      // 비워서 재시도가 가능하게 한다.
      _initFuture = null;
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