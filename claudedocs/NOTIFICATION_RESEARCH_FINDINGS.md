# Flutter Local Notifications Research Findings
**Date**: 2025-11-12
**Package**: flutter_local_notifications v18.0.1
**Target Devices**: Samsung Galaxy (S23, A31, A50, A53) with One UI
**Android Versions**: 12, 13, 14

## Executive Summary

Scheduled notifications failing on Samsung devices is a **well-documented issue** caused by:
1. Samsung's aggressive battery optimization policies (One UI specific)
2. Android 14's stricter exact alarm permission requirements
3. 500 alarm limit imposed by Samsung's AlarmManager implementation
4. Doze mode and App Standby restrictions

## Current Implementation Analysis

### What's Working ✅
- **Permissions**: All required permissions declared in AndroidManifest.xml
  - `POST_NOTIFICATIONS` (Android 13+)
  - `SCHEDULE_EXACT_ALARM` (Android 12+)
  - `USE_EXACT_ALARM` (Android 12+)
  - `RECEIVE_BOOT_COMPLETED`
  - `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`

- **Notification Channel**: Properly configured with `Importance.max`
- **Schedule Mode**: Using `AndroidScheduleMode.exactAllowWhileIdle`
- **Permission Handling**: Sequential delays to prevent "Reply already submitted" crash

### What's Missing ⚠️

