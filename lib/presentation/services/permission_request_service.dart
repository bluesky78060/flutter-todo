/// Permission request service for managing Android permissions.
///
/// Handles all permission request flows with dialog management:
/// - Notifications (POST_NOTIFICATIONS)
/// - Location (ACCESS_FINE_LOCATION)
/// - Exact Alarms (SCHEDULE_EXACT_ALARM)
/// - Battery Optimization exemption
///
/// Features:
/// - Sequential permission requests with delays
/// - Theme-aware dialog styling
/// - Duplicate request guard
/// - Error handling and logging
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:todo_app/core/services/battery_optimization_service.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';

/// Service for managing permission requests with dialogs.
///
/// Provides:
/// - `requestNotificationPermission()` - POST_NOTIFICATIONS on Android 13+
/// - `requestLocationPermission()` - ACCESS_FINE_LOCATION
/// - `requestExactAlarmPermission()` - SCHEDULE_EXACT_ALARM on Android 12+
/// - `requestBatteryOptimization()` - Battery optimization exemption
/// - `showPermissionDialog()` - Generic theme-aware dialog builder
///
/// All methods handle errors gracefully and log for debugging.
class PermissionRequestService {
  /// Creates a new permission request service.
  ///
  /// Parameters:
  /// - [context]: BuildContext for showing dialogs
  /// - [isDarkMode]: Whether dark mode is enabled
  /// - [onSettingsOpen]: Optional callback when settings are opened
  PermissionRequestService({
    required this.context,
    required this.isDarkMode,
    this.onSettingsOpen,
  });

  /// BuildContext for showing dialogs
  final BuildContext context;

  /// Dark mode flag for dialog styling
  final bool isDarkMode;

  /// Optional callback when opening settings
  final VoidCallback? onSettingsOpen;

  /// Request notification permission (POST_NOTIFICATIONS).
  ///
  /// Shows a themed dialog explaining why notifications are needed,
  /// then requests the permission. If granted, shows a guide to enable
  /// in Android settings.
  ///
  /// Returns true if user allowed, false if denied or error occurred.
  Future<bool> requestNotificationPermission() async {
    try {
      final notificationService = NotificationService();
      final isEnabled = await notificationService.areNotificationsEnabled();

      if (!isEnabled && context.mounted) {
        // Show permission request dialog
        final shouldRequest = await showPermissionDialog(
          title: 'permission_notification_title'.tr(),
          message: 'permission_notification_desc'.tr(),
          icon: null,
          iconColor: AppColors.primaryBlue,
        );

        if (shouldRequest == true) {
          await notificationService.requestPermissions();

          // Show settings guide after requesting
          if (context.mounted) {
            await Future.delayed(const Duration(milliseconds: 500));
            await _showNotificationSettingsGuide(notificationService);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Notification permission request error: $e');
      return false;
    }
  }

  /// Request location permission (ACCESS_FINE_LOCATION).
  ///
  /// Shows a themed dialog explaining why location is needed.
  /// Skips if already granted or permanently denied.
  ///
  /// Returns true if user allowed, false otherwise.
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      // Skip if already granted
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        debugPrint('📍 Location permission already granted');
        return true;
      }

      // Skip if permanently denied
      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied');
        return false;
      }

      // Request permission
      if (context.mounted) {
        final shouldRequest = await showPermissionDialog(
          title: 'permission_location_title'.tr(),
          message: 'permission_location_desc'.tr(),
          icon: FluentIcons.location_24_regular,
          iconColor: AppColors.primaryBlue,
        );

        if (shouldRequest == true) {
          final result = await Geolocator.requestPermission();
          if (result == LocationPermission.denied) {
            debugPrint('📍 Location permission denied');
            return false;
          } else if (result == LocationPermission.deniedForever) {
            debugPrint('⚠️ Location permission denied forever');
            return false;
          } else {
            debugPrint('✅ Location permission granted: $result');
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Location permission request error: $e');
      return false;
    }
  }

  /// Request exact alarm permission (SCHEDULE_EXACT_ALARM).
  ///
  /// On Android 12+, apps need explicit permission to schedule exact alarms.
  /// Shows a themed dialog explaining the requirement.
  ///
  /// Returns true if user allowed settings, false otherwise.
  Future<bool> requestExactAlarmPermission() async {
    try {
      final notificationService = NotificationService();
      final canSchedule = await notificationService.canScheduleExactAlarms();

      if (!canSchedule && context.mounted) {
        final shouldRequest = await showPermissionDialog(
          title: 'permission_exact_alarm_title'.tr(),
          message: 'permission_exact_alarm_desc'.tr(),
          icon: FluentIcons.alert_24_regular,
          iconColor: AppColors.accentOrange,
        );

        if (shouldRequest == true) {
          await notificationService.openExactAlarmSettings();
          onSettingsOpen?.call();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Exact alarm permission request error: $e');
      return false;
    }
  }

  /// Request battery optimization exemption.
  ///
  /// Samsung and other devices can aggressively optimize battery,
  /// preventing notifications and alarms. This requests exemption.
  ///
  /// Returns true if user opened settings, false otherwise.
  Future<bool> requestBatteryOptimization() async {
    try {
      final isIgnoring =
          await BatteryOptimizationService.isIgnoringBatteryOptimizations();

      if (!isIgnoring && context.mounted) {
        final shouldRequest = await showPermissionDialog(
          title: 'permission_battery_title'.tr(),
          message: 'permission_battery_desc'.tr(),
          icon: null,
          iconColor: AppColors.primaryBlue,
        );

        if (shouldRequest == true) {
          await BatteryOptimizationService.requestIgnoreBatteryOptimizations();
          onSettingsOpen?.call();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Battery optimization request error: $e');
      return false;
    }
  }

  /// Show a themed permission request dialog.
  ///
  /// Parameters:
  /// - [title]: Dialog title
  /// - [message]: Dialog message/description
  /// - [icon]: Optional icon widget to show in title
  /// - [iconColor]: Color for the icon
  ///
  /// Returns:
  /// - `true` if user pressed "Allow" or "Open Settings"
  /// - `false` if user pressed "Deny"
  /// - `null` if dialog was dismissed
  Future<bool?> showPermissionDialog({
    required String title,
    required String message,
    IconData? icon,
    required Color iconColor,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(isDarkMode),
        title: icon != null
            ? Row(
                children: [
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: AppColors.textWhite),
                    ),
                  ),
                ],
              )
            : Text(
                title,
                style: const TextStyle(color: AppColors.textWhite),
              ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textGray, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'deny'.tr(),
              style: const TextStyle(color: AppColors.textGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              'allow'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Show notification settings guide dialog.
  ///
  /// After requesting notification permission, guides user to enable
  /// notifications in Android settings where it's often disabled by default.
  Future<void> _showNotificationSettingsGuide(
    NotificationService notificationService,
  ) async {
    if (!context.mounted) return;

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCard(isDarkMode),
        title: Row(
          children: [
            const Icon(
              FluentIcons.info_24_regular,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 12),
            Text(
              'notification_settings'.tr(),
              style: const TextStyle(color: AppColors.textWhite),
            ),
          ],
        ),
        content: Text(
          'permission_notification_rationale'.tr(),
          style: const TextStyle(color: AppColors.textGray, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'deny'.tr(),
              style: const TextStyle(color: AppColors.textGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              'settings_open'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await notificationService.openNotificationSettings();
      onSettingsOpen?.call();
    }
  }
}
