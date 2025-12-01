import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
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
      final permission = html.Notification.permission;
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
    return html.window.navigator.userAgent.isNotEmpty &&
           html.Notification.supported;
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (!kIsWeb || !_isNotificationSupported()) {
      return false;
    }

    try {
      final permission = await html.Notification.requestPermission();
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
    return _permissionGranted && html.Notification.permission == 'granted';
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

      // Use JS interop to create notification with options
      final notificationConstructor = js.context['Notification'];
      final options = js.JsObject.jsify({
        'body': body,
        'icon': '/icons/Icon-192.png',
        'tag': 'todo-$id',
        'requireInteraction': false,
        'silent': false,
      });

      final jsNotification = js.JsObject(notificationConstructor, [title, options]);

      // Auto close after 10 seconds
      Timer(const Duration(seconds: 10), () {
        jsNotification.callMethod('close', []);
      });

      // Handle notification click
      jsNotification['onclick'] = js.allowInterop((_) {
        // Focus window
        try {
          js.context.callMethod('focus', []);
        } catch (e) {
          if (kDebugMode) {
            logger.d('⚠️ Could not focus window: $e');
          }
        }
        jsNotification.callMethod('close', []);
      });

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
