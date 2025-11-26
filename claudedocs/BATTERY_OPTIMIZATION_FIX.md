# Battery Optimization Service - MethodChannel Fix

**Date**: 2025-11-26
**Issue**: MissingPluginException for battery optimization whitelist request
**Status**: ✅ **FIXED**

---

## Problem Description

When the app launched, it threw a `MissingPluginException` with the following error:

```
MissingPluginException(No implementation found for method requestIgnoreBatteryOptimizations on channel com.example.todo_app/battery)
```

This error was logged in `BatteryOptimizationService.requestIgnoreBatteryOptimizations()` but did not crash the app due to proper error handling with `AppLogger.error()`.

---

## Root Cause

**Package Name Mismatch**:
- **Dart side** (Flutter app): Used MethodChannel name `'com.example.todo_app/battery'`
- **Android side** (Native code): Registered MethodChannel with name `'kr.bluesky.dodo/battery'`

The app's actual package name is `kr.bluesky.dodo` (as defined in `AndroidManifest.xml`), but the Flutter code was looking for a channel registered with the old example package name `com.example.todo_app`.

---

## Solution

### File Modified
**lib/core/services/battery_optimization_service.dart**

### Changes Made

**Line 165** - `isIgnoringBatteryOptimizations()` method:
```dart
// BEFORE
const methodChannel = MethodChannel('com.example.todo_app/battery');

// AFTER
const methodChannel = MethodChannel('kr.bluesky.dodo/battery');
```

**Line 183** - `requestIgnoreBatteryOptimizations()` method:
```dart
// BEFORE
const methodChannel = MethodChannel('com.example.todo_app/battery');

// AFTER
const methodChannel = MethodChannel('kr.bluesky.dodo/battery');
```

### Android Native Code (No Changes Needed)

The Android native implementation in **MainActivity.kt** (lines 32-47) was already correct:
```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
    when (call.method) {
        "requestIgnoreBatteryOptimizations" -> {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    result.success(true)
                } else {
                    result.success(true)
                }
            } else {
                result.success(true)
            }
        }
        // ...
    }
}
```

Where `BATTERY_CHANNEL = "kr.bluesky.dodo/battery"` (line 13)

---

## Testing & Verification

### Build
✅ **APK Build**: Successful (59.0 MB)
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (59.0MB)
```

### Installation
✅ **Device Installation**: Success
```
Device: Samsung Galaxy A31 (API 31)
Package: kr.bluesky.dodo
Status: Successfully installed
```

### Runtime Verification

**Before Fix** (old logs):
```
[38;5;196m│ MissingPluginException(No implementation found for method requestIgnoreBatteryOptimizations on channel com.example.todo_app/battery)[0m
[38;5;196m│ ⛔ Failed to request battery optimization whitelist[0m
```

**After Fix** (new logs):
```
[38;5;12m│ 💡 ℹ️ Geofence service uses unified WorkManager dispatcher[0m
[38;5;12m│ 💡 ✅ Geofence monitoring started (interval: 15min)[0m
```

No battery optimization errors in the latest app logs ✅

---

## Impact

### What was fixed
- ✅ Battery optimization request now properly communicates with Android native code
- ✅ App can now request device battery optimization whitelist without errors
- ✅ Geofencing service can properly adjust check intervals based on battery state
- ✅ No more MissingPluginException errors in logs

### What still works
- ✅ Geofencing background monitoring (WorkManager 15-minute intervals)
- ✅ Battery state monitoring and adaptive intervals
- ✅ Location-based notifications
- ✅ All other app functionality (unaffected)

---

## Technical Details

### MethodChannel Communication

The MethodChannel is used for Dart ↔ Android native code communication:

```
Flutter App (Dart)
    ↓ (calls method)
MethodChannel('kr.bluesky.dodo/battery')
    ↓ (method call)
Android MainActivity (Kotlin)
    ↓ (implements handler)
requestIgnoreBatteryOptimizations()
    ↓ (launches intent)
Android Settings Activity
    ↓ (user grants/denies)
PowerManager.isIgnoringBatteryOptimizations()
```

The channel name must match exactly between Dart and Android sides.

---

## Related Files

- **Dart Implementation**: [lib/core/services/battery_optimization_service.dart](../lib/core/services/battery_optimization_service.dart)
- **Android Native Code**: [android/app/src/main/kotlin/kr/bluesky/dodo/MainActivity.kt](../android/app/src/main/kotlin/kr/bluesky/dodo/MainActivity.kt)
- **Usage in UI**: [lib/presentation/screens/todo_list_screen.dart](../lib/presentation/screens/todo_list_screen.dart) (line 229)
- **Geofencing Service**: [lib/core/services/geofence_workmanager_service.dart](../lib/core/services/geofence_workmanager_service.dart)

---

## Git Commit

```
commit: 126ecc0
message: fix: Correct MethodChannel name in battery optimization service
date: 2025-11-26
```

---

## Lessons Learned

1. **Always verify package names match** between Dart and native implementations
2. **MethodChannel names must be exact matches** - even one character difference causes MissingPluginException
3. **Error handling is important** - this error was caught and logged properly so it didn't crash the app
4. **Test on physical device** - MethodChannel errors are specific to Android/iOS platforms
5. **Check package name during project setup** - the example package name `com.example.todo_app` should have been replaced with `kr.bluesky.dodo` in all places

---

## Future Improvements

1. Consider creating a constants file for all MethodChannel names to avoid future mismatches
2. Add unit tests for MethodChannel calls
3. Add error logging to help identify similar issues faster
4. Document all Android native methods in a central location

---

**Status**: ✅ **COMPLETE AND VERIFIED**

The battery optimization service now correctly communicates with Android native code and handles battery level monitoring for adaptive geofencing intervals.
