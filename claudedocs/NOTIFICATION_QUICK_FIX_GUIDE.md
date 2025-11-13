# Quick Fix Guide: Samsung Notification Issues

**Target**: Samsung Galaxy devices (S23, A31, A50, A53) with One UI
**Problem**: Scheduled notifications not appearing or appearing late
**Root Cause**: Android 14 permission changes + Samsung battery optimization

---

## Immediate Actions (Can Implement Today)

### 1. Add Runtime Permission Check (5 minutes)

**File**: `lib/core/services/notification_service.dart`

**Add before line 208** (in `scheduleNotification()` method):

```dart
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

    // ✅ ADD THIS CHECK - Critical for Android 14+
    if (_isAndroid) {
      final canSchedule = await _canScheduleExactAlarms();
      if (!canSchedule) {
        if (kDebugMode) {
          print('❌ Cannot schedule exact alarm - permission denied');
        }
        // Show dialog to user asking them to grant permission
        return;
      }
    }

    // For web platform, use WebNotificationService
    if (kIsWeb) {
      // ... existing web code
    }

    // ... rest of existing code
  }
}

// ✅ ADD THIS NEW METHOD at end of class
Future<bool> _canScheduleExactAlarms() async {
  try {
    // Check if exact alarm permission is granted
    final alarmStatus = await Permission.scheduleExactAlarm.status;

    if (!alarmStatus.isGranted) {
      if (kDebugMode) {
        print('⚠️ Exact alarm permission not granted - requesting...');
      }
      return false;
    }

    return true;
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Error checking exact alarm permission: $e');
    }
    return false; // Fail safe
  }
}
```

### 2. Update Notification Channel ID (2 minutes)

**File**: `lib/core/services/notification_service.dart`

**Change line 114**:
```dart
// BEFORE:
'todo_notifications_v2',

// AFTER:
'todo_notifications_v3',
```

**Change line 251**:
```dart
// BEFORE:
'todo_notifications_v2',

// AFTER:
'todo_notifications_v3',
```

**Reason**: Android caches channel settings. Users who installed earlier versions won't get new `Importance.max` settings until channel ID changes.

### 3. Add Battery Optimization Prompt (10 minutes)

**File**: `lib/presentation/screens/todo_list_screen.dart`

**Add after first notification is scheduled** (around line 200, in `_handleTodoAction()` or after `scheduleNotification()` call):

```dart
// After scheduling notification
await notificationService.scheduleNotification(...);

// ✅ ADD THIS - Prompt for battery optimization
if (mounted && Platform.isAndroid) {
  _promptBatteryOptimization();
}

// ✅ ADD THIS METHOD
void _promptBatteryOptimization() async {
  // Check if already shown
  final prefs = await SharedPreferences.getInstance();
  final hasShown = prefs.getBool('battery_optimization_prompt_shown') ?? false;

  if (hasShown) return;

  // Check if battery optimization is disabled
  final status = await Permission.ignoreBatteryOptimizations.status;

  if (!status.isGranted && mounted) {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림 안내'),
        content: const Text(
          '삼성 기기에서 알림이 정확한 시간에 표시되려면 배터리 최적화 해제가 필요합니다.\n\n'
          '지금 설정하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('설정하기'),
          ),
        ],
      ),
    );

    if (result == true) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    // Mark as shown
    await prefs.setBool('battery_optimization_prompt_shown', true);
  }
}
```

**Add import**:
```dart
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
```

---

## User Guidance (Copy-Paste for Users)

### For Samsung Users Experiencing Missing Notifications

**Settings to Check**:

1. **배터리 최적화 해제**
   - 설정 → 배터리 → 백그라운드 사용 제한 → "DoDo" 앱을 "절전 모드 제외 앱"에 추가

2. **절전 모드 예외**
   - 설정 → 배터리 → "사용하지 않는 앱 절전" 끄기
   - "절전 모드 앱" 목록에서 "DoDo" 제거

3. **알림 권한 확인**
   - 설정 → 알림 → "DoDo" → "알림 허용" 활성화
   - "알람 및 알림 예약" 권한 활성화

4. **앱 설정에서 권한 확인**
   - 설정 → 앱 → DoDo → 권한 → "알람 및 알림" 권한 허용

### Testing After Changes

1. **Schedule test notification** for 2 minutes from now
2. **Lock device** (turn off screen)
3. **Wait 3 minutes**
4. **Check if notification appeared**

If notification still doesn't appear:
- Open battery settings and manually add app to "Never sleeping apps"
- Check if "Alarms & reminders" permission is granted in app info

---

## Quick Debug Commands

```bash
# Check if notification is scheduled
adb shell dumpsys alarm | grep kr.bluesky.dodo

# Check notification channels
adb shell dumpsys notification | grep -A 20 "kr.bluesky.dodo"

# Check battery optimization
adb shell dumpsys deviceidle whitelist | grep kr.bluesky.dodo

# Check permissions
adb shell dumpsys package kr.bluesky.dodo | grep permission

# View real-time logs
adb logcat | grep -E "(flutter|kr.bluesky.dodo|Notification)"
```

---

## Expected Results After Fixes

✅ **Android 14 devices**: Permission prompt appears when scheduling first notification
✅ **Samsung devices**: Battery optimization prompt appears after scheduling
✅ **Notifications**: Appear within 1-2 minutes of scheduled time (if permissions granted)
✅ **Doze mode**: Notifications may be delayed up to 15 minutes (Android limitation)

---

## Still Not Working?

### Last Resort Options

1. **Use AlarmClock mode** (shows alarm icon in status bar):
   - Change `androidScheduleMode: AndroidScheduleMode.alarmClock`
   - More reliable but less user-friendly

2. **Reduce notification frequency**:
   - Don't schedule more than 1 notification per 15 minutes
   - Samsung/Doze mode throttles frequent alarms

3. **Check alarm limit**:
   - Samsung has 500 alarm limit system-wide
   - Run: `adb shell dumpsys alarm | wc -l` to check total

4. **Report device model**:
   - Some One UI versions have known bugs
   - Check [dontkillmyapp.com/samsung](https://dontkillmyapp.com/samsung)

---

## Checklist Before Release

- [ ] Channel ID updated to v3
- [ ] Runtime permission check added
- [ ] Battery optimization prompt implemented
- [ ] Tested on physical Samsung device (S23/A31/A50/A53)
- [ ] Tested with Doze mode (screen off for 5+ minutes)
- [ ] Updated CLAUDE.md with new debug steps
- [ ] Created user FAQ for troubleshooting

---

**Last Updated**: 2025-11-12
**Status**: Ready for implementation
**Est. Time**: 20-30 minutes total
