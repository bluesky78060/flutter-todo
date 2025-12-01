package kr.bluesky.dodo.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import kr.bluesky.dodo.MainActivity
import kr.bluesky.dodo.R

/**
 * RemoteViewsFactory for todo list widget
 * Creates individual RemoteViews for each todo item
 * Handles dynamic data loading and theme application
 */
class TodoListRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val widgetId = intent.getIntExtra("appWidgetId", -1)
    private var todoItems = mutableListOf<TodoItemData>()

    data class TodoItemData(
        val id: String,
        val title: String,
        val time: String?,
        val isCompleted: Boolean,
        val dateGroup: String // "Today", "Tomorrow", "This Week", "Next Week"
    )

    override fun onCreate() {
        // Initialize when factory is created
        loadTodoData()
    }

    override fun onDataSetChanged() {
        // Reload data whenever widget updates
        loadTodoData()
    }

    override fun getCount(): Int {
        return todoItems.size
    }

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= todoItems.size) {
            return null
        }

        val item = todoItems[position]
        val theme = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getString("widget_theme", "light") ?: "light"

        return RemoteViews(context.packageName, R.layout.widget_todo_item).apply {
            // Set title
            setTextViewText(R.id.widget_item_title, item.title)

            // Set time if available
            if (!item.time.isNullOrEmpty()) {
                setTextViewText(R.id.widget_item_time, item.time)
            } else {
                setViewVisibility(R.id.widget_item_time, android.view.View.GONE)
            }

            // Set completion state
            if (item.isCompleted) {
                setInt(R.id.widget_item_checkbox, "setBackgroundColor",
                    Color.parseColor("#4CAF50"))
                setTextViewText(R.id.widget_item_checkbox, "✓")
            } else {
                setInt(R.id.widget_item_checkbox, "setBackgroundColor",
                    Color.parseColor("#BDBDBD"))
                setTextViewText(R.id.widget_item_checkbox, "")
            }

            // Set strikethrough if completed
            if (item.isCompleted) {
                setTextViewText(R.id.widget_item_title, item.title + " ")
                // Apply paint flags for strikethrough (if supported)
            }

            // Set click intent for completion toggle
            val toggleIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = "kr.bluesky.dodo.widget.TOGGLE_TODO"
                putExtra("todo_id", item.id)
                putExtra("widget_id", widgetId)
            }
            val togglePendingIntent = PendingIntent.getBroadcast(
                context,
                item.id.hashCode(),
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            setOnClickPendingIntent(R.id.widget_item_checkbox, togglePendingIntent)

            // Set click intent for delete
            val deleteIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = "kr.bluesky.dodo.widget.DELETE_TODO"
                putExtra("todo_id", item.id)
                putExtra("widget_id", widgetId)
            }
            val deletePendingIntent = PendingIntent.getBroadcast(
                context,
                (item.id.hashCode() * 31),
                deleteIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            setOnClickPendingIntent(R.id.widget_item_delete, deletePendingIntent)

            // Apply theme colors
            applyTheme(this, theme)
        }
    }

    override fun getLoadingView(): RemoteViews? {
        return null
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }

    override fun onDestroy() {
        todoItems.clear()
    }

    private fun loadTodoData() {
        todoItems.clear()

        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            // Load todo data from SharedPreferences
            // Data format: "todo_{index}_text", "todo_{index}_time"
            // (matches what WidgetService._updateTodoListWidget() saves)
            for (index in 1..5) {
                val title = prefs.getString("todo_${index}_text", null) ?: continue
                val time = prefs.getString("todo_${index}_time", "") ?: ""

                // Generate ID from index (since Flutter doesn't save ID in SharedPreferences)
                val id = "todo_$index"

                android.util.Log.d("TodoListRemoteViewsFactory", "Loaded todo $index: $title (time: $time)")

                todoItems.add(
                    TodoItemData(
                        id = id,
                        title = title,
                        time = if (time.isEmpty()) null else time,
                        isCompleted = false, // Widget only shows pending todos
                        dateGroup = "Today"
                    )
                )
            }

            android.util.Log.d("TodoListRemoteViewsFactory", "Total todos loaded: ${todoItems.size}")
        } catch (e: Exception) {
            android.util.Log.e("TodoListRemoteViewsFactory", "Error loading todo data", e)
        }
    }

    private fun applyTheme(views: RemoteViews, theme: String) {
        val (titleColor, textColor, subTextColor) = when (theme) {
            "dark" -> Triple(
                Color.WHITE,
                Color.parseColor("#E0E0E0"),
                Color.parseColor("#9E9E9E")
            )
            "transparent" -> Triple(
                Color.WHITE,
                Color.WHITE,
                Color.parseColor("#E0E0E0")
            )
            "blue" -> Triple(
                Color.WHITE,
                Color.parseColor("#E3F2FD"),
                Color.parseColor("#BBDEFB")
            )
            "purple" -> Triple(
                Color.WHITE,
                Color.parseColor("#EDE7F6"),
                Color.parseColor("#D1C4E9")
            )
            else -> Triple(
                Color.parseColor("#212121"),
                Color.parseColor("#212121"),
                Color.parseColor("#757575")
            )
        }

        views.setTextColor(R.id.widget_item_title, textColor)
        views.setTextColor(R.id.widget_item_time, subTextColor)
    }
}
