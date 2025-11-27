package kr.bluesky.dodo.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import kr.bluesky.dodo.R
import android.util.Log

/**
 * Today's Todo List Widget - Static layout with dynamic data updates
 * Updates widget with top 5 pending todos from SharedPreferences
 * Supports multiple themes and direct widget interactions
 */
class TodoListWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")

        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        Log.d(TAG, "Updating widget $appWidgetId")

        // Create the RemoteViews object with static layout
        val views = RemoteViews(context.packageName, R.layout.widget_todo_list)

        // Load todo data from SharedPreferences and update views
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            // Load and display top 5 todos
            for (index in 1..5) {
                val todoText = prefs.getString("todo_${index}_text", null)
                val todoTime = prefs.getString("todo_${index}_time", "") ?: ""

                if (todoText != null) {
                    // Update text
                    views.setTextViewText(context.resources.getIdentifier(
                        "widget_todo_${index}_text", "id", context.packageName
                    ), todoText)

                    // Update time if available
                    if (todoTime.isNotEmpty()) {
                        views.setTextViewText(context.resources.getIdentifier(
                            "widget_todo_${index}_time", "id", context.packageName
                        ), todoTime)
                    }

                    Log.d(TAG, "Updated todo $index: $todoText (time: $todoTime)")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading todo data", e)
        }

        // Update the app widget
        appWidgetManager.updateAppWidget(appWidgetId, views)

        Log.d(TAG, "Widget $appWidgetId updated")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "Widget received broadcast: ${intent.action}")

        // If widget data updated, refresh all widgets
        if (intent.action == "android.appwidget.action.APPWIDGET_UPDATE") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, TodoListWidget::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        private const val TAG = "TodoListWidget"
    }
}
