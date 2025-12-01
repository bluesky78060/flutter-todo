package kr.bluesky.dodo.widgets

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.widget.Toast
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * BroadcastReceiver for handling widget button actions
 * Processes TOGGLE_TODO and DELETE_TODO actions from widget items
 * Works in background without opening the app by directly modifying SQLite database
 */
class WidgetActionReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WidgetActionReceiver"
        private const val METHOD_CHANNEL_NAME = "kr.bluesky.dodo/widget"
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val DATABASE_NAME = "app_database.sqlite"

        private var flutterEngine: FlutterEngine? = null

        fun setFlutterEngine(engine: FlutterEngine) {
            flutterEngine = engine
        }
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
            // DELETE_TODO action removed - delete only from app
        }
    }

    /**
     * Toggle todo completion - Primary: MethodChannel to Flutter (Supabase sync)
     * Fallback: Local SQLite database (for when app is closed)
     *
     * This app uses Supabase as primary storage, so MethodChannel approach is preferred.
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

            // Update SharedPreferences immediately for instant UI feedback
            prefs.edit().putBoolean("todo_${todoIndex}_completed", newState).apply()
            android.util.Log.d(TAG, "SharedPreferences updated: todo_${todoIndex}_completed = $newState")

            // PRIMARY: Try to notify Flutter via MethodChannel (for Supabase sync)
            if (flutterEngine != null) {
                try {
                    val channel = MethodChannel(
                        flutterEngine!!.dartExecutor.binaryMessenger,
                        METHOD_CHANNEL_NAME
                    )
                    channel.invokeMethod("toggleTodo", mapOf("todo_id" to todoId))
                    android.util.Log.d(TAG, "Notified Flutter for todo: $todoId")

                    // Flutter will handle everything including widget refresh
                    val message = if (newState) "✓ 완료!" else "↩ 미완료"
                    Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
                    return // Let Flutter handle everything
                } catch (e: Exception) {
                    android.util.Log.w(TAG, "Could not notify Flutter (app may be closed): ${e.message}")
                }
            }

            // FALLBACK: Flutter not available - update locally and refresh widget
            android.util.Log.d(TAG, "Flutter not available, updating locally")

            // Try to update local SQLite (may fail if no local data)
            val dbUpdated = toggleTodoInDatabase(context, todoIdInt)
            android.util.Log.d(TAG, "Database update result: $dbUpdated")

            // Refresh widget to show updated state
            refreshAllWidgets(context)

            // Show feedback
            val message = if (newState) "✓ 완료!" else "↩ 미완료"
            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()

            if (dbUpdated == null) {
                android.util.Log.w(TAG, "Todo toggled only in widget UI. Sync will happen when app opens.")
            }

            android.util.Log.d(TAG, "Todo toggle completed (local mode)")

        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error toggling todo", e)
            Toast.makeText(context, "오류가 발생했습니다", Toast.LENGTH_SHORT).show()
        }
    }

    /**
     * Toggle todo completion in SQLite database
     * Returns the new isCompleted state, or null if failed
     */
    private fun toggleTodoInDatabase(context: Context, todoId: Int): Boolean? {
        var db: SQLiteDatabase? = null
        try {
            // Get database path (Flutter uses getApplicationDocumentsDirectory which maps to app_flutter folder)
            // On Android, this is dataDir/app_flutter/, not filesDir
            val dbPath = File(context.dataDir, "app_flutter/$DATABASE_NAME")
            android.util.Log.d(TAG, "Database path: ${dbPath.absolutePath}")

            if (!dbPath.exists()) {
                android.util.Log.e(TAG, "Database file does not exist")
                return null
            }

            // Open database in read-write mode with WAL support
            // Drift uses WAL mode by default, so we need to enable it when opening
            db = SQLiteDatabase.openDatabase(
                dbPath.absolutePath,
                null,
                SQLiteDatabase.OPEN_READWRITE or SQLiteDatabase.ENABLE_WRITE_AHEAD_LOGGING
            )

            // Enable WAL mode to read uncommitted data from WAL file
            db.enableWriteAheadLogging()

            // Force WAL checkpoint to ensure all data is visible
            // This merges WAL file content into the main database
            try {
                val checkpointCursor = db.rawQuery("PRAGMA wal_checkpoint(PASSIVE)", null)
                if (checkpointCursor.moveToFirst()) {
                    val busy = checkpointCursor.getInt(0)
                    val log = checkpointCursor.getInt(1)
                    val checkpointed = checkpointCursor.getInt(2)
                    android.util.Log.d(TAG, "WAL checkpoint: busy=$busy, log=$log, checkpointed=$checkpointed")
                }
                checkpointCursor.close()
            } catch (e: Exception) {
                android.util.Log.w(TAG, "WAL checkpoint failed: ${e.message}")
            }

            // First, check how many todos exist
            val countCursor = db.rawQuery("SELECT COUNT(*) FROM todos", null)
            if (countCursor.moveToFirst()) {
                val totalTodos = countCursor.getInt(0)
                android.util.Log.d(TAG, "Total todos in database: $totalTodos")
            }
            countCursor.close()

            // Get current state
            val cursor = db.rawQuery(
                "SELECT is_completed FROM todos WHERE id = ?",
                arrayOf(todoId.toString())
            )

            if (!cursor.moveToFirst()) {
                cursor.close()
                android.util.Log.e(TAG, "Todo not found: $todoId (check if WAL is preventing read)")
                // List some existing todo IDs for debugging
                val listCursor = db.rawQuery("SELECT id, title FROM todos LIMIT 5", null)
                while (listCursor.moveToNext()) {
                    android.util.Log.d(TAG, "Existing todo: id=${listCursor.getInt(0)}, title=${listCursor.getString(1)}")
                }
                listCursor.close()
                return null
            }

            val currentState = cursor.getInt(0) == 1
            cursor.close()

            val newState = !currentState
            val newStateInt = if (newState) 1 else 0

            // Update completion state
            val completedAt = if (newState) {
                System.currentTimeMillis()
            } else {
                null
            }

            val result = if (completedAt != null) {
                db.execSQL(
                    "UPDATE todos SET is_completed = ?, completed_at = ? WHERE id = ?",
                    arrayOf(newStateInt, completedAt, todoId)
                )
                true
            } else {
                db.execSQL(
                    "UPDATE todos SET is_completed = ?, completed_at = NULL WHERE id = ?",
                    arrayOf(newStateInt, todoId)
                )
                true
            }

            android.util.Log.d(TAG, "Updated todo $todoId: isCompleted=$newState")
            return newState

        } catch (e: Exception) {
            android.util.Log.e(TAG, "Database error: ${e.message}", e)
            return null
        } finally {
            db?.close()
        }
    }

    /**
     * Refresh all TodoListWidget instances
     */
    private fun refreshAllWidgets(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TodoListWidget::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(componentName)

            android.util.Log.d(TAG, "Refreshing ${widgetIds.size} widgets")

            // Send update broadcast to refresh widgets
            val updateIntent = Intent(context, TodoListWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
            }
            context.sendBroadcast(updateIntent)

            android.util.Log.d(TAG, "Widget refresh broadcast sent")
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error refreshing widgets", e)
        }
    }
}
