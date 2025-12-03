package kr.bluesky.dodo.widgets

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.Toast
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

/**
 * BroadcastReceiver for handling widget button actions
 * Processes TOGGLE_TODO action from widget items
 * Syncs with Supabase in background without opening the app
 */
class WidgetActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WidgetActionReceiver"
        private const val PREFS_NAME = "HomeWidgetPreferences"

        // Supabase configuration - loaded from SharedPreferences (set by Flutter)
        private const val SUPABASE_PREFS = "FlutterSharedPreferences"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        android.util.Log.d(TAG, "Action received: $action")

        when (action) {
            "kr.bluesky.dodo.widget.TOGGLE_TODO" -> {
                val todoId = intent.getStringExtra("todo_id") ?: ""
                val todoIndex = intent.getIntExtra("todo_index", -1)
                val widgetId = intent.getIntExtra("widget_id", -1)
                android.util.Log.d(TAG, "Toggle todo - id: $todoId, index: $todoIndex, widgetId: $widgetId")
                toggleTodoInBackground(context, todoId, todoIndex, widgetId)
            }
        }
    }

    /**
     * Toggle todo completion in background
     * 1. Update SharedPreferences for immediate UI feedback
     * 2. Sync with Supabase API in background
     */
    private fun toggleTodoInBackground(context: Context, todoId: String, todoIndex: Int, widgetId: Int) {
        try {
            if (todoId.isEmpty()) {
                android.util.Log.w(TAG, "Empty todoId, cannot toggle")
                Toast.makeText(context, "Error: Missing todo ID", Toast.LENGTH_SHORT).show()
                return
            }

            val todoIdInt = todoId.toIntOrNull()
            if (todoIdInt == null) {
                android.util.Log.e(TAG, "Invalid todoId: $todoId")
                Toast.makeText(context, "Error: Invalid todo ID", Toast.LENGTH_SHORT).show()
                return
            }

            android.util.Log.d(TAG, "Toggling todo: id=$todoId, index=$todoIndex")

            // Get current state from SharedPreferences for UI feedback
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val currentState = prefs.getBoolean("todo_${todoIndex}_completed", false)
            val newState = !currentState

            // If completing (newState = true), remove the item from widget list
            if (newState) {
                removeCompletedItemFromWidget(prefs, todoIndex)
                android.util.Log.d(TAG, "Removed completed item at index $todoIndex from widget")
                // Mark that widget needs full refresh from Flutter to load next items
                prefs.edit().putBoolean("pending_widget_refresh", true).apply()
                android.util.Log.d(TAG, "Marked pending_widget_refresh for Flutter to load next items")
            } else {
                prefs.edit().putBoolean("todo_${todoIndex}_completed", newState).apply()
                android.util.Log.d(TAG, "SharedPreferences updated: todo_${todoIndex}_completed = $newState")
            }

            // Refresh widget immediately for visual feedback
            refreshAllWidgets(context)

            // Show feedback
            val message = if (newState) "✓ 완료!" else "↩ 미완료"
            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()

            // Sync with Supabase in background (don't open app)
            syncWithSupabase(context, todoId, newState)

        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error toggling todo", e)
            Toast.makeText(context, "오류가 발생했습니다", Toast.LENGTH_SHORT).show()
        }
    }

    /**
     * Sync todo completion status with Supabase API in background
     */
    private fun syncWithSupabase(context: Context, todoId: String, isCompleted: Boolean) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Get Supabase credentials from Flutter SharedPreferences
                val flutterPrefs = context.getSharedPreferences(SUPABASE_PREFS, Context.MODE_PRIVATE)
                val supabaseUrl = flutterPrefs.getString("flutter.supabase_url", null)
                    ?: "https://bulwfcsyqgsvmbadhlye.supabase.co"
                val supabaseKey = flutterPrefs.getString("flutter.supabase_anon_key", null)
                    ?: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1bHdmY3N5cWdzdm1iYWRobHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxMzM1MjMsImV4cCI6MjA3NzcwOTUyM30._5Ft7sTK6m946oDSRHgjFgDBRc7YH-nD9KC8gLkHeo0"

                // Get access token for authenticated request
                val accessToken = flutterPrefs.getString("flutter.supabase_access_token", null)

                if (accessToken == null) {
                    android.util.Log.w(TAG, "No access token found, will sync on next app launch")
                    // Mark for sync when app opens
                    markForSync(context, todoId, isCompleted)
                    return@launch
                }

                android.util.Log.d(TAG, "Syncing todo $todoId with Supabase (completed=$isCompleted)")

                // Build the API URL
                val apiUrl = "$supabaseUrl/rest/v1/todos?id=eq.$todoId"

                // Prepare the request body
                val completedAt = if (isCompleted) {
                    "\"${java.time.Instant.now()}\""
                } else {
                    "null"
                }
                val requestBody = """{"is_completed": $isCompleted, "completed_at": $completedAt}"""

                // Make PATCH request to Supabase
                val url = URL(apiUrl)
                val connection = url.openConnection() as HttpURLConnection
                connection.apply {
                    requestMethod = "PATCH"
                    setRequestProperty("Content-Type", "application/json")
                    setRequestProperty("apikey", supabaseKey)
                    setRequestProperty("Authorization", "Bearer $accessToken")
                    setRequestProperty("Prefer", "return=minimal")
                    doOutput = true
                    connectTimeout = 10000
                    readTimeout = 10000
                }

                OutputStreamWriter(connection.outputStream).use { writer ->
                    writer.write(requestBody)
                    writer.flush()
                }

                val responseCode = connection.responseCode
                android.util.Log.d(TAG, "Supabase response code: $responseCode")

                if (responseCode in 200..299) {
                    android.util.Log.d(TAG, "Successfully synced todo $todoId with Supabase")
                    // Clear any pending sync marker
                    clearPendingSync(context, todoId)
                } else {
                    android.util.Log.e(TAG, "Failed to sync with Supabase: $responseCode")
                    // Mark for sync when app opens
                    markForSync(context, todoId, isCompleted)
                }

                connection.disconnect()

            } catch (e: Exception) {
                android.util.Log.e(TAG, "Error syncing with Supabase", e)
                // Mark for sync when app opens
                markForSync(context, todoId, isCompleted)
            }
        }
    }

    /**
     * Mark todo for sync when app opens next time
     * Stores as comma-separated string for Flutter HomeWidget compatibility
     */
    private fun markForSync(context: Context, todoId: String, isCompleted: Boolean) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existingSyncs = prefs.getString("pending_syncs", "") ?: ""
        val syncEntry = "$todoId:$isCompleted"

        // Avoid duplicates
        val syncList = if (existingSyncs.isNotEmpty()) {
            existingSyncs.split(",").toMutableList()
        } else {
            mutableListOf()
        }

        // Remove existing entry for this todo if exists
        syncList.removeIf { it.startsWith("$todoId:") }
        syncList.add(syncEntry)

        val newSyncs = syncList.joinToString(",")
        prefs.edit().putString("pending_syncs", newSyncs).apply()
        android.util.Log.d(TAG, "Marked todo $todoId for sync on next app launch. Pending: $newSyncs")
    }

    /**
     * Clear pending sync marker for a todo
     */
    private fun clearPendingSync(context: Context, todoId: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val existingSyncs = prefs.getString("pending_syncs", "") ?: ""

        if (existingSyncs.isEmpty()) return

        val syncList = existingSyncs.split(",").toMutableList()
        syncList.removeIf { it.startsWith("$todoId:") }

        val newSyncs = syncList.joinToString(",")
        prefs.edit().putString("pending_syncs", newSyncs).apply()
        android.util.Log.d(TAG, "Cleared pending sync for todo $todoId. Remaining: $newSyncs")
    }

    /**
     * Remove completed item from widget SharedPreferences and shift remaining items up
     * Flutter saves 10 items (index 1-10), widget displays 2 (index 1-2)
     * This allows up to 8 consecutive completions without reopening the app
     */
    private fun removeCompletedItemFromWidget(prefs: android.content.SharedPreferences, completedIndex: Int) {
        val editor = prefs.edit()

        android.util.Log.e(TAG, "DEBUG: removeCompletedItemFromWidget: completedIndex=$completedIndex")

        // Shift items up (Flutter saves 10 items for extended shift capability)
        // Widget uses 1-based index, shift from completedIndex to 9
        // This pulls items 2->1, 3->2, ..., 10->9 (depending on completedIndex)
        for (i in completedIndex..9) {
            val nextIndex = i + 1
            android.util.Log.e(TAG, "DEBUG: Shifting: todo_$nextIndex -> todo_$i")
            val nextText = prefs.getString("todo_${nextIndex}_text", null)
            val nextDesc = prefs.getString("todo_${nextIndex}_description", "")
            val nextTime = prefs.getString("todo_${nextIndex}_time", "")
            val nextId = prefs.getString("todo_${nextIndex}_id", "")
            val nextCompleted = prefs.getBoolean("todo_${nextIndex}_completed", false)
            val nextGroup = prefs.getString("todo_${nextIndex}_group", "")

            android.util.Log.e(TAG, "DEBUG: nextText=$nextText, nextGroup=$nextGroup")
            if (nextText != null) {
                editor.putString("todo_${i}_text", nextText)
                editor.putString("todo_${i}_description", nextDesc)
                editor.putString("todo_${i}_time", nextTime)
                editor.putString("todo_${i}_id", nextId)
                editor.putBoolean("todo_${i}_completed", nextCompleted)
                editor.putString("todo_${i}_group", nextGroup)
                android.util.Log.e(TAG, "DEBUG: Shifted: $nextText to position $i")
            } else {
                editor.remove("todo_${i}_text")
                editor.putString("todo_${i}_description", "")
                editor.putString("todo_${i}_time", "")
                editor.putString("todo_${i}_id", "")
                editor.putBoolean("todo_${i}_completed", false)
                editor.putString("todo_${i}_group", "")
                android.util.Log.e(TAG, "DEBUG: Cleared position $i (no next item)")
            }
        }

        // Clear the last position (10th item in SharedPreferences)
        editor.remove("todo_10_text")
        editor.putString("todo_10_description", "")
        editor.putString("todo_10_time", "")
        editor.putString("todo_10_id", "")
        editor.putBoolean("todo_10_completed", false)
        editor.putString("todo_10_group", "")

        // Update completed count
        val completedCount = prefs.getInt("todo_completed_count", 0)
        editor.putInt("todo_completed_count", completedCount + 1)

        editor.apply()
    }

    /**
     * Refresh all TodoListWidget and TodoDetailWidget instances
     */
    private fun refreshAllWidgets(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            // Refresh TodoListWidget
            val listComponentName = ComponentName(context, TodoListWidget::class.java)
            val listWidgetIds = appWidgetManager.getAppWidgetIds(listComponentName)
            android.util.Log.d(TAG, "Refreshing ${listWidgetIds.size} TodoListWidgets")

            val listUpdateIntent = Intent(context, TodoListWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, listWidgetIds)
            }
            context.sendBroadcast(listUpdateIntent)

            // Refresh TodoDetailWidget
            val detailComponentName = ComponentName(context, TodoDetailWidget::class.java)
            val detailWidgetIds = appWidgetManager.getAppWidgetIds(detailComponentName)
            android.util.Log.d(TAG, "Refreshing ${detailWidgetIds.size} TodoDetailWidgets")

            val detailUpdateIntent = Intent(context, TodoDetailWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, detailWidgetIds)
            }
            context.sendBroadcast(detailUpdateIntent)

            android.util.Log.d(TAG, "Widget refresh broadcast sent for both widgets")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error refreshing widgets", e)
        }
    }
}
