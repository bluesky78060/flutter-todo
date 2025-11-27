package kr.bluesky.dodo.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * BroadcastReceiver for handling widget button actions
 * Processes TOGGLE_TODO and DELETE_TODO actions from widget items
 * Routes actions to Flutter via MethodChannel
 */
class WidgetActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WidgetActionReceiver"
        private const val METHOD_CHANNEL_NAME = "kr.bluesky.dodo/widget"
        private const val METHOD_TOGGLE_TODO = "toggleTodo"
        private const val METHOD_DELETE_TODO = "deleteTodo"

        private var flutterEngine: FlutterEngine? = null

        fun setFlutterEngine(engine: FlutterEngine) {
            flutterEngine = engine
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val todoId = intent.getStringExtra("todo_id") ?: return
        val widgetId = intent.getIntExtra("widget_id", -1)

        android.util.Log.d(TAG, "Action received: $action, TodoId: $todoId, WidgetId: $widgetId")

        when (action) {
            "kr.bluesky.dodo.widget.TOGGLE_TODO" -> {
                toggleTodo(context, todoId, widgetId)
            }
            "kr.bluesky.dodo.widget.DELETE_TODO" -> {
                deleteTodo(context, todoId, widgetId)
            }
        }
    }

    private fun toggleTodo(context: Context, todoId: String, widgetId: Int) {
        android.util.Log.d(TAG, "Toggling todo: $todoId")

        // Route to Flutter via MethodChannel
        callFlutterMethod(METHOD_TOGGLE_TODO, mapOf("todo_id" to todoId)) { success ->
            if (success) {
                // Update widget display
                refreshWidget(context, widgetId)
                showToast(context, "✓ Todo toggled")
            } else {
                showToast(context, "Failed to toggle todo")
            }
        }
    }

    private fun deleteTodo(context: Context, todoId: String, widgetId: Int) {
        android.util.Log.d(TAG, "Deleting todo: $todoId")

        // Route to Flutter via MethodChannel
        callFlutterMethod(METHOD_DELETE_TODO, mapOf("todo_id" to todoId)) { success ->
            if (success) {
                // Update widget display
                refreshWidget(context, widgetId)
                showToast(context, "✓ Todo deleted")
            } else {
                showToast(context, "Failed to delete todo")
            }
        }
    }

    private fun callFlutterMethod(
        method: String,
        arguments: Map<String, Any>,
        callback: (Boolean) -> Unit
    ) {
        // If Flutter engine is not initialized yet, start the app
        if (flutterEngine == null) {
            android.util.Log.w(TAG, "Flutter engine not initialized, will be set when app starts")
            // For now, we'll handle this via intent routing to MainActivity
            // The MainActivity will set the FlutterEngine when it's ready
            callback(false)
            return
        }

        try {
            val channel = MethodChannel(
                flutterEngine!!.dartExecutor.binaryMessenger,
                METHOD_CHANNEL_NAME
            )

            channel.invokeMethod(method, arguments, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    if (result is Boolean) {
                        callback(result)
                    } else {
                        callback(true)
                    }
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    android.util.Log.e(TAG, "Flutter method error: $errorCode - $errorMessage")
                    callback(false)
                }

                override fun notImplemented() {
                    android.util.Log.w(TAG, "Flutter method not implemented: $method")
                    callback(false)
                }
            })
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error calling Flutter method: $method", e)
            callback(false)
        }
    }

    private fun refreshWidget(context: Context, widgetId: Int) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            appWidgetManager.notifyAppWidgetViewDataChanged(intArrayOf(widgetId), android.R.id.list)
            android.util.Log.d(TAG, "Widget refreshed: $widgetId")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error refreshing widget", e)
        }
    }

    private fun showToast(context: Context, message: String) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
}