1. **No runtime permission check** for `SCHEDULE_EXACT_ALARM` before scheduling
2. **No proactive battery optimization prompt** for users
3. **No alarm limit check** (Samsung's 500 alarm limit)
4. **Channel ID hasn't changed** since modifications - Android caches channel settings
5. **No user guidance** for Samsung-specific power saving settings

## Critical Issues Identified

### 1. Android 14 Permission Changes (🔴 CRITICAL)

**Issue**: `SCHEDULE_EXACT_ALARM` is **denied by default** on Android 14+ for newly installed apps.

**Official Documentation** (developer.android.com):
> "SCHEDULE_EXACT_ALARM is no longer being pre-granted to most newly installed apps targeting Android 13 and higher and will be set to denied by default on Android 14."

**Current Code Problem**:
```dart
// lib/core/services/notification_service.dart:159-184
// Only logs alarm permission status, doesn't check canScheduleExactAlarms()
final alarmStatus = await Permission.scheduleExactAlarm.status;
```

**Required Fix**:
```dart
// BEFORE scheduling notification
if (_isAndroid) {
  final alarmManager = AlarmManagerPlatformChannel();
  final canSchedule = await alarmManager.canScheduleExactAlarms();

  if (!canSchedule) {
    // Open settings for user to grant permission
    await openAlarmSettings();
    return;
  }
}
```

### 2. Samsung's 500 Alarm Limit (🔴 CRITICAL)

**Issue**: Samsung devices have a **hard limit of 500 scheduled alarms** system-wide.

**Source**: flutter_local_notifications documentation, dontkillmyapp.com

**Impact**:
- Exceeding this limit throws exceptions
- No error surfaced to user
- Silent failure mode

**Recommendation**:
```dart
Future<int> getPendingAlarmCount() async {
  final pending = await _notificationsPlugin.pendingNotificationRequests();
  return pending.length;
}

Future<void> scheduleNotification({...}) async {
  final count = await getPendingAlarmCount();

  if (count >= 450) { // Leave buffer for other apps
    // Warn user or auto-cleanup old notifications
    await _cleanupOldNotifications();
  }

  // Continue with scheduling...
}
```

### 3. Doze Mode Restrictions (🟡 IMPORTANT)

**Issue**: `setExactAndAllowWhileIdle()` is **throttled to ~15 minutes** in Doze mode.

**Official Documentation** (developer.android.com):
> "Under normal system operation, it will not dispatch these alarms more than about every minute; when in low-power idle modes this duration may be significantly longer, such as 15 minutes."

**Samsung-Specific Problem**:
Samsung's custom AlarmManager **overrides exact timing** from 13s → 5 minutes due to battery optimization, **even if app is whitelisted**.

**Workaround** (from Stack Overflow):
```dart
// Use setAlarmClock() for truly critical notifications
// Disadvantage: Shows alarm icon in status bar
androidScheduleMode: isPhoneInteractive
  ? AndroidScheduleMode.exactAllowWhileIdle
  : AndroidScheduleMode.alarmClock  // More reliable but shows icon
```

### 4. Notification Channel Caching (🟡 IMPORTANT)

**Issue**: Android **caches channel settings** on first creation. Subsequent changes are ignored.

**Current Code**:
```dart
// Channel ID changed from 'todo_notifications' to 'todo_notifications_v2'
// BUT users who installed v1 still have old channel cached
const androidChannel = AndroidNotificationChannel(
  'todo_notifications_v2',  // Line 114
```

**Problem**: Users upgrading from v1 → v2 won't get new `Importance.max` settings.

**Solution**:
```dart
// 1. Delete old channel
await _notificationsPlugin
  .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  ?.deleteNotificationChannel('todo_notifications');

// 2. Create new channel with incremented version
const androidChannel = AndroidNotificationChannel(
  'todo_notifications_v3',  // Increment version
  'Todo Reminders',
  importance: Importance.max,
);
```

### 5. Samsung Battery Optimization (🔴 CRITICAL)

**Issue**: Samsung has **three layers** of battery restrictions:

1. **App Power Management**: Automatically puts apps to sleep after 3 days
2. **Deep Sleeping Apps**: User-managed list of restricted apps
3. **"Put unused apps to sleep"**: Auto-sleep feature (enabled by default)

**Source**: dontkillmyapp.com/samsung

**Current Code**: Permission declared but **not proactively requested**:
```xml
<!-- AndroidManifest.xml:10 -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

**Recommendation**: Implement proactive battery optimization prompt:

```dart
Future<void> requestBatteryOptimizationExemption() async {
  if (!_isAndroid) return;

  // Check if already exempted
  final isIgnoringBatteryOptimizations =
    await Permission.ignoreBatteryOptimizations.isGranted;

  if (!isIgnoringBatteryOptimizations) {
    // Show explanation dialog first (required by Google Play policy)
    final userConsents = await showDialog<bool>(...);

    if (userConsents == true) {
      // Open battery optimization settings
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
}
```

**Additional Samsung-Specific Guidance Needed**:
```
Settings → Battery → Background usage limits
1. Turn off "Put unused apps to sleep"
2. Remove app from "Sleeping apps" list
3. Add app to "Never sleeping apps"
```

## Recommended Solutions (Priority Order)

### 🔴 Priority 1: Permission Validation Before Scheduling

**File**: `lib/core/services/notification_service.dart`

**Add method**:
```dart
Future<bool> canScheduleExactAlarms() async {
  if (!_isAndroid) return true;

  // For Android 12+ (API 31+)
  if (Platform.version.contains('API 31') ||
      Platform.version.contains('API 32') ||
      Platform.version.contains('API 33') ||
      Platform.version.contains('API 34')) {

    // Check SCHEDULE_EXACT_ALARM permission
    final alarmStatus = await Permission.scheduleExactAlarm.status;

    if (!alarmStatus.isGranted) {
      if (kDebugMode) {
        print('⚠️ SCHEDULE_EXACT_ALARM permission not granted');
      }
      return false;
    }
  }

  return true;
}
```

**Modify `scheduleNotification()`**:
```dart
Future<void> scheduleNotification({...}) async {
  // BEFORE scheduling, validate permissions
  if (_isAndroid) {
    final canSchedule = await canScheduleExactAlarms();

    if (!canSchedule) {
      // Prompt user to grant permission
      await _promptExactAlarmPermission();
      return;
    }
  }

  // Continue with existing scheduling logic...
}
```

### 🔴 Priority 2: Samsung Battery Optimization Guidance

**New file**: `lib/presentation/widgets/samsung_battery_guide_dialog.dart`

Show this dialog **after first notification is scheduled**:

```dart
class SamsungBatteryGuideDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('중요: 알림 설정 안내'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('삼성 기기에서 알림이 정상적으로 작동하려면 아래 설정이 필요합니다:'),
            SizedBox(height: 12),
            _buildStep('1', '배터리 최적화 해제'),
            _buildStep('2', '절전 모드 예외 앱 등록'),
            _buildStep('3', '"사용하지 않는 앱 절전" 끄기'),
            SizedBox(height: 12),
            Text('지금 설정하시겠습니까?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('나중에'),
        ),
        ElevatedButton(
          onPressed: () async {
            await Permission.ignoreBatteryOptimizations.request();
            Navigator.pop(context);
          },
          child: Text('설정하기'),
        ),
      ],
    );
  }
}
```

**Trigger in**: `lib/presentation/screens/todo_list_screen.dart`

After user schedules their first notification with reminder time.

### 🟡 Priority 3: Notification Channel Version Bump

**File**: `lib/core/services/notification_service.dart`

**Change lines 114, 251**:
```dart
// OLD:
'todo_notifications_v2'

