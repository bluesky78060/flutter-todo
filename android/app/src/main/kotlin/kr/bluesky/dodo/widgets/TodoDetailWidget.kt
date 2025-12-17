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
 * Todo Detail Widget - Shows 2 todos with title AND description
 * Features:
 * - Multiple themes: light, dark, transparent, blue, purple
 * - Add button to open app with add todo action
 * - Checkbox to toggle todo completion
 * - Shows title and description for each todo
 */
class TodoDetailWidget : HomeWidgetProvider() {

    companion object {
        private const val TAG = "TodoDetailWidget"

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
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")

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

        val views = RemoteViews(context.packageName, R.layout.widget_todo_detail)

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
            3001,
            addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_detail_add_button, addPendingIntent)
        Log.d(TAG, "Add button click handler set")

        // Get progress data
        val completedCount = widgetData.getInt("todo_completed_count", 0)
        val totalCount = widgetData.getInt("todo_total_count", 0)

        // Update progress display
        val progressViewId = R.id.widget_detail_progress
        if (totalCount > 0) {
            val progressText = context.getString(R.string.widget_progress_format, completedCount, totalCount)
            views.setTextViewText(progressViewId, progressText)
            views.setViewVisibility(progressViewId, android.view.View.VISIBLE)
            val (_, _, timeColor) = getTextColors(theme)
            views.setTextColor(progressViewId, timeColor)
        } else {
            views.setViewVisibility(progressViewId, android.view.View.GONE)
        }

        // Load and display todos (2 items with title + description)
        try {
            for (index in 1..2) {
                val todoText = widgetData.getString("todo_${index}_text", null)
                val todoDescription = widgetData.getString("todo_${index}_description", "") ?: ""
                val todoId = widgetData.getString("todo_${index}_id", "") ?: ""
                val isCompleted = widgetData.getBoolean("todo_${index}_completed", false)

                val titleViewId = context.resources.getIdentifier(
                    "widget_detail_todo_${index}_title", "id", context.packageName
                )
                val descViewId = context.resources.getIdentifier(
                    "widget_detail_todo_${index}_desc", "id", context.packageName
                )
                val checkboxId = context.resources.getIdentifier(
                    "widget_detail_todo_${index}_checkbox", "id", context.packageName
                )
                val containerId = context.resources.getIdentifier(
                    "widget_detail_todo_${index}_container", "id", context.packageName
                )

                if (todoText != null && todoText.isNotEmpty()) {
                    // Show the container
                    if (containerId != 0) {
                        views.setViewVisibility(containerId, android.view.View.VISIBLE)
                    }

                    // Get theme-appropriate colors
                    val (textColor, completedColor, descColor) = getTextColors(theme)

                    // Update title
                    if (titleViewId != 0) {
                        views.setTextViewText(titleViewId, todoText)
                        if (isCompleted) {
                            views.setTextColor(titleViewId, completedColor)
                        } else {
                            views.setTextColor(titleViewId, textColor)
                        }
                    }

                    // Update description
                    if (descViewId != 0) {
                        if (todoDescription.isNotEmpty()) {
                            views.setTextViewText(descViewId, todoDescription)
                            views.setTextColor(descViewId, descColor)
                            views.setViewVisibility(descViewId, android.view.View.VISIBLE)
                        } else {
                            views.setViewVisibility(descViewId, android.view.View.GONE)
                        }
                    }

                    // Update checkbox appearance
                    if (checkboxId != 0) {
                        if (isCompleted) {
                            views.setImageViewResource(checkboxId, R.drawable.widget_checkbox_checked)
                        } else {
                            views.setImageViewResource(checkboxId, R.drawable.widget_checkbox_unchecked)
                        }

                        // Set checkbox click handler
                        val toggleIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                            action = "kr.bluesky.dodo.widget.TOGGLE_TODO"
                            putExtra("todo_id", todoId)
                            putExtra("todo_index", index)
                            putExtra("widget_id", appWidgetId)
                        }
                        val togglePendingIntent = PendingIntent.getBroadcast(
                            context,
                            4000 + index,
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                        )
                        views.setOnClickPendingIntent(checkboxId, togglePendingIntent)
                    }

                    Log.d(TAG, "Updated todo $index: $todoText (desc: $todoDescription, completed: $isCompleted)")
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

        views.setInt(R.id.widget_detail_container, "setBackgroundResource", bgResId)

        // Apply title color based on theme
        val titleColor = when (theme) {
            THEME_LIGHT -> Color.parseColor("#212121")
            THEME_TRANSPARENT -> Color.WHITE
            else -> Color.WHITE
        }
        views.setTextColor(R.id.widget_detail_title, titleColor)

        // Menu button removed from new design
    }

    /**
     * Get text colors based on theme
     * Returns Triple(textColor, completedColor, descColor)
     */
    private fun getTextColors(theme: String): Triple<Int, Int, Int> {
        return when (theme) {
            THEME_LIGHT -> Triple(
                Color.parseColor("#212121"),
                Color.parseColor("#9E9E9E"),
                Color.parseColor("#757575")
            )
            THEME_TRANSPARENT -> Triple(
                Color.WHITE,
                Color.parseColor("#AAAAAA"),
                Color.parseColor("#CCCCCC")
            )
            THEME_DARK -> Triple(
                Color.WHITE,
                Color.parseColor("#888888"),
                Color.parseColor("#888888")
            )
            THEME_BLUE -> Triple(
                Color.WHITE,
                Color.parseColor("#90CAF9"),
                Color.parseColor("#BBDEFB")
            )
            THEME_PURPLE -> Triple(
                Color.WHITE,
                Color.parseColor("#B39DDB"),
                Color.parseColor("#D1C4E9")
            )
            else -> Triple(
                Color.WHITE,
                Color.parseColor("#888888"),
                Color.parseColor("#888888")
            )
        }
    }
}
