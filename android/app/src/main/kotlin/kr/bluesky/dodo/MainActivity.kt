package kr.bluesky.dodo

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kr.bluesky.dodo.widgets.TodoListWidget
import kr.bluesky.dodo.widgets.TodoCalendarWidget

class MainActivity: FlutterActivity() {
    private val BATTERY_CHANNEL = "kr.bluesky.dodo/battery"
    private val DEVICE_INFO_CHANNEL = "kr.bluesky.dodo/device_info"
    private val SYSTEM_PROPS_CHANNEL = "kr.bluesky.dodo/system_properties"
    private val SAMSUNG_INFO_CHANNEL = "kr.bluesky.dodo/samsung_info"
    private val WIDGET_CHANNEL = "kr.bluesky.dodo/widget"

    companion object {
        private const val TAG = "MainActivity"
        // Store pending widget action to process after Flutter is ready
        private var pendingWidgetAction: String? = null
        private var pendingTodoId: String? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle deep link if app was launched from widget
        handleDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle deep link when app is already running
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent?) {
        val uri = intent?.data ?: return
        Log.d(TAG, "Received deep link: $uri")

        when (uri.host) {
            "toggle-todo" -> {
                val todoId = uri.getQueryParameter("id")
                Log.d(TAG, "Toggle todo action for id: $todoId")
                if (todoId != null) {
                    pendingWidgetAction = "toggle"
                    pendingTodoId = todoId
                    // Send to Flutter if engine is ready
                    flutterEngine?.let { sendWidgetActionToFlutter(it) }
                }
            }
            "add-todo" -> {
                Log.d(TAG, "Add todo action")
                pendingWidgetAction = "add"
                pendingTodoId = null
                // Send to Flutter if engine is ready
                flutterEngine?.let { sendWidgetActionToFlutter(it) }
            }
        }
    }

    private fun sendWidgetActionToFlutter(engine: FlutterEngine) {
        val action = pendingWidgetAction ?: return
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)

        when (action) {
            "toggle" -> {
                val todoId = pendingTodoId ?: return
                Log.d(TAG, "Sending toggleTodo to Flutter for id: $todoId")
                channel.invokeMethod("toggleTodo", mapOf("todo_id" to todoId))
            }
            "add" -> {
                Log.d(TAG, "Sending addTodo to Flutter")
                channel.invokeMethod("addTodo", null)
            }
        }

        // Clear pending action after sending
        pendingWidgetAction = null
        pendingTodoId = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Send any pending widget action now that Flutter is ready
        if (pendingWidgetAction != null) {
            // Delay slightly to ensure Flutter is fully initialized
            android.os.Handler(mainLooper).postDelayed({
                sendWidgetActionToFlutter(flutterEngine)
            }, 500)
        }

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
                "forceUpdateWidgets" -> {
                    // Force immediate update of all widgets
                    Log.d(TAG, "forceUpdateWidgets called from Flutter")
                    try {
                        forceUpdateAllWidgets()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error forcing widget update", e)
                        result.error("UPDATE_FAILED", e.message, null)
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

    /**
     * Force immediate update of all home screen widgets
     * Uses direct widget update instead of broadcast for faster sync
     */
    private fun forceUpdateAllWidgets() {
        val startTime = System.currentTimeMillis()
        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)

        // Get SharedPreferences with latest data from Flutter
        val widgetData = applicationContext.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        // Debug: Log calendar data keys to verify data is present
        val calendarKeys = widgetData.all.keys.filter { it.startsWith("calendar_day_") }
        val upcomingKeys = widgetData.all.keys.filter { it.startsWith("upcoming_event_") }
        Log.d(TAG, "forceUpdateAllWidgets: Found ${calendarKeys.size} calendar day keys, ${upcomingKeys.size} upcoming event keys")

        // Log calendar days with tasks (those containing ●)
        for (i in 1..42) {
            val dayData = widgetData.getString("calendar_day_$i", null)
            if (dayData != null && dayData.contains("●")) {
                Log.d(TAG, "  calendar_day_$i = $dayData (HAS TASK)")
            }
        }
        // Also log today's date position (Nov 30 = grid position 35 for 2024)
        val today = java.util.Calendar.getInstance()
        val firstOfMonth = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.DAY_OF_MONTH, 1)
        }
        val firstWeekday = (firstOfMonth.get(java.util.Calendar.DAY_OF_WEEK) - 1) // 0=Sun
        val todayGridPos = firstWeekday + today.get(java.util.Calendar.DAY_OF_MONTH)
        val todayData = widgetData.getString("calendar_day_$todayGridPos", null)
        Log.d(TAG, "  TODAY (day ${today.get(java.util.Calendar.DAY_OF_MONTH)}) grid pos $todayGridPos = '$todayData'")

        // Update TodoListWidget directly
        val todoListWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(applicationContext, TodoListWidget::class.java)
        )
        if (todoListWidgetIds.isNotEmpty()) {
            Log.d(TAG, "Updating ${todoListWidgetIds.size} TodoListWidget(s)")
            val todoListWidget = TodoListWidget()
            todoListWidget.onUpdate(applicationContext, appWidgetManager, todoListWidgetIds, widgetData)
        }

        // Update TodoCalendarWidget directly
        val calendarWidgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(applicationContext, TodoCalendarWidget::class.java)
        )
        if (calendarWidgetIds.isNotEmpty()) {
            Log.d(TAG, "Updating ${calendarWidgetIds.size} TodoCalendarWidget(s)")
            val calendarWidget = TodoCalendarWidget()
            calendarWidget.onUpdate(applicationContext, appWidgetManager, calendarWidgetIds, widgetData)
        }

        val elapsed = System.currentTimeMillis() - startTime
        Log.d(TAG, "forceUpdateAllWidgets completed in ${elapsed}ms")
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