// NEW:
'todo_notifications_v3'
```

**Add migration logic** in `initialize()`:
```dart
if (_isAndroid) {
  // Delete old channels to force recreation with new settings
  await _notificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.deleteNotificationChannel('todo_notifications');

  await _notificationsPlugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.deleteNotificationChannel('todo_notifications_v2');

  // Create new channel with v3
  await _createNotificationChannel();
}
```

### 🟡 Priority 4: Alarm Limit Monitoring

**File**: `lib/core/services/notification_service.dart`

**Add method**:
```dart
Future<void> _cleanupOldNotifications() async {
  final pending = await getPendingNotifications();

  // Sort by scheduled time (if available)
  // Cancel oldest notifications exceeding threshold
  if (pending.length > 450) {
    final toCancel = pending.length - 450;
    for (int i = 0; i < toCancel; i++) {
      await cancelNotification(pending[i].id);
    }

    if (kDebugMode) {
      print('🧹 Cleaned up $toCancel old notifications (Samsung 500 limit protection)');
    }
  }
}
```

**Call before scheduling**:
```dart
Future<void> scheduleNotification({...}) async {
  // Check alarm limit (Samsung-specific)
  if (_isAndroid) {
    await _cleanupOldNotifications();
  }

  // Continue with scheduling...
}
```

### 🟢 Priority 5: Fallback to AlarmClock for Critical Notifications

**File**: `lib/core/services/notification_service.dart`

**Add option** to `scheduleNotification()`:
```dart
Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  bool isHighPriority = false,  // NEW parameter
}) async {
  // ...

  // For Samsung devices in Doze mode, use alarmClock for reliability
  final scheduleMode = (isHighPriority && _isAndroid)
    ? AndroidScheduleMode.alarmClock  // Shows alarm icon but more reliable
    : AndroidScheduleMode.exactAllowWhileIdle;

  await _notificationsPlugin.zonedSchedule(
    id,
    title,
    body,
    scheduledTZ,
    notificationDetails,
    androidScheduleMode: scheduleMode,  // Dynamic based on priority
    // ...
  );
}
```

**Usage**:
```dart
// For urgent todos (e.g., due in <1 hour), use high priority
await notificationService.scheduleNotification(
  id: todo.id,
  title: todo.title,
  body: todo.description,
  scheduledDate: todo.reminderTime,
  isHighPriority: todo.dueDate?.difference(DateTime.now()).inHours ?? 24 < 1,
);
```

## Testing Checklist

### Pre-Release Testing (Samsung Devices Required)

- [ ] **Fresh Install on Android 14** (Galaxy S23)
  - [ ] Verify exact alarm permission prompt appears
  - [ ] Check notification appears at exact scheduled time
  - [ ] Confirm no "Reply already submitted" crash

- [ ] **App in Background (Doze Mode)**
  - [ ] Schedule notification for 2 minutes from now
  - [ ] Turn off screen and wait 5 minutes
  - [ ] Verify notification appeared (may be delayed up to 15 min)

- [ ] **Battery Optimization Enabled**
  - [ ] Enable "Put unused apps to sleep" in Samsung settings
  - [ ] Wait 10 minutes with app closed
  - [ ] Verify scheduled notifications still fire

- [ ] **Alarm Limit Test**
  - [ ] Schedule 20+ notifications
  - [ ] Verify no exceptions thrown
  - [ ] Check pending notification count

- [ ] **Upgrade Flow (v1 → v2 → v3)**
  - [ ] Install app with old channel ID
  - [ ] Upgrade to new version
  - [ ] Verify new channel settings applied

### Debug Commands

```bash
# Check pending alarms
adb shell dumpsys alarm | grep kr.bluesky.dodo

