package kr.bluesky.dodo.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import kr.bluesky.dodo.R
import kr.bluesky.dodo.MainActivity
import android.util.Log

/**
 * Today's Todo List Widget - Using HomeWidgetProvider (home_widget 0.8.1)
 * Features:
 * - Multiple themes: light, dark, transparent, blue, purple
 * - Add button to open app with add todo action
 * - Checkbox to toggle todo completion
 * - Click on todo to open app
 */
class TodoListWidget : HomeWidgetProvider() {

    companion object {
        private const val TAG = "TodoListWidget"

        const val THEME_LIGHT = "light"
        const val THEME_DARK = "dark"
        const val THEME_TRANSPARENT = "transparent"
        const val THEME_BLUE = "blue"
        const val THEME_PURPLE = "purple"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets with HomeWidgetProvider")

        appWidgetIds.forEach { widgetId ->
            updateAppWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "Updating widget $appWidgetId")

        val views = RemoteViews(context.packageName, R.layout.widget_todo_list)

        // Get theme setting
        val theme = widgetData.getString("widget_theme", THEME_DARK) ?: THEME_DARK
        Log.d(TAG, "Applying theme: $theme")

        // Apply theme
        applyTheme(context, views, theme)

        // Set up Add Button click - opens app with add todo action
        val addIntent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("dodo://add-todo")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addPendingIntent = PendingIntent.getActivity(
            context,
            1001,
            addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_add_button, addPendingIntent)
        Log.d(TAG, "Add button click handler set")

        // NOTE: Container click to open app is removed per user request
        // Only the + (add) button will open the app now

        // Load and display todos (3 items - today's todos only)
        try {
            for (index in 1..3) {
                val todoText = widgetData.getString("todo_${index}_text", null)
                val todoTime = widgetData.getString("todo_${index}_time", "") ?: ""
                val todoId = widgetData.getString("todo_${index}_id", "") ?: ""
                val isCompleted = widgetData.getBoolean("todo_${index}_completed", false)

                val textViewId = context.resources.getIdentifier(
                    "widget_todo_${index}_text", "id", context.packageName
                )
                val timeViewId = context.resources.getIdentifier(
                    "widget_todo_${index}_time", "id", context.packageName
                )
                val checkboxId = context.resources.getIdentifier(
                    "widget_todo_${index}_checkbox", "id", context.packageName
                )
                val containerId = context.resources.getIdentifier(
                    "widget_todo_${index}_container", "id", context.packageName
                )

                if (todoText != null && todoText.isNotEmpty()) {
                    // Show the container
                    if (containerId != 0) {
                        views.setViewVisibility(containerId, android.view.View.VISIBLE)
                    }

                    // Get theme-appropriate colors
                    val (textColor, completedColor, timeColor) = getTextColors(theme)

                    // Update text
                    if (textViewId != 0) {
                        views.setTextViewText(textViewId, todoText)
                        // Apply different color for completed items
                        if (isCompleted) {
                            views.setTextColor(textViewId, completedColor)
                        } else {
                            views.setTextColor(textViewId, textColor)
                        }
                    }

                    // Update time
                    if (timeViewId != 0 && todoTime.isNotEmpty()) {
                        views.setTextViewText(timeViewId, todoTime)
                        views.setTextColor(timeViewId, timeColor)
                        views.setViewVisibility(timeViewId, android.view.View.VISIBLE)
                    } else if (timeViewId != 0) {
                        views.setViewVisibility(timeViewId, android.view.View.GONE)
                    }

                    // Update checkbox appearance
                    if (checkboxId != 0) {
                        if (isCompleted) {
                            views.setImageViewResource(checkboxId, R.drawable.widget_checkbox_checked)
                        } else {
                            views.setImageViewResource(checkboxId, R.drawable.widget_checkbox_unchecked)
                        }

                        // Set checkbox click handler - toggle completion via BroadcastReceiver (no app launch)
                        val toggleIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                            action = "kr.bluesky.dodo.widget.TOGGLE_TODO"
                            putExtra("todo_id", todoId)
                            putExtra("todo_index", index)
                            putExtra("widget_id", appWidgetId)
                        }
                        val togglePendingIntent = PendingIntent.getBroadcast(
                            context,
                            2000 + index,
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                        )
                        views.setOnClickPendingIntent(checkboxId, togglePendingIntent)
                    }

                    Log.d(TAG, "Updated todo $index: $todoText (time: $todoTime, completed: $isCompleted)")
                } else {
                    // Hide empty todo items
                    if (containerId != 0) {
                        views.setViewVisibility(containerId, android.view.View.GONE)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading todo data", e)
        }

        // Update the app widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
        Log.d(TAG, "Widget $appWidgetId updated successfully")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "Widget received broadcast: ${intent.action}")
    }

    /**
     * Apply theme to widget
     */
    private fun applyTheme(context: Context, views: RemoteViews, theme: String) {
        val bgResId = when (theme) {
            THEME_LIGHT -> R.drawable.widget_background
            THEME_DARK -> R.drawable.widget_background_dark
            THEME_TRANSPARENT -> R.drawable.widget_background_transparent
            THEME_BLUE -> R.drawable.widget_background_blue
            THEME_PURPLE -> R.drawable.widget_background_purple
            else -> R.drawable.widget_background_dark
        }

        views.setInt(R.id.widget_container, "setBackgroundResource", bgResId)

        // Apply title color based on theme
        val titleColor = when (theme) {
            THEME_LIGHT -> Color.parseColor("#212121")
            THEME_TRANSPARENT -> Color.WHITE // White text for dark wallpaper visibility
            else -> Color.WHITE // Dark, Blue, Purple use white text
        }
        views.setTextColor(R.id.widget_title, titleColor)

        // Apply menu button color
        val menuColor = when (theme) {
            THEME_LIGHT -> Color.parseColor("#757575")
            THEME_TRANSPARENT -> Color.parseColor("#CCCCCC") // Light gray for dark wallpaper
            else -> Color.parseColor("#888888")
        }
        views.setTextColor(R.id.widget_menu_button, menuColor)
    }

    /**
     * Get text colors based on theme
     * Returns Triple(textColor, completedColor, timeColor)
     */
    private fun getTextColors(theme: String): Triple<Int, Int, Int> {
        return when (theme) {
            THEME_LIGHT -> Triple(
                Color.parseColor("#212121"), // text
                Color.parseColor("#9E9E9E"), // completed
                Color.parseColor("#757575")  // time
            )
            THEME_TRANSPARENT -> Triple(
                Color.WHITE,                  // text - white for dark wallpaper visibility
                Color.parseColor("#AAAAAA"), // completed - light gray
                Color.parseColor("#CCCCCC")  // time - light gray
            )
            THEME_DARK -> Triple(
                Color.WHITE,                  // text
                Color.parseColor("#888888"), // completed
                Color.parseColor("#888888")  // time
            )
            THEME_BLUE -> Triple(
                Color.WHITE,                  // text
                Color.parseColor("#90CAF9"), // completed
                Color.parseColor("#BBDEFB")  // time
            )
            THEME_PURPLE -> Triple(
                Color.WHITE,                  // text
                Color.parseColor("#B39DDB"), // completed
                Color.parseColor("#D1C4E9")  // time
            )
            else -> Triple(
                Color.WHITE,
                Color.parseColor("#888888"),
                Color.parseColor("#888888")
            )
        }
    }
}
