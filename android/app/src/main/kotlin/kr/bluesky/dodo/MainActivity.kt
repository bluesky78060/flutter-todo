package kr.bluesky.dodo

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val BATTERY_CHANNEL = "kr.bluesky.dodo/battery"
    private val DEVICE_INFO_CHANNEL = "kr.bluesky.dodo/device_info"
    private val SYSTEM_PROPS_CHANNEL = "kr.bluesky.dodo/system_properties"
    private val SAMSUNG_INFO_CHANNEL = "kr.bluesky.dodo/samsung_info"
    private val WIDGET_CHANNEL = "kr.bluesky.dodo/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Store FlutterEngine for WidgetActionReceiver to use
        kr.bluesky.dodo.widgets.WidgetActionReceiver.setFlutterEngine(flutterEngine)

        // Widget action channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "toggleTodo" -> {
                    val todoId = call.argument<String>("todo_id")
                    if (todoId != null) {
                        // Call your Flutter widget toggle handler
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "todo_id is required", null)
                    }
                }
                "deleteTodo" -> {
                    val todoId = call.argument<String>("todo_id")
                    if (todoId != null) {
                        // Call your Flutter widget delete handler
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "todo_id is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Battery optimization channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
                }
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
                else -> result.notImplemented()
            }
        }

        // Device info channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_INFO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getManufacturer" -> {
                    result.success(Build.MANUFACTURER)
                }
                "getModel" -> {
                    result.success(Build.MODEL)
                }
                "getDevice" -> {
                    result.success(Build.DEVICE)
                }
                else -> result.notImplemented()
            }
        }

        // System properties channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SYSTEM_PROPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrand" -> {
                    result.success(Build.BRAND)
                }
                "getProduct" -> {
                    result.success(Build.PRODUCT)
                }
                else -> result.notImplemented()
            }
        }

        // Samsung-specific info channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SAMSUNG_INFO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getOneUIVersion" -> {
                    // Samsung One UI version detection
                    try {
                        val oneUIVersion = getOneUIVersion()
                        result.success(oneUIVersion ?: "Unknown")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to get One UI version", e.message)
                    }
                }
                "isInSleepingApps" -> {
                    // This would require Samsung-specific API access
                    // For now, return false as we can't directly check this
                    result.success(false)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getOneUIVersion(): String? {
        return try {
            // Try to get One UI version from system properties
            val clazz = Class.forName("android.os.SystemProperties")
            val method = clazz.getMethod("get", String::class.java)

            // Samsung stores One UI version in these properties
            val oneUIVersion = method.invoke(null, "ro.build.version.oneui") as? String
            if (!oneUIVersion.isNullOrEmpty()) {
                // Convert version code to readable format
                // e.g., 50001 -> 5.0, 60000 -> 6.0
                val versionInt = oneUIVersion.toIntOrNull() ?: return oneUIVersion
                val major = versionInt / 10000
                val minor = (versionInt % 10000) / 100
                return if (minor == 0) "$major.0" else "$major.$minor"
            }

            // Alternative property
            val sepVersion = method.invoke(null, "ro.build.version.sep") as? String
            sepVersion
        } catch (e: Exception) {
            null
        }
    }
}