# Check notification channels
adb shell dumpsys notification | grep -A 20 "kr.bluesky.dodo"

# Check battery optimization status
adb shell dumpsys deviceidle whitelist | grep kr.bluesky.dodo

# Simulate Doze mode
adb shell dumpsys battery unplug
adb shell dumpsys deviceidle force-idle

# Exit Doze mode
adb shell dumpsys deviceidle unforce
adb shell dumpsys battery reset
```

## References

### Official Documentation
- [Android Developer - Schedule Exact Alarms](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
- [Android Developer - Doze and App Standby](https://developer.android.com/training/monitoring-device-state/doze-standby)
- [Android Developer - AlarmManager API](https://developer.android.com/reference/android/app/AlarmManager)
- [flutter_local_notifications v18 Documentation](https://pub.dev/packages/flutter_local_notifications)

### Community Resources
- [Don't Kill My App - Samsung Guide](https://dontkillmyapp.com/samsung)
- [GitHub Issue #2185 - Android 14 Schedule Notifications](https://github.com/MaikuB/flutter_local_notifications/issues/2185)
- [Stack Overflow - Samsung AlarmManager Issues](https://stackoverflow.com/questions/52991241/alarmmanager-does-not-wakeup-at-right-time-on-samsung-phone)

### Key Insights from Research

1. **Samsung's AlarmManager Override**: Samsung devices override `setExact()` timing from 13s → 5 min due to battery optimization, **even for whitelisted apps**

2. **Android 14 Breaking Change**: `SCHEDULE_EXACT_ALARM` denied by default for new installs on Android 14+

3. **Doze Mode Throttling**: `setExactAndAllowWhileIdle()` limited to ~15 min intervals in Doze mode

4. **Channel Caching**: Android caches notification channel settings on first creation; must delete + recreate to apply changes

5. **500 Alarm Limit**: Samsung-specific hard limit requires proactive cleanup

## Implementation Timeline

### Phase 1 (Critical - Week 1)
- [ ] Add `canScheduleExactAlarms()` check before scheduling
- [ ] Implement battery optimization prompt
- [ ] Bump channel ID to v3 with migration

### Phase 2 (Important - Week 2)
- [ ] Add alarm limit monitoring and cleanup
- [ ] Create Samsung-specific user guidance dialog
- [ ] Implement high-priority alarm mode (alarmClock fallback)

### Phase 3 (Testing - Week 3)
- [ ] Test on Samsung S23 (Android 14)
- [ ] Test on Samsung A31 (Android 11/12)
- [ ] Validate Doze mode behavior
- [ ] Stress test with 50+ scheduled notifications

### Phase 4 (Documentation)
- [ ] Update CLAUDE.md with new testing procedures
- [ ] Create user-facing FAQ for notification issues
- [ ] Add troubleshooting guide to SAMSUNG_ONE_UI_NOTIFICATION_GUIDE.md

## Conclusion

Samsung notification issues are **systemic** and require **multiple layers of mitigation**:

1. **Permission Layer**: Validate exact alarm permissions at runtime
2. **Optimization Layer**: Guide users to disable battery restrictions
3. **Technical Layer**: Implement alarm limit protection + channel versioning
4. **Fallback Layer**: Use `alarmClock` mode for critical notifications

No single fix resolves all issues - a **comprehensive approach** is required.

---
**Next Steps**: Implement Priority 1 changes and test on physical Samsung device before proceeding to Priority 2-5.
